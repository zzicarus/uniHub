# 编辑器图片与剪贴板方案调研

## 背景

本任务需要让想法编辑中的图片在所有入口都能渲染，并支持 `Ctrl+V` 粘贴图片。当前项目是 Flutter 应用，已使用 `flutter_markdown` 渲染 Markdown，使用 `image_picker` 从图库选择图片，图片路径以 JSON 字符串存入 `thoughts_table.image_paths`。

## 现有代码约束

- `lib/src/plugins/thoughts/ui/widgets/thought_editor_drawer.dart`
  - 当前抽屉编辑器有“编辑/预览”切换，默认是源码编辑态。
  - 图片插入时先保存路径到 `_images`，再向正文插入 Markdown。
  - 现有代码使用 `Uri.file(path).toString()` 后又拼接 `file://`，会形成无效 URI，导致 Markdown 图片不渲染。
- `lib/src/plugins/thoughts/ui/thoughts_list_page.dart`
  - 快速记录入口支持选择图片，但只保存到 `imagePaths`，不会插入正文 Markdown。
  - 草稿图片只在提交前显示 60x60 缩略图。
- `lib/src/plugins/thoughts/ui/widgets/thought_card.dart`
  - 卡片只显示“X 张图片”提示，不展示图片内容。
- `lib/src/plugins/thoughts/ui/thoughts_editor_page.dart`
  - 独立编辑页还没有接入图片路径加载、保存、选择或渲染逻辑。

## 外部能力调研

- Flutter 内置 `Clipboard` 主要面向文本，不能可靠读取图片字节。
- `super_clipboard` 提供跨平台剪贴板读取能力，可通过 `SystemClipboard.instance` 获取 reader，再按图片格式读取数据，适合实现桌面端 `Ctrl+V` 粘贴图片。
- `appflowy_editor`、`super_editor`、`flutter_quill` 等富文本编辑器可作为长期 WYSIWYG 方案，但迁移成本较高，涉及数据模型转换、现有 Markdown 内容兼容、图片节点和数据库格式迁移。

## 可行方案

### 方案 A：现有 Markdown 数据模型上做“渲染优先编辑器”（推荐本任务）

- 保持数据库仍保存 Markdown 文本与 `imagePaths` JSON。
- 将抽屉编辑器默认展示为 Markdown 渲染态，工具栏和点击/聚焦时进入编辑动作。
- 修复图片 URI 生成与解析，统一图片保存、正文插入、预览渲染、卡片缩略图展示。
- 给快速记录、抽屉编辑、独立编辑页复用同一套图片插入/粘贴逻辑。
- 优点：改动集中、兼容已有数据、风险较低。
- 缺点：不是真正完整富文本编辑器，用户在实际输入过程中仍可能短暂看到 Markdown 标记，除非进一步做输入后自动转渲染。

### 方案 B：引入富文本编辑器并迁移数据模型（用户已选择）

- 用富文本文档模型替换正文 Markdown 存储，图片作为文档节点。
- 对历史 Markdown 做导入转换，对导出/搜索做兼容。
- 优点：最贴近“不让用户感知 Markdown 源码”的长期体验。
- 缺点：改动面大，可能牵涉搜索、卡片摘要、数据迁移、测试和未来同步。

## 富文本编辑器对比

| 方案 | 关键事实 | 风险/代价 | 结论 |
|------|----------|-----------|------|
| `flutter_quill` + `flutter_quill_extensions` + `markdown_quill` | `flutter_quill` 是 MIT，支持 Android/iOS/Web/desktop，官方推荐以 Delta JSON 保存；`flutter_quill_extensions` 提供图片 embed；`markdown_quill` 可做旧 Markdown 转 Delta | 需要接入 Delta 序列化、图片 embed 和旧数据兼容；Markdown 快捷输入可能需要局部自定义 | 推荐 |
| `appflowy_editor` | 块编辑体验更接近 Notion，支持多平台和 Markdown 导入导出 | 许可为 MPL-2.0/AGPL-3.0 双许可，项目当前没有明确采用 AGPL 依赖的策略 | 暂不选 |
| `super_editor` | 模型灵活，支持标题、列表、图片等文档节点，理念适合自定义编辑器 | pub.dev 稳定版较久未发布；桌面能力主要依赖示例/开发版，集成成本较高 | 暂不选 |

## 决策

采用 `flutter_quill` 作为本任务的真 WYSIWYG 编辑器基础：

- 正文存储格式改为 Quill Delta JSON，使用轻量 envelope 标记，避免和历史 Markdown 混淆。
- 读取历史 Markdown 时转换成 Delta 文档；保存后统一写回 Delta JSON。
- 图片作为 Quill image embed 插入，同时继续维护 `imagePaths` 字段，便于卡片缩略图、删除清理和兼容旧页面。
- `Ctrl+V` 粘贴图片优先使用 `flutter_quill`/native bridge 能力；如果平台剪贴板图片能力不足，再补充独立剪贴板图片读取依赖。

## 建议

用户已确认选择方案 B。本任务直接实现真 WYSIWYG 编辑器，但仍控制范围：先覆盖标题、加粗/斜体、列表、引用、代码块、图片、基础粘贴和旧 Markdown 兼容；复杂块数据库、协作编辑、云端图片上传后续再做。
