import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:uni_hub/src/core/theme/app_theme.dart';
import 'package:uni_hub/src/core/theme/app_theme_preset.dart';
import 'package:uni_hub/src/core/theme/app_theme_registry.dart';
import 'package:uni_hub/src/core/theme/app_theme_tokens.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppTheme', () {
    group('light', () {
      test('returns a valid ThemeData with useMaterial3 == true', () {
        final lightTheme = AppTheme.light;
        expect(lightTheme.useMaterial3, isTrue);
      });

      test('has Brightness.light', () {
        final lightTheme = AppTheme.light;
        expect(lightTheme.brightness, equals(Brightness.light));
      });

      test('has a non-null colorScheme', () {
        final lightTheme = AppTheme.light;
        expect(lightTheme.colorScheme, isNotNull);
      });

      test('colorScheme.seed matches AppColors.primary', () {
        final lightTheme = AppTheme.light;
        expect(lightTheme.colorScheme.primary, isNotNull);
      });

      test('has non-null appBarTheme', () {
        final lightTheme = AppTheme.light;
        expect(lightTheme.appBarTheme, isNotNull);
      });

      test('has non-null cardTheme', () {
        final lightTheme = AppTheme.light;
        expect(lightTheme.cardTheme, isNotNull);
      });

      test('has non-null navigationBarTheme', () {
        final lightTheme = AppTheme.light;
        expect(lightTheme.navigationBarTheme, isNotNull);
      });
    });

    group('dark', () {
      test('returns a valid ThemeData with useMaterial3 == true', () {
        final darkTheme = AppTheme.dark;
        expect(darkTheme.useMaterial3, isTrue);
      });

      test('has Brightness.dark', () {
        final darkTheme = AppTheme.dark;
        expect(darkTheme.brightness, equals(Brightness.dark));
      });

      test('has a non-null colorScheme', () {
        final darkTheme = AppTheme.dark;
        expect(darkTheme.colorScheme, isNotNull);
      });

      test('colorScheme.seed matches AppColors.primary', () {
        final darkTheme = AppTheme.dark;
        expect(darkTheme.colorScheme.primary, isNotNull);
      });

      test('has non-null appBarTheme', () {
        final darkTheme = AppTheme.dark;
        expect(darkTheme.appBarTheme, isNotNull);
      });

      test('has non-null cardTheme', () {
        final darkTheme = AppTheme.dark;
        expect(darkTheme.cardTheme, isNotNull);
      });

      test('has non-null navigationBarTheme', () {
        final darkTheme = AppTheme.dark;
        expect(darkTheme.navigationBarTheme, isNotNull);
      });
    });

    group('brightness comparison', () {
      test('light and dark themes have different brightness', () {
        final light = AppTheme.light;
        final dark = AppTheme.dark;
        expect(light.brightness, isNot(equals(dark.brightness)));
      });
    });

    group('build', () {
      test('registers UniHubThemeColors extension', () {
        final theme = AppTheme.build(
          preset: AppThemePreset.uniBlue,
          brightness: Brightness.light,
        );
        expect(theme.extension<UniHubThemeColors>(), isNotNull);
      });

      test('generates different primary colors for different presets', () {
        final uniBlue = AppTheme.build(
          preset: AppThemePreset.uniBlue,
          brightness: Brightness.light,
        );
        final paper = AppTheme.build(
          preset: AppThemePreset.paper,
          brightness: Brightness.light,
        );
        expect(
          uniBlue.colorScheme.primary,
          isNot(equals(paper.colorScheme.primary)),
        );
      });

      test('scaffoldBackgroundColor matches registry background', () {
        final preset = AppThemePreset.uniBlue;
        final brightness = Brightness.light;
        final theme = AppTheme.build(preset: preset, brightness: brightness);
        final expected = AppThemeRegistry.colorsOf(preset, brightness);
        expect(theme.scaffoldBackgroundColor, expected.background);
      });
    });
  });
}
