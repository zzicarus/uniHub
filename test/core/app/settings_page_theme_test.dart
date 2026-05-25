import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:uni_hub/src/core/app/settings_page.dart';
import 'package:uni_hub/src/core/theme/app_theme.dart';
import 'package:uni_hub/src/core/theme/app_theme_preset.dart';
import 'package:uni_hub/src/core/theme/theme_settings_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsPage theme switching', () {
    /// Renders [SettingsPage] inside a [ProviderScope] + [MaterialApp].
    Future<void> pumpSettingsPage(WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light,
            home: const SettingsPage(),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('displays "主题模式" and "主题预设"', (tester) async {
      await pumpSettingsPage(tester);

      expect(find.text('主题模式'), findsOneWidget);
      expect(find.text('主题预设'), findsOneWidget);
    });

    testWidgets('displays all preset names', (tester) async {
      await pumpSettingsPage(tester);

      expect(find.text('Uni Blue'), findsOneWidget);
      expect(find.text('Paper'), findsOneWidget);
      expect(find.text('Forest'), findsOneWidget);
      expect(find.text('Sakura'), findsOneWidget);
      expect(find.text('Amber'), findsOneWidget);
      expect(find.text('Graphite'), findsOneWidget);
    });

    testWidgets('clicking Forest preset sets preset to forest',
        (tester) async {
      await pumpSettingsPage(tester);

      await tester.tap(find.text('Forest'));
      await tester.pump();

      final element = tester.element(find.byType(SettingsPage));
      final container = ProviderScope.containerOf(element);
      expect(container.read(themeSettingsProvider).preset,
          AppThemePreset.forest);
    });

    testWidgets('clicking 深色 sets mode to dark', (tester) async {
      await pumpSettingsPage(tester);

      await tester.tap(find.text('深色'));
      await tester.pump();

      final element = tester.element(find.byType(SettingsPage));
      final container = ProviderScope.containerOf(element);
      expect(
          container.read(themeSettingsProvider).mode, ThemeMode.dark);
    });
  });
}
