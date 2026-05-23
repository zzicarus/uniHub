# Type Safety

> UniHub 类型安全惯例 — Dart 严格模式 + 代码生成

---

## Overview

UniHub 使用 Dart 的严格类型系统（`strict-calls`、`strict-raw-types` 等），禁止任何类型抑制。代码生成（`build_runner`）用于 Drift 和 Riverpod 的模板代码。

---

## 基本原则

| 原则 | 说明 | 反例 | 正例 |
|------|------|------|------|
| 禁止 `as dynamic` | 不绕过类型系统 | `(x as dynamic).foo()` | `x.foo()` 或明确类型转换 |
| 避免 `as` 强制转换 | 优先 is 检查 | `obj as MyType` | `if (obj is MyType) obj.safeMethod()` |
| 禁止空 catch | catch 必须处理或抛回 | `catch (e) {}` | `catch (e) { debugPrint(e.toString()); rethrow; }` |
| 禁止 `// ignore` 无原因 | 每个 ignore 必须有解释 | `// ignore: unused_local_variable` | `// ignore: unused_local_variable — 保留供后续扩展` |

---

## 代码生成模式

项目使用 `build_runner` 生成三类代码：

### 1. Drift（数据库表）

```dart
// 手写的表定义 → 生成 .g.dart（连接器、映射器）
@UseRowClass(Thought)
class ThoughtsTable extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  // ...
}
```

### 2. Riverpod（Provider）

```dart
// @riverpod 注解 → 生成 .g.dart（Provider 实例）
@riverpod
ThoughtsDao thoughtDao(ThoughtDaoRef ref) { ... }
```

### 3. Freezed（数据类）— 可选

当前项目主要使用 `@UseRowClass`，Freezed 不是强制要求。

---

## 类型定义约定

### 数据模型

```dart
// 用 @UseRowClass 配合 Drift 表
@UseRowClass(Thought)
class ThoughtsTable extends Table { ... }

// 数据类使用 final 属性 + 构造器
class Thought {
  final String id;
  final String title;
  final String content;
  
  const Thought({required this.id, this.title = '', this.content = ''});
}
```

### 枚举

```dart
// 状态/分类枚举
enum ThoughtStatus { all, inbox, archived, trashed }
```

### Typedef

```dart
// 仅在跨多个方法/类共享同一函数签名时使用
typedef ContentValidator = String? Function(String content);
```

---

## 避免的类型模式

| 模式 | 问题 | 替代 |
|------|------|------|
| `Map<String, dynamic>` 作为公共 API 返回 | 失去类型信息 | 定义具体 Model 类 |
| `List<dynamic>` | 失去元素类型 | `List<Thought>` |
| 可选参数过多（8+） | 容易传错顺序 | 使用命名参数 + required |
| `Object?` 作为公共方法返回 | 调用者必须向下转型 | 明确返回类型或用 sealed class |
