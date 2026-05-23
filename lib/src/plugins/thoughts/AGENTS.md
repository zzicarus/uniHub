# plugins/thoughts — Thoughts 插件

UniHub 当前唯一的业务插件，管理"想法"笔记。

## 内部分层

```
thoughts/
├── data/            ← 数据层：DAO → Repository → ContentCodec → ImageService
├── providers/       ← Riverpod Provider 层
└── ui/              ← 表示层：页面 + Widget
```

## 数据层详情

### ThoughtsDao
- 封装 drift 查询，纯数据访问
- 接收 `AppDatabase` 构造器注入
- 使用类型安全 API（`select().get()`、`into().insert()`）

### ThoughtsRepository
- 封装用例级 API，业务语义的方法名（`pinThought` 而非 `updatePinnedColumn`）
- 接收 `ThoughtsDao` 构造器注入
- 返回值使用业务模型

### ThoughtImageService
- 管理想法的图片生命周期：选择、保存、删除
- 不直接依赖平台 API，通过构造器注入 `ImagePickerService` + `ImageStorage`
- 平台实现（`PlatformImagePicker`、`FileImageStorage`）依赖 `image_picker`、`path_provider`
- 测试中可通过 `FakeImagePicker` + `FakeImageStorage` 完全解耦文件系统
- `encodeImagePaths` / `decodeImagePaths` 为静态方法，纯 JSON 编解码

### ThoughtContentCodec
- 处理富文本存储格式转换
- `documentFromStored(String)` — 兼容读取：envelope JSON / 裸 Delta / 旧 Markdown
- `encodeDocument(Document)` — 输出 envelope JSON
- `plainTextFromStored(String)` — UI 摘要用纯文本

#### 富文本存储格式（envelope JSON）
```json
{
  "format": "unihub.quill_delta.v1",
  "delta": [{"insert": "内容"}]
}
```
旧 Markdown 数据打开编辑后自动升级为 envelope JSON。

## Provider 模式

```dart
// thoughts Provider 使用 asyncNotifier/Notifier 模式
// 数据流：UI → Provider.watch() → Repository → DAO → DB
```

具体 Provider 定义在 `providers/` 目录，通过 `UniHubPlugin.providers()` 贡献。

## UI 分层

- `thoughts_list_page.dart` — 列表页
- `thoughts_editor_page.dart` — 编辑器页主体
- `thoughts_editor_drawer.dart` — 编辑器附加面板

> **2026-05-21**：编辑状态逻辑已重构。`ThoughtEditorController` 和 `ThoughtEditorImageStrip` 提取至 `thoughts/ui/widgets/`。
> **2026-05-24**：`thought_editor_drawer.dart` 已删除，替换为 `thought_editor_workspace.dart`。

### Inbox 模式 UI 结构（V2 Phase 1）

Thoughts 页面现采用 Inbox 模式，布局分三档响应式：

| 断点 | 布局 | 右侧栏 |
|------|------|--------|
| ≥1280px (expanded) | 三列：侧栏 + 内容 + 右侧栏 | 显示 |
| 900-1279px (medium) | 两列：侧栏 + 内容 | 隐藏 |
| <900px (compact) | 单列：移动端全屏 | 无 |

**文件结构：**

```
thoughts/ui/
├── layouts/                         ← 布局级组件
│   ├── thoughts_desktop_layout.dart  — 桌面端布局（主内容 + 右侧栏）
│   ├── thoughts_mobile_layout.dart   — 移动端单列布局
│   ├── thought_composer.dart         — 轻量化 Composer（max 1080px, 96px input）
│   ├── thought_filter_bar.dart       — 状态筛选 chips：全部/置顶/有图片/归档
│   ├── thought_tag_filter_bar.dart   — 标签筛选栏 adapter（委托 AppTagFilterBar）
│   ├── thought_selected_tags_bar.dart — 已选标签栏 adapter（委托 AppSelectedTagsBar）
├── widgets/                         ← 可复用 Widget
│   ├── thought_card.dart             — 压缩卡片（max 180px, 1+2 lines, +N tags）
│   ├── thought_context_menu.dart     — 7项右键菜单（2项 disabled）
│   ├── thought_composer_controller.dart — Composer 状态管理（ChangeNotifier，含 TagCodec 校验 + tagErrorMessage）
│   ├── thought_state_templates.dart  — 空态/错误态模板（4空态+6错误态）
│   ├── thought_pinned_panel.dart     — 置顶面板（max 3）
│   ├── thought_pending_review_panel.dart — 待整理计数
│   ├── thought_common_tags_panel.dart — 常用标签 panel（max 8, 使用 AppTagChip）
│   ├── thought_random_review_panel.dart — 随机回顾（session 级去重）
│   └── thought_quick_actions_panel.dart — 快速操作（转为待办/笔记，disabled）
│   ├── thought_editor_controller.dart — 编辑器状态管理（含 TagCodec 校验 + tagErrorMessage）
│   ├── thought_editor_workspace.dart  — 编辑工作台
│   └── thought_editor_image_strip.dart — 编辑器中图片条
```

