import 'package:flutter/material.dart';

import 'app_theme_preset.dart';
import 'app_theme_registry.dart';
import 'app_tokens.dart';

abstract final class AppTheme {
  /// 根据 [preset] 和 [brightness] 构建完整的 [ThemeData]。
  static ThemeData build({
    required AppThemePreset preset,
    required Brightness brightness,
  }) {
    final colors = AppThemeRegistry.colorsOf(preset, brightness);
    final isLight = brightness == Brightness.light;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: colors.primary,
      brightness: brightness,
    ).copyWith(
      primary: colors.primary,
      onPrimary: isLight ? const Color(0xFFFFFFFF) : const Color(0xFF000000),
      primaryContainer: colors.primarySoft,
      onPrimaryContainer: colors.primary,
      secondary: colors.purple,
      tertiary: colors.warning,
      error: colors.danger,
      surface: colors.surface,
      onSurface: colors.textPrimary,
      onSurfaceVariant: colors.textSecondary,
      outline: colors.border,
      outlineVariant: colors.borderStrong,
      surfaceContainerLowest: colors.background,
      surfaceContainerLow: colors.surfaceMuted,
      surfaceContainer: colors.surface,
      surfaceContainerHigh:
          Color.lerp(colors.surfaceMuted, colors.border, 0.5)!,
      surfaceContainerHighest: colors.border,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colors.background,
      canvasColor: colors.background,
      fontFamily: AppFonts.ui,
      fontFamilyFallback: AppFonts.fallback,
      extensions: <ThemeExtension<dynamic>>[
        colors,
      ],
    );

