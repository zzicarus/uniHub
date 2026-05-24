# Use system font in editor

## Goal

让 AppFlowy 编辑器正文使用应用主题配置的字体（Inter + Noto Sans SC fallback），并跟随主题 ColorScheme 支持深色模式，使编辑器文本与其余 UI 保持一致的字体和色彩体验。

## What I already know

- 应用主题在 `app_tokens.dart` 中定义了 `AppFonts.sansLatin = 'Inter'` 作为主字体，`AppFonts.sansCJK = 'Noto Sans SC'` 作为 CJK 回退字体。
- `app_theme.dart` 通过 `GoogleFonts.interTextTheme(base)` 全局应用 Inter 字体，所有 TextTheme 样式都有 `fontFamilyFallback: [AppFonts.sansCJK]`。
- **`AppFlowyThoughtEditor`**（`lib/src/shared/editor/appflowy_thought_editor.dart`）在 `EditorStyle.desktop()` 中硬编码了文本样式：
  ```dart
  textStyleConfiguration: const TextStyleConfiguration(
    text: TextStyle(fontSize: 15, color: Colors.black87),
  )
  ```
  - 未设置 `fontFamily` → 使用 Flutter 平台默认字体（非 Inter）
  - 硬编码 `Colors.black87` → 不响应深色模式
  - `const` 关键字阻止了运行时 Theme 值注入
- `ThoughtEditorWorkspace` 中标题使用 `theme.textTheme.headlineSmall`（已应用 Inter），但编辑器正文不跟随。

## Decision (ADR-lite)

**Context**: AppFlowy editor 是唯一不使用 Inter 字体的主要 UI 区域，且硬编码颜色不跟随深色模式。

**Decision**: 修改 `AppFlowyThoughtEditor` 的 `build()` 方法，改为运行时从 Theme 读取字体和颜色配置：
- `fontFamily: AppFonts.sansLatin`（Inter）
- `fontFamilyFallback: [AppFonts.sansCJK]`（CJK 回退）
- 颜色使用 `Theme.of(context).colorScheme.onSurface`（适应深色/浅色）
- 字号保持 15（编辑器专用值，不强制绑定 theme body 字号）

**Consequences**:
- 编辑器正文文本将显示 Inter 字体，与其余 UI 统一
- 跟随系统/应用主题切换自动适应深色模式
- CJK 字符通过 Noto Sans SC 回退正常显示
- 修改仅限 `appflowy_thought_editor.dart` 一个文件

## Requirements

- [x] AppFlowy editor 正文文本使用 Inter 字体
- [x] AppFlowy editor 正文文本跟随主题颜色（支持深色模式）
- [x] CJK 字符使用 Noto Sans SC 回退
- [x] 不影响编辑器已有的其他功能（斜体、加粗、列表等）
- [x] `const` 关键字改为运行时构造以支持 Theme 值

## Acceptance Criteria

- [x] 编辑器中输入的文本显示为 Inter 字体
- [x] 切换深色模式后编辑器文本颜色正确变化
- [x] CJK 字符正常显示（Noto Sans SC 回退）
- [x] `flutter analyze` 0 error 0 warning

## Definition of Done

- [x] 单个文件的精确修改（`appflowy_thought_editor.dart`）
- [x] `flutter analyze` 通过，0 error 0 warning
- [x] 深色/浅色模式均正确显示

## Out of Scope

- 不改变编辑器 toolbar / 按钮样式（仅正文文本）
- 不改动 ThoughtEditorController 或其他业务逻辑
- 不引入新的字体文件
- 不调整字号（保持 15）
- 不修改 AppFlowy Editor 的 mobile 样式

## Technical Approach

### 修改文件

`lib/src/shared/editor/appflowy_thought_editor.dart` — `build` 方法

### 当前代码

```dart
@override
Widget build(BuildContext context) {
  return AppFlowyEditor(
    editorState: _editorState,
    autoFocus: widget.autofocus,
    shrinkWrap: false,
    editorStyle: EditorStyle.desktop(
      cursorColor: Theme.of(context).colorScheme.primary,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      textStyleConfiguration: const TextStyleConfiguration(
        text: TextStyle(fontSize: 15, color: Colors.black87),
      ),
    ),
  );
}
```

### 改为

```dart
@override
Widget build(BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;

  return AppFlowyEditor(
    editorState: _editorState,
    autoFocus: widget.autofocus,
    shrinkWrap: false,
    editorStyle: EditorStyle.desktop(
      cursorColor: colorScheme.primary,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      textStyleConfiguration: TextStyleConfiguration(
        text: TextStyle(
          fontSize: 15,
          color: colorScheme.onSurface,
          fontFamily: AppFonts.sansLatin,
          fontFamilyFallback: const [AppFonts.sansCJK],
        ),
      ),
    ),
  );
}
```

### 注意事项

- 需要导入 `package:uni_hub/src/core/theme/app_tokens.dart` 以使用 `AppFonts` 常量
- `TextStyleConfiguration` 构造函数不再有 `const`（因为传入运行时 Theme 值）

## Research References

- `EditorStyle.desktop()` 接受 `TextStyleConfiguration?` 作为参数
- `TextStyleConfiguration` 的 `text` 字段是默认文本样式的 `TextStyle`
- `EditorStyle` 无单独的 light/dark 变体 — 单一样式配置一次设置
