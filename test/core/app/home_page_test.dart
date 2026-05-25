import 'dart:convert';
import 'dart:ui' as ui;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uni_hub/src/core/app/app.dart';
import 'package:uni_hub/src/core/database/app_database.dart';
import 'package:uni_hub/src/core/database/database_provider.dart';
import 'package:uni_hub/src/core/plugin/plugin_registry.dart';
import 'package:uni_hub/src/plugins/thoughts/thoughts_plugin.dart';
import 'package:uni_hub/src/plugins/thoughts/ui/widgets/thought_editor_workspace.dart';
import 'package:uni_hub/src/shared/ui/rich_text_editor/rich_text_editor.dart';

String _makeAppFlowyContent(String text) {
  return jsonEncode({
    'format': 'unihub.appflowy_json.v1',
    'document': {
      'type': 'page',
      'children': [
        {
          'type': 'paragraph',
          'data': {
            'delta': [
              {'insert': text},
            ],
          },
        },
      ],
    },
    'plainText': text,
  });
}

void main() {
  testWidgets('HomePage shows — for metrics without plugin data', (
    tester,
  ) async {
    tester.view.physicalSize = const ui.Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final registry = PluginRegistry();
    registry.register(ThoughtsPlugin());
    final testDb = AppDatabase(NativeDatabase.memory(), registry);
    addTearDown(() => testDb.close());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(testDb),
          pluginRegistryProvider.overrideWithValue(registry),
        ],
        child: const UniHubApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Metric cards should be present (may appear in sidebar too)
    expect(find.text('今日待办'), findsWidgets);
    expect(find.text('想法总数'), findsOneWidget);
    expect(find.text('本周笔记'), findsOneWidget);
    expect(find.text('纪念日'), findsOneWidget);

    // Without plugins providing these, they show —
    expect(find.text('—'), findsWidgets);
  });

  testWidgets('HomePage shows dashboard todo items in work grid', (
    tester,
  ) async {
    tester.view.physicalSize = const ui.Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final registry = PluginRegistry();
    registry.register(ThoughtsPlugin());
    final testDb = AppDatabase(NativeDatabase.memory(), registry);
    addTearDown(() => testDb.close());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(testDb),
          pluginRegistryProvider.overrideWithValue(registry),
        ],
        child: const UniHubApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Desktop work grid uses dashboard-style placeholder items.
    expect(find.text('整理 Dashboard 改造清单'), findsOneWidget);
    expect(find.text('最近活动'), findsWidgets);
  });

  testWidgets('HomePage shows today overview rail with metrics', (
    tester,
  ) async {
    // 1600px: content area after sidebar (286px) = 1314px ≥ wideMin=1280
    tester.view.physicalSize = const ui.Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final registry = PluginRegistry();
    registry.register(ThoughtsPlugin());
    final testDb = AppDatabase(NativeDatabase.memory(), registry);
    addTearDown(() => testDb.close());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(testDb),
          pluginRegistryProvider.overrideWithValue(registry),
        ],
        child: const UniHubApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Right rail uses the new dashboard information architecture.
    expect(find.text('今日概览'), findsOneWidget);
    expect(find.text('近日日程'), findsOneWidget);
    expect(find.text('纪念日提醒'), findsOneWidget);
    expect(find.text('连续记录'), findsOneWidget);

    expect(find.text('已完成待办'), findsOneWidget);
    expect(find.text('今日想法'), findsOneWidget);
    expect(find.text('专注记录'), findsOneWidget);
  });

  testWidgets('Dashboard recent thought opens AppFlowy workspace', (
    tester,
  ) async {
    tester.view.physicalSize = const ui.Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final registry = PluginRegistry()..register(ThoughtsPlugin());
    final testDb = AppDatabase(NativeDatabase.memory(), registry);
    addTearDown(() => testDb.close());

    await testDb
        .into(testDb.thoughtsTable)
        .insert(
          ThoughtsTableCompanion.insert(
            content: _makeAppFlowyContent('Route opens AppFlowy'),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(testDb),
          pluginRegistryProvider.overrideWithValue(registry),
        ],
        child: const UniHubApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Route opens AppFlowy').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(RichTextEditor), findsNothing);
    expect(find.byType(ThoughtEditorWorkspace), findsOneWidget);
    expect(find.text('编辑想法'), findsOneWidget);
  });

  testWidgets('Mobile home page shows FocusCards with — for missing data', (
    tester,
  ) async {
    tester.view.physicalSize = const ui.Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final registry = PluginRegistry();
    registry.register(ThoughtsPlugin());
    final testDb = AppDatabase(NativeDatabase.memory(), registry);
    addTearDown(() => testDb.close());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(testDb),
          pluginRegistryProvider.overrideWithValue(registry),
        ],
        child: const UniHubApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Mobile focus cards should show — for 今日待办 and 最近笔记
    expect(find.text('今日待办'), findsWidgets);
    expect(find.text('最近笔记'), findsWidgets);
    expect(find.text('想法灵感'), findsWidgets);
  });

  testWidgets('Mobile home page shows 暂无待办数据', (tester) async {
    tester.view.physicalSize = const ui.Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final registry = PluginRegistry();
    registry.register(ThoughtsPlugin());
    final testDb = AppDatabase(NativeDatabase.memory(), registry);
    addTearDown(() => testDb.close());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(testDb),
          pluginRegistryProvider.overrideWithValue(registry),
        ],
        child: const UniHubApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Mobile todo section shows empty state
    expect(find.text('暂无待办数据'), findsWidgets);
  });
}
