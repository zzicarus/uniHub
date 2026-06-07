import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../search/search_result.dart';

class NavEntry {
  final String label;
  final IconData icon;
  final String routeName;
  final String path;
  final Map<String, String> routeParams;
  final Map<String, String> queryParams;
  final List<NavEntry>? children;

  const NavEntry({
    required this.label,
    required this.icon,
    required this.routeName,
    required this.path,
    this.routeParams = const {},
    this.queryParams = const {},
    this.children,
  });
}

/// Dashboard item displayed on home page.
class DashboardItem {
  final String pluginId;
  final String itemId;
  final String content;
  final List<String> tags;
  final String? colorHex;
  final bool isPinned;
  final DateTime createdAt;
  final String routePath;

  const DashboardItem({
    required this.pluginId,
    required this.itemId,
    required this.content,
    this.tags = const [],
    this.colorHex,
    this.isPinned = false,
    required this.createdAt,
    required this.routePath,
  });
}

/// Stats contributed by a plugin to the dashboard.
class PluginStat {
  final String pluginId;
  final String label;
  final int count;

  const PluginStat({
    required this.pluginId,
    required this.label,
    required this.count,
  });
}

// ─── Capability interfaces ───────────────────────────────────────────
//
// 插件能力拆分为多个独立 interface，PluginRegistry 按能力收集而不是
// 假设所有插件都有全部能力。新增插件只需实现自身需要的接口。

/// 插件贡献路由。
abstract interface class RouteContributor {
  List<GoRoute> get routes;
}

/// 插件贡献侧边栏导航条目。
abstract interface class NavContributor {
  List<NavEntry> get navEntries;
}

/// 插件声明数据库表。
abstract interface class DatabaseContributor {
  List<Type> get tables;
  int get schemaVersion;
}

/// 插件贡献首页 Dashboard 面板。
abstract interface class DashboardContributor {
  Future<List<DashboardItem>> getRecentItems(
    Ref ref, {
    int count = 4,
  });

  Future<List<DashboardItem>> getPinnedItems(
    Ref ref, {
    int count = 3,
  });

  Future<PluginStat?> getStat(Ref ref);
}

/// 插件支持快速创建。
abstract interface class QuickCaptureHandler {
  bool canHandleQuickCreate(String content);

  Future<DashboardItem?> quickCreate(
    Ref ref, {
    required String content,
    String? tags,
  });
}

/// 插件提供搜索能力。
abstract interface class SearchProvider {
  Future<List<SearchResult>> search(String query);
}

abstract class UniHubPlugin
    implements
        RouteContributor,
        NavContributor,
        DatabaseContributor,
        DashboardContributor,
        QuickCaptureHandler,
        SearchProvider {
  String get id;
  String get name;
  @override
  List<NavEntry> get navEntries => [];
  @override
  List<GoRoute> get routes => [];
  @override
  List<Type> get tables => [];
  @override
  int get schemaVersion => 0;
  Future<void> onInit() async {}
  Future<void> onDispose() async {}
  @override
  Future<List<SearchResult>> search(String query) async => [];

  /// Return recent items for the dashboard home page.
  @override
  Future<List<DashboardItem>> getRecentItems(
    Ref ref, {
    int count = 4,
  }) async => [];

  /// Return pinned items for the dashboard right rail.
  @override
  Future<List<DashboardItem>> getPinnedItems(
    Ref ref, {
    int count = 3,
  }) async => [];

  /// Return stats (count) for the dashboard.
  @override
  Future<PluginStat?> getStat(Ref ref) async => null;

  /// 判断本插件是否可处理该快速创建内容。
  ///
  /// 用于 [PluginRegistry.quickCreate] 分流：先过滤出可处理的插件，
  /// 再按注册顺序调用 [quickCreate]。默认返回 false。
  @override
  bool canHandleQuickCreate(String content) => false;

  /// Quick-create an item from the dashboard. Returns the created item.
  @override
  Future<DashboardItem?> quickCreate(
    Ref ref, {
    required String content,
    String? tags,
  }) async => null;
}
