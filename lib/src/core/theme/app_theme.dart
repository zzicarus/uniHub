import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_tokens.dart';

abstract final class AppTheme {
  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      canvasColor: colorScheme.surface,
      fontFamily: AppFonts.sansLatin,
      fontFamilyFallback: const [AppFonts.sansCJK],
    );

    return base.copyWith(
      textTheme: _textTheme(base.textTheme, colorScheme),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 20,
          height: 1.4,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerLow,
        elevation: 0,
        shadowColor: colorScheme.shadow.withValues(alpha: 0.06),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.25)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, AppSizes.buttonHeight),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          disabledBackgroundColor: colorScheme.surfaceContainerHighest,
          disabledForegroundColor: colorScheme.onSurface.withValues(
            alpha: 0.38,
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            height: 1.43,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, AppSizes.buttonHeight),
          foregroundColor: colorScheme.primary,
          disabledForegroundColor: colorScheme.onSurface.withValues(
            alpha: 0.38,
          ),
          side: BorderSide(color: colorScheme.outline),
          textStyle: const TextStyle(
            fontSize: 14,
            height: 1.43,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          disabledForegroundColor: colorScheme.onSurface.withValues(
            alpha: 0.38,
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            height: 1.43,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        hintStyle: TextStyle(color: colorScheme.outline),
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        border: _inputBorder(colorScheme.outline),
        enabledBorder: _inputBorder(colorScheme.outline),
        focusedBorder: _inputBorder(colorScheme.primary),
        errorBorder: _inputBorder(colorScheme.error),
        focusedErrorBorder: _inputBorder(colorScheme.error),
      ),
      listTileTheme: ListTileThemeData(
        minTileHeight: AppSizes.listItem,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        iconColor: colorScheme.onSurfaceVariant,
        textColor: colorScheme.onSurface,
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 16,
          height: 1.5,
          fontWeight: FontWeight.w600,
        ),
        subtitleTextStyle: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontSize: 14,
          height: 1.55,
          fontWeight: FontWeight.w400,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHigh,
        selectedColor: colorScheme.primaryContainer,
        labelStyle: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontSize: 12,
          height: 1.33,
          fontWeight: FontWeight.w600,
        ),
        side: BorderSide(color: colorScheme.outlineVariant),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      iconTheme: IconThemeData(color: colorScheme.onSurfaceVariant, size: 22),
    );
  }

  static ThemeData get dark {
    final darkSeed = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: darkSeed,
      scaffoldBackgroundColor: darkSeed.surface,
      canvasColor: darkSeed.surface,
      fontFamily: AppFonts.sansLatin,
      fontFamilyFallback: const [AppFonts.sansCJK],
    );

    return base.copyWith(
      textTheme: _textTheme(base.textTheme, darkSeed),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: darkSeed.onSurface,
          fontSize: 20,
          height: 1.4,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkSeed.surfaceContainerLow,
        elevation: 0,
        shadowColor: darkSeed.shadow.withValues(alpha: 0.15),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, AppSizes.buttonHeight),
          textStyle: const TextStyle(
            fontSize: 14,
            height: 1.43,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, AppSizes.buttonHeight),
          textStyle: const TextStyle(
            fontSize: 14,
            height: 1.43,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: const TextStyle(
            fontSize: 14,
            height: 1.43,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSeed.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        hintStyle: TextStyle(color: darkSeed.outline),
        labelStyle: TextStyle(color: darkSeed.onSurfaceVariant),
        border: _inputBorder(darkSeed.outline),
        enabledBorder: _inputBorder(darkSeed.outline),
        focusedBorder: _inputBorder(darkSeed.primary),
        errorBorder: _inputBorder(darkSeed.error),
        focusedErrorBorder: _inputBorder(darkSeed.error),
      ),
      listTileTheme: ListTileThemeData(
        minTileHeight: AppSizes.listItem,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        iconColor: darkSeed.onSurfaceVariant,
        textColor: darkSeed.onSurface,
        titleTextStyle: TextStyle(
          color: darkSeed.onSurface,
          fontSize: 16,
          height: 1.5,
          fontWeight: FontWeight.w600,
        ),
        subtitleTextStyle: TextStyle(
          color: darkSeed.onSurfaceVariant,
          fontSize: 14,
          height: 1.55,
          fontWeight: FontWeight.w400,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: darkSeed.surfaceContainerHigh,
        selectedColor: darkSeed.primary.withValues(alpha: 0.12),
        labelStyle: TextStyle(
          color: darkSeed.onSurfaceVariant,
          fontSize: 12,
          height: 1.33,
          fontWeight: FontWeight.w600,
        ),
        side: BorderSide(color: darkSeed.outline),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: darkSeed.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      iconTheme: IconThemeData(color: darkSeed.onSurfaceVariant, size: 22),
    );
  }

  static TextTheme _textTheme(TextTheme base, ColorScheme colorScheme) {
    // Apply Inter as primary font via GoogleFonts, then customise colors/sizes.
    // fontFamilyFallback is set per-style so CJK characters fall back to Noto Sans SC.
    final interTheme = GoogleFonts.interTextTheme(base);

    return interTheme.copyWith(
      headlineMedium: interTheme.headlineMedium?.copyWith(
        color: colorScheme.onSurface,
        fontSize: 28,
        height: 1.29,
        fontWeight: FontWeight.w700,
        fontFamilyFallback: const [AppFonts.sansCJK],
      ),
      titleLarge: interTheme.titleLarge?.copyWith(
        color: colorScheme.onSurface,
        fontSize: 22,
        height: 1.36,
        fontWeight: FontWeight.w700,
        fontFamilyFallback: const [AppFonts.sansCJK],
      ),
      titleMedium: interTheme.titleMedium?.copyWith(
        color: colorScheme.onSurface,
        fontSize: 16,
        height: 1.5,
        fontWeight: FontWeight.w600,
        fontFamilyFallback: const [AppFonts.sansCJK],
      ),
      titleSmall: interTheme.titleSmall?.copyWith(
        color: colorScheme.onSurface,
        fontSize: 14,
        height: 1.43,
        fontWeight: FontWeight.w600,
        fontFamilyFallback: const [AppFonts.sansCJK],
      ),
      bodyLarge: interTheme.bodyLarge?.copyWith(
        color: colorScheme.onSurface,
        fontSize: 16,
        height: 1.5,
        fontWeight: FontWeight.w400,
        fontFamilyFallback: const [AppFonts.sansCJK],
      ),
      bodyMedium: interTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurfaceVariant,
        fontSize: 14,
        height: 1.57,
        fontWeight: FontWeight.w400,
        fontFamilyFallback: const [AppFonts.sansCJK],
      ),
      bodySmall: interTheme.bodySmall?.copyWith(
        color: colorScheme.outline,
        fontSize: 12,
        height: 1.5,
        fontWeight: FontWeight.w400,
        fontFamilyFallback: const [AppFonts.sansCJK],
      ),
      labelLarge: interTheme.labelLarge?.copyWith(
        color: colorScheme.onSurface,
        fontSize: 14,
        height: 1.43,
        fontWeight: FontWeight.w600,
        fontFamilyFallback: const [AppFonts.sansCJK],
      ),
      labelMedium: interTheme.labelMedium?.copyWith(
        color: colorScheme.onSurfaceVariant,
        fontSize: 12,
        height: 1.33,
        fontWeight: FontWeight.w600,
        fontFamilyFallback: const [AppFonts.sansCJK],
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide(color: color),
    );
  }
}
