import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
      fontFamily: AppFonts.sansLatin,
      fontFamilyFallback: const [AppFonts.sansCJK],
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
          textStyle: TextStyle(
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
          textStyle: TextStyle(
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
          textStyle: TextStyle(
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
    // Apply Inter as primary font via GoogleFonts, then customise colors/sizes.
    // fontFamilyFallback is set per-style so CJK characters fall back to Noto Sans SC.
    final interTheme = GoogleFonts.interTextTheme(base);

    return interTheme.copyWith(
      headlineMedium: interTheme.headlineMedium?.copyWith(
        color: colorScheme.onSurface,
        fontSize: AppFontTokens.display,
        height: AppFontTokens.displayHeight,
        fontWeight: AppFontTokens.bold,
        fontFamilyFallback: const [AppFonts.sansCJK],
      ),
      titleLarge: interTheme.titleLarge?.copyWith(
        color: colorScheme.onSurface,
        fontSize: AppFontTokens.headline,
        height: AppFontTokens.headlineHeight,
        fontWeight: AppFontTokens.bold,
        fontFamilyFallback: const [AppFonts.sansCJK],
      ),
      titleMedium: interTheme.titleMedium?.copyWith(
        color: colorScheme.onSurface,
        fontSize: AppFontTokens.titleLg,
        height: AppFontTokens.titleLgHeight,
        fontWeight: AppFontTokens.semiBold,
        fontFamilyFallback: const [AppFonts.sansCJK],
      ),
      titleSmall: interTheme.titleSmall?.copyWith(
        color: colorScheme.onSurface,
        fontSize: AppFontTokens.titleMd,
        height: AppFontTokens.titleMdHeight,
        fontWeight: AppFontTokens.semiBold,
        fontFamilyFallback: const [AppFonts.sansCJK],
      ),
      bodyLarge: interTheme.bodyLarge?.copyWith(
        color: colorScheme.onSurface,
        fontSize: AppFontTokens.bodyLg,
        height: AppFontTokens.bodyLgHeight,
        fontWeight: AppFontTokens.normal,
        fontFamilyFallback: const [AppFonts.sansCJK],
      ),
      bodyMedium: interTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurfaceVariant,
        fontSize: AppFontTokens.bodyMd,
        height: AppFontTokens.bodyMdHeight,
        fontWeight: AppFontTokens.normal,
        fontFamilyFallback: const [AppFonts.sansCJK],
      ),
      bodySmall: interTheme.bodySmall?.copyWith(
        color: colorScheme.outline,
        fontSize: AppFontTokens.bodySm,
        height: AppFontTokens.bodySmHeight,
        fontWeight: AppFontTokens.normal,
        fontFamilyFallback: const [AppFonts.sansCJK],
      ),
      labelLarge: interTheme.labelLarge?.copyWith(
        color: colorScheme.onSurface,
        fontSize: AppFontTokens.labelLg,
        height: AppFontTokens.labelLgHeight,
        fontWeight: AppFontTokens.semiBold,
        fontFamilyFallback: const [AppFonts.sansCJK],
      ),
      labelMedium: interTheme.labelMedium?.copyWith(
        color: colorScheme.onSurfaceVariant,
        fontSize: AppFontTokens.labelMd,
        height: AppFontTokens.labelMdHeight,
        fontWeight: AppFontTokens.semiBold,
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
