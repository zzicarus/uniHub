# Hook 与复用逻辑指南

> UniHub 中自定义复用逻辑的模式 — Extension、Mixin 与 Controller

---

## Overview

UniHub 不使用 `flutter_hooks` 包。代码复用通过以下机制实现：

| 机制 | 用途 | 示例 |
|------|------|------|
| Dart Extension | 向已有类型添加方法 | `String.extractPlainText()`、`BuildContext.goNamed()` |
| Mixin | Widget 间共享生命周期/状态 | 编辑器控制器复用 |
| Controller 类 | 跨 Widget 共享复杂 UI 逻辑 | `ThoughtEditorController` |
| 工具类 | 纯函数、编解码器 | `TagCodec`、`ThoughtContentCodec` |

---

## Extension 模式

### 何时使用

向通用类型（`String`、`BuildContext`、`DateTime`）添加项目中频繁使用的方法。

### 示例

```dart
// shared/extensions/ 下的项目级 extension
extension StringExtensions on String {
  /// 从 quill delta JSON 提取纯文本
  String extractPlainText() {
    // ... 解析逻辑
  }
}

extension BuildContextExtensions on BuildContext {
  /// 简化 GoRouter 导航
  void goNamed(String name, {Map<String, String>? pathParameters}) {
    GoRouter.of(this).goNamed(name, pathParameters: pathParameters);
  }
}
```

### 约定

- Extension 文件放在 `lib/src/shared/extensions/`
- 一个文件一个扩展目标类型
- 方法名前缀尽量自解释（避免命名冲突）

---

## Mixin 模式

### 何时使用

多个 Widget 需要共享相同生命周期钩子（`initState`、`dispose`）或相同的辅助方法集合。

### 示例

```dart
// 编辑器相关的 mixin
mixin EditorLifecycleMixin on State<StatefulWidget> {
  late final ThoughtEditorController controller;
  
  @override
  void initState() {
    super.initState();
    controller = ThoughtEditorController(ref: context.read(), ...);
  }
  
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
```

### 约定

- Mixin 要紧跟使用它的 Widget 定义，避免跨文件混用
- 优先考虑 Controller 类替代 Mixin 共享逻辑

---

## Controller 模式

### 何时使用

复杂 UI 交互逻辑（富文本编辑、图片管理）需要跨方法、跨 Widget 共享状态时。

### 示例

```dart
class ThoughtEditorController {
  final WidgetRef ref;
  late final QuillEditorController quillController;
  
  ThoughtEditorController({required this.ref}) {
    quillController = QuillEditorController();
  }
  
  Future<void> handleImagePaste() async {
    final svc = ref.read(thoughtImageServiceProvider);
    final image = await svc.pasteImage();
    if (image != null) {
      quillController.insertImageBlock(image);
    }
  }
  
  void dispose() {
    quillController.dispose();
  }
}
```

### 约定

- Controller 接收 `WidgetRef` 以访问 Provider
- 必须实现 `dispose()` 清理资源
- Controller 不直接操作 Context — 通过 Provider 通信

---

## 工具类模式

### 何时使用

纯数据转换逻辑（Codec、Serializer）不需要 UI 依赖。

### 示例

```dart
class ThoughtContentCodec {
  static String encode(Delta delta) => jsonEncode(delta.toJson());
  static Delta decode(String json) => Delta()..compose(Delta()..insert(jsonDecode(json)));
}

class TagCodec {
  static String encode(Set<String> tags) => tags.join(',');
  static Set<String> decode(String stored) => stored.isEmpty ? {} : stored.split(',').toSet();
}
```

---

## 反模式

| 模式 | 问题 | 替代 |
|------|------|------|
| 全局工具类 `Utils.doXxx()` | 类职责不清晰 | 按功能分拆为具体类 |
| Widget 内嵌 200+ 行逻辑 | 不可测试 | 提取 Controller 或 Provider |
| Extension 包含 UI 逻辑 | extension 应该是纯数据操作 | 放在 Controller 或 Provider 中 |
| Mixin 跨文件引用内部状态 | 耦合度高 | 提取为独立 Controller 类 |
