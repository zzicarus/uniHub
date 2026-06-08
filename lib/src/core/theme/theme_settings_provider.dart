import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_theme_preset.dart';

// ── SharedPreferences keys ────────────────────────────────────────────────

const _keyPreset = 'themePreset';
const _keyMode = 'themeMode';

// ── Models ────────────────────────────────────────────────────────────────

/// 主题设置，包含预设选择和亮暗模式。
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

// ── Controller ────────────────────────────────────────────────────────────

/// 主题设置控制器，管理 [ThemeSettings] 的变更，自动持久化到 SharedPreferences。
class ThemeSettingsController extends Notifier<ThemeSettings> {
  bool _initialized = false;

  @override
  ThemeSettings build() {
    // 异步加载持久化设置，完成后更新 state。
    unawaited(_lazyRestore());
    return const ThemeSettings();
  }

  /// 从 SharedPreferences 恢复已保存的设置。
  Future<void> _lazyRestore() async {
    if (_initialized) return;
    _initialized = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final presetStr = prefs.getString(_keyPreset);
      final modeStr = prefs.getString(_keyMode);

      AppThemePreset? preset;
      if (presetStr != null) {
        preset = AppThemePreset.values.cast<AppThemePreset?>().firstWhere(
          (p) => p!.name == presetStr,
          orElse: () => null,
        );
      }

      final mode = _parseMode(modeStr);

      if (preset != null || mode != null) {
        state = ThemeSettings(
          preset: preset ?? state.preset,
          mode: mode ?? state.mode,
        );
      }
    } catch (_) {
      // 忽略反序列化错误，保持默认值。
    }
  }

  /// 持久化当前设置。
  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyPreset, state.preset.name);
      await prefs.setString(_keyMode, _modeToString(state.mode));
    } catch (_) {
      // 忽略持久化错误。
    }
  }

  // ── Actions ────────────────────────────────────────────────────────────

  /// 切换主题预设。
  Future<void> setPreset(AppThemePreset preset) async {
    state = state.copyWith(preset: preset);
    await _persist();
  }

  /// 切换亮暗模式（light / dark / system）。
  Future<void> setMode(ThemeMode mode) async {
    state = state.copyWith(mode: mode);
    await _persist();
  }

  // ── Serialization helpers ──────────────────────────────────────────────

  static ThemeMode? _parseMode(String? value) {
    if (value == null) return null;
    for (final mode in ThemeMode.values) {
      if (_modeToString(mode) == value) return mode;
    }
    return null;
  }

  static String _modeToString(ThemeMode mode) => mode.name;
}

// ── Provider ──────────────────────────────────────────────────────────────

/// 全局主题设置 provider。
final themeSettingsProvider =
    NotifierProvider<ThemeSettingsController, ThemeSettings>(
  ThemeSettingsController.new,
);
