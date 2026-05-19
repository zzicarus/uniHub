# 迁移 UI 到 Material Design 3

## Goal

检测当前 Flutter UI 是否完整遵循 Material Design 3，并将现有 UI 迁移为以 `ThemeData(useMaterial3: true)`、`ColorScheme`、M3 组件和主题扩展为核心的实现，减少页面层对旧 `AppColors` 和硬编码颜色的依赖，保证亮色/暗色主题一致可用。

## What I Already Know

* 项目是 Flutter 应用，入口位于 `lib/src/core/app/app.dart`。
* `MaterialApp.router` 已配置 `theme: AppTheme.light`、`darkTheme: AppTheme.dark`、`themeMode: ThemeMode.system`。
* `lib/src/core/theme/app_theme.dart` 的亮色和暗色主题都已启用 `useMaterial3: true`。
* 前端规范明确要求 widget 层使用 `Theme.of(context).colorScheme`，而不是直接使用 `AppColors.*`；`*Soft` 装饰色可以作为无 M3 直接对应的辅助装饰保留。
* 当前代码仍有大量页面层 `AppColors.*` 使用，主要集中在：
  * `lib/src/core/app/home_page.dart`
  * `lib/src/shared/ui/style_guide_screen.dart`
  * `lib/src/core/theme/app_theme.dart`
  * `lib/src/core/app/mobile_placeholder_pages.dart`
  * `lib/src/plugins/thoughts/ui/**`
  * `lib/src/core/app/settings_page.dart`
  * `lib/src/shared/widgets/sidebar.dart`
* 当前状态判断：项目已经“启用 Material Design 3”，但尚未“全面按 M3 设计体系实现”。

## Requirements

* 审计所有 Flutter UI 入口、页面、共享组件和插件 UI，识别与 M3 不一致的实现。
* 迁移范围覆盖 `lib/src/**` 下所有 Flutter UI，包括内部样式指南 `style_guide_screen.dart` 和尚未实现功能的移动端占位页面 `mobile_placeholder_pages.dart`。
* 主题层改为更完整地由 `ColorScheme` 驱动：
  * 亮色/暗色主题均基于 `ColorScheme.fromSeed`。
  * 主题中的 foreground/background/fill/border/icon/text 尽量引用 `colorScheme`。
  * 不禁用 M3 `surfaceTintColor`。
* 页面和组件层迁移到 M3 风格：
  * 页面背景、卡片、边框、主/次文字、图标、输入框、按钮、Chip、导航等优先使用 `Theme.of(context).colorScheme` 和现有 Theme。
  * 保留 `AppSpacing`、`AppRadius`、`AppSizes` 等结构 token。
  * 仅在语义色、装饰渐变、非 M3 直接对应的柔和色块等场景保留 `AppColors.*`，并尽量集中为可解释的少数用法。
  * 避免 `Colors.white`、`Colors.black*` 等破坏暗色模式的硬编码颜色；`Colors.transparent` 等语义明确的透明值可保留。
* 保持当前响应式结构：
  * 桌面端侧栏布局。
  * 移动端底部 `NavigationBar`。
  * 现有路由和业务功能不改变。
* 优先保持现有视觉信息结构和交互流程，不进行无关重设计。

## Acceptance Criteria

* [ ] 代码审计能说明当前 UI 的 M3 覆盖状态和主要偏差。
* [ ] `AppTheme.light` 与 `AppTheme.dark` 均由 `ColorScheme` 驱动，并符合项目 M3 规范。
* [ ] Widget 层中旧 `AppColors` 用法被迁移或明确保留为装饰/语义例外。
* [ ] 主要页面和组件在亮色/暗色主题下均避免不可读的硬编码颜色。
* [ ] 桌面 Shell、移动 Shell、首页、设置页、想法模块、占位页面、样式指南页面保持可编译。
* [ ] `flutter analyze` 通过。
* [ ] 相关测试可运行；若测试本身不覆盖 UI 视觉，至少保证现有 widget test 不被破坏。

## Definition of Done

* 遵守 `.trellis/spec/frontend` 中的 Widget、M3 ColorScheme、响应式和质量规范。
* 迁移完成后运行 `dart format`、`flutter analyze`、`flutter test`。
* 若实现过程中发现可沉淀的新 UI 约定，更新 `.trellis/spec/`。
* 不提交或回滚用户已有未跟踪文件。

## Confirmed Decisions

* 范围选择 A：迁移所有 `lib/src/**` 下的 Flutter UI，包括 `style_guide_screen.dart` 和 `mobile_placeholder_pages.dart`。

## Technical Approach

推荐采用“完整 Flutter UI 覆盖，但保留装饰例外”的迁移方式：

1. 先修正 `AppTheme`，让亮色主题也与暗色主题一样从 `ColorScheme` 派生。
2. 再按模块迁移页面层颜色：
   * Shell/导航和共享组件。
   * 首页、设置页、移动占位页。
   * 想法插件页面、卡片、编辑器抽屉和富文本外框。
   * 样式指南页面。
3. 对必要的非 M3 装饰色保留 `AppColors.*Soft` 或语义色，但不再用于基础背景、文本、边框、表面。
4. 运行格式化、分析和测试，修复迁移引入的问题。

## Out of Scope

* 不更改业务数据结构、数据库、Provider 行为或路由命名。
* 不引入新的 UI 框架或第三方设计系统。
* 不实现尚未完成的占位功能。
* 不做大规模交互改版或信息架构调整，除非 M3 迁移必须。

## Technical Notes

* 已读取：
  * `.trellis/spec/frontend/index.md`
  * `.trellis/spec/frontend/component-guidelines.md`
  * `pubspec.yaml`
  * `lib/src/core/app/app.dart`
  * `lib/src/core/theme/app_theme.dart`
  * `lib/src/core/theme/app_tokens.dart`
  * `lib/src/core/app/mobile_shell.dart`
  * `lib/src/core/app/desktop_shell.dart`
  * `lib/src/shared/widgets/sidebar.dart`
* 关键规范：
  * Widget 层必须使用 `Theme.of(context).colorScheme` 获取颜色，而非硬编码 `AppColors.*`。
  * `Colors.white` / `Colors.black54` 在 widget 文件中会破坏暗色模式。
  * `surfaceTintColor` 不应被禁用。
* 当前未跟踪文件存在：`.gemini/`、`.playwright-mcp/`、`devtools_options.yaml`、`expected-1.png`、`expected-design-1.png`、`figure/`。这些不是本任务创建的文件，后续不会纳入提交计划，除非用户明确要求。
