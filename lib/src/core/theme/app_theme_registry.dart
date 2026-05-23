import 'package:flutter/material.dart';

import 'app_theme_preset.dart';
import 'app_theme_tokens.dart';

/// 主题注册表，管理所有预设主题的 [UniHubThemeColors] 色板。
///
/// 通过 [colorsOf] 方法根据预设和亮度获取对应的颜色令牌集合。
/// 每套主题的 primary 色均不同，确保视觉差异化。
abstract final class AppThemeRegistry {
  /// 根据 [preset] 和 [brightness] 返回对应的 [UniHubThemeColors]。
  static UniHubThemeColors colorsOf(
    AppThemePreset preset,
    Brightness brightness,
  ) {
    return switch (brightness) {
      Brightness.light => _lightColors(preset),
      Brightness.dark => _darkColors(preset),
    };
  }

  // ──────────────────────────────────────────────
  // Light themes
  // ──────────────────────────────────────────────

  static UniHubThemeColors _lightColors(AppThemePreset preset) {
    return switch (preset) {
      AppThemePreset.uniBlue => _uniBlueLight,
      AppThemePreset.paper => _paperLight,
      AppThemePreset.forest => _forestLight,
      AppThemePreset.sakura => _sakuraLight,
      AppThemePreset.amber => _amberLight,
      AppThemePreset.graphite => _graphiteLight,
    };
  }

  // ──────────────────────────────────────────────
  // Dark themes
  // ──────────────────────────────────────────────

  static UniHubThemeColors _darkColors(AppThemePreset preset) {
    return switch (preset) {
      AppThemePreset.uniBlue => _uniBlueDark,
      AppThemePreset.paper => _paperDark,
      AppThemePreset.forest => _forestDark,
      AppThemePreset.sakura => _sakuraDark,
      AppThemePreset.amber => _amberDark,
      AppThemePreset.graphite => _graphiteDark,
    };
  }

  // ──────────────────────────────────────────────
  // Light theme definitions
  // ──────────────────────────────────────────────

  static const _lightSurface = Color(0xFFFFFFFF);
  static const _lightPanel = Color(0xFFFFFFFF);
  static const _lightTextPrimary = Color(0xFF111827);
  static const _lightTextSecondary = Color(0xFF667085);
  static const _lightTextTertiary = Color(0xFF98A2B3);
  static const _lightSuccess = Color(0xFF22C55E);
  static const _lightSuccessSoft = Color(0xFFEAFBF0);
  static const _lightWarning = Color(0xFFF59E0B);
  static const _lightWarningSoft = Color(0xFFFFF7E6);
  static const _lightPurple = Color(0xFF8B5CF6);
  static const _lightPurpleSoft = Color(0xFFF3EEFF);
  static const _lightDanger = Color(0xFFF43F5E);
  static const _lightDangerSoft = Color(0xFFFFEEF3);

  static const _uniBlueLight = UniHubThemeColors(
    background: Color(0xFFFAFBFE),
    surface: _lightSurface,
    surfaceMuted: Color(0xFFF6F8FC),
    border: Color(0xFFE6EAF2),
    borderStrong: Color(0xFFD8DEE9),
    primary: Color(0xFF3F6DF6),
    primaryHover: Color(0xFF345EE8),
    primarySoft: Color(0xFFEEF4FF),
    success: _lightSuccess,
    successSoft: _lightSuccessSoft,
    warning: _lightWarning,
    warningSoft: _lightWarningSoft,
    purple: _lightPurple,
    purpleSoft: _lightPurpleSoft,
    danger: _lightDanger,
    dangerSoft: _lightDangerSoft,
    textPrimary: _lightTextPrimary,
    textSecondary: _lightTextSecondary,
    textTertiary: _lightTextTertiary,
    sidebarBackground: Color(0xFFFAFBFE),
    navSelectedBackground: Color(0xFFEEF4FF),
    panelBackground: _lightPanel,
  );

