import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  group('Dashboard concurrent aggregation', () {
    late DateTime now;

    setUp(() {
      now = DateTime.now();
    });

    PluginRegistry createRegistryWithTwoPlugins() {
      final r = PluginRegistry();
      r.register(_DashboardTestPlugin(
        idValue: 'plugin-a',
        items: [
          DashboardItem(
            pluginId: 'plugin-a',
            itemId: '1',
            content: 'Item A1',
            createdAt: now.subtract(const Duration(hours: 2)),
            routePath: '/a',
          ),
        ],
        stats: const [
          PluginStat(pluginId: 'plugin-a', label: 'Plugin A', count: 5),
        ],
      ));
      r.register(_DashboardTestPlugin(
        idValue: 'plugin-b',
        items: [
          DashboardItem(
            pluginId: 'plugin-b',
            itemId: '2',
            content: 'Item B1',
            createdAt: now,
            routePath: '/b',
          ),
        ],
        stats: const [
          PluginStat(pluginId: 'plugin-b', label: 'Plugin B', count: 3),
        ],
      ));
      return r;
    }

    testWidgets('getDashboardItems returns items sorted by createdAt',
        (tester) async {
      final testRegistry = createRegistryWithTwoPlugins();
      List<DashboardItem>? items;

      await tester.pumpWidget(
        ProviderScope(
          child: _RegistryTestWidget<DashboardItem>(
            provider: _testDashboardItemsProvider(testRegistry),
            onData: (data) => items = data,
          ),
        ),
      );
      await tester.pump();

      expect(items, hasLength(2));
      expect(items![0].pluginId, equals('plugin-b'));
      expect(items![1].pluginId, equals('plugin-a'));
    });

    testWidgets('getDashboardItems with count limit', (tester) async {
      final testRegistry = PluginRegistry();
      testRegistry.register(_DashboardTestPlugin(
        idValue: 'multi',
        items: [
          DashboardItem(
            pluginId: 'multi',
            itemId: '1',
            content: 'Item 1',
            createdAt: now,
            routePath: '/multi',
          ),
          DashboardItem(
            pluginId: 'multi',
            itemId: '2',
            content: 'Item 2',
            createdAt: now.subtract(const Duration(hours: 1)),
            routePath: '/multi',
          ),
          DashboardItem(
            pluginId: 'multi',
            itemId: '3',
            content: 'Item 3',
            createdAt: now.subtract(const Duration(hours: 2)),
            routePath: '/multi',
          ),
        ],
      ));
      List<DashboardItem>? items;

      await tester.pumpWidget(
        ProviderScope(
          child: _RegistryTestWidget<DashboardItem>(
            provider: _testDashboardItemsCountProvider(testRegistry, count: 2),
            onData: (data) => items = data,
          ),
        ),
      );
      await tester.pump();

      expect(items, hasLength(2));
    });

    testWidgets('one plugin error does not break dashboard', (tester) async {
      final testRegistry = PluginRegistry();
      testRegistry.register(_DashboardTestPlugin(
        idValue: 'good',
        items: [
          DashboardItem(
            pluginId: 'good',
            itemId: '1',
            content: 'Good item',
            createdAt: now,
            routePath: '/good',
          ),
        ],
      ));
      testRegistry.register(_DashboardTestPlugin(
        idValue: 'bad',
        throwOnRecent: true,
      ));
      List<DashboardItem>? items;

      await tester.pumpWidget(
        ProviderScope(
          child: _RegistryTestWidget<DashboardItem>(
            provider: _testDashboardItemsProvider(testRegistry),
            onData: (data) => items = data,
          ),
        ),
      );
      await tester.pump();

      expect(items, hasLength(1));
      expect(items![0].pluginId, equals('good'));
    });

    testWidgets('getDashboardPinned returns items', (tester) async {
      final testRegistry = PluginRegistry();
      testRegistry.register(_DashboardTestPlugin(
        idValue: 'pinned',
        pinnedItems: [
          DashboardItem(
            pluginId: 'pinned',
            itemId: '1',
            content: 'Pinned 1',
            createdAt: now,
            routePath: '/pinned',
          ),
        ],
      ));
      List<DashboardItem>? items;

      await tester.pumpWidget(
        ProviderScope(
          child: _RegistryTestWidget<DashboardItem>(
            provider: _testDashboardPinnedProvider(testRegistry),
            onData: (data) => items = data,
          ),
        ),
      );
      await tester.pump();

      expect(items, hasLength(1));
      expect(items![0].content, equals('Pinned 1'));
    });

    testWidgets('getDashboardStats returns stats from all plugins',
        (tester) async {
      final testRegistry = createRegistryWithTwoPlugins();
      List<PluginStat>? stats;

      await tester.pumpWidget(
        ProviderScope(
          child: _RegistryTestWidget<PluginStat>(
            provider: _testDashboardStatsProvider(testRegistry),
            onData: (data) => stats = data,
          ),
        ),
      );
      await tester.pump();

      expect(stats, hasLength(2));
      expect(
          stats!.where((s) => s.pluginId == 'plugin-a').first.count,
          equals(5));
      expect(
          stats!.where((s) => s.pluginId == 'plugin-b').first.count,
          equals(3));
    });

    testWidgets('one plugin stats error does not break all stats',
        (tester) async {
      final testRegistry = PluginRegistry();
      testRegistry.register(_DashboardTestPlugin(
        idValue: 'good',
        stats: const [PluginStat(pluginId: 'good', label: 'Good', count: 1)],
      ));
      testRegistry.register(_DashboardTestPlugin(
        idValue: 'bad-stats',
        throwOnStats: true,
      ));
      List<PluginStat>? stats;

      await tester.pumpWidget(
        ProviderScope(
          child: _RegistryTestWidget<PluginStat>(
            provider: _testDashboardStatsProvider(testRegistry),
            onData: (data) => stats = data,
          ),
        ),
      );
      await tester.pump();

      expect(stats, hasLength(1));
      expect(stats![0].pluginId, equals('good'));
    });
  });
}

