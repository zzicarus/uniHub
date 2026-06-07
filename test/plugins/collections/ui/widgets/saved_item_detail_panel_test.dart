import 'dart:ui' as ui;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uni_hub/src/core/database/app_database.dart';
import 'package:uni_hub/src/core/database/database_provider.dart';
import 'package:uni_hub/src/core/plugin/plugin_registry.dart';
import 'package:uni_hub/src/plugins/collections/collections_plugin.dart';
import 'package:uni_hub/src/plugins/collections/data/collection_boxes_dao.dart';
import 'package:uni_hub/src/plugins/collections/data/collections_repository.dart';
import 'package:uni_hub/src/plugins/collections/data/enrichment_jobs_dao.dart';
import 'package:uni_hub/src/plugins/collections/data/saved_items_dao.dart';
import 'package:uni_hub/src/plugins/collections/domain/media_type.dart';
import 'package:uni_hub/src/plugins/collections/domain/source_platform.dart';
import 'package:uni_hub/src/plugins/collections/ui/widgets/saved_item_detail_panel.dart';

void main() {
  Future<({AppDatabase db, PluginRegistry registry, int itemId})> setupTestItem({
    required String title,
    String originalUrl = 'https://www.bilibili.com/',
    String normalizedUrl = 'https://www.bilibili.com/',
    String description = '很有趣的生活视频',
    String mediaType = 'video',
    String sourcePlatform = 'bilibili',
  }) async {
    final registry = PluginRegistry()..register(CollectionsPlugin());
    final db = AppDatabase(NativeDatabase.memory(), registry);

    final savedItemsDao = SavedItemsDao(db);
    final collectionBoxesDao = CollectionBoxesDao(db);
    final enrichmentJobsDao = EnrichmentJobsDao(db);
    final repository = CollectionsRepository(
      savedItemsDao: savedItemsDao,
      collectionBoxesDao: collectionBoxesDao,
      enrichmentJobsDao: enrichmentJobsDao,
    );

    final item = await repository.createSavedItem(
      originalUrl: originalUrl,
      normalizedUrl: normalizedUrl,
      title: title,
      mediaType: MediaType.fromValue(mediaType),
      sourcePlatform: SourcePlatform.fromValue(sourcePlatform),
    );

    return (db: db, registry: registry, itemId: item.id);
  }

  testWidgets('SavedItemDetailPanel renders mobile-style detail sections', (
    tester,
  ) async {
    tester.view.physicalSize = const ui.Size(375, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final setup = await setupTestItem(
      title: '哔哩哔哩 ( ゜- ゜)つロ 干杯~~ bilibili',
    );
    addTearDown(setup.db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(setup.db),
          pluginRegistryProvider.overrideWithValue(setup.registry),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 375,
                height: 900,
                child: SavedItemDetailPanel(itemId: setup.itemId),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('打开原网页'), findsOneWidget);
    expect(find.text('来源'), findsOneWidget);
    expect(find.text('状态'), findsOneWidget);
    expect(find.text('收藏夹'), findsOneWidget);
    expect(find.text('标签'), findsOneWidget);
    expect(find.text('备注'), findsOneWidget);
    expect(find.text('暂未关联笔记、想法或 Todo。'), findsOneWidget);
    expect(find.text('收藏时间'), findsOneWidget);
    expect(find.text('最后访问'), findsOneWidget);
    expect(find.text('快速操作'), findsOneWidget);
    expect(find.text('复制链接'), findsOneWidget);
    expect(find.text('移动'), findsOneWidget);
    expect(find.text('归档'), findsWidgets);
    expect(find.text('删除'), findsOneWidget);
  });

  testWidgets('SavedItemDetailPanel renders with favicon without crashing', (
    tester,
  ) async {
    tester.view.physicalSize = const ui.Size(375, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final setup = await setupTestItem(
      title: 'Article With Favicon',
      originalUrl: 'https://example.com/article',
      normalizedUrl: 'https://example.com/article',
    );
    addTearDown(setup.db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(setup.db),
          pluginRegistryProvider.overrideWithValue(setup.registry),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 375,
                height: 900,
                child: SavedItemDetailPanel(itemId: setup.itemId),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Panel renders with basic sections
    expect(find.text('Article With Favicon'), findsOneWidget);
    expect(find.text('来源'), findsOneWidget);
    expect(find.text('状态'), findsOneWidget);
    expect(find.text('收藏夹'), findsOneWidget);
    expect(find.text('快速操作'), findsOneWidget);
  });
}
