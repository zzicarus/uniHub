import 'dart:ui' as ui;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uni_hub/src/core/database/app_database.dart';
import 'package:uni_hub/src/core/database/database_provider.dart';
import 'package:uni_hub/src/core/plugin/plugin_registry.dart';
import 'package:uni_hub/src/plugins/collections/collections_plugin.dart';
import 'package:uni_hub/src/plugins/collections/ui/layouts/collections_desktop_layout.dart';
import 'package:uni_hub/src/plugins/thoughts/thoughts_plugin.dart';

void main() {
  // ─── Collections Layout: detail panel visibility at various widths ───

  group('Collections responsive detail panel no overflow', () {
    Future<void> pumpCollectionsAtWidth(
      WidgetTester tester, {
      required double width,
    }) async {
      tester.view.physicalSize = ui.Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final registry = PluginRegistry()..register(CollectionsPlugin());
      final db = AppDatabase(NativeDatabase.memory(), registry);
      addTearDown(() => db.close());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            pluginRegistryProvider.overrideWithValue(registry),
          ],
          child: const MaterialApp(
            home: Scaffold(body: CollectionsDesktopLayout()),
          ),
        ),
      );

      // Allow async database queries to settle
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
    }

    // Available width = physicalWidth - SafeArea - Column padding (≈ 96px)
    // Use physical widths large enough to account for UI chrome.

    testWidgets('1366px: shows detail panel', (tester) async {
      await pumpCollectionsAtWidth(tester, width: 1366);

      expect(
        find.text('选择一条收藏查看详情'),
        findsOneWidget,
      );
    });

    testWidgets('1200px: shows detail panel', (tester) async {
      await pumpCollectionsAtWidth(tester, width: 1200);

      expect(
        find.text('选择一条收藏查看详情'),
        findsOneWidget,
      );
    });

    testWidgets('1050px: shows detail panel', (tester) async {
      await pumpCollectionsAtWidth(tester, width: 1050);

      expect(
        find.text('选择一条收藏查看详情'),
        findsOneWidget,
      );
    });

    testWidgets('800px: no detail panel, card tap opens bottom sheet',
        (tester) async {
      // For narrow layout: SafeArea(20) + Padding(24) makes the content
      // area ~756px which is < 960, so detail panel should NOT show.
      await pumpCollectionsAtWidth(tester, width: 800);

      expect(find.text('选择一条收藏查看详情'), findsNothing);
      expect(find.text('还没有收藏'), findsOneWidget);
    });
  });
}
