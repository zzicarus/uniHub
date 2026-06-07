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
- **CRUD 操作反馈**：通过 `CrudFeedbackCoordinator` 统一处理（见下方 CRUD 结果模型）
  - 成功 + 可撤销 → `AppToast.undo()`
  - 成功 + 需提示 → `AppToast.show(type: success)`
  - 字段验证错误 → Inline Field Error（表单已处理时静默）
  - 冲突/关联数据 → `AppToast.show(type: warning)`
  - 数据库/网络/文件系统错误 → `AppToast.show(type: error)`
- **删除/操作确认**：使用 `AppConfirmDialog` / `AppConflictDialog`
- **网络/图片加载**：显示占位图 + 可选重试
- 业务代码**禁止**直接创建 `SnackBar`、调用 `ScaffoldMessenger.showSnackBar` 或直接创建原生 `AlertDialog`
- 所有临时提示必须通过 `AppToast.show` / `AppToast.undo`
- 所有确认对话框必须通过 `AppConfirmDialog.show` / `AppConflictDialog.show`

---

## CRUD 操作结构化结果模型（CrudResult / AppFailure）

自 2026-06-07 起，所有 CRUD 操作统一使用 `CrudResult<T>` 作为返回类型，替代裸异常或私有 ActionResult 模型。

### 核心类型

```dart
// 结构化失败信息
class AppFailure {
  final AppFailureCode code;    // validation / duplicate / notFound / conflict / referenced / database / network / ...
  final String message;         // 用户可见文案
  final String? field;          // 关联的表单字段（用于 inline error）
  final Object? cause;          // 技术异常（仅用于调试）
  final StackTrace? stackTrace;
}

// 统一返回类型
class CrudResult<T> {
  final bool success;
  final T? data;
  final String? message;              // 用户可见成功/失败文案
  final AppFailure? failure;          // 失败详情
  final CrudUndoAction? undo;         // 可撤销操作
  final List<CrudSideEffect> sideEffects; // 页面副作用（选中、关闭详情等）
  final bool suppressFeedback;        // 静默模式
  final bool fieldErrorHandled;       // 表单字段错误已就地处理
}

// 批量操作结果
class BatchCrudResult<T> {
  final List<CrudResult<T>> results;
  BatchCrudStatus get status;  // allSucceeded / allFailed / partialSucceeded
  String get summaryMessage;
}
```

### 分层责任

| 层 | 责任 | 错误处理方式 |
|----|------|-------------|
| DAO | 数据库访问 | 让 Drift 异常自然传播 |
| Repository | 业务一致性（重名、引用、唯一约束） | 抛出 `ArgumentError` / `StateError` 等明确异常 |
| Controller | 将业务异常/技术异常转为 `CrudResult` | `try-catch` → `CrudResult.failure(...)` |
| UI | 展示表单错误 + 调用 coordinator | `ref.read(crudFeedbackCoordinatorProvider).handle(context, result)` |

### Controller 模式

```dart
// ✅ 正确：Controller 将异常转为 CrudResult
Future<CrudResult<void>> deleteItem(int itemId) async {
  try {
    final item = await _repository.getSavedItem(itemId);
    if (item == null) {
      return _failure('收藏项不存在', AppFailureCode.notFound);
    }
    await _repository.deleteSavedItem(itemId);
    return CrudResult<void>.success(
      message: '已删除「$title」',
      undo: CrudUndoAction(execute: () => restoreDeletedItem(snapshot)),
    );
  } catch (error, stackTrace) {
    return _failure('删除失败', AppFailureCode.database, cause: error, stackTrace: stackTrace);
  }
}
```

### UI 使用模式

```dart
// ✅ UI 层不拼接错误文案，不直接创建 SnackBar
final result = await controller.deleteItem(item.id);
if (!context.mounted) return;
ref.read(crudFeedbackCoordinatorProvider).handle(context, result);
```

### CrudFeedbackCoordinator 反馈规则

| result 条件 | 反馈行为 |
|-------------|---------|
| success + undo | `AppToast.undo(message, onUndo)` |
| success + message | `AppToast.show(message, type: success)` |
| validation / duplicate + fieldErrorHandled | 静默（表单已处理） |
| conflict / referenced | `AppToast.show(message, type: warning)` |
| database / network / permission / notFound / unknown | `AppToast.show(message, type: error)` |
| cancelled | info toast |
| suppressFeedback | 完全静默 |

### 禁止模式

| 禁止 | 原因 | 正确做法 |
|------|------|---------|
| UI 层直接调用 `ScaffoldMessenger.showSnackBar` | 反馈不统一，无法撤销 | 使用 `CrudFeedbackCoordinator` |
| Controller 返回 `SavedItemActionResult` 等私有类型 | 每个插件都要重复实现 | 统一使用 `CrudResult<T>` |
| 业务代码展示技术异常信息 | 用户无法理解 | 使用 `AppFailure.message`（用户友好文案） |
| Repository 返回 `CrudResult` | 分层混乱 | Repository 抛异常，Controller 转为 `CrudResult` |

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
