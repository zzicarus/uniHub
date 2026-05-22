import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:uni_hub/src/core/theme/app_tokens.dart';

void main() {
  group('AppColors', () {
    test('primary is non-null', () {
      expect(AppColors.primary, isNotNull);
    });

    test('secondary is non-null', () {
      expect(AppColors.secondary, isNotNull);
    });

    test('accent is non-null', () {
      expect(AppColors.accent, isNotNull);
    });

    test('purple is non-null', () {
      expect(AppColors.purple, isNotNull);
    });

    test('error is non-null', () {
      expect(AppColors.error, isNotNull);
    });

    test('background is a valid Color', () {
      expect(AppColors.background, isNotNull);
      expect(AppColors.background, isA<Color>());
    });

    test('surface is a valid Color', () {
      expect(AppColors.surface, isNotNull);
      expect(AppColors.surface, isA<Color>());
    });

    test('surfaceMuted is a valid Color', () {
      expect(AppColors.surfaceMuted, isNotNull);
    });

    test('textPrimary is a valid Color', () {
      expect(AppColors.textPrimary, isNotNull);
      expect(AppColors.textPrimary, isA<Color>());
    });

    test('textSecondary is a valid Color', () {
      expect(AppColors.textSecondary, isNotNull);
      expect(AppColors.textSecondary, isA<Color>());
    });

    test('textTertiary is a valid Color', () {
      expect(AppColors.textTertiary, isNotNull);
      expect(AppColors.textTertiary, isA<Color>());
    });

    test('soft color variants are all valid Colors', () {
      expect(AppColors.primarySoft, isA<Color>());
      expect(AppColors.greenSoft, isA<Color>());
      expect(AppColors.purpleSoft, isA<Color>());
      expect(AppColors.yellowSoft, isA<Color>());
      expect(AppColors.roseSoft, isA<Color>());
    });
  });

  group('AppSpacing', () {
    test('xxs is a non-null double', () {
      expect(AppSpacing.xxs, isA<double>());
      expect(AppSpacing.xxs, isNotNull);
    });

    test('xs is a non-null double', () {
      expect(AppSpacing.xs, isA<double>());
      expect(AppSpacing.xs, isNotNull);
    });

    test('sm is a non-null double', () {
      expect(AppSpacing.sm, isA<double>());
      expect(AppSpacing.sm, isNotNull);
    });

    test('md is a non-null double', () {
      expect(AppSpacing.md, isA<double>());
      expect(AppSpacing.md, isNotNull);
    });

    test('lg is a non-null double', () {
      expect(AppSpacing.lg, isA<double>());
      expect(AppSpacing.lg, isNotNull);
    });

    test('xl is a non-null double', () {
      expect(AppSpacing.xl, isA<double>());
      expect(AppSpacing.xl, isNotNull);
    });

    test('xxl is a non-null double', () {
      expect(AppSpacing.xxl, isA<double>());
      expect(AppSpacing.xxl, isNotNull);
    });

    test('section is a non-null double', () {
      expect(AppSpacing.section, isA<double>());
      expect(AppSpacing.section, isNotNull);
    });

    test('values increase logically (xxs < xs < sm < md < lg < xl < xxl < section)', () {
      expect(AppSpacing.xxs, lessThan(AppSpacing.xs));
      expect(AppSpacing.xs, lessThan(AppSpacing.sm));
      expect(AppSpacing.sm, lessThan(AppSpacing.md));
      expect(AppSpacing.md, lessThan(AppSpacing.lg));
      expect(AppSpacing.lg, lessThan(AppSpacing.xl));
      expect(AppSpacing.xl, lessThan(AppSpacing.xxl));
      expect(AppSpacing.xxl, lessThan(AppSpacing.section));
    });
  });

  group('AppRadius', () {
    test('xs is non-null and non-negative', () {
      expect(AppRadius.xs, isA<double>());
      expect(AppRadius.xs, greaterThanOrEqualTo(0));
    });

    test('sm is non-null and non-negative', () {
      expect(AppRadius.sm, isA<double>());
      expect(AppRadius.sm, greaterThanOrEqualTo(0));
    });

    test('md is non-null and non-negative', () {
      expect(AppRadius.md, isA<double>());
      expect(AppRadius.md, greaterThanOrEqualTo(0));
    });

    test('lg is non-null and non-negative', () {
      expect(AppRadius.lg, isA<double>());
      expect(AppRadius.lg, greaterThanOrEqualTo(0));
    });

    test('xl is non-null and non-negative', () {
      expect(AppRadius.xl, isA<double>());
      expect(AppRadius.xl, greaterThanOrEqualTo(0));
    });

    test('full is non-null and non-negative', () {
      expect(AppRadius.full, isA<double>());
      expect(AppRadius.full, greaterThanOrEqualTo(0));
    });
  });

  group('AppFonts', () {
    test('decorative is a non-null String', () {
      expect(AppFonts.decorative, isA<String>());
      expect(AppFonts.decorative, isNotNull);
    });

    test('decorative has the expected font family value', () {
      expect(AppFonts.decorative, equals('LXGW WenKai Screen'));
    });

    test('fallback is a non-null List<String>', () {
      expect(AppFonts.fallback, isA<List<String>>());
      expect(AppFonts.fallback, isNotNull);
    });

    test('fallback contains Roboto as first entry', () {
      expect(AppFonts.fallback.first, equals('Roboto'));
    });

    test('fallback contains expected font families', () {
      expect(AppFonts.fallback, contains('Segoe UI'));
      expect(AppFonts.fallback, contains('PingFang SC'));
      expect(AppFonts.fallback, contains('Microsoft YaHei'));
      expect(AppFonts.fallback, contains('Noto Sans CJK SC'));
    });

    test('fallback has at least 5 font families', () {
      expect(AppFonts.fallback.length, greaterThanOrEqualTo(5));
    });
  });
}
