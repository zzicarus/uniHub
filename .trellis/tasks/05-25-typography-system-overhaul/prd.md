# 字体系统闭环改造

## Goal

建立 UniHub 全局统一、可控、可验证的字体系统，使 Windows 和 Android 上的中文 UI、小字号标签、按钮、状态文本保持一致、清晰、精致。

## Background

当前代码中存在：
- `AppTheme` 使用 `GoogleFonts.interTextTheme(base)` 构造全局 TextTheme
- `AppFonts.sansLatin = Inter` 为主字体，Noto Sans SC 为 fallback
- `AppPillChip` 内部硬编码 `_fontSize = 12/13`、`height = 1.15`
- `labelSmall` 等小字号样式未被完整覆盖
- 中文小字号文本（状态标签、时间信息、快捷操作）视觉效果粗糙

## Requirements

### FR-1: 本地字体资产接入
- 通过 `pubspec.yaml > flutter.fonts` 声明本地字体资产
- 字体：Noto Sans SC (400/500/600/700), Inter (400/500/600/700), JetBrains Mono (400/500)
- 字体文件本地打包，不依赖运行时远程加载

### FR-2: 重构 AppFonts
- 全局 UI 主字体改为 `Noto Sans SC`
- `AppFonts.ui` = Noto Sans SC, `AppFonts.latin` = Inter, `AppFonts.mono` = JetBrains Mono
- 旧命名标记为 `@Deprecated`

### FR-3: 重构 AppTheme 全局 TextTheme
- 移除 `GoogleFonts.interTextTheme(base)`
- 显式定义完整 TextTheme，覆盖 headline / title / body / label 全部 10 个样式
- 全局 `fontFamily: AppFonts.ui`，中文 UI 主导

### FR-4: 修复 AppPillChip
- 移除 `_fontSize` 和局部 `height: 1.15`
- compact → `labelSmall`, normal → `labelMedium`

### FR-5: 修复收藏详情页红框区域
- SavedItemDetailPanel 中状态标签、时间信息、快捷操作、操作按钮使用 TextTheme
- 不裸写 `fontSize`、`fontFamily`、`FontWeight.wXXX`

### FR-6: 更新组件规范
- `.trellis/spec/frontend/component-guidelines.md` 新增 Typography 章节

### FR-7: 更新 AGENTS.md
- 增加 Typography 强制约束

### FR-8: 新增字体规范检查脚本
- `tool/check_typography.dart` 自动检查 Widget 层字体违规

## Impacted Files

| File | Change |
|------|--------|
| pubspec.yaml | Add flutter.fonts, remove google_fonts |
| lib/src/core/theme/app_tokens.dart | Refactor AppFonts |
| lib/src/core/theme/app_theme.dart | Remove GoogleFonts, define full TextTheme |
| lib/src/shared/widgets/app_pill_chip.dart | Use TextTheme |
| lib/src/plugins/collections/ui/widgets/saved_item_detail_panel.dart | Fix font usage |
| .trellis/spec/frontend/component-guidelines.md | Add Typography section |
| AGENTS.md | Add Typography constraints |
| tool/check_typography.dart | New file |

## Implementation Plan

**Phase 1**: Font assets + AppFonts (FR-1, FR-2)
- Add font files to assets/fonts/
- Update pubspec.yaml flutter.fonts
- Refactor AppFonts

**Phase 2**: ThemeData refactor (FR-3)
- Remove google_fonts import
- Define full TextTheme
- Set fontFamily to AppFonts.ui

**Phase 3**: Component fixes (FR-4, FR-5)
- Fix AppPillChip
- Fix SavedItemDetailPanel

**Phase 4**: Specs & governance (FR-6, FR-7, FR-8)
- Update component-guidelines.md
- Update AGENTS.md
- Add check_typography.dart

**Phase 5**: Verification
- `flutter pub get` → `dart run tool/check_typography.dart` → `flutter analyze`

## Out of Scope

- 不重做整体 UI
- 不改数据库 schema
- 不改业务逻辑
- 不改路由
- 不引入运行时远程字体加载
- 不新增主题预设
- 不重构所有 Widget（仅修核心路径）
