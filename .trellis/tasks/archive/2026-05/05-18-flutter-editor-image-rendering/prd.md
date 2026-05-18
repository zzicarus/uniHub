# 修复 Flutter 编辑器异常并完善图片渲染粘贴

## Goal

修复想法编辑器中的 Flutter framework assertion 异常，统一想法图片的插入、保存、渲染和粘贴体验，让用户在快速记录、编辑抽屉、独立编辑页等入口添加的图片都能正确显示，并让编辑栏目默认呈现为渲染后的内容，而不是 Markdown 源码优先。

## What I already know

- 用户反馈出现异常：`Failed assertion: line 2168 pos 12: '_elements.contains(element)': is not true.`
- 用户要求任何位置插入的图片都需要能渲染出来。
- 用户要求支持 `Ctrl+V` 粘贴图片，且这个能力需要多处同步。
- 用户要求编辑栏目默认是渲染好的格式，用户输入 `# 一级标题` 后应看到一级标题效果，而不是长期暴露 Markdown 源码。
- 用户已确认选择方案 B：一步到位做真 WYSIWYG 富文本编辑器，而不是“默认预览 + 点击编辑源码”的折中方案。
- 当前项目是 Flutter 应用，核心代码位于 `lib/src/plugins/thoughts/`。
- 当前依赖包含 `flutter_markdown`、`image_picker`、`path_provider`、`path`，尚未包含剪贴板图片读取依赖。

## Requirements

- 修复编辑器页面/抽屉中的 framework assertion 异常，避免在 build 期间触发不稳定的 provider 读取、同步 `setState` 或 drawer element 生命周期冲突。
- 统一图片路径处理：
  - 选择图片、粘贴图片、已有图片路径都保存到应用文档目录下的 `thought_images`。
  - Markdown 图片 URI 必须能被 `flutter_markdown` 正确解析。
  - 已存储在 `imagePaths` 字段中的图片必须在相关 UI 中渲染。
- 图片渲染入口至少覆盖：
  - 快速记录输入区的待提交图片预览。
  - 想法卡片中的图片缩略图，而不是只显示“X 张图片”。
  - 编辑抽屉正文预览/默认渲染态。
  - 独立编辑页。
- 支持 `Ctrl+V` 粘贴图片：
  - 快速记录输入区。
  - 编辑抽屉正文区域。
  - 独立编辑页正文区域。
  - 粘贴后图片应被保存、加入当前想法图片列表，并插入正文中的图片引用。
- 编辑栏目必须是真 WYSIWYG 富文本编辑器：
  - 用户输入 `# 一级标题` 后，编辑器将当前段落转换为一级标题样式。
  - 用户编辑过程中不应长期暴露 Markdown 源码作为主要体验。
  - 工具栏支持标题、加粗、斜体、列表、引用、代码块、图片等基础富文本动作。
- 正文持久化改为富文本文档格式：
  - 新内容以 Quill Delta JSON 保存。
  - 旧 Markdown 内容读取时应转换为富文本文档，保存后写回新格式。
  - 卡片摘要、搜索、标题提取必须基于富文本纯文本，不直接显示 Delta JSON。
- 图片作为富文本 embed 插入，同时继续同步维护 `imagePaths`，便于卡片缩略图、删除清理和兼容已有数据。
- 仍保留必要编辑能力：用户可以修改文字、插入标题/列表/图片、保存标签/颜色/置顶/归档等已有功能。

## Acceptance Criteria

- [ ] 打开、关闭、切换想法编辑抽屉不再触发 `_elements.contains(element)` assertion。
- [ ] 从按钮选择图片后，图片能在创建页、卡片、编辑抽屉、独立编辑页中显示。
- [ ] 粘贴剪贴板图片后，图片文件被保存到本地应用目录，并立即在当前入口可见。
- [ ] 历史 Markdown 中形如 `![](file:///...)` 的本地图片能导入为富文本图片节点并正常渲染。
- [ ] 用户在编辑器中输入 `# 一级标题` 后，当前段落自动转换为一级标题样式。
- [ ] 想法卡片和搜索结果不会展示富文本 JSON，而是展示可读纯文本摘要。
- [ ] `flutter analyze` 无新增错误；如可行，补充或更新相关测试。

## Definition of Done

- 代码遵循 `.trellis/spec/frontend/` 中 Flutter UI 层规范。
- 复用图片服务和富文本内容转换 helper，避免各页面重复实现路径、复制、编码、摘要提取逻辑。
- 运行静态分析和相关测试。
- 若引入新依赖，说明原因并验证构建/分析通过。

## Technical Approach

采用真 WYSIWYG 富文本编辑方案：

- 引入 `flutter_quill` 作为富文本编辑器基础，正文存储为 Delta JSON。
- 引入 `flutter_quill_extensions` 渲染图片 embed。
- 引入 `markdown_quill` 将旧 Markdown 内容转换为 Delta，保证已有数据可读。
- 抽取或扩展共享图片服务，提供选择图片、保存剪贴板图片、插入富文本图片节点、解析正文图片引用等能力。
- 修复抽屉中加载数据的生命周期：避免在 `build()` 中直接触发异步读取后同步 `setState`，改为 `initState`/provider listener/post-frame 等更稳定方式。
- 将富文本内容解析、纯文本摘要、图片路径提取抽成可复用 helper，供卡片、搜索、抽屉、独立编辑页复用。
- 快速记录入口也使用同一套富文本编辑组件或最小等价组件，保证图片粘贴和富文本输入行为一致。

## Decision (ADR-lite)

**Context**：用户明确要求不让用户感知 Markdown 源码，并在方案选择中确认必须一步到位做真 WYSIWYG。

**Decision**：采用 `flutter_quill` + Delta JSON 存储作为富文本编辑基础；保留 `imagePaths` 字段作为图片索引和兼容字段；旧 Markdown 读取时转换为 Delta。

**Consequences**：本任务改动面扩大，会影响编辑器、快速记录、卡片摘要、搜索和图片服务；但能满足真实富文本体验。后续如需块级数据库或协作编辑，可以在 Delta 模型上继续演进。

## Out of Scope

- 不实现多人协作编辑。
- 不实现块级数据库、拖拽块排序、双链/块引用等复杂 Notion 能力。
- 不处理远程图片上传、云同步、图片压缩质量配置等后续能力。

## Research References

- [`research/editor-image-clipboard.md`](research/editor-image-clipboard.md) — 剪贴板图片、图片渲染和编辑器方案调研。

## Technical Notes

- 已检查：
  - `lib/src/plugins/thoughts/ui/widgets/thought_editor_drawer.dart`
  - `lib/src/plugins/thoughts/ui/thoughts_list_page.dart`
  - `lib/src/plugins/thoughts/ui/thoughts_editor_page.dart`
  - `lib/src/plugins/thoughts/ui/widgets/thought_card.dart`
  - `lib/src/plugins/thoughts/data/thought_image_service.dart`
  - `pubspec.yaml`
- 现有抽屉图片 URI 拼接存在风险：`Uri.file(path).toString()` 已经是 `file:///...`，再拼接 `file://` 会生成错误地址。
- `ThoughtCard` 当前只展示图片数量，不展示缩略图。
- `ThoughtsEditorPage` 当前没有同步 `imagePaths`。
