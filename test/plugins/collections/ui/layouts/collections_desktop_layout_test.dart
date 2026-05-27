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

void main() {
  testWidgets('CollectionsDesktopLayout renders content collection workbench', (
    tester,
  ) async {
    tester.view.physicalSize = const ui.Size(1500, 900);
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

    await tester.pumpAndSettle();

    expect(find.text('内容收藏'), findsOneWidget);
    expect(find.text('收藏夹'), findsOneWidget);
    expect(find.text('全部收藏'), findsOneWidget);
    expect(find.text('排序：最新收藏'), findsOneWidget);
    expect(find.text('还没有收藏'), findsOneWidget);
  });
}
