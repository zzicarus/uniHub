import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'plugin_interface.dart';

class PluginRegistry {
  final List<UniHubPlugin> _plugins = [];

  void register(UniHubPlugin plugin) => _plugins.add(plugin);
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
    for (final p in _plugins) {
      final item = await p.quickCreate(ref, content: content, tags: tags);
      if (item != null) return item;
    }
    return null;
  }
}

final pluginRegistryProvider = Provider<PluginRegistry>(
  (ref) {
    final registry = PluginRegistry();
    ref.onDispose(() => registry.disposeAll());
    return registry;
  },
);
