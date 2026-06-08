import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'plugin_interface.dart';

class PluginRegistry {
  final List<UniHubPlugin> _plugins = [];

  void register(UniHubPlugin plugin) {
    _validatePlugin(plugin);
    _plugins.add(plugin);
  }

  List<UniHubPlugin> get plugins => List.unmodifiable(_plugins);

  /// 按能力收集：只遍历实现了 [NavContributor] 的插件。
  List<NavEntry> get navEntries => [
    for (final p in _plugins.whereType<NavContributor>())
      ...p.navEntries,
  ];

  /// 按能力收集：只遍历实现了 [RouteContributor] 的插件。
  List<GoRoute> get mergedRoutes => [
    for (final p in _plugins.whereType<RouteContributor>())
      ...p.routes,
  ];

  Future<void> initAll() async {
    for (final p in _plugins) {
      await p.onInit();
    }
  }

  Future<void> disposeAll() async {
    for (final p in _plugins.reversed) {
      await p.onDispose();
    }
  }

  Future<List<DashboardItem>> getDashboardItems(
    Ref ref, {
    int count = 4,
  }) async {
    final contributors = _plugins.whereType<DashboardContributor>();
    final results = await Future.wait(
      contributors.map((p) async {
        try {
          return await p.getRecentItems(ref, count: count);
        } catch (e) {
          debugPrint('[PluginRegistry] getDashboardItems failed for ${(p as UniHubPlugin).id}: $e');
          return <DashboardItem>[];
        }
      }),
    );

    final items = results.expand((e) => e).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return items.take(count).toList();
  }

  Future<List<DashboardItem>> getDashboardPinned(
    Ref ref, {
    int count = 3,
  }) async {
    final contributors = _plugins.whereType<DashboardContributor>();
    final results = await Future.wait(
      contributors.map((p) async {
        try {
          return await p.getPinnedItems(ref, count: count);
        } catch (e) {
          debugPrint('[PluginRegistry] getDashboardPinned failed for ${(p as UniHubPlugin).id}: $e');
          return <DashboardItem>[];
        }
      }),
    );

    final items = results.expand((e) => e).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return items.take(count).toList();
  }

  Future<List<PluginStat>> getDashboardStats(Ref ref) async {
    final contributors = _plugins.whereType<DashboardContributor>();
    final results = await Future.wait(
      contributors.map((p) async {
        try {
          final stat = await p.getStat(ref);
          return stat != null ? [stat] : <PluginStat>[];
        } catch (e) {
          debugPrint('[PluginRegistry] getDashboardStats failed for ${(p as UniHubPlugin).id}: $e');
          return <PluginStat>[];
        }
      }),
    );

    return results.expand((e) => e).toList();
  }

  Future<DashboardItem?> quickCreate(
    Ref ref, {
    required String content,
    String? tags,
  }) async {
    final handlers = _plugins.whereType<QuickCaptureHandler>();
    for (final p in handlers) {
      if (!p.canHandleQuickCreate(content)) continue;
      final item = await p.quickCreate(ref, content: content, tags: tags);
      if (item != null) return item;
    }
    return null;
  }

  void _validatePlugin(UniHubPlugin plugin) {
    _ensureUniquePluginId(plugin);
    _ensureUniqueRoutes(plugin);
    _ensureUniqueTables(plugin);
    _ensureUniqueTopLevelNavEntries(plugin);
  }

  /// 返回实现了指定 Capability 的插件列表。
  /// 供外部按能力查询使用。
  List<T> contributors<T>() =>
      _plugins.whereType<T>().toList();

  void _ensureUniquePluginId(UniHubPlugin plugin) {
    for (final existing in _plugins) {
      if (existing.id == plugin.id) {
        throw StateError('Duplicate plugin id: ${plugin.id}');
      }
    }
  }

  void _ensureUniqueRoutes(UniHubPlugin plugin) {
    final routePlugins = _plugins.whereType<RouteContributor>();
    final existingPaths = <String, String>{};
    final existingNames = <String, String>{};
    for (final existing in routePlugins) {
      for (final route in existing.routes) {
        existingPaths[route.path] = (existing as dynamic).id;
        final name = route.name;
        if (name != null) existingNames[name] = (existing as dynamic).id;
      }
    }

    final newPaths = <String>{};
    final newNames = <String>{};
    for (final route in plugin.routes) {
      final existingPluginId = existingPaths[route.path];
      if (existingPluginId != null || !newPaths.add(route.path)) {
        throw StateError(
          'Duplicate route path: ${route.path} (${plugin.id} conflicts with ${existingPluginId ?? plugin.id})',
        );
      }

      final name = route.name;
      if (name == null) continue;
      final existingPluginIdForName = existingNames[name];
      if (existingPluginIdForName != null || !newNames.add(name)) {
        throw StateError(
          'Duplicate route name: $name (${plugin.id} conflicts with ${existingPluginIdForName ?? plugin.id})',
        );
      }
    }
  }

  void _ensureUniqueTables(UniHubPlugin plugin) {
    final dbPlugins = _plugins.whereType<DatabaseContributor>();
    final existingTables = <Type, String>{};
    for (final existing in dbPlugins) {
      for (final table in existing.tables) {
        existingTables[table] = (existing as dynamic).id;
      }
    }

    final newTables = <Type>{};
    for (final table in plugin.tables) {
      final existingPluginId = existingTables[table];
      if (existingPluginId != null || !newTables.add(table)) {
        throw StateError(
          'Duplicate table declaration: $table (${plugin.id} conflicts with ${existingPluginId ?? plugin.id})',
        );
      }
    }
  }

  void _ensureUniqueTopLevelNavEntries(UniHubPlugin plugin) {
    final navPlugins = _plugins.whereType<NavContributor>();
    final existingLabels = <String, String>{};
    final existingTargets = <String, String>{};
    for (final existing in navPlugins) {
      for (final entry in existing.navEntries) {
        existingLabels[entry.label] = (existing as dynamic).id;
        existingTargets[_navEntryTarget(entry)] = (existing as dynamic).id;
      }
    }

    final newLabels = <String>{};
    final newTargets = <String>{};
    for (final entry in plugin.navEntries) {
      final existingPluginIdForLabel = existingLabels[entry.label];
      if (existingPluginIdForLabel != null || !newLabels.add(entry.label)) {
        throw StateError(
          'Duplicate nav entry label: ${entry.label} (${plugin.id} conflicts with ${existingPluginIdForLabel ?? plugin.id})',
        );
      }

      final target = _navEntryTarget(entry);
      final existingPluginIdForTarget = existingTargets[target];
      if (existingPluginIdForTarget != null || !newTargets.add(target)) {
        throw StateError(
          'Duplicate nav entry path: ${entry.path} (${plugin.id} conflicts with ${existingPluginIdForTarget ?? plugin.id})',
        );
      }
    }
  }

  String _navEntryTarget(NavEntry entry) {
    final query = entry.queryParams.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final queryPart = query
        .map((entry) => '${entry.key}=${entry.value}')
        .join('&');
    return '${entry.path}|$queryPart';
  }
}

final pluginRegistryProvider = Provider<PluginRegistry>((ref) {
  final registry = PluginRegistry();
  ref.onDispose(registry.disposeAll);
  return registry;
});