  static const _paperLight = UniHubThemeColors(
    background: Color(0xFFF7F6F2),
    surface: _lightSurface,
    surfaceMuted: Color(0xFFEFEDE8),
    border: Color(0xFFDFDCD4),
    borderStrong: Color(0xFFCFCBC0),
    primary: Color(0xFF4B6382),
    primaryHover: Color(0xFF3E5570),
    primarySoft: Color(0xFFEBEFF4),
    success: _lightSuccess,
    successSoft: _lightSuccessSoft,
    warning: _lightWarning,
    warningSoft: _lightWarningSoft,
    purple: _lightPurple,
    purpleSoft: _lightPurpleSoft,
    danger: _lightDanger,
    dangerSoft: _lightDangerSoft,
    textPrimary: _lightTextPrimary,
    textSecondary: _lightTextSecondary,
    textTertiary: _lightTextTertiary,
    sidebarBackground: Color(0xFFF7F6F2),
    navSelectedBackground: Color(0xFFEBEFF4),
    panelBackground: _lightPanel,
  );

  static const _forestLight = UniHubThemeColors(
    background: Color(0xFFF6FAF6),
    surface: _lightSurface,
    surfaceMuted: Color(0xFFEEF3EE),
    border: Color(0xFFDCE4DC),
    borderStrong: Color(0xFFCCD6CC),
    primary: Color(0xFF2F855A),
    primaryHover: Color(0xFF26734E),
    primarySoft: Color(0xFFE8F5ED),
    success: _lightSuccess,
    successSoft: _lightSuccessSoft,
    warning: _lightWarning,
    warningSoft: _lightWarningSoft,
    purple: _lightPurple,
    purpleSoft: _lightPurpleSoft,
    danger: _lightDanger,
    dangerSoft: _lightDangerSoft,
    textPrimary: _lightTextPrimary,
    textSecondary: _lightTextSecondary,
    textTertiary: _lightTextTertiary,
    sidebarBackground: Color(0xFFF6FAF6),
    navSelectedBackground: Color(0xFFE8F5ED),
    panelBackground: _lightPanel,
  );

  static const _sakuraLight = UniHubThemeColors(
    background: Color(0xFFFEF8FA),
    surface: _lightSurface,
    surfaceMuted: Color(0xFFF6F0F2),
    border: Color(0xFFE8DEE2),
    borderStrong: Color(0xFFDACED4),
    primary: Color(0xFFD9468A),
    primaryHover: Color(0xFFC23A78),
    primarySoft: Color(0xFFFDEEF5),
    success: _lightSuccess,
    successSoft: _lightSuccessSoft,
    warning: _lightWarning,
    warningSoft: _lightWarningSoft,
    purple: _lightPurple,
    purpleSoft: _lightPurpleSoft,
    danger: _lightDanger,
    dangerSoft: _lightDangerSoft,
    textPrimary: _lightTextPrimary,
    textSecondary: _lightTextSecondary,
    textTertiary: _lightTextTertiary,
    sidebarBackground: Color(0xFFFEF8FA),
    navSelectedBackground: Color(0xFFFDEEF5),
    panelBackground: _lightPanel,
  );

  static const _amberLight = UniHubThemeColors(
    background: Color(0xFFFEFCF5),
    surface: _lightSurface,
    surfaceMuted: Color(0xFFF6F2E8),
    border: Color(0xFFE8E0D0),
    borderStrong: Color(0xFFDACCB8),
    primary: Color(0xFFD97706),
    primaryHover: Color(0xFFC06806),
    primarySoft: Color(0xFFFFF3E0),
    success: _lightSuccess,
    successSoft: _lightSuccessSoft,
    warning: _lightWarning,
    warningSoft: _lightWarningSoft,
    purple: _lightPurple,
    purpleSoft: _lightPurpleSoft,
    danger: _lightDanger,
    dangerSoft: _lightDangerSoft,
    textPrimary: _lightTextPrimary,
    textSecondary: _lightTextSecondary,
    textTertiary: _lightTextTertiary,
    sidebarBackground: Color(0xFFFEFCF5),
    navSelectedBackground: Color(0xFFFFF3E0),
    panelBackground: _lightPanel,
  );

