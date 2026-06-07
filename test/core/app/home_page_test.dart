import 'dart:convert';
import 'dart:ui' as ui;

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
  testWidgets('HomePage shows greeting and quick capture without fake data', (
    tester,
  ) async {
    tester.view.physicalSize = const ui.Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final registry = PluginRegistry();
    registry.register(ThoughtsPlugin());
    final testDb = AppDatabase(NativeDatabase.memory(), registry);
    addTearDown(testDb.close);

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

    // PRD 2.3: Hardcoded user name removed — greeting should not contain Alex
    expect(find.textContaining('Alex'), findsNothing);

    // PRD 2.4: Fake metric cards (今日待办 —, 本周笔记 —, 纪念日 —) removed
    expect(find.text('—'), findsNothing);

    // Core path: quick capture + recent thoughts
    expect(find.text('快捷入口'), findsWidgets);
    expect(find.text('最近想法'), findsWidgets);
  });

  testWidgets('HomePage shows quick capture and recent thoughts', (
    tester,
  ) async {
    tester.view.physicalSize = const ui.Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final registry = PluginRegistry();
    registry.register(ThoughtsPlugin());
    final testDb = AppDatabase(NativeDatabase.memory(), registry);
    addTearDown(testDb.close);

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

    // PRD 2.4: Home shows real data sections, not fake todo/activity items.
    expect(find.text('快捷入口'), findsWidgets);
    expect(find.text('最近想法'), findsWidgets);

    // _TodoPanel / _ActivityPanel removed — no longer show hardcoded todos
    expect(find.text('整理 Dashboard 改造清单'), findsNothing);
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
    addTearDown(testDb.close);

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
    addTearDown(testDb.close);

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
    addTearDown(testDb.close);

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
    addTearDown(testDb.close);

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
