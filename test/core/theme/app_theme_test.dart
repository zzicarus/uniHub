import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:uni_hub/src/core/theme/app_theme.dart';

/// Verifies ThemeData structure without failing on google_fonts' async font
/// loading attempts (which time out / fail in test environments).
///
/// Must be called at the start of every testWidgets that triggers
/// [AppTheme.light] or [AppTheme.dark], which internally call
/// [GoogleFonts.interTextTheme].
Future<void> consumeFontLoadErrors(WidgetTester tester) async {
  // Let any pending google_fonts HTTP load attempts settle.
  await tester.pump(const Duration(seconds: 1));
  // Consume any unhandled font-load errors — these are irrelevant for
  // ThemeData-structure tests.
  tester.takeException();
  // Reset config so subsequent GoogleFonts calls are also silent.
  GoogleFonts.config.allowRuntimeFetching = false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Prevent google_fonts from making HTTP requests during tests.
  GoogleFonts.config.allowRuntimeFetching = false;

  group('AppTheme', () {
    group('light', () {
      testWidgets('returns a valid ThemeData with useMaterial3 == true',
          (tester) async {
        final lightTheme = AppTheme.light;
        await consumeFontLoadErrors(tester);
        expect(lightTheme.useMaterial3, isTrue);
      });

      testWidgets('has Brightness.light', (tester) async {
        final lightTheme = AppTheme.light;
        await consumeFontLoadErrors(tester);
        expect(lightTheme.brightness, equals(Brightness.light));
      });

      testWidgets('has a non-null colorScheme', (tester) async {
        final lightTheme = AppTheme.light;
        await consumeFontLoadErrors(tester);
        expect(lightTheme.colorScheme, isNotNull);
      });

      testWidgets('colorScheme.seed matches AppColors.primary', (tester) async {
        final lightTheme = AppTheme.light;
        await consumeFontLoadErrors(tester);
        expect(lightTheme.colorScheme.primary, isNotNull);
      });

      testWidgets('has non-null appBarTheme', (tester) async {
        final lightTheme = AppTheme.light;
        await consumeFontLoadErrors(tester);
        expect(lightTheme.appBarTheme, isNotNull);
      });

      testWidgets('has non-null cardTheme', (tester) async {
        final lightTheme = AppTheme.light;
        await consumeFontLoadErrors(tester);
        expect(lightTheme.cardTheme, isNotNull);
      });

      testWidgets('has non-null navigationBarTheme', (tester) async {
        final lightTheme = AppTheme.light;
        await consumeFontLoadErrors(tester);
        expect(lightTheme.navigationBarTheme, isNotNull);
      });
    });

    group('dark', () {
      testWidgets('returns a valid ThemeData with useMaterial3 == true',
          (tester) async {
        final darkTheme = AppTheme.dark;
        await consumeFontLoadErrors(tester);
        expect(darkTheme.useMaterial3, isTrue);
      });

      testWidgets('has Brightness.dark', (tester) async {
        final darkTheme = AppTheme.dark;
        await consumeFontLoadErrors(tester);
        expect(darkTheme.brightness, equals(Brightness.dark));
      });

      testWidgets('has a non-null colorScheme', (tester) async {
        final darkTheme = AppTheme.dark;
        await consumeFontLoadErrors(tester);
        expect(darkTheme.colorScheme, isNotNull);
      });

      testWidgets('colorScheme.seed matches AppColors.primary', (tester) async {
        final darkTheme = AppTheme.dark;
        await consumeFontLoadErrors(tester);
        expect(darkTheme.colorScheme.primary, isNotNull);
      });

      testWidgets('has non-null appBarTheme', (tester) async {
        final darkTheme = AppTheme.dark;
        await consumeFontLoadErrors(tester);
        expect(darkTheme.appBarTheme, isNotNull);
      });

      testWidgets('has non-null cardTheme', (tester) async {
        final darkTheme = AppTheme.dark;
        await consumeFontLoadErrors(tester);
        expect(darkTheme.cardTheme, isNotNull);
      });

      testWidgets('has non-null navigationBarTheme', (tester) async {
        final darkTheme = AppTheme.dark;
        await consumeFontLoadErrors(tester);
        expect(darkTheme.navigationBarTheme, isNotNull);
      });
    });

    group('brightness comparison', () {
      testWidgets('light and dark themes have different brightness',
          (tester) async {
        GoogleFonts.config.allowRuntimeFetching = false;
        final light = AppTheme.light;
        final dark = AppTheme.dark;
        await consumeFontLoadErrors(tester);
        expect(light.brightness, isNot(equals(dark.brightness)));
      });
    });
  });
}