  static const _graphiteLight = UniHubThemeColors(
    background: Color(0xFFF8F9FA),
    surface: _lightSurface,
    surfaceMuted: Color(0xFFF0F2F4),
    border: Color(0xFFDEE0E4),
    borderStrong: Color(0xFFCED0D6),
    primary: Color(0xFF475569),
    primaryHover: Color(0xFF3B4658),
    primarySoft: Color(0xFFEBEDF0),
    success: _lightSuccess,
    successSoft: _lightSuccessSoft,
    warning: _lightWarning,
    warningSoft: _lightWarningSoft,
    purple: _lightPurple,
    purpleSoft: _lightPurpleSoft,
    danger: _lightDanger,
    dangerSoft: _lightDangerSoft,
    textPrimary: _lightTextPrimary,
    textSecondary: _lightTextSecondary,
    textTertiary: _lightTextTertiary,
    sidebarBackground: Color(0xFFF8F9FA),
    navSelectedBackground: Color(0xFFEBEDF0),
    panelBackground: _lightPanel,
  );

  // ──────────────────────────────────────────────
  // Dark theme shared base colors
  // ──────────────────────────────────────────────

  static const _darkSurface = Color(0xFF1A1F26);
  static const _darkSurfaceMuted = Color(0xFF242A33);
  static const _darkBorder = Color(0xFF2E3640);
  static const _darkBorderStrong = Color(0xFF3B4450);
  static const _darkPanel = Color(0xFF1A1F26);
  static const _darkTextPrimary = Color(0xFFF1F5F9);
  static const _darkTextSecondary = Color(0xFF94A3B8);
  static const _darkTextTertiary = Color(0xFF64748B);
  static const _darkSuccess = Color(0xFF34D16F);
  static const _darkSuccessSoft = Color(0xFF1A2E24);
  static const _darkWarning = Color(0xFFF5B125);
  static const _darkWarningSoft = Color(0xFF2E2210);
  static const _darkPurple = Color(0xFFA47CFF);
  static const _darkPurpleSoft = Color(0xFF241E3A);
  static const _darkDanger = Color(0xFFF75E7A);
  static const _darkDangerSoft = Color(0xFF2E1A24);

  // ──────────────────────────────────────────────
  // Dark theme definitions
  // ──────────────────────────────────────────────

  static const _uniBlueDark = UniHubThemeColors(
    background: Color(0xFF0E121B),
    surface: _darkSurface,
    surfaceMuted: _darkSurfaceMuted,
    border: _darkBorder,
    borderStrong: _darkBorderStrong,
    primary: Color(0xFF5B82F7),
    primaryHover: Color(0xFF7B9EF9),
    primarySoft: Color(0xFF1E2A4A),
    success: _darkSuccess,
    successSoft: _darkSuccessSoft,
    warning: _darkWarning,
    warningSoft: _darkWarningSoft,
    purple: _darkPurple,
    purpleSoft: _darkPurpleSoft,
    danger: _darkDanger,
    dangerSoft: _darkDangerSoft,
    textPrimary: _darkTextPrimary,
    textSecondary: _darkTextSecondary,
    textTertiary: _darkTextTertiary,
    sidebarBackground: Color(0xFF0E121B),
    navSelectedBackground: Color(0xFF1E2A4A),
    panelBackground: _darkPanel,
  );

  static const _paperDark = UniHubThemeColors(
    background: Color(0xFF12161C),
    surface: _darkSurface,
    surfaceMuted: _darkSurfaceMuted,
    border: _darkBorder,
    borderStrong: _darkBorderStrong,
    primary: Color(0xFF6B83A2),
    primaryHover: Color(0xFF8B9DB6),
    primarySoft: Color(0xFF1E2A3A),
    success: _darkSuccess,
    successSoft: _darkSuccessSoft,
    warning: _darkWarning,
    warningSoft: _darkWarningSoft,
    purple: _darkPurple,
    purpleSoft: _darkPurpleSoft,
    danger: _darkDanger,
    dangerSoft: _darkDangerSoft,
    textPrimary: _darkTextPrimary,
    textSecondary: _darkTextSecondary,
    textTertiary: _darkTextTertiary,
    sidebarBackground: Color(0xFF12161C),
    navSelectedBackground: Color(0xFF1E2A3A),
    panelBackground: _darkPanel,
  );

