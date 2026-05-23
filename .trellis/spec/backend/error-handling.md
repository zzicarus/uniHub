# Error Handling

> UniHub 错误处理策略（Dart 异常 + Riverpod AsyncValue）

---

## Overview

UniHub 使用 Dart 的异常机制（`throw`/`catch`）配合 Riverpod 的 `AsyncValue` 三态模式处理错误。不引入 `Either`/`Result` 等函数式错误处理库。

| 层 | 错误处理方式 |
|----|-------------|
| 数据层（DAO/Repository） | 抛出类型化异常或让 Drift 异常传播 |
| Provider 层 | AsyncValue.when 的 error 分支 |
| UI 层 | 统一错误提示组件 |

---

## 异常类型

### 自定义异常（建议但非强制）

```dart
// 需要明确区分错误类型时
class ThoughtNotFoundException implements Exception {
  final String id;
  ThoughtNotFoundException(this.id);
  @override
  String toString() => 'Thought not found: $id';
}
```

### 使用 Drift 内建异常

大多数数据操作异常直接让 Drift 传播（`drift.DriftError`、`SqliteException`），不额外包装。

---

## 各层错误处理规则

### 数据层（DAO / Repository）

```dart
// ✅ DAO 让异常自然传播到调用方
Future<Thought> getById(String id) async {
  final result = await (select(thoughtsTable)
    ..where((t) => t.id.equals(id))
  ).getSingle();
  // Drift 在没有记录时会抛出 StateError，不需要额外处理
  return result;
}

// ✅ Repository 可以抛出明确含义的异常
Future<void> archiveThought(String id) async {
  final thought = await dao.getById(id);
  if (thought == null) {
    throw ThoughtNotFoundException(id);
  }
  await dao.archive(id);
}
```

### Provider 层

```dart
// ✅ FutureProvider 自动将异常转为 AsyncValue.error
@riverpod
Future<List<Thought>> allThoughts(AllThoughtsRef ref) {
  final repo = ref.watch(thoughtsRepositoryProvider);
  return repo.getAll(); // 异常自动捕获为 error 状态
}
```

### UI 层

```dart
// ✅ 统一三态处理
thoughtsAsync.when(
  data: (thoughts) => ListView(children: thoughts.map(ThoughtCard.new).toList()),
  error: (error, stack) => _ErrorWidget(message: error.toString()),
  loading: () => const Center(child: CircularProgressIndicator()),
);

// ✅ 错误 Widget 使用 colorScheme.error
Widget _buildError(BuildContext context, Object error) {
  return Center(
    child: Column(
      children: [
        Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
        const SizedBox(height: 8),
        Text('加载失败: $error'),
      ],
    ),
  );
}
```

---

## 禁止模式

| 模式 | 问题 | 正确做法 |
|------|------|---------|
| `catch (e) {}` | 静默吞掉错误 | 至少 `debugPrint` 或 `rethrow` |
| `catch (e) { return null; }` | 丢失错误上下文 | 让异常传播或记录日志 |
| 将 UI 异常作为状态字段存储（`String? errorMessage`） | 无法区分 error/loading | 使用 `AsyncValue` 内置三态 |
| `try-catch` 包裹整个 build 方法 | 掩盖真正的问题 | 对具体操作 try-catch |

---

## 用户可见错误处理

- **数据加载失败**：显示 error icon + 错误描述 + 重试按钮
- **操作失败**：使用 `SnackBar` 提示（不超过 4 秒自动消失）
- **网络/图片加载**：显示占位图 + 可选重试
- **严重错误**：TODO — 未来可引入集中错误报告

---

## 调试建议

```dart
// 开发阶段用 debugPrint 记录错误
try {
  await dao.insert(thought);
} catch (e) {
  debugPrint('Failed to insert thought: $e');
  rethrow; // 仍然向上传播
}
```
