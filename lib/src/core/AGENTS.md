# core/ — 基础设施层

贯穿应用核心功能：数据库、路由、主题、插件系统、搜索。

## 模块一览

| 模块 | 路径 | 用途 |
|------|------|------|
| app/ | `core/app/` | 应用入口、App 组件、Shell 布局、HomePage |
| database/ | `core/database/` | Drift 数据库定义 + Provider |
| plugin/ | `core/plugin/` | **插件系统（详见 plugin/AGENTS.md）** |
| router/ | `core/router/` | GoRouter 配置 + 路由 Provider |
| search/ | `core/search/` | 全局搜索基础设施 |
| theme/ | `core/theme/` | Material 3 主题 + 设计令牌 |

## 布局系统（重要）

两套布局——确定自己该用哪个：

| 你的页面类型 | 使用 |
|-------------|------|
| 顶层路由页面（从 GoRouter 导航过来） | 不直接选——GoRouter ShellRoute（`AdaptiveShell`）自动选择 DesktopShell/MobileShell |
| 插件页面内的子布局 | `AdaptiveLayout`（参考 ThoughtsPage 中的用法） |
| 任何地方都不要新建 | `AppLayout`（已删除） |

## 启动序列

```
main()
├─ WidgetsFlutterBinding.ensureInitialized()
├─ PluginRegistry (注册所有插件)
│  └─ registry.initAll() (各插件.onInit 按注册顺序执行)
└─ runApp(
     ProviderScope (顶层)
        ├─ AppDatabase (LazyDatabase → 延迟创建, 接收 PluginRegistry)
        ├─ PluginRegistry (overrideWithValue, 已初始化完毕)
        └─ UniHubApp (MaterialApp.router)
           └─ routerProvider (GoRouter + ShellRoute)
   )
```

## 已知死代码

- `app/mobile_placeholder_pages.dart` — 5 个轻量占位页面（用于未实现的移动端路由）
- `shared/ui/style_guide_screen.dart` — 组件目录页面（已接入路由，通过侧栏「组件目录」访问）

## 数据库

详见 `.trellis/spec/backend/database-guidelines.md`。核心注意：

- `AppDatabase` 通过遍历插件 `tables` 合并所有表
- 表定义统一放在 `core/database/tables/` 下，插件不直接引入数据库表
- 使用 `LazyDatabase` 延迟创建，Provider dispose 时关闭
- 所有 DAO/Repository 使用构造器注入 `AppDatabase`

## 主题

### 架构概览

v2 引入了**多预设主题系统**，核心文件：

| 文件 | 职责 |
|------|------|
| `app_theme_tokens.dart` | `UniHubThemeColors`（`ThemeExtension`）定义产品级语义颜色；通过 `context.appColors` 扩展访问 |
| `app_theme_preset.dart` | `AppThemePreset` 枚举（uniBlue / paper / forest / sakura / amber / graphite） |
| `app_theme_registry.dart` | `AppThemeRegistry` 统一管理所有预设的亮/暗色板 |
| `theme_settings_provider.dart` | `ThemeSettings` + `Notifier`，运行时切换预设和亮暗模式 |
| `app_theme.dart` | `AppTheme.build(preset, brightness)` 工厂方法，替代原来的 `light`/`dark` getter |

### 使用方法

```dart
// 旧方式（v1）：
Theme.of(context).colorScheme.primary

// 新方式（v2）——推荐：
context.appColors.primary         // 产品级语义颜色
context.appColors.sidebarBackground
context.appColors.textSecondary
```

### 关键约定

- 所有 Widget 优先使用 `context.appColors`（`UniHubThemeColors`）
- `colorScheme` 保留给 M3 系统级颜色（`onSurface`、`primaryContainer` 等）
- 主题入口统一通过 `AppTheme.build(preset: ..., brightness: ...)` 构造
- 运行时可切换：`ref.read(themeSettingsProvider.notifier).setPreset(AppThemePreset.forest)`
- 设计令牌（间距、圆角、字号）仍定义在 `app_tokens.dart`

---

## 近期变更

> 本 section 由 sync-knowledge 自动管理，按时间倒序追加。

### 2026-05-23: 设置页外观设置组件化重构
- **appearance_settings_section.dart（新增）** — `AppearanceSettingsSection` ConsumerWidget，将外观设置（主题模式切换 + 主题预设选择）从 `settings_page.dart` 提取为独立可复用组件
- **settings\_page.dart** — 外观面板替换为 `AppearanceSettingsSection`；Scaffold backgroundColor 切换至 `context.appColors.background`；`_SettingsPanel` 样式改用 `panelBackground`/`border` Token
- **主题设置 UI 完成**：ThemeMode SegmentedButton（跟随系统/浅色/深色）+ ThemePresetGrid 响应式卡片列表（6 预设，3/2/1 列自适应），交互通过 `themeSettingsProvider` 即时生效

