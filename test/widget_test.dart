import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:uni_hub/src/core/app/app.dart';
import 'package:uni_hub/src/core/database/app_database.dart';
import 'package:uni_hub/src/core/database/database_provider.dart';
import 'package:uni_hub/src/core/plugin/plugin_registry.dart';
import 'package:uni_hub/src/plugins/thoughts/thoughts_plugin.dart';

void main() {
  testWidgets('App smoke test - home page renders', (tester) async {
    tester.view.physicalSize = const ui.Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final testDb = AppDatabase(NativeDatabase.memory());
    addTearDown(() => testDb.close());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(testDb),
          pluginRegistryProvider.overrideWith((ref) {
            final registry = PluginRegistry();
            registry.register(ThoughtsPlugin());
            return registry;
          }),
        ],
        child: const UniHubApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('早上好，Alex'), findsOneWidget);
  });

  testWidgets('Navigation to Thoughts page works', (tester) async {
    tester.view.physicalSize = const ui.Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final testDb = AppDatabase(NativeDatabase.memory());
    addTearDown(() => testDb.close());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(testDb),
          pluginRegistryProvider.overrideWith((ref) {
            final registry = PluginRegistry();
            registry.register(ThoughtsPlugin());
            return registry;
          }),
        ],
        child: const UniHubApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('想法').first);
    await tester.pumpAndSettle();
    expect(find.text('想法'), findsWidgets);
  });
}