    return base.copyWith(
      textTheme: _textTheme(base.textTheme, colorScheme),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: colors.textPrimary,
          fontSize: AppFontTokens.headline,
          height: AppFontTokens.headlineHeight,
          fontWeight: AppFontTokens.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerLow,
        elevation: 0,
        shadowColor: colorScheme.shadow.withValues(alpha: isLight ? 0.06 : 0.15),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: isLight
              ? BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.25),
                )
              : BorderSide.none,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, AppSizes.buttonHeight),
          backgroundColor: colors.primary,
          foregroundColor: colorScheme.onPrimary,
          disabledBackgroundColor: colorScheme.surfaceContainerHighest,
          disabledForegroundColor: colors.textPrimary.withValues(alpha: 0.38),
          textStyle: const TextStyle(
            fontSize: AppFontTokens.titleMd,
            height: AppFontTokens.titleMdHeight,
            fontWeight: AppFontTokens.semiBold,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, AppSizes.buttonHeight),
          foregroundColor: colors.primary,
          disabledForegroundColor: colors.textPrimary.withValues(alpha: 0.38),
          side: BorderSide(color: colors.border),
          textStyle: const TextStyle(
            fontSize: AppFontTokens.titleMd,
            height: AppFontTokens.titleMdHeight,
            fontWeight: AppFontTokens.semiBold,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.primary,
          disabledForegroundColor: colors.textPrimary.withValues(alpha: 0.38),
          textStyle: const TextStyle(
            fontSize: AppFontTokens.titleMd,
            height: AppFontTokens.titleMdHeight,
            fontWeight: AppFontTokens.semiBold,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        hintStyle: TextStyle(color: colors.textTertiary),
        labelStyle: TextStyle(color: colors.textSecondary),
        border: _inputBorder(colors.border),
        enabledBorder: _inputBorder(colors.border),
        focusedBorder: _inputBorder(colors.primary),
        errorBorder: _inputBorder(colors.danger),
        focusedErrorBorder: _inputBorder(colors.danger),
      ),
      listTileTheme: ListTileThemeData(
        minTileHeight: AppSizes.listItem,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        iconColor: colors.textSecondary,
        textColor: colors.textPrimary,
        titleTextStyle: TextStyle(
          color: colors.textPrimary,
          fontSize: AppFontTokens.titleLg,
          height: AppFontTokens.titleLgHeight,
          fontWeight: AppFontTokens.semiBold,
        ),
        subtitleTextStyle: TextStyle(
          color: colors.textSecondary,
          fontSize: AppFontTokens.titleMd,
          height: AppFontTokens.titleMdHeight,
          fontWeight: AppFontTokens.normal,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHigh,
        selectedColor: isLight ? colors.primarySoft : colors.primary.withValues(alpha: 0.12),
        labelStyle: TextStyle(
          color: colors.textSecondary,
          fontSize: AppFontTokens.labelMd,
          height: AppFontTokens.labelMdHeight,
          fontWeight: AppFontTokens.semiBold,
        ),
        side: BorderSide(color: colors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colors.border,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        contentTextStyle: const TextStyle(
          fontWeight: AppFontTokens.medium,
        ),
      ),
      iconTheme: IconThemeData(color: colors.textSecondary, size: 22),
    );
  }

  /// 兼容入口：Uni Blue 浅色主题。
  static ThemeData get light => build(
        preset: AppThemePreset.uniBlue,
        brightness: Brightness.light,
      );

  /// 兼容入口：Uni Blue 深色主题。
  static ThemeData get dark => build(
        preset: AppThemePreset.uniBlue,
        brightness: Brightness.dark,
      );

  static TextTheme _textTheme(TextTheme base, ColorScheme colorScheme) {
    TextStyle style({
      required double size,
      required double height,
      required FontWeight weight,
      required Color color,
      double letterSpacing = 0,
      String fontFamily = AppFonts.ui,
    }) {
      return TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: AppFonts.fallback,
        fontSize: size,
        height: height,
        fontWeight: weight,
        letterSpacing: letterSpacing,
        color: color,
      );
    }

    return TextTheme(
      headlineMedium: style(
        size: AppFontTokens.display,
        height: AppFontTokens.displayHeight,
        weight: AppFontTokens.bold,
        color: colorScheme.onSurface,
      ),
      titleLarge: style(
        size: AppFontTokens.headline,
        height: AppFontTokens.headlineHeight,
        weight: AppFontTokens.bold,
        color: colorScheme.onSurface,
      ),
      titleMedium: style(
        size: AppFontTokens.titleLg,
        height: AppFontTokens.titleLgHeight,
        weight: AppFontTokens.semiBold,
        color: colorScheme.onSurface,
      ),
      titleSmall: style(
        size: AppFontTokens.titleMd,
        height: AppFontTokens.titleMdHeight,
        weight: AppFontTokens.semiBold,
        color: colorScheme.onSurface,
      ),
      bodyLarge: style(
        size: AppFontTokens.bodyLg,
        height: AppFontTokens.bodyLgHeight,
        weight: AppFontTokens.normal,
        color: colorScheme.onSurface,
      ),
      bodyMedium: style(
        size: AppFontTokens.bodyMd,
        height: AppFontTokens.bodyMdHeight,
        weight: AppFontTokens.normal,
        color: colorScheme.onSurfaceVariant,
      ),
      bodySmall: style(
        size: AppFontTokens.bodySm,
        height: AppFontTokens.bodySmHeight,
        weight: AppFontTokens.normal,
        color: colorScheme.onSurfaceVariant,
      ),
      labelLarge: style(
        size: AppFontTokens.labelLg,
        height: AppFontTokens.labelLgHeight,
        weight: AppFontTokens.semiBold,
        color: colorScheme.onSurface,
      ),
      labelMedium: style(
        size: AppFontTokens.labelMd,
        height: AppFontTokens.labelMdHeight,
        weight: AppFontTokens.medium,
        color: colorScheme.onSurfaceVariant,
      ),
      labelSmall: style(
        size: AppFontTokens.caption,
        height: 1.36,
        weight: AppFontTokens.medium,
        color: colorScheme.onSurfaceVariant,
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