  static const _forestDark = UniHubThemeColors(
    background: Color(0xFF0E1712),
    surface: _darkSurface,
    surfaceMuted: _darkSurfaceMuted,
    border: _darkBorder,
    borderStrong: _darkBorderStrong,
    primary: Color(0xFF4FA57A),
    primaryHover: Color(0xFF6FBA92),
    primarySoft: Color(0xFF1A2E24),
    success: _darkSuccess,
    successSoft: _darkSuccessSoft,
    warning: _darkWarning,
    warningSoft: _darkWarningSoft,
    purple: _darkPurple,
    purpleSoft: _darkPurpleSoft,
    danger: _darkDanger,
    dangerSoft: _darkDangerSoft,
    textPrimary: _darkTextPrimary,
    textSecondary: _darkTextSecondary,
    textTertiary: _darkTextTertiary,
    sidebarBackground: Color(0xFF0E1712),
    navSelectedBackground: Color(0xFF1A2E24),
    panelBackground: _darkPanel,
  );

  static const _sakuraDark = UniHubThemeColors(
    background: Color(0xFF1A0E14),
    surface: _darkSurface,
    surfaceMuted: _darkSurfaceMuted,
    border: _darkBorder,
    borderStrong: _darkBorderStrong,
    primary: Color(0xFFE0669E),
    primaryHover: Color(0xFFE886B2),
    primarySoft: Color(0xFF2E1A24),
    success: _darkSuccess,
    successSoft: _darkSuccessSoft,
    warning: _darkWarning,
    warningSoft: _darkWarningSoft,
    purple: _darkPurple,
    purpleSoft: _darkPurpleSoft,
    danger: _darkDanger,
    dangerSoft: _darkDangerSoft,
    textPrimary: _darkTextPrimary,
    textSecondary: _darkTextSecondary,
    textTertiary: _darkTextTertiary,
    sidebarBackground: Color(0xFF1A0E14),
    navSelectedBackground: Color(0xFF2E1A24),
    panelBackground: _darkPanel,
  );

  static const _amberDark = UniHubThemeColors(
    background: Color(0xFF1A1410),
    surface: _darkSurface,
    surfaceMuted: _darkSurfaceMuted,
    border: _darkBorder,
    borderStrong: _darkBorderStrong,
    primary: Color(0xFFF59E0B),
    primaryHover: Color(0xFFF7B235),
    primarySoft: Color(0xFF2E241A),
    success: _darkSuccess,
    successSoft: _darkSuccessSoft,
    warning: _darkWarning,
    warningSoft: _darkWarningSoft,
    purple: _darkPurple,
    purpleSoft: _darkPurpleSoft,
    danger: _darkDanger,
    dangerSoft: _darkDangerSoft,
    textPrimary: _darkTextPrimary,
    textSecondary: _darkTextSecondary,
    textTertiary: _darkTextTertiary,
    sidebarBackground: Color(0xFF1A1410),
    navSelectedBackground: Color(0xFF2E241A),
    panelBackground: _darkPanel,
  );

  static const _graphiteDark = UniHubThemeColors(
    background: Color(0xFF101214),
    surface: _darkSurface,
    surfaceMuted: _darkSurfaceMuted,
    border: _darkBorder,
    borderStrong: _darkBorderStrong,
    primary: Color(0xFF677588),
    primaryHover: Color(0xFF8796A8),
    primarySoft: Color(0xFF1E222A),
    success: _darkSuccess,
    successSoft: _darkSuccessSoft,
    warning: _darkWarning,
    warningSoft: _darkWarningSoft,
    purple: _darkPurple,
    purpleSoft: _darkPurpleSoft,
    danger: _darkDanger,
    dangerSoft: _darkDangerSoft,
    textPrimary: _darkTextPrimary,
    textSecondary: _darkTextSecondary,
    textTertiary: _darkTextTertiary,
    sidebarBackground: Color(0xFF101214),
    navSelectedBackground: Color(0xFF1E222A),
    panelBackground: _darkPanel,
  );
}
