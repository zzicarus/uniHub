import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uni_hub/src/core/database/tables/collection_boxes_table.dart';
import 'package:uni_hub/src/core/database/tables/enrichment_jobs_table.dart';
import 'package:uni_hub/src/core/database/tables/website_logo_cache_table.dart';
import 'package:uni_hub/src/core/database/tables/saved_item_boxes_table.dart';
import 'package:uni_hub/src/core/database/tables/saved_items_table.dart';
import 'package:uni_hub/src/core/plugin/plugin_interface.dart';
import 'package:uni_hub/src/core/router/route_names.dart';

import 'ui/collections_page.dart';

class CollectionsPlugin extends UniHubPlugin {
  @override
  String get id => 'collections';

  @override
  String get name => '收藏';

  @override
  List<NavEntry> get navEntries => [
    const NavEntry(
      label: '收藏',
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
}
