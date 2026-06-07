import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uni_hub/src/core/plugin/plugin_interface.dart';
import 'package:uni_hub/src/core/plugin/plugin_registry.dart';

/// A fake plugin that handles quick-create for URL-like content.
class _FakeCollectionsPlugin extends UniHubPlugin {
  @override
  String get id => 'collections';

  @override
  String get name => 'FakeCollections';

  @override
  bool canHandleQuickCreate(String content) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return false;
    return trimmed.startsWith('http') ||
        trimmed.contains('.') && !trimmed.contains(' ');
  }

  @override
  Future<DashboardItem?> quickCreate(
    Ref ref, {
    required String content,
    String? tags,
  }) async {
    return DashboardItem(
      pluginId: 'collections',
      itemId: '1',
      content: content,
      createdAt: DateTime.now(),
      routePath: '/collections',
    );
  }
}

/// A fake plugin that handles quick-create for plain-text content.
class _FakeThoughtsPlugin extends UniHubPlugin {
  @override
  String get id => 'thoughts';

  @override
  String get name => 'FakeThoughts';

  @override
  bool canHandleQuickCreate(String content) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return false;
    return !trimmed.startsWith('http') &&
        !(trimmed.contains('.') && !trimmed.contains(' '));
  }

  @override
  Future<DashboardItem?> quickCreate(
    Ref ref, {
    required String content,
    String? tags,
  }) async {
    return DashboardItem(
      pluginId: 'thoughts',
      itemId: '1',
      content: content,
      createdAt: DateTime.now(),
      routePath: '/thoughts',
    );
  }
}

void main() {
  late PluginRegistry registry;

  setUp(() {
    registry = PluginRegistry();
    registry.register(_FakeCollectionsPlugin());
    registry.register(_FakeThoughtsPlugin());
  });

  group('canHandleQuickCreate dispatch', () {
    test('URL → collections canHandleQuickCreate returns true', () {
      final collectionsPlugin = _FakeCollectionsPlugin();
      expect(collectionsPlugin.canHandleQuickCreate('https://example.com'),
          isTrue);
      expect(collectionsPlugin.canHandleQuickCreate('example.com'), isTrue);
      expect(collectionsPlugin.canHandleQuickCreate('www.example.com'), isTrue);
    });

    test('URL → thoughts canHandleQuickCreate returns false', () {
      final thoughtsPlugin = _FakeThoughtsPlugin();
      expect(thoughtsPlugin.canHandleQuickCreate('https://example.com'),
          isFalse);
      expect(thoughtsPlugin.canHandleQuickCreate('example.com'), isFalse);
    });

    test('text → thoughts canHandleQuickCreate returns true', () {
      final thoughtsPlugin = _FakeThoughtsPlugin();
      expect(
          thoughtsPlugin.canHandleQuickCreate('今天记录一个想法'), isTrue);
      expect(thoughtsPlugin.canHandleQuickCreate('#Flutter 学习记录'), isTrue);
      expect(thoughtsPlugin.canHandleQuickCreate('not a url'), isTrue);
    });

    test('text → collections canHandleQuickCreate returns false', () {
      final collectionsPlugin = _FakeCollectionsPlugin();
      expect(
          collectionsPlugin.canHandleQuickCreate('今天记录一个想法'), isFalse);
      expect(collectionsPlugin.canHandleQuickCreate('#Flutter 学习记录'),
          isFalse);
    });

    test('registry dispatch: URL handled only by collections', () async {
      bool collectionsCanHandle = false;
      bool thoughtsCanHandle = false;

      for (final p in registry.plugins) {
        if (p.canHandleQuickCreate('https://example.com')) {
          if (p.id == 'collections') collectionsCanHandle = true;
          if (p.id == 'thoughts') thoughtsCanHandle = true;
        }
      }

      expect(collectionsCanHandle, isTrue);
      expect(thoughtsCanHandle, isFalse);
    });

    test('registry dispatch: text handled only by thoughts', () async {
      bool collectionsCanHandle = false;
      bool thoughtsCanHandle = false;

      for (final p in registry.plugins) {
        if (p.canHandleQuickCreate('今天记录一个想法')) {
          if (p.id == 'collections') collectionsCanHandle = true;
          if (p.id == 'thoughts') thoughtsCanHandle = true;
        }
      }

      expect(collectionsCanHandle, isFalse);
      expect(thoughtsCanHandle, isTrue);
    });
  });
}
