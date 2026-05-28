import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uni_hub/src/core/database/tables/collection_boxes_table.dart';
import 'package:uni_hub/src/core/database/tables/enrichment_jobs_table.dart';
import 'package:uni_hub/src/core/database/tables/website_logo_cache_table.dart';
import 'package:uni_hub/src/core/database/tables/saved_item_boxes_table.dart';
import 'package:uni_hub/src/core/database/tables/saved_items_table.dart';
import 'package:uni_hub/src/core/plugin/plugin_interface.dart';
import 'package:uni_hub/src/core/router/route_names.dart';
import 'package:uni_hub/src/plugins/collections/domain/url_normalizer.dart';
import 'package:uni_hub/src/plugins/collections/providers/collections_providers.dart';

import 'ui/collections_page.dart';

class CollectionsPlugin extends UniHubPlugin {
  @override
  String get id => 'collections';

  @override
  String get name => '收藏库';

  @override
  List<NavEntry> get navEntries => [
    const NavEntry(
      label: '收藏库',
      icon: Icons.bookmark_border_rounded,
      routeName: RouteNames.collections,
      path: '/collections',
    ),
  ];

  @override
  List<GoRoute> get routes => [
    GoRoute(
      path: '/collections',
      name: RouteNames.collections,
      builder: (context, state) => const CollectionsPage(),
    ),
  ];

  @override
  List<Type> get tables => [
    SavedItemsTable,
    CollectionBoxesTable,
    SavedItemBoxesTable,
    EnrichmentJobsTable,
    WebsiteLogoCacheTable,
  ];

  @override
  int get schemaVersion => 5;

  // ─── Dashboard methods ───────────────────────────────────────────

  @override
  bool canHandleQuickCreate(String content) {
    // #7: Collections 处理 URL 内容
    final trimmed = content.trim();
    if (trimmed.isEmpty) return false;
    return const UrlNormalizer().tryNormalize(trimmed) != null;
  }

  @override
  Future<DashboardItem?> quickCreate(
    Ref ref, {
    required String content,
    String? tags,
  }) async {
    final trimmed = content.trim();
    if (!canHandleQuickCreate(trimmed)) return null;

    // 调用完整收藏创建链路：创建或定位已存在的收藏项
    final result = await ref
        .read(collectionCaptureServiceProvider)
        .captureUrl(trimmed);

    // 从数据库查询创建后的真实数据
    final item = await ref
        .read(collectionsRepositoryProvider)
        .getSavedItem(result.itemId);

    if (item == null) return null;

    return DashboardItem(
      pluginId: id,
      itemId: item.id.toString(),
      content: item.title.trim().isNotEmpty ? item.title : item.normalizedUrl,
      tags: tags != null
          ? tags
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList()
          : const [],
      createdAt: item.createdAt,
      routePath: '/collections',
    );
  }
}
