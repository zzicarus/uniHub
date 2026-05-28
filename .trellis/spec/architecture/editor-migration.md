# 编辑引擎迁移：flutter_quill → AppFlowy Editor

> 记录想法编辑器的迁移背景、当前状态、合约和遗留事项。

---

## 背景

UniHub 初始使用 [flutter_quill](https://pub.dev/packages/flutter_quill) 作为想法编辑器，支持富文本和本地图片。随着项目方向从「笔记应用」演进为「个人工具箱」，需要更稳定和可扩展的编辑引擎。

选择 [AppFlowy Editor](https://github.com/AppFlowy-IO/AppFlowy)（AppFlowy 开源的 Flutter 富文本编辑器）作为主力引擎：
- **稳定的 Delta 实现**：flatten 操作可预测，不出现花括号 `{}` 等奇怪问题
- **更好的折叠/展开支持**：适合大纲式笔记
- **持续维护的社区**：AppFlowy 项目活跃

---

## 迁移阶段

| 阶段 | 时间 | 内容 | 状态 |
|------|------|------|------|
| Phase 0 | 2026-05 中 | AppFlowy Editor 引入，`ThoughtContentCodec` 新增 `format` 和 `unihub.appflowy_json.v1` | ✅ 完成 |
| Phase 1 | 2026-05 末 | 路由入口 `/thoughts/:id` 切到 AppFlowy Workspace；`quickCreate()` 只写 AppFlowy JSON | ✅ 完成 |
| Phase 2 | 未来 | 清理遗留 Quill 组件、可选的旧数据批量迁移 | ⏳ 规划中 |

---

## 当前状态

### 已迁移

- `/thoughts/:id` 路由 → `ThoughtEditorWorkspace`（AppFlowy Editor）
- Dashboard "最近想法" 点击 → AppFlowy Workspace（通过路由）
- 卡片点击编辑入口 → Workspace Modal（AppFlowy Editor）
- `quickCreate()` → 纯文本段落 AppFlowy JSON

### 遗留（不删除，但不从主路径引用）

- `lib/src/plugins/thoughts/ui/thoughts_editor_page.dart` — 旧 Quill 编辑页
- `lib/src/shared/ui/rich_text_editor/rich_text_editor.dart` — 旧 Quill 编辑器组件
- `ThoughtContentCodec.documentFromStored()` / `encodeDocument()` — Quill 操作（标记 `@Deprecated`）
- 数据库中已存在的 `unihub.quill_delta.v1` 数据（不做批量迁移）

---

## `ThoughtContentCodec` 合同

见 `database-guidelines.md` 中 Scenario 5「Thoughts 富文本正文存储合同」的最新版本。

关键常量：

```dart
// lib/src/plugins/thoughts/data/thought_content_codec.dart
static const String format = 'unihub.appflowy_json.v1';
```

### 读取方法优先级

| 方法 | 输入 | 输出 | 旧格式支持 |
|------|------|------|-----------|
| `encodeAppFlowy(document:, plainText:)` | AppFlowy JSON + 纯文本 | envelope String | — |
| `documentJsonFromStored(stored)` | envelope String | `Map<String, dynamic>?` | ❌ 仅 AppFlowy |
| `plainTextFromStored(stored)` | envelope String | 纯文本 String | ❌ 丢弃旧格式 |
| `titleFromStored(stored)` | envelope String | 截断标题 String | ❌ 丢弃旧格式 |

### 已废弃方法

| 方法 | 移除计划 |
|------|---------|
| `documentFromStored()` | Phase 2 |
| `encodeDocument()` | Phase 2 |
| `imageSourceForPath()` | Phase 2 |
| `imagePathFromSource()` | Phase 2 |
| `removeImage()` | Phase 2 |
| `mergeImagePaths()` | Phase 2 |

---

## AppFlowy 编辑器组件

| 组件 | 文件 |
|------|------|
| `AppFlowyThoughtEditor` | `lib/src/shared/editor/appflowy_thought_editor.dart` |
| `ThoughtEditorWorkspace` | `lib/src/plugins/thoughts/ui/widgets/thought_editor_workspace.dart` |
| `ThoughtEditorController` | `lib/src/plugins/thoughts/ui/widgets/thought_editor_controller.dart` |
| `AppFlowyDocumentTools` | `lib/src/shared/editor/appflowy_document_tools.dart` |

`ThoughtEditorWorkspace` 是完整的编辑工作台，包含：
- AppFlowy Editor 渲染
- 标题 + 正文编辑
- 标签输入（TagKit）
- 图片管理
- 保存逻辑（自动 + 手动）
- 关闭/返回回调

---

## 数据格式参考

```json
{
  "format": "unihub.appflowy_json.v1",
  "document": {
    "type": "page",
    "children": [
      {
        "type": "paragraph",
        "data": {
          "delta": [
            {"insert": "想法正文内容"}
          ]
        }
      }
    ]
  },
  "plainText": "想法正文内容"
}
```

### AppFlowy Document 结构

| 字段 | 类型 | 说明 |
|------|------|------|
| `type` | `"page"` | 根节点类型，固定为 page |
| `children` | `List<AppFlowyBlock>` | 子块列表 |
| block.`type` | `"paragraph"` / `"heading"` / `"image"` 等 | 块类型 |
| block.`data` | `Map` | 块数据，`delta` 数组包含行内样式 |
| block.`data.delta` | `List<DeltaOperation>` | Quill-compatible delta 操作 |
| `plainText` | String | envelope 层缓存纯文本，用于列表摘要/搜索 |

---

## 注意事项

- AppFlowy Editor 的 delta 与 flutter_quill 的 delta 在 flatten 行为上不同。AppFlowy 的 `editorState.transaction` 和 `afterSelection` 更稳定，不会产生多余的花括号文本。
- 图片功能通过两套管理：`imagePaths`（legacy Quill 方式）和 `imageRefs`（AppFlowy image block 引用）。两者均已接入，删除/清理时需同时覆盖。
- 旧数据的批量转换不在当前 scope 内。如果用户编辑一条旧数据，保存时会升级为 `unihub.appflowy_json.v1`。

---

## 数据一致性约定

以下约定来自 P0 缺陷修复，新增编辑器相关代码时必须遵守。

### 1. `onChanged` 入口必须做差异判断

编辑器初始化后会 emit 当前值，如果 `updateDocument()` 不做差异检查会触发无意义 dirty。使用 `DeepCollectionEquality` 比较新值与当前值：

```dart
import 'package:collection/collection.dart';

void updateDocument(Map<String, dynamic> doc, String text) {
  if (const DeepCollectionEquality().equals(documentJson, doc) &&
      plainText == text) return;
  // ... continue with markDirty()
}
```

### 2. 编辑器元数据修改必须通过 Transaction API

修改文档结构（标题、段落内容等）必须通过 `EditorState.transaction` 的 `replaceText`/`insertText` 方法，不能直接改本地 `plainText` 副本：

```dart
void updateFirstParagraphText(String newText, EditorState editorState) {
  final transaction = editorState.transaction
    ..insertText(TextLocation(position: 0), newText);
  editorState.apply(transaction);
}
```

只有通过 Transaction API 才能确保 `onChanged` 原子同步更新 `documentJson` + `plainText`。

### 3. Controller 方法 `_editorState == null` 必须 throw

任何依赖于 `_editorState` 的 public 方法在 `_editorState == null` 时必须 `throw StateError`，不能静默 `return`：

```dart
void insertImageBlock(...) {
  if (_editorState == null) throw StateError('Editor state not initialized');
  // ...
}
```

### 4. 异步回调不信任原则

依赖异步回调（`onChanged`）刷新的状态，如果后续操作需要新状态，先用当前值同步计算预期结果：

```dart
// ✅ 正确：基于当前 imageRefs 同步计算
final remainingRefs = imageRefs.where((r) => r.id != imageId).toList();

// ❌ 错误：依赖 onChanged 异步刷新后重新读取
removeImageBlock(imageId); // 异步
final stillReferenced = imageRefs.any(...); // 可能还是旧值
```

### 5. 数据清理必须覆盖新旧两种模型

涉及删除/清理时必须同时处理 legacy（`images`）和 V2（`imageRefs`）两种数据模型：

```dart
Future<void> deleteImages(Thought thought) async {
  final paths = ThoughtContentCodec.imagePathsFromStored(thought.content);
  // paths 已合并 images + imageRefs
  for (final path in paths) { /* 删除本地文件 */ }
}
```

---

## 核心组件合约

### `AppFlowyThoughtEditorController`

| 方法 | 前置条件 | 后置条件 | 备注 |
|------|---------|---------|------|
| `updateDocument(doc, text)` | — | 文档属性更新，必要时 `markDirty` | 有差异判断，无变化则跳过 |
| `updateFirstParagraphText(text)` | editorState != null | 文档第一段内容替换，`markDirty` | 通过 Transaction API |
| `insertImageBlock(image)` | editorState != null | image block 插入文档 | 抛出 `StateError(state == null)` |
| `removeImageBlock(imageId)` | editorState != null | image block 从文档移除 | 抛出 `StateError(state == null)` |
| `removeImageFromDocument(imageId)` | — | 从文档和本地删除图片 | 同步计算预期引用集合 |
| `delete()` | — | 清理图片 + 调用删除服务 | 合并 `images` + `imageRefs` |
