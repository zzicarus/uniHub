import 'package:flutter/material.dart';

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
      fontFamilyFallback: AppFonts.fallback,
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
      fontFamilyFallback: AppFonts.fallback,
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
    return base.copyWith(
      headlineMedium: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 28,
        height: 1.29,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 22,
        height: 1.36,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 16,
        height: 1.5,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 14,
        height: 1.43,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 16,
        height: 1.5,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: TextStyle(
        color: colorScheme.onSurfaceVariant,
        fontSize: 14,
        height: 1.57,
        fontWeight: FontWeight.w400,
      ),
      bodySmall: TextStyle(
        color: colorScheme.outline,
        fontSize: 12,
        height: 1.5,
        fontWeight: FontWeight.w400,
      ),
      labelLarge: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 14,
        height: 1.43,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: TextStyle(
        color: colorScheme.onSurfaceVariant,
        fontSize: 12,
        height: 1.33,
        fontWeight: FontWeight.w600,
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
