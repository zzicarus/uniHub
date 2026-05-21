import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:uni_hub/src/core/app/app.dart';
import 'package:uni_hub/src/core/app/dashboard_providers.dart';
import 'package:uni_hub/src/core/database/app_database.dart';
import 'package:uni_hub/src/core/database/database_provider.dart';
import 'package:uni_hub/src/core/plugin/plugin_registry.dart';
import 'package:uni_hub/src/plugins/thoughts/thoughts_plugin.dart';

void main() {
  testWidgets('HomePage shows — for metrics without plugin data', (tester) async {
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

  testWidgets('HomePage shows 暂无待办数据 in todo panel', (tester) async {
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

    // The todo panel should show empty state instead of hardcoded items
    expect(find.text('暂无待办数据'), findsWidgets);
  });

  testWidgets('HomePage shows data overview panel with metrics', (tester) async {
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

    // Data overview panel exists
    expect(find.text('数据概览'), findsOneWidget);

    // Data lines should show — for metrics without plugins
    expect(find.text('待办'), findsWidgets);
    expect(find.text('笔记'), findsWidgets);
    expect(find.text('想法'), findsWidgets);
  });

  testWidgets('Mobile home page shows FocusCards with — for missing data', (tester) async {
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
