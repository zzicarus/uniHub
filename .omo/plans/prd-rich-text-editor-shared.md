# PRD: 富文本编辑器下沉至 shared/ 层

## 背景与动机

Thoughts 插件内部存在 3 份重复的编辑器逻辑：
- `thoughts_editor_page.dart`（全屏编辑页，~500 行）
- `thought_editor_drawer.dart`（抽屉编辑，~490 行）
- `thoughts_page.dart`（底部快速录入，~380 行）

三者共享相同的 `QuillController` 管理、图片粘贴/插入、Markdown 快捷键、工具栏配置等逻辑，但各自维护一份副本。

目标是提取**可复用的通用编辑器组件**到 `shared/ui/rich_text_editor/`，使未来 Notes 插件、Home 快速录入等场景可以直接复用。

## 范围

### In Scope
- [ ] 新建 `shared/ui/rich_text_editor/` 目录，包含通用编辑器组件
- [ ] 提取 `ThoughtRichEditor` 为 `RichTextEditor`，解除对 `ThoughtContentCodec` / `ThoughtImageService` 的直接依赖
- [ ] 三种编辑器 UI（全屏页、抽屉、快速录入）统一使用 `RichTextEditor`
- [ ] `ThoughtImageService` 和 `ThoughtContentCodec` 保留在 thoughts 插件，通过回调注入
- [ ] 保持所有现有功能行为不变（自动保存、图片粘贴/选取、Markdown 快捷键、工具栏）

### Out of Scope
- 不修改 `ThoughtImageService` 和 `ThoughtContentCodec` 的实现（仅通过回调解耦）
- 不修改数据库 schema 或 Provider 层
- 不新增其他插件的编辑器消费方
- 不修改 `thoughts_editor_page` / `thought_editor_drawer` / `thoughts_page` 中的非编辑器布局逻辑

## 技术方案

### 1. 新建通用组件 `RichTextEditor`

位置：`lib/src/shared/ui/rich_text_editor/rich_text_editor.dart`

```dart
class RichTextEditor extends StatefulWidget {
  final QuillController controller;
  final Future<String?> Function()? onPickImage;      // 返回 embed source
  final Future<String?> Function(Uint8List bytes)? onPasteImage;
  final ValueChanged<Document>? onChanged;
  final double minHeight;
  final String placeholder;
  final bool showToolbar;
  final EdgeInsetsGeometry padding;
  final bool expands;

  static QuillController createController({...});
  ...
}
```

**关键解耦：**
- `onPickImage`: 调用方负责唤起图片选择、保存文件、返回 embed source（如 `file:///path`）
- `onPasteImage`: 调用方负责保存粘贴图片、返回 embed source
- `onChanged`: 内容变化回调

### 2. Thoughts 层适配

三种消费者统一改为：

```dart
RichTextEditor(
  controller: _contentController,
  onPickImage: () async {
    final path = await ref.read(thoughtImageServiceProvider).pickImage();
    return path != null ? ThoughtContentCodec.imageSourceForPath(path) : null;
  },
  onPasteImage: (bytes) async {
    final path = await ref.read(thoughtImageServiceProvider).saveImageBytes(bytes);
    return ThoughtContentCodec.imageSourceForPath(path);
  },
  onChanged: (_) => _markDirty(),
  ...
)
```

### 3. 依赖关系

```
shared/ui/rich_text_editor/          ← 仅依赖 flutter_quill, flutter_quill_extensions, Material
    ↑
plugins/thoughts/ui/widgets/         ← 依赖 shared/rich_text_editor + 注入 thoughts 专用回调
    ↑
plugins/thoughts/ui/pages/           ← 使用 widgets/
```

## UI 变更

- 新增：`lib/src/shared/ui/rich_text_editor/rich_text_editor.dart`
- 修改：`lib/src/plugins/thoughts/ui/widgets/thought_rich_editor.dart`（删除，改为导出 `shared/` 版本或完全删除）
- 修改：`lib/src/plugins/thoughts/ui/thoughts_editor_page.dart`（替换 `ThoughtRichEditor` 为 `RichTextEditor`）
- 修改：`lib/src/plugins/thoughts/ui/widgets/thought_editor_drawer.dart`（同上）
- 修改：`lib/src/plugins/thoughts/ui/thoughts_page.dart`（同上）

## 测试计划

- [ ] 运行 `flutter analyze` — 全量通过
- [ ] 运行 `dart fix --dry-run` — 0 fixes
- [ ] 运行 `flutter test` — 全量通过
- [ ] 手动验证：桌面端打开编辑页 → 粘贴图片 → 保存 → 重新打开确认图片存在
- [ ] 手动验证：移动端快速录入 → 选取图片 → 提交 → 列表页可见

## 验收标准

- [ ] `flutter analyze` 0 error, 0 warning
- [ ] `dart fix --dry-run` 无可修复项
- [ ] `flutter test` 通过
- [ ] 桌面端（≥720px）和移动端编辑器行为与重构前一致
- [ ] 图片粘贴、选取、Markdown 快捷键正常工作
- [ ] `RichTextEditor` 不引用任何 `plugins/thoughts/` 路径
