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
  List<NavEntry> get navEntries => [for (final p in _plugins) ...p.navEntries];
  List<GoRoute> get mergedRoutes => [for (final p in _plugins) ...p.routes];

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
    final items = <DashboardItem>[];
    for (final p in _plugins) {
      final pluginItems = await p.getRecentItems(ref, count: count);
      items.addAll(pluginItems);
    }
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items.take(count).toList();
  }

  Future<List<DashboardItem>> getDashboardPinned(
    Ref ref, {
    int count = 3,
  }) async {
    final items = <DashboardItem>[];
    for (final p in _plugins) {
      final pluginItems = await p.getPinnedItems(ref, count: count);
      items.addAll(pluginItems);
    }
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items.take(count).toList();
  }

  Future<List<PluginStat>> getDashboardStats(Ref ref) async {
    final stats = <PluginStat>[];
    for (final p in _plugins) {
      final stat = await p.getStat(ref);
      if (stat != null) stats.add(stat);
    }
    return stats;
  }

  Future<DashboardItem?> quickCreate(
    Ref ref, {
    required String content,
    String? tags,
  }) async {
    // #7: 先按 canHandleQuickCreate 过滤，避免非 URL 内容被 Thoughts 优先拦截
    for (final p in _plugins) {
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

  void _ensureUniquePluginId(UniHubPlugin plugin) {
    for (final existing in _plugins) {
      if (existing.id == plugin.id) {
        throw StateError('Duplicate plugin id: ${plugin.id}');
      }
    }
  }

  void _ensureUniqueRoutes(UniHubPlugin plugin) {
    final existingPaths = <String, String>{};
    final existingNames = <String, String>{};
    for (final existing in _plugins) {
      for (final route in existing.routes) {
        existingPaths[route.path] = existing.id;
        final name = route.name;
        if (name != null) existingNames[name] = existing.id;
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
    final existingTables = <Type, String>{};
    for (final existing in _plugins) {
      for (final table in existing.tables) {
        existingTables[table] = existing.id;
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
    final existingLabels = <String, String>{};
    final existingTargets = <String, String>{};
    for (final existing in _plugins) {
      for (final entry in existing.navEntries) {
        existingLabels[entry.label] = existing.id;
        existingTargets[_navEntryTarget(entry)] = existing.id;
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
  ref.onDispose(() => registry.disposeAll());
  return registry;
});
