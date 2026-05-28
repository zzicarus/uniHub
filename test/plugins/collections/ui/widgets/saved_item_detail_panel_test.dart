import 'dart:ui' as ui;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uni_hub/src/core/database/app_database.dart';
import 'package:uni_hub/src/core/database/database_provider.dart';
import 'package:uni_hub/src/core/plugin/plugin_registry.dart';
import 'package:uni_hub/src/plugins/collections/application/saved_item_list_entry.dart';
import 'package:uni_hub/src/plugins/collections/collections_plugin.dart';
import 'package:uni_hub/src/plugins/collections/ui/widgets/saved_item_detail_panel.dart';

void main() {
  testWidgets('SavedItemDetailPanel renders mobile-style detail sections', (
    tester,
  ) async {
    tester.view.physicalSize = const ui.Size(375, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final registry = PluginRegistry()..register(CollectionsPlugin());
    final db = AppDatabase(NativeDatabase.memory(), registry);
    addTearDown(() => db.close());

    final createdAt = DateTime(2024, 5, 20, 14, 32);
    final updatedAt = DateTime(2024, 5, 20, 15, 12);
    final item = SavedItemsTableData(
      id: 1,
      originalUrl: 'https://www.bilibili.com/',
      normalizedUrl: 'https://www.bilibili.com/',
      title: '哔哩哔哩 ( ゜- ゜)つロ 干杯~~ bilibili',
      description: '很有趣的生活视频',
      mediaType: 'video',
      sourcePlatform: 'bilibili',
      status: 'unread',
      isInInbox: true,
      enrichmentStatus: 'pending',
      createdAt: createdAt,
      updatedAt: updatedAt,
      lastOpenedAt: updatedAt,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          pluginRegistryProvider.overrideWithValue(registry),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 375,
                height: 900,
                child: SavedItemDetailPanel(
                  entry: SavedItemListEntry(
                    item: item,
                    boxes: const [],
                    logo: null,
                    selected: false,
                  ),
                ),
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
    expect(find.text('2024-05-20 14:32'), findsOneWidget);
    expect(find.text('2024-05-20 15:12'), findsOneWidget);
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

    final registry = PluginRegistry()..register(CollectionsPlugin());
    final db = AppDatabase(NativeDatabase.memory(), registry);
    addTearDown(() => db.close());

    final createdAt = DateTime(2024, 5, 20, 14, 32);
    final updatedAt = DateTime(2024, 5, 20, 15, 12);
    final item = SavedItemsTableData(
      id: 2,
      originalUrl: 'https://example.com/article',
      normalizedUrl: 'https://example.com/article',
      title: 'Article With Favicon',
      mediaType: 'article',
      sourcePlatform: 'web',
      status: 'unread',
      isInInbox: true,
      enrichmentStatus: 'pending',
      favicon: 'https://example.com/favicon.ico',
      createdAt: createdAt,
      updatedAt: updatedAt,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          pluginRegistryProvider.overrideWithValue(registry),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 375,
                height: 900,
                child: SavedItemDetailPanel(
                  entry: SavedItemListEntry(
                    item: item,
                    boxes: const [],
                    logo: null,
                    selected: false,
                  ),
                ),
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