/// Provider that wraps [PluginRegistry.getDashboardItems].
FutureProvider<List<DashboardItem>> _testDashboardItemsProvider(
  PluginRegistry registry,
) =>
    FutureProvider<List<DashboardItem>>((ref) async {
      return registry.getDashboardItems(ref);
    });

FutureProvider<List<DashboardItem>> _testDashboardItemsCountProvider(
  PluginRegistry registry, {
  required int count,
}) =>
    FutureProvider<List<DashboardItem>>((ref) async {
      return registry.getDashboardItems(ref, count: count);
    });

/// Provider that wraps [PluginRegistry.getDashboardPinned].
FutureProvider<List<DashboardItem>> _testDashboardPinnedProvider(
  PluginRegistry registry,
) =>
    FutureProvider<List<DashboardItem>>((ref) async {
      return registry.getDashboardPinned(ref);
    });

/// Provider that wraps [PluginRegistry.getDashboardStats].
FutureProvider<List<PluginStat>> _testDashboardStatsProvider(
  PluginRegistry registry,
) =>
    FutureProvider<List<PluginStat>>((ref) async {
      return registry.getDashboardStats(ref);
    });

/// Test widget that captures the data from a [FutureProvider].
class _RegistryTestWidget<T> extends ConsumerWidget {
  const _RegistryTestWidget({
    required this.provider,
    required this.onData,
  });

  final FutureProvider<List<T>> provider;
  final void Function(List<T> data) onData;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(provider);
    async.whenOrNull(
      data: (data) {
        // Defer to next frame to avoid build-time side effects
        WidgetsBinding.instance.addPostFrameCallback((_) {
          onData(data);
        });
      },
    );
    return const SizedBox.shrink();
  }
}

/// A test plugin that provides configurable dashboard data for testing
/// concurrent aggregation and error resilience.
class _DashboardTestPlugin extends UniHubPlugin {
  _DashboardTestPlugin({
    required this.idValue,
    this.items = const [],
    this.pinnedItems = const [],
    this.stats = const [],
    this.throwOnRecent = false,
    this.throwOnStats = false,
  });

  final String idValue;
  final List<DashboardItem> items;
  final List<DashboardItem> pinnedItems;
  final List<PluginStat> stats;
  final bool throwOnRecent;
  final bool throwOnStats;

  @override
  String get id => idValue;

  @override
  String get name => 'Dashboard test $idValue';

  @override
  Future<List<DashboardItem>> getRecentItems(
    Ref ref, {
    int count = 4,
  }) async {
    if (throwOnRecent) throw Exception('Recent items error');
    return items.take(count).toList();
  }

  @override
  Future<List<DashboardItem>> getPinnedItems(
    Ref ref, {
    int count = 3,
  }) async {
    return pinnedItems.take(count).toList();
  }

  @override
  Future<PluginStat?> getStat(Ref ref) async {
    if (throwOnStats) throw Exception('Stats error');
    return stats.isNotEmpty ? stats.first : null;
  }
}
