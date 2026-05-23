import 'package:flutter/material.dart';

/// 产品级颜色令牌，定义 uniHub 所有自定义语义颜色。
///
/// 与 Material 3 的 [ColorScheme] 互补：[ColorScheme] 管理系统级颜色
/// （onSurface、primaryContainer 等），而 [UniHubThemeColors] 管理业务级颜色
/// （sidebarBackground、navSelectedBackground 等）。
///
/// 使用方式：
/// ```dart
/// final colors = context.appColors;
/// ```
///
/// 需要在 [ThemeData] 中通过 `extensions` 注册后生效。
class UniHubThemeColors extends ThemeExtension<UniHubThemeColors> {
  final Color background;
  final Color surface;
  final Color surfaceMuted;
  final Color border;
  final Color borderStrong;
  final Color primary;
  final Color primaryHover;
  final Color primarySoft;
  final Color success;
  final Color successSoft;
  final Color warning;
  final Color warningSoft;
  final Color purple;
  final Color purpleSoft;
  final Color danger;
  final Color dangerSoft;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color sidebarBackground;
  final Color navSelectedBackground;
  final Color panelBackground;

  const UniHubThemeColors({
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.border,
    required this.borderStrong,
    required this.primary,
    required this.primaryHover,
    required this.primarySoft,
    required this.success,
    required this.successSoft,
    required this.warning,
    required this.warningSoft,
    required this.purple,
    required this.purpleSoft,
    required this.danger,
    required this.dangerSoft,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.sidebarBackground,
    required this.navSelectedBackground,
    required this.panelBackground,
  });

  @override
  UniHubThemeColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceMuted,
    Color? border,
    Color? borderStrong,
    Color? primary,
    Color? primaryHover,
    Color? primarySoft,
    Color? success,
    Color? successSoft,
    Color? warning,
    Color? warningSoft,
    Color? purple,
    Color? purpleSoft,
    Color? danger,
    Color? dangerSoft,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? sidebarBackground,
    Color? navSelectedBackground,
    Color? panelBackground,
  }) {
    return UniHubThemeColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      primary: primary ?? this.primary,
      primaryHover: primaryHover ?? this.primaryHover,
      primarySoft: primarySoft ?? this.primarySoft,
      success: success ?? this.success,
      successSoft: successSoft ?? this.successSoft,
      warning: warning ?? this.warning,
      warningSoft: warningSoft ?? this.warningSoft,
      purple: purple ?? this.purple,
      purpleSoft: purpleSoft ?? this.purpleSoft,
      danger: danger ?? this.danger,
      dangerSoft: dangerSoft ?? this.dangerSoft,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      sidebarBackground: sidebarBackground ?? this.sidebarBackground,
      navSelectedBackground:
          navSelectedBackground ?? this.navSelectedBackground,
      panelBackground: panelBackground ?? this.panelBackground,
    );
  }

  @override
  UniHubThemeColors lerp(
    ThemeExtension<UniHubThemeColors>? other,
    double t,
  ) {
    if (other is! UniHubThemeColors) return this;

    return UniHubThemeColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryHover: Color.lerp(primaryHover, other.primaryHover, t)!,
      primarySoft: Color.lerp(primarySoft, other.primarySoft, t)!,
      success: Color.lerp(success, other.success, t)!,
      successSoft: Color.lerp(successSoft, other.successSoft, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningSoft: Color.lerp(warningSoft, other.warningSoft, t)!,
      purple: Color.lerp(purple, other.purple, t)!,
      purpleSoft: Color.lerp(purpleSoft, other.purpleSoft, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerSoft: Color.lerp(dangerSoft, other.dangerSoft, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      sidebarBackground:
          Color.lerp(sidebarBackground, other.sidebarBackground, t)!,
      navSelectedBackground:
          Color.lerp(navSelectedBackground, other.navSelectedBackground, t)!,
      panelBackground:
          Color.lerp(panelBackground, other.panelBackground, t)!,
    );
  }
}

/// [BuildContext] 扩展，提供便捷访问 [UniHubThemeColors] 的方式。
extension UniHubThemeX on BuildContext {
  /// 获取当前主题的 [UniHubThemeColors]。
  ///
  /// 使用前确保在 [ThemeData] 的 `extensions` 中注册了 [UniHubThemeColors]。
  UniHubThemeColors get appColors {
    assert(
      Theme.of(this).extension<UniHubThemeColors>() != null,
      'UniHubThemeColors is not registered.',
    );
    return Theme.of(this).extension<UniHubThemeColors>()!;
  }
}
