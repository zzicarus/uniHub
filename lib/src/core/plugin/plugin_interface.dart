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

abstract class UniHubPlugin {
  String get id;
  String get name;
  List<NavEntry> get navEntries => [];
  List<GoRoute> get routes => [];
  List<Type> get tables => [];
  int get schemaVersion => 0;
  Future<void> onInit() async {}
  Future<void> onDispose() async {}
  Future<List<SearchResult>> search(String query) async => [];

  /// Return recent items for the dashboard home page.
  Future<List<DashboardItem>> getRecentItems(
    Ref ref, {
    int count = 4,
  }) async => [];

  /// Return pinned items for the dashboard right rail.
  Future<List<DashboardItem>> getPinnedItems(
    Ref ref, {
    int count = 3,
  }) async => [];

  /// Return stats (count) for the dashboard.
  Future<PluginStat?> getStat(Ref ref) async => null;

  /// 判断本插件是否可处理该快速创建内容。
  ///
  /// 用于 [PluginRegistry.quickCreate] 分流：先过滤出可处理的插件，
  /// 再按注册顺序调用 [quickCreate]。默认返回 false。
  bool canHandleQuickCreate(String content) => false;

  /// Quick-create an item from the dashboard. Returns the created item.
  Future<DashboardItem?> quickCreate(
    Ref ref, {
    required String content,
    String? tags,
  }) async => null;
}