**Provider 链：** `allThoughtsProvider` → `thoughtStatusFilterProvider` → `tagFilterProvider` → `thoughtSearchDebouncedProvider` → `thoughtsListProvider`

**右侧栏独立数据源：** `pinnedThoughtsProvider`、`pendingReviewProvider`、`commonTagsProvider`、`randomReviewProvider` 均 watch `allThoughtsProvider`（仅未归档），不受主内容筛选影响。

**关键约束（Phase 1）：**
- 数据库 schema 未变更（无 status/linkedTodoId/linkedNoteId/processedAt 列）
- `tagFilterProvider` 保持 `StateProvider<String?>`（单标签筛选）
- 转为待办/笔记按钮 disabled 并附带 Tooltip("即将推出")
- 随机回顾使用内存 `Set<int>` 做会话去重（不持久化）

## 已知代码问题

| 问题 | 位置 | 状态 |
|------|------|------|
| `experimental_member_use` lint 抑制 | `shared/ui/rich_text_editor/rich_text_editor.dart` | 未修复 |
| 遗留 Markdown fallback 路径 | `thought_content_codec.dart` | 未修复 |
| 主页使用硬编码 Mock 数据（5 个 TODO） | `home_page.dart` | 未修复 |
| ~~图片服务硬依赖平台 API~~ | ~~`thought_image_service.dart`~~ | ✅ **P2-15 已完成** |
| ~~标签 UI 与 provider 强耦合于 thoughts 内部~~ | ~~`thoughts/ui/layouts/thought_tag_filter_bar.dart`~~ | ✅ **已完成 → 提取共享 tag system** |

---

## 近期变更

> 本 section 由 sync-knowledge 自动管理，按时间倒序追加。

### 2026-05-24: flutter_quill → AppFlowy Editor 迁移
- 编辑器主线从 `flutter_quill` 切换为 `appflowy_editor`，详情编辑器改为 AppFlowy block editor
- 新增 `lib/src/shared/editor/`：`AppFlowyDocumentTools`（文档创建/纯文本提取）、`AppFlowyThoughtEditor`（封装层）
- 新增 `ThoughtEditorWorkspace`——居中大尺寸编辑工作台（1040–1180px，含 Header + Body + PropertyRail + Footer）
- `ThoughtContentCodec` 数据格式改为 `unihub.appflowy_json.v1`（document + plainText）
- `ThoughtEditorController` 停止使用 QuillController，管理 documentJson + plainText
- ThoughtComposer 改为轻量 Capture Composer（多行 TextField + AppTagInput + AppFlowy JSON 保存）
- 新增通用 `AppTagInput` 共享组件（`lib/src/shared/widgets/tags/app_tag_input.dart`）
- 点击卡片编辑入口从窄 drawer 切换为 Workspace Modal（`ThoughtEditorWorkspace.show()`）
- 删除 `thought_editor_drawer.dart`（已替换）
- 清理死依赖 `markdown_quill`、`markdown`（直接依赖→传递依赖）
- 通过 `dependency_overrides` + `vendor/appflowy_editor` 修复 `appflowy_editor` 与 Flutter 3.44.0 的 `TextInputClient.onFocusReceived` 兼容问题
- 新增 27 个单元测试（content_codec 21 + workspace 6），修复 2 个发现 bug
- 技术决策文档：`docs/thought-editor-appflowy-migration.md`

