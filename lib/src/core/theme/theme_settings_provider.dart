import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_theme_preset.dart';

/// 主题设置，包含预设选择和亮暗模式。
///
/// TODO: 后续接入 SharedPreferences 持久化。
class ThemeSettings {
  final AppThemePreset preset;
  final ThemeMode mode;

  const ThemeSettings({
    this.preset = AppThemePreset.uniBlue,
    this.mode = ThemeMode.system,
  });

  ThemeSettings copyWith({
    AppThemePreset? preset,
    ThemeMode? mode,
  }) {
    return ThemeSettings(
      preset: preset ?? this.preset,
      mode: mode ?? this.mode,
    );
  }
}

/// 主题设置控制器，管理 [ThemeSettings] 的变更。
///
/// TODO: 后续接入 SharedPreferences 持久化。
class ThemeSettingsController extends Notifier<ThemeSettings> {
  @override
  ThemeSettings build() => const ThemeSettings();

  /// 切换主题预设。
  void setPreset(AppThemePreset preset) {
    state = state.copyWith(preset: preset);
  }

  /// 切换亮暗模式（light / dark / system）。
  void setMode(ThemeMode mode) {
    state = state.copyWith(mode: mode);
  }
}

/// 全局主题设置 provider。
final themeSettingsProvider =
    NotifierProvider<ThemeSettingsController, ThemeSettings>(
  ThemeSettingsController.new,
);
