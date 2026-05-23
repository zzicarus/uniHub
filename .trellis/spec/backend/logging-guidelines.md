# Logging Guidelines

> UniHub 日志记录约定 — Dart debug 优先

---

## Overview

UniHub 目前没有引入专门的日志库（如 `logging`、`talker`）。日志需求较轻量，主要依赖：

| 机制 | 用途 | 示例 |
|------|------|------|
| `debugPrint` | 开发中的调试输出 | `debugPrint('Thought inserted: $id')` |
| `print` | 禁止在正式提交中使用（lint 规则 `avoid_print`） | 仅用于临时调试 |
| `debugPrint` + `rethrow` | 错误记录+传播 | `catch (e) { debugPrint(e.toString()); rethrow; }` |

---

## 日志级别（参考）

目前不使用结构化日志级别，但根据日志内容区分：

| 级别 | 含义 | 使用场景 |
|------|------|---------|
| INFO | 正常操作信息 | 数据插入/删除成功、导航事件 |
| WARNING | 预期内的异常情况 | 查询无结果、图片加载失败 | 
| ERROR | 不应发生的失败 | 数据库写入失败、数据损坏 |
| FATAL | 严重不可恢复 | 启动失败、插件注册冲突 |

---

## 打印规则

### 数据层

```dart
// ✅ 关键操作记录
final id = await dao.insert(thought);
debugPrint('Thought inserted: $id');

// ✅ 错误记录 + 传播
try {
  await dao.archive(id);
} catch (e) {
  debugPrint('Failed to archive thought $id: $e');
  rethrow;
}
```

### UI 层

```dart
// ✅ AsyncValue.error 中使用 debugPrint 记录
thoughtsAsync.when(
  error: (error, stack) {
    debugPrint('Failed to load thoughts: $error');
    return ErrorWidget(error.toString());
  },
  // ...
);
```

### Provider 层

Provider 中的异常自动由 Riverpod 捕获为 AsyncValue.error，不需要额外 `debugPrint`。

---

## 禁止模式

| 模式 | 原因 |
|------|------|
| `print(...)` 提交到 main 分支 | lint 规则（`avoid_print`）禁止 |
| `debugPrint` 包含敏感数据（用户输入原文） | 日志中不应包含用户原始内容 |
| 在发布模式中记录详细日志 | `debugPrint` 默认只在 debug 模式输出 |

---

## 未来扩展

当需要更复杂的日志需求时（如错误报告、日志文件导出），建议按以下优先级引入：

1. `package:logging` — Dart 标准日志库，结构化级别
2. `package:talker` — Flutter 友好的日志 UI
3. 自定义日志 Provider 统一管理

当前阶段保持轻量 — `debugPrint` 已经足够。
