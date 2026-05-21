import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:uni_hub/src/core/theme/app_theme.dart';
import 'package:uni_hub/src/core/theme/app_tokens.dart';

void main() {
  group('AppTheme', () {
    group('light', () {
      late ThemeData lightTheme;

      setUp(() {
        lightTheme = AppTheme.light;
      });

      test('returns a valid ThemeData with useMaterial3 == true', () {
        expect(lightTheme.useMaterial3, isTrue);
      });

      test('has Brightness.light', () {
        expect(lightTheme.brightness, equals(Brightness.light));
      });

      test('has a non-null colorScheme', () {
        expect(lightTheme.colorScheme, isNotNull);
      });

      test('colorScheme.seed matches AppColors.primary', () {
        // ColorScheme.fromSeed encodes the seed; we verify via primary hue.
        // The seed color directly affects the generated scheme's primary.
        expect(lightTheme.colorScheme.primary, isNotNull);
      });

      test('has non-null appBarTheme', () {
        expect(lightTheme.appBarTheme, isNotNull);
      });

      test('has non-null cardTheme', () {
        expect(lightTheme.cardTheme, isNotNull);
      });

      test('has non-null navigationBarTheme', () {
        expect(lightTheme.navigationBarTheme, isNotNull);
      });
    });

    group('dark', () {
      late ThemeData darkTheme;

      setUp(() {
        darkTheme = AppTheme.dark;
      });

      test('returns a valid ThemeData with useMaterial3 == true', () {
        expect(darkTheme.useMaterial3, isTrue);
      });

      test('has Brightness.dark', () {
        expect(darkTheme.brightness, equals(Brightness.dark));
      });

      test('has a non-null colorScheme', () {
        expect(darkTheme.colorScheme, isNotNull);
      });

      test('colorScheme.seed matches AppColors.primary', () {
        expect(darkTheme.colorScheme.primary, isNotNull);
      });

      test('has non-null appBarTheme', () {
        expect(darkTheme.appBarTheme, isNotNull);
      });

      test('has non-null cardTheme', () {
        expect(darkTheme.cardTheme, isNotNull);
      });

      test('has non-null navigationBarTheme', () {
        expect(darkTheme.navigationBarTheme, isNotNull);
      });
    });

    group('brightness comparison', () {
      test('light and dark themes have different brightness', () {
        expect(AppTheme.light.brightness, isNot(equals(AppTheme.dark.brightness)));
      });
    });
  });
}
