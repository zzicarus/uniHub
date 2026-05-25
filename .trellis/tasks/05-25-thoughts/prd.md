# 收口 Thoughts 编辑器迁移

## Goal

立刻关闭 Thoughts 用户主路径中残留的旧 Quill 编辑入口，确保 `/thoughts/:id`、Dashboard 最近想法点击、快速创建写入都进入/产生 AppFlowy JSON 主格式，避免继续生成 `unihub.quill_delta.v1` 数据。

## What I already know

- `ThoughtsPlugin.routes` 中 `/thoughts/:id` 仍返回 `ThoughtsEditorPage(thoughtId: id)`。
- `ThoughtsEditorPage` 仍使用 `RichTextEditor`，属于旧 `flutter_quill` 路径。
- `ThoughtsPlugin.quickCreate()` 当前调用 `ThoughtContentCodec.documentFromStored()` 和 `ThoughtContentCodec.encodeDocument()`，会继续写入旧 `unihub.quill_delta.v1` envelope。
- 当前主格式已经是 `ThoughtContentCodec.encodeAppFlowy()` 生成的 `unihub.appflowy_json.v1`。
- AppFlowy 主编辑体验已有 `ThoughtEditorWorkspace` / `AppFlowyThoughtEditor`，卡片点击编辑入口已迁移到 Workspace Modal。
- Dashboard 最近想法点击通过 `DashboardItem.routePath` → `context.go(item.routePath)` 进入路由。

## Requirements

1. `/thoughts/:id` 不再进入旧 `ThoughtsEditorPage`。
2. `/thoughts/:id` 改为进入 AppFlowy 编辑体验；优先复用已有 `ThoughtEditorWorkspace`，避免新增第二套编辑器。
3. `quickCreate()` 改为构造 AppFlowy 文档并使用 `ThoughtContentCodec.encodeAppFlowy()` 存储。
4. `RichTextEditor` / `ThoughtsEditorPage` 仅保留为迁移遗留代码，不再被用户主路径路由引用。
5. Dashboard 点击最近想法后，不能进入旧 Quill 编辑器。

## Acceptance Criteria

- [ ] `ThoughtsPlugin.routes` 的 `/thoughts/:id` 路由不再返回 `ThoughtsEditorPage`。
- [ ] 打开 `/thoughts/:id` 能显示 AppFlowy 编辑工作台/编辑体验，并加载对应 Thought。
- [ ] `ThoughtsPlugin.quickCreate()` 新建的 `content` envelope 格式为 `unihub.appflowy_json.v1`。
- [ ] 新增/更新测试覆盖 Dashboard 最近想法点击：点击后不出现 `RichTextEditor`，且进入 AppFlowy 编辑体验。
- [ ] 相关 focused tests 通过。
- [ ] `flutter analyze` 通过（0 error / 0 warning）。

## Definition of Done

- Tests added/updated for route + quickCreate storage format + Dashboard click regression.
- Lint/typecheck green for touched code.
- 不修改数据库 schema。
- 不移除迁移遗留 `RichTextEditor`，只从用户主路径下线。

## Technical Approach

- 在 `ThoughtsPlugin` 中替换 `/thoughts/:id` builder：解析 id 后返回一个轻量路由宿主页面/组件，该宿主通过 provider/repository 加载 Thought，并展示 AppFlowy 编辑工作台体验。
- 复用 `ThoughtEditorWorkspace`、`ThoughtEditorController`、现有保存/图片/标签逻辑，避免复制旧编辑器逻辑。
- `quickCreate()` 使用 `AppFlowyDocumentTools` 生成纯文本段落文档 JSON，再调用 `ThoughtContentCodec.encodeAppFlowy(document: ..., plainText: ...)`。
- 测试优先放在现有 Thoughts/UI 或 Dashboard/Home widget 测试附近，按 `test/AGENTS.md` 使用 in-memory Drift + ProviderScope overrides，不引入 mockito。

## Decision (ADR-lite)

**Context**: AppFlowy Editor 已完成主线迁移，但路由和 quickCreate 仍残留 Quill 路径，存在继续写旧格式数据和用户进入旧编辑器的 P0 风险。

**Decision**: 立即将用户主路径完全切到 AppFlowy：路由入口复用现有 AppFlowy Workspace，quickCreate 只写 AppFlowy JSON。旧 Quill 组件保留但不再由主路由进入。

**Consequences**: 变更面控制在 Thoughts 插件和目标测试；不进行旧数据批量迁移，不删除旧组件，降低 P0 修复风险。

## Out of Scope

- 不删除 `RichTextEditor` / `ThoughtsEditorPage` 文件。
- 不做数据库 schema 迁移。
- 不做历史 Quill 数据批量转换。
- 不重构 Dashboard 整体布局。

## Technical Notes

- 需遵守 `.trellis/spec/frontend/component-guidelines.md`、`.trellis/spec/frontend/uiux-guidelines.md`、`.trellis/spec/frontend/state-management.md`、`.trellis/spec/frontend/quality-guidelines.md`。
- 相关代码：`lib/src/plugins/thoughts/thoughts_plugin.dart`、`lib/src/plugins/thoughts/ui/widgets/thought_editor_workspace.dart`、`lib/src/plugins/thoughts/ui/widgets/thought_editor_controller.dart`、`lib/src/shared/editor/appflowy_document_tools.dart`、`lib/src/plugins/thoughts/data/thought_content_codec.dart`、`lib/src/core/app/home/recent_section.dart`。
- 测试约定：`test/AGENTS.md`，零 mockito，使用真实 in-memory Drift 与 ProviderScope overrides。