### 2026-05-23: 标签系统提取为共享模块
- 新增 `lib/src/shared/tags/`：`tag_models.dart`（`AppTagStat`/`TagMatchMode`/`TagValidationResult`）、`tag_codec.dart`（`TagCodec` 归一化/解析/校验）、`tag_filter_logic.dart`（`TagFilterLogic` 切换/匹配/统计/排序）
- 新增 `lib/src/shared/widgets/tags/`：`AppTagChip`、`AppSelectedTagChip`、`AppMoreTagsButton`、`AppTagFilterBar`、`AppSelectedTagsBar`、`AppMoreTagsPopoverContent`
- `ThoughtTagFilterBar`、`ThoughtSelectedTagsBar`、`ThoughtCommonTagsPanel` 重写为 adapter，委托共享组件，消除内联 `FilterChip`/`InputChip` 样式重复
- `thoughts_providers.dart`：`_parseTags`/`_tagCounts`/`_filterByTags` 迁移至 `TagCodec`/`TagFilterLogic`；`toggleTagInFilter`/`renameTagInFilter`/`removeTagFromFilter` 委托给 `TagFilterLogic`
- 新增 58 个测试（tag_codec 26 + tag_filter_logic 24 + app_tag_chip 8），providers 测试从 7 增至 10

### 2026-05-22: P2-15 图片服务抽象为依赖注入模式
- `ThoughtImageService` 改为构造器注入 `ImagePickerService` + `ImageStorage`，不再直接依赖 `ImagePicker`/`File`/`path_provider`
- 新建接口层：`ImagePickerService`（选择）、`ImageStorage`（存储+exists 检查）
- 新建平台实现：`PlatformImagePicker`（`image_picker` 包装）、`FileImageStorage`（`path_provider`+`dart:io`）
- 提供测试 fake：`FakeImagePicker`（预设返回）、`FakeImageStorage`（内存 Map 存储）
- `ThoughtContentCodec.mergeImagePaths` 增加可选 `existsChecker` 参数，解耦 `File.existsSync`
- Provider 层拆分为 `imagePickerServiceProvider` + `imageStorageProvider`
- 新增 13 个单元测试覆盖全路径

### 2026-05-22: Thoughts Inbox V2 Phase 1 完成
- 全局断点更新为 mobileMax=899 / tabletMin=900 / wideMin=1280
- 新增 Provider：`thoughtStatusFilterProvider`（enum: all/pinned/withImages/archived）、`thoughtSearchQueryProvider` + `thoughtSearchDebouncedProvider`（300ms）、`pinnedThoughtsProvider`（top 3）、`pendingReviewProvider`、`commonTagsProvider`（top 8）、`randomReviewProvider`（session 去重）
- `thoughtsListProvider` 重构为链式：archive → status → tag → search
- 提取 `ThoughtComposerController`（ChangeNotifier + `ChangeNotifierProvider`），消除 `_LayoutParams` 单体
- 新增 `ThoughtStateTemplate` 共享模板（4 空态 + 6 错误态），集成到桌面端和移动端布局
- 桌面端布局重构：轻量化 Composer（max 1080px, 96px input）、状态筛选 chips、标签筛选栏（top 6 + popover）、已选标签清除栏、移除 pinned/unpinned 内容分割
- 卡片压缩：maxHeight 180px、标题 1 行、正文 2 行、最多 3 个标签 +N 溢出
- 右键菜单：`ThoughtContextMenu` 含 7 项（编辑/置顶/加标签/转为待办disabled/转为笔记disabled/归档/删除），确认对话框与 snackbar 反馈
- 右侧栏重建：置顶（max 3）、待整理计数、常用标签（max 8，与主筛选同步）、随机回顾、快速操作（2 项 disabled）
- 移动端并行更新：搜索框、水平滚动状态 chips、标签 chips（top 4）+ bottom sheet
- `ThoughtsPage` 简化为纯编排层（无 `_LayoutParams`、无内联筛选逻辑）
- 新增 27 个证据文件 + 553 行集成测试（thoughts_integration_test.dart）+ 809 行 QA 测试（thoughts_qa_test.dart），全量 244 测试通过
