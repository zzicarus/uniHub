# P0: 编辑器 P0 数据一致性 5 个 Bug 修复

> 状态：已完成 | 2026-05-28 | @alan

## 背景

Thoughts 插件从 Quill 迁移到 AppFlowy Editor 后，编辑器数据一致性存在 5 个 P0 缺陷。

## 修复清单

### 1. 打开编辑器触发无意义 dirty / 自动保存

`updateDocument()` 添加 `DeepCollectionEquality` 差异判断，若 `documentJson` 和 `plainText` 均未变化则跳过 `markDirty()`。

**影响文件**: `thought_editor_controller.dart`

### 2. 标题只改 plainText，不改 documentJson

新增 `updateFirstParagraphText()` 方法到 `AppFlowyThoughtEditorController`，通过 Transaction API 修改文档树。`_onTitleChanged` 改为通过 controller 修改而非直接改 `plainText`。

**影响文件**: `appflowy_thought_editor.dart`, `thought_editor_workspace.dart`

### 3. 删除想法时遗漏 V2 图片

`delete()` 合并 `images` + `imageRefs` 清理；`ThoughtDeletionService` 同理；`ThoughtContentCodec.imagePathsFromStored()` 从 stub 改为实际提取。

**影响文件**: `thought_editor_controller.dart`, `thought_deletion_service.dart`, `thought_content_codec.dart`

### 4. 图片插入失败静默留下孤儿文件

`insertImageBlock()` / `removeImageBlock()` `_editorState == null` 改为 `throw StateError`，调用方 catch 块可可靠回滚。

**影响文件**: `appflowy_thought_editor.dart`

### 5. 删除图片后异步回调时序问题

`removeImageFromDocument()` 改为基于当前 `imageRefs` 同步计算预期新引用集合，不依赖异步 `onChanged` 刷新。

**影响文件**: `thought_editor_controller.dart`

## 验证

- `dart analyze lib/` — 0 error, 0 warning
- `flutter test test/plugins/thoughts/` — 203 通过（含 6 skip）
- `flutter test test/shared/` — 119 通过
- 全量: 661 pass, 3 fail（全部在 collections 预存测试，与本次无关）
