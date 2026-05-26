# 收藏内容详情页移动端视觉改造

## Goal

将 Collections 的收藏内容详情页改造成截图所示的移动端卡片式详情体验：顶部内容身份区突出标题与来源，主按钮用于打开原网页，下面集中展示来源、状态、收藏夹、标签、备注、时间信息和快速操作。

## What I Already Know

- 用户给出的目标图是窄屏移动端详情页，宽度约 375px，内容按单列从上到下组织。
- 当前代码入口是 `lib/src/plugins/collections/ui/collections_page.dart`，目前直接返回 `CollectionsDesktopLayout`。
- 当前详情组件是 `lib/src/plugins/collections/ui/widgets/saved_item_detail_panel.dart`。
- 现有详情组件已经包含内容身份区、打开原网页、星标占位、来源、状态、收藏夹和标签。
- 当前详情组件缺少目标图中的备注/联动预留区、收藏时间/最后访问时间信息卡、底部快速操作区。
- `saved_items` 表已有 `createdAt`、`updatedAt`、`lastOpenedAt`、`completedAt`、`archivedAt`，可以支持时间信息展示。
- `saved_items` 表当前没有独立备注字段；用户明确要求本任务先不做备注持久化，后续可能接入笔记、想法或 Todo 联动。
- Collections 插件规范要求 UI 使用 Material 3 `ColorScheme` 和 `app_tokens.dart` 设计令牌。

## Assumptions

- 本任务优先实现目标图里的窄屏详情体验，同时保持现有桌面右侧详情面板可用。
- 顶部粉色缩略图可先使用媒体类型图标容器，不引入网络封面加载，避免扩展失败态和缓存策略。
- 快速操作中的“分享/移动/删除”等可以沿用当前已有能力或显示占位反馈；若涉及真正删除、系统分享或跨插件联动，可作为后续任务拆分。

## Open Questions

- 无阻塞问题；备注区本任务只做联动预留，不做真实持久化。

## Requirements

- 详情页在窄屏下呈现目标图风格的单列详情卡片。
- 顶部区域包含媒体图标、标题、平台/类型/相对时间、副操作图标。
- 主按钮“打开原网页”使用高强调样式，并调用现有打开逻辑与 `markOpened`。
- 来源行展示 URL，并提供复制链接按钮。
- 状态、收藏夹、标签使用 pill/chip 形式，视觉接近目标图。
- 展示收藏时间与最后访问时间；无最后访问时间时提供明确空值展示。
- 备注/笔记区域只保留轻量预留入口或静态提示，不提供可编辑输入，不写数据库。
- 增加快速操作区：复制链接、分享、移动、归档、删除。
- 不改动数据库 schema。

## Acceptance Criteria

- [ ] 窄屏下详情内容不横向溢出，按钮/Chip/文本在 375px 宽度内排版稳定。
- [ ] 原有打开网页、复制链接、状态切换、收藏夹选择能力保持可用。
- [ ] 收藏时间和最后访问时间来自真实字段，不使用 mock 数据。
- [ ] 桌面布局仍能显示详情面板，不破坏左侧列表 + 右侧详情结构。
- [ ] 通过 focused widget test 或现有 Collections UI 测试补充关键断言。
- [ ] `flutter analyze` 在当前环境可运行时无新增 error/warning；若 SDK/WSL 环境阻塞，需要记录阻塞证据。

## Definition of Done

- 代码改动集中在 Collections UI 层；不触碰无关插件。
- 同步更新或新增测试覆盖窄屏详情核心元素。
- 若发现需要数据库 schema、路由级改造或跨插件联动，先回到需求确认。

## Out of Scope

- 不在本任务内实现完整网页元数据抓取、封面缓存、系统级分享接入。
- 不在本任务内重构 Collections 整体桌面布局。
- 不在本任务内实现全量标签系统，目标图中的标签先沿用现有平台/类型/收藏夹标签展示。
- 不在本任务内实现备注、笔记、想法、Todo 的真实联动。

## Technical Notes

- 目标组件：`lib/src/plugins/collections/ui/widgets/saved_item_detail_panel.dart`
- 可能涉及响应式入口：`lib/src/plugins/collections/ui/collections_page.dart`、`lib/src/plugins/collections/ui/layouts/collections_desktop_layout.dart`
- 相关规范：`.trellis/spec/frontend/component-guidelines.md`、`.trellis/spec/frontend/uiux-guidelines.md`、`.trellis/spec/frontend/state-management.md`
- 模块说明：`lib/src/plugins/collections/AGENTS.md`