### 2026-05-23: 引入多预设主题系统（v2）
- **app_theme_tokens.dart（新增）** — `UniHubThemeColors` 继承 `ThemeExtension`，定义 21 个产品级语义颜色（background、sidebarBackground、panelBackground、textPrimary 等）；提供 `context.appColors` 扩展
- **app_theme_preset.dart（新增）** — `AppThemePreset` 枚举：uniBlue / paper / forest / sakura / amber / graphite
- **app_theme_registry.dart（新增）** — `AppThemeRegistry.colorsOf(preset, brightness)` 统一管理 6 个预设 × 2 种亮度 = 12 套色板
- **theme_settings_provider.dart（新增）** — `ThemeSettingsController` Notifier，支持运行时切换 preset 和 ThemeMode
- **app_theme.dart** — 重写为 `AppTheme.build(preset, brightness)` 工厂方法，`light`/`dark` getter 改为兼容入口；`cardTheme` 暗色模式自适应移除卡片边框
- **home_page.dart / right_rail.dart / sidebar.dart / app_panel.dart** — 从 `colorScheme` 迁移至 `context.appColors`，消除 `AppColors` 常量的直接使用
- **app.dart** — `MaterialApp.router` 接入 `themeSettingsProvider`，theme/darkTheme 改为 `AppTheme.build()` 调用
- **设计原则**：由单预设硬编码变为多预设运行时切换，所有视觉颜色收敛到 `UniHubThemeColors` 统一管理

### 2026-05-22: 配色调整至蓝白色系 + 卡片边界恢复
- **app_tokens.dart** — 种子色 `AppColors.primary` 从 `0xFF4F6BFF`（靛蓝）改为 `0xFF64B5F6`（浅蓝）；配套 `primaryDark`、`primarySoft`、`border` 等 30 个色彩常量同步调整；`AppShadows` 透明度保持低值
- **app_theme.dart** — `CardTheme.side` 恢复为 `outlineVariant.withValues(alpha: 0.25)`（极淡边框）；亮/暗主题 seedColor 跟随新值
- **home_page.dart** — `_Panel`、`_MetricCard`、`_ShortcutCard`、`_ThoughtPreviewCard` 全部恢复 `Border.all(color: outlineVariant.withValues(alpha: 0.25))`
- **home/header.dart** — `_SearchBox`、`_NotificationButton` 恢复淡边框（alpha 0.25）
- **home/mobile_home.dart** — 5 处移动端卡片同步恢复淡边框
- **shared/widgets/sidebar.dart**、**home/right_rail.dart** — 分隔线透明度设为 `alpha: 0.5`
- **设计原则**：由「无边框+阴影」改为「极淡边框(alpha 0.25)+弥散阴影」——漂浮但边界清晰

### 2026-05-22: 全局视觉风格改造（卡片去边框 + 大圆角 + 柔和阴影）
- **app_tokens.dart** — `AppShadows` 全部柔化：`cardSoft` blur 8→16、`card` blur 24→32、`cardElevated` blur 16→24，透明度降低（弥散漂浮感）
- **app_theme.dart** — `CardTheme` 圆角 16→20px（`AppRadius.lg`→`AppRadius.xl`），移除边框 `side`，elevation 设为 0（阴影由各组件自行控制）
- **desktop_shell.dart** — 背景色改为 `surfaceContainerLowest`（更柔和的浅色背景）
- **home_page.dart** — `_Panel`、`_MetricCard`、`_ShortcutCard`、`_ThoughtPreviewCard`、`_IconBubble` 统一去边框、圆角改为 `AppRadius.xl`(20px)、使用 `AppShadows.cardSoft` 弥散阴影
- **home/header.dart** — `_SearchBox` 圆角改为 `AppRadius.xl`(20px)、移除边框；`_NotificationButton` 圆角改为 `AppRadius.lg`(16px)、移除边框
- **home/right_rail.dart** — 分隔线透明度减半（`alpha: 0.5`）
- **home/mobile_home.dart** — `_MobileQuickCaptureCard`、`_MobileFocusCard`、`_MobileThoughtLine`、`_MobileShortcutCard` 同步改造：去边框、`AppRadius.xl`(20px)、`AppShadows.cardSoft`
- **home/focus_section.dart** — 统计卡片网格改用 `SliverGridDelegateWithFixedCrossAxisCount`，纵横比 `childAspectRatio: 0.85`（4 列）/ `1.1`（2 列），适应纵向布局
- **统计卡片** `_MetricCard` 从横向 `Row`（图标左，文字右）改为纵向 `Column`（图标在上，标题/数值/副标题垂直排列），图标容器增大至 52×52

### 2026-05-22: P1-1/P1-2 插件数据库与生命周期修复
- **AppDatabase** 现在接收 `PluginRegistry`，`schemaVersion` 动态计算（取所有插件版本的最大值），构造函数增加 debug 模式断言验证插件表与集中注册表一致性
- **main.dart** 启动序列改为 `async main()`，在 `runApp()` 之前调用 `registry.initAll()`，使用 `overrideWithValue` 传递已初始化的 registry
- **database_provider** 创建 `AppDatabase` 时传入 PluginRegistry
- 插件 `AGENTS.md` 和 `database.md` 规范文档同步更新
