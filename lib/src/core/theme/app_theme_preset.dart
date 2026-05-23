/// 主题预设枚举，定义 uniHub 支持的所有主题变体。
///
/// 每个预设代表一套由 [seedColor] 驱动的 Material 3 ColorScheme，
/// 搭配产品级 [UniHubThemeColors]（后续实现）来形成完整的视觉风格。
///
/// 当前枚举值：
/// - [uniBlue]  — 清爽蓝色默认主题
/// - [paper]    — 柔和纸感主题
/// - [forest]   — 绿色低刺激主题
/// - [sakura]   — 粉紫柔和主题
/// - [amber]    — 暖色琥珀主题
/// - [graphite] — 克制灰蓝主题
enum AppThemePreset {
  uniBlue,
  paper,
  forest,
  sakura,
  amber,
  graphite,
}

/// [AppThemePreset] 的扩展方法，提供面向用户的可读信息。
extension AppThemePresetX on AppThemePreset {
  /// 面向用户显示的主题名称。
  String get label {
    return switch (this) {
      AppThemePreset.uniBlue => 'Uni Blue',
      AppThemePreset.paper => 'Paper',
      AppThemePreset.forest => 'Forest',
      AppThemePreset.sakura => 'Sakura',
      AppThemePreset.amber => 'Amber',
      AppThemePreset.graphite => 'Graphite',
    };
  }

  /// 主题风格的简要中文描述。
  String get description {
    return switch (this) {
      AppThemePreset.uniBlue => '清爽蓝色默认主题',
      AppThemePreset.paper => '柔和纸感主题',
      AppThemePreset.forest => '绿色低刺激主题',
      AppThemePreset.sakura => '粉紫柔和主题',
      AppThemePreset.amber => '暖色琥珀主题',
      AppThemePreset.graphite => '克制灰蓝主题',
    };
  }
}
