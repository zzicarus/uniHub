import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uni_hub/src/core/app/dashboard_providers.dart';
import 'package:uni_hub/src/core/database/app_database.dart';
import 'package:uni_hub/src/core/database/database_provider.dart';
import 'package:uni_hub/src/core/plugin/plugin_interface.dart';
import 'package:uni_hub/src/core/plugin/plugin_registry.dart';
import 'package:uni_hub/src/plugins/thoughts/data/thought_content_codec.dart';
import 'package:uni_hub/src/plugins/thoughts/thoughts_plugin.dart';

/// A minimal stub plugin that returns controlled dashboard data.
class _StubPlugin extends UniHubPlugin {
  final PluginStat? stat;
  final List<DashboardItem> items;
  final List<DashboardItem> pinned;

  _StubPlugin({this.stat, this.items = const [], this.pinned = const []});

  @override
  String get id => 'stub';
  @override
  String get name => 'Stub Plugin';

  @override
  Future<PluginStat?> getStat(Ref ref) async => stat;

  @override
  Future<List<DashboardItem>> getRecentItems(Ref ref, {int count = 4}) async =>
      items;

  @override
  Future<List<DashboardItem>> getPinnedItems(Ref ref, {int count = 3}) async =>
      pinned;
}

/// A stub plugin that returns no data (empty) for all dashboard methods.
class _EmptyPlugin extends UniHubPlugin {
  _EmptyPlugin();

  @override
  String get id => 'empty';
  @override
  String get name => 'Empty Plugin';
}

void main() {
  late DateTime now;

  setUp(() {
    now = DateTime(2026, 5, 21);
  });

  group('dashboardStatsProvider', () {
    test('empty registry returns empty list', () async {
      final registry = PluginRegistry();
      final container = ProviderContainer(
        overrides: [pluginRegistryProvider.overrideWithValue(registry)],
      );
      addTearDown(() => container.dispose());

      final stats = await container.read(dashboardStatsProvider.future);
      expect(stats, isEmpty);
    });

    test('registry with one stub plugin returns its stats', () async {
      final stat = const PluginStat(
        pluginId: 'stub',
        label: 'Test Stat',
        count: 42,
      );
      final registry = PluginRegistry();
      registry.register(_StubPlugin(stat: stat));
      final container = ProviderContainer(
        overrides: [pluginRegistryProvider.overrideWithValue(registry)],
      );
      addTearDown(() => container.dispose());

      final stats = await container.read(dashboardStatsProvider.future);
      expect(stats, hasLength(1));
      expect(stats.first.pluginId, 'stub');
      expect(stats.first.label, 'Test Stat');
      expect(stats.first.count, 42);
    });

    test('registry with empty plugin returns empty list', () async {
      final registry = PluginRegistry();
      registry.register(_EmptyPlugin());
      final container = ProviderContainer(
        overrides: [pluginRegistryProvider.overrideWithValue(registry)],
      );
      addTearDown(() => container.dispose());

      final stats = await container.read(dashboardStatsProvider.future);
      expect(stats, isEmpty);
    });
  });

  group('dashboardItemsProvider', () {
    test('empty registry returns empty list', () async {
      final registry = PluginRegistry();
      final container = ProviderContainer(
        overrides: [pluginRegistryProvider.overrideWithValue(registry)],
      );
      addTearDown(() => container.dispose());

      final items = await container.read(dashboardItemsProvider.future);
      expect(items, isEmpty);
    });

    test('registry with one stub plugin returns its items', () async {
      final dashboardItem = DashboardItem(
        pluginId: 'stub',
        itemId: '1',
        content: 'Test item',
        createdAt: now,
        routePath: '/test',
      );
      final registry = PluginRegistry();
      registry.register(_StubPlugin(items: [dashboardItem]));
      final container = ProviderContainer(
        overrides: [pluginRegistryProvider.overrideWithValue(registry)],
      );
      addTearDown(() => container.dispose());

      final items = await container.read(dashboardItemsProvider.future);
      expect(items, hasLength(1));
      expect(items.first.pluginId, 'stub');
      expect(items.first.content, 'Test item');
    });
  });

  group('quickCreateProvider', () {
    test('ThoughtsPlugin writes AppFlowy JSON content', () async {
      final registry = PluginRegistry()..register(ThoughtsPlugin());
      final db = AppDatabase(NativeDatabase.memory(), registry);
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          pluginRegistryProvider.overrideWithValue(registry),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(db.close);

      final item = await container.read(
        quickCreateProvider((
          content: 'AppFlowy quick create',
          tags: 'idea',
        )).future,
      );

      expect(item?.content, 'AppFlowy quick create');
      final thoughts = await db.select(db.thoughtsTable).get();
      expect(thoughts, hasLength(1));

      final stored = jsonDecode(thoughts.single.content);
      expect(stored, isA<Map<String, dynamic>>());
      final envelope = stored as Map<String, dynamic>;
      expect(envelope['format'], ThoughtContentCodec.format);
      expect(envelope['plainText'], 'AppFlowy quick create');
      expect(envelope['document'], isA<Map<String, dynamic>>());
    });
  });

  group('dashboardPinnedProvider', () {
    test('empty registry returns empty list', () async {
      final registry = PluginRegistry();
      final container = ProviderContainer(
        overrides: [pluginRegistryProvider.overrideWithValue(registry)],
      );
      addTearDown(() => container.dispose());

      final pinned = await container.read(dashboardPinnedProvider.future);
      expect(pinned, isEmpty);
    });

    test('registry with one stub plugin returns its pinned items', () async {
      final pinnedItem = DashboardItem(
        pluginId: 'stub',
        itemId: 'p1',
        content: 'Pinned item',
        isPinned: true,
        createdAt: now,
        routePath: '/test',
      );
      final registry = PluginRegistry();
      registry.register(_StubPlugin(pinned: [pinnedItem]));
      final container = ProviderContainer(
        overrides: [pluginRegistryProvider.overrideWithValue(registry)],
      );
      addTearDown(() => container.dispose());

      final pinned = await container.read(dashboardPinnedProvider.future);
      expect(pinned, hasLength(1));
      expect(pinned.first.pluginId, 'stub');
      expect(pinned.first.content, 'Pinned item');
      expect(pinned.first.isPinned, isTrue);
    });
  });
}
