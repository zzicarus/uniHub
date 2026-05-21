# PRD: 提取通用富文本编辑器到 Shared 层

## 背景与动机

Thoughts 插件内存在 3 份编辑器状态机逻辑（`thoughts_editor_page.dart`、`thought_editor_drawer.dart`、`thoughts_page.dart`），以及一份渲染层 `thought_rich_editor.dart`。渲染层本身已高度参数化，但因直接 import `thought_content_codec.dart` 和 `thought_image_service.dart`，无法被其他插件复用。

目标：将 `ThoughtRichEditor` 下沉为 `shared/ui/rich_text_editor/` 下的通用组件，彻底解耦对 Thoughts 插件的依赖。

## 范围

### In Scope
- [ ] 新建 `shared/ui/rich_text_editor/rich_text_editor.dart`，完全替代 `thought_rich_editor.dart`
- [ ] 更新三处消费者（`thoughts_editor_page`、`thought_editor_drawer`、`thoughts_page`），改用 `shared/` 层组件
- [ ] 废弃 `plugins/thoughts/ui/widgets/thought_rich_editor.dart`
- [ ] 同步更新所有 import 路径

### Out of Scope
- 不改动编辑器状态机逻辑（load/save/tag/color/pin/archive）
- 不改动数据库 schema、DAO、Repository
- 不改动现有路由
- 本次不迁移 `ThoughtImageService` 和 `ThoughtContentCodec`（仍留在 thoughts 层，通过回调注入）

## 技术方案

### 新建文件

**`shared/ui/rich_text_editor/rich_text_editor.dart`**

与 `ThoughtRichEditor` 相比，移除 `imageService` 参数，改为纯回调驱动：

```dart
class RichTextEditor extends StatefulWidget {
  final QuillController controller;
  final Future<String?> Function()? onPickImage;      // 返回 embed source string
  final Future<String?> Function(Uint8List)? onPasteImage; // 返回 embed source string
  final ValueChanged<Document>? onChanged;
  final ValueChanged<String>? onImageAdded;           // 返回 path
  final double minHeight;
  final String placeholder;
  final bool showToolbar;
  final EdgeInsetsGeometry padding;
  final bool expands;

  const RichTextEditor({...});

  static QuillController createController({
    required Document document,
    required Future<String?> Function(Uint8List imageBytes) onImagePaste,
  });
}
```

- `onPickImage`: 用户点击 toolbar 的图片按钮时调用，由调用方（thoughts 插件）负责 pick + save + 返回 embed source
- `onPasteImage`: 用户粘贴图片时调用，由调用方负责 save + 返回 embed source
- `onImageAdded`: 图片插入成功后回调，返回的是本地 path（供调用方管理图片列表）
- 内部不再调用 `ThoughtContentCodec.imageSourceForPath`

### 修改文件

**`plugins/thoughts/ui/widgets/thought_rich_editor.dart`**
→ 删除，所有引用指向 `shared/ui/rich_text_editor/rich_text_editor.dart`

**`plugins/thoughts/ui/thoughts_editor_page.dart`**
→ 更新 import：`thought_rich_editor.dart` → `package:uni_hub/src/shared/ui/rich_text_editor/rich_text_editor.dart`
→ 调整 `_createController` 中 `onImagePaste` 回调不变
→ `build` 中的 `ThoughtRichEditor(...)` → `RichTextEditor(...)`，去掉 `imageService` 参数，补充 `onPickImage` 回调

**`plugins/thoughts/ui/widgets/thought_editor_drawer.dart`**
→ 同上

**`plugins/thoughts/ui/thoughts_page.dart`**
→ 同上（composer 场景）

### 依赖方向

保持不变：`plugins/thoughts/` → `shared/ui/` → `core/`

`RichTextEditor` 不依赖任何 thoughts 特定代码。thoughts 层通过回调注入业务逻辑。

## 测试计划

- [ ] `flutter analyze` 通过（0 error / 0 warning）
- [ ] `flutter test` 全部通过
- [ ] `dart fix --dry-run` 无可修复项
- [ ] 手动验证：桌面端/移动端编辑器正常打开、编辑、保存、插入图片

## 验收标准

- [ ] `flutter analyze` 0 error / 0 warning
- [ ] `flutter test` 全部通过
- [ ] `dart fix --dry-run` 0 fixes
- [ ] thoughts 编辑器在桌面端和移动端均正常工作
- [ ] 无 `as any`、`@ts-ignore`、空 catch 块
- [ ] 依赖方向符合 `plugins/ → shared/ → core/`
