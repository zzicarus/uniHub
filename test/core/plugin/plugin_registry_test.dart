import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:uni_hub/src/core/database/tables/saved_items_table.dart';
import 'package:uni_hub/src/core/database/tables/thoughts_table.dart';
import 'package:uni_hub/src/core/plugin/plugin_interface.dart';
import 'package:uni_hub/src/core/plugin/plugin_registry.dart';
import 'package:uni_hub/src/core/search/search_result.dart';

/// A minimal test plugin for registry tests.
class _TestPlugin extends UniHubPlugin {
  _TestPlugin({
    required this.idValue,
    required this.nameValue,
    required this.routePath,
    required this.routeName,
    required this.navLabel,
    String? navPath,
    required this.tableTypes,
  }) : navPath = navPath ?? routePath;

  factory _TestPlugin.one() => _TestPlugin(
    idValue: 'test',
    nameValue: 'Test Plugin',
    routePath: '/test',
    routeName: 'test',
    navLabel: 'Test',
    tableTypes: const [ThoughtsTable],
  );

  factory _TestPlugin.two() => _TestPlugin(
    idValue: 'other',
    nameValue: 'Other Plugin',
    routePath: '/other',
    routeName: 'other',
    navLabel: 'Other',
    tableTypes: const [SavedItemsTable],
  );

  final String idValue;
  final String nameValue;
  final String routePath;
  final String routeName;
  final String navLabel;
  final String navPath;
  final List<Type> tableTypes;

  bool initCalled = false;
  bool disposeCalled = false;

  @override
  String get id => idValue;

  @override
  String get name => nameValue;

  @override
  List<NavEntry> get navEntries => [
    NavEntry(
      label: navLabel,
      icon: Icons.star,
      routeName: routeName,
      path: navPath,
    ),
  ];

  @override
  List<GoRoute> get routes => [
    GoRoute(
      path: routePath,
      name: routeName,
      builder: (context, state) => const SizedBox.shrink(),
    ),
  ];

  @override
  List<Type> get tables => tableTypes;

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

      registry.register(_TestPlugin.one());
      expect(registry.plugins, hasLength(1));
    });

    test('returns unmodifiable plugin list', () {
      final registry = PluginRegistry();
      registry.register(_TestPlugin.one());

      expect(() => registry.plugins.clear(), throwsUnsupportedError);
    });

    test('merges nav entries from all plugins', () {
      final registry = PluginRegistry();
      registry.register(_TestPlugin.one());

      final entries = registry.navEntries;
      expect(entries, hasLength(1));
      expect(entries.first.label, 'Test');
      expect(entries.first.path, '/test');
    });

    test('merges routes from all plugins', () {
      final registry = PluginRegistry();
      registry.register(_TestPlugin.one());

      final routes = registry.mergedRoutes;
      expect(routes, hasLength(1));
      expect(routes.first.path, '/test');
      expect(routes.first.name, 'test');
    });

    test('initAll calls onInit for each plugin', () async {
      final registry = PluginRegistry();
      final plugin = _TestPlugin.one();
      registry.register(plugin);

      expect(plugin.initCalled, false);
      await registry.initAll();
      expect(plugin.initCalled, true);
    });

    test('disposeAll calls onDispose in reverse order', () async {
      final registry = PluginRegistry();
      final plugin1 = _TestPlugin.one();
      final plugin2 = _TestPlugin.two();
      registry.register(plugin1);
      registry.register(plugin2);

      await registry.disposeAll();
      expect(plugin1.disposeCalled, true);
      expect(plugin2.disposeCalled, true);
    });

    test('multiple plugins contribute entries and routes', () {
      final registry = PluginRegistry();
      registry.register(_TestPlugin.one());
      registry.register(_TestPlugin.two());

      expect(registry.navEntries, hasLength(2));
      expect(registry.mergedRoutes, hasLength(2));
    });

    test('rejects duplicate plugin id', () {
      final registry = PluginRegistry();
      registry.register(_TestPlugin.one());

      expect(
        () => registry.register(
          _TestPlugin(
            idValue: 'test',
            nameValue: 'Duplicate Id',
            routePath: '/duplicate-id',
            routeName: 'duplicateId',
            navLabel: 'Duplicate Id',
            tableTypes: const [],
          ),
        ),
        throwsStateError,
      );
    });

    test('rejects duplicate route path', () {
      final registry = PluginRegistry();
      registry.register(_TestPlugin.one());

      expect(
        () => registry.register(
          _TestPlugin(
            idValue: 'duplicate-route-path',
            nameValue: 'Duplicate Route Path',
            routePath: '/test',
            routeName: 'duplicateRoutePath',
            navLabel: 'Duplicate Route Path',
            tableTypes: const [],
          ),
        ),
        throwsStateError,
      );
    });

    test('rejects duplicate route name', () {
      final registry = PluginRegistry();
      registry.register(_TestPlugin.one());

      expect(
        () => registry.register(
          _TestPlugin(
            idValue: 'duplicate-route-name',
            nameValue: 'Duplicate Route Name',
            routePath: '/duplicate-route-name',
            routeName: 'test',
            navLabel: 'Duplicate Route Name',
            tableTypes: const [],
          ),
        ),
        throwsStateError,
      );
    });

    test('rejects duplicate nav label', () {
      final registry = PluginRegistry();
      registry.register(_TestPlugin.one());

      expect(
        () => registry.register(
          _TestPlugin(
            idValue: 'duplicate-nav-label',
            nameValue: 'Duplicate Nav Label',
            routePath: '/duplicate-nav-label',
            routeName: 'duplicateNavLabel',
            navLabel: 'Test',
            tableTypes: const [],
          ),
        ),
        throwsStateError,
      );
    });

    test('rejects duplicate nav path', () {
      final registry = PluginRegistry();
      registry.register(_TestPlugin.one());

      expect(
        () => registry.register(
          _TestPlugin(
            idValue: 'duplicate-nav-path',
            nameValue: 'Duplicate Nav Path',
            routePath: '/duplicate-nav-path',
            routeName: 'duplicateNavPath',
            navLabel: 'Duplicate Nav Path',
            navPath: '/test',
            tableTypes: const [],
          ),
        ),
        throwsStateError,
      );
    });

    test('rejects duplicate table declaration', () {
      final registry = PluginRegistry();
      registry.register(_TestPlugin.one());

      expect(
        () => registry.register(
          _TestPlugin(
            idValue: 'duplicate-table',
            nameValue: 'Duplicate Table',
            routePath: '/duplicate-table',
            routeName: 'duplicateTable',
            navLabel: 'Duplicate Table',
            tableTypes: const [ThoughtsTable],
          ),
        ),
        throwsStateError,
      );
    });
  });
}
