import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:uni_hub/src/core/plugin/plugin_interface.dart';
import 'package:uni_hub/src/core/plugin/plugin_registry.dart';
import 'package:uni_hub/src/core/search/search_result.dart';

/// A minimal test plugin for registry tests.
class _TestPlugin extends UniHubPlugin {
  @override
  String get id => 'test';
  @override
  String get name => 'Test Plugin';

  bool initCalled = false;
  bool disposeCalled = false;

  @override
  List<NavEntry> get navEntries => [
    const NavEntry(
      label: 'Test',
      icon: Icons.star,
      routeName: 'test',
      path: '/test',
    ),
  ];

  @override
  List<GoRoute> get routes => [
    GoRoute(
      path: '/test',
      name: 'test',
      builder: (context, state) => const SizedBox.shrink(),
    ),
  ];

  @override
  Future<void> onInit() async {
    initCalled = true;
  }

  @override
  Future<void> onDispose() async {
    disposeCalled = true;
  }

  @override
  Future<List<SearchResult>> search(String query) async {
    if (query == 'match') {
      return [
        const SearchResult(
          id: '1',
          title: 'Test Result',
          routeName: 'test',
          pluginId: 'test',
          score: 1.0,
        ),
      ];
    }
    return [];
  }
}

void main() {
  group('PluginRegistry', () {
    test('registers and returns plugins', () {
      final registry = PluginRegistry();
      expect(registry.plugins, isEmpty);

      registry.register(_TestPlugin());
      expect(registry.plugins, hasLength(1));
    });

    test('returns unmodifiable plugin list', () {
      final registry = PluginRegistry();
      registry.register(_TestPlugin());

      expect(() => registry.plugins.clear(), throwsUnsupportedError);
    });

    test('merges nav entries from all plugins', () {
      final registry = PluginRegistry();
      registry.register(_TestPlugin());

      final entries = registry.navEntries;
      expect(entries, hasLength(1));
      expect(entries.first.label, 'Test');
      expect(entries.first.path, '/test');
    });

    test('merges routes from all plugins', () {
      final registry = PluginRegistry();
      registry.register(_TestPlugin());

      final routes = registry.mergedRoutes;
      expect(routes, hasLength(1));
      expect(routes.first.path, '/test');
      expect(routes.first.name, 'test');
    });

    test('initAll calls onInit for each plugin', () async {
      final registry = PluginRegistry();
      final plugin = _TestPlugin();
      registry.register(plugin);

      expect(plugin.initCalled, false);
      await registry.initAll();
      expect(plugin.initCalled, true);
    });

    test('disposeAll calls onDispose in reverse order', () async {
      final registry = PluginRegistry();
      final plugin1 = _TestPlugin();
      final plugin2 = _TestPlugin();
      registry.register(plugin1);
      registry.register(plugin2);

      await registry.disposeAll();
      expect(plugin1.disposeCalled, true);
      expect(plugin2.disposeCalled, true);
    });

    test('multiple plugins contribute entries and routes', () {
      final registry = PluginRegistry();
      registry.register(_TestPlugin());
      registry.register(_TestPlugin());

      expect(registry.navEntries, hasLength(2));
      expect(registry.mergedRoutes, hasLength(2));
    });
  });
}
