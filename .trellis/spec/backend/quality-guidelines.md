# Quality Guidelines

> UniHub 后端代码质量标准（Drift/SQLite + Dart）

---

## Overview

所有数据层代码必须通过 `flutter analyze`（0 error 0 warning）。核心原则：

- **禁止类型抑制** `as dynamic`、空 catch、不加原因的 ignore
- **测试必须隔离**：`NativeDatabase.memory()` + `setUp`/`tearDown`
- **分层清晰**：DAO（数据访问）↛ Repository（业务逻辑）↛ Service（外部服务）

---

## Forbidden Patterns

| 模式 | 原因 | 替代 |
|------|------|------|
| 在 DAO 中写业务逻辑 | DAO 应只做 CRUD | 业务逻辑放在 Repository |
| `await db.execute('SELECT *')` 手写 SQL | 绕过 Drift 类型安全 | 使用 drift 的 Query API |
| 在 Provider 或 Widget 中直接操作数据库 | 耦合，无法测试 | 通过 Repository 访问 |
| 测试中使用 `sqflite` | 需要物理数据库 | `NativeDatabase.memory()` |
| 表间硬编码外键引用 | 耦合表定义 | 通过 DAO/Repository 组合 |
| `schemaVersion` 手动写固定值 | 忽略插件版本变化 | 从 PluginRegistry 自动计算 |

---

## Required Patterns

| 模式 | 要求 |
|------|------|
| Drift 表定义使用 `@UseRowClass` | 代码生成类型安全的 row 类 |
| DAO 用 Riverpod Provider 注入 | `@riverpod` 注解生成 Provider |
| Repository 通过 DAO 组合 | Repository 接收 DAO 参数，不直接访问数据库 |
| 时间戳字段命名 | `createdAt`(DateTime)、`updatedAt`(DateTime)、`archivedAt`(DateTime?) |
| 软删除模式 | 使用 `archivedAt` 字段，不改 SQL DELETE |
| 测试隔离 | `setUp` 创建内存数据库，`tearDown` 关闭 |
| 迁移策略 | `shouldRecreateOnVersionChange: true` 开发模式 |

---

## Testing Requirements

### Database 测试

```dart
void main() {
  late AppDatabase db;
  late ThoughtsDao dao;

  setUp(() async {
    db = NativeDatabase.memory();
    dao = ThoughtsDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('insert and retrieve', () async {
    await dao.insert(ThoughtForInsert(title: 'Test'));
    final thoughts = await dao.getAll();
    expect(thoughts.length, 1);
  });
}
```

### 测试覆盖要求

| 层 | 覆盖率目标 | 关键场景 |
|---|-----------|---------|
| DAO | 核心 CRUD 方法 100% | 插入、查询（含条件）、更新、删除/归档 |
| Repository | 业务逻辑 100% | 组合操作、边界条件、错误路径 |
| Codec | 往返测试 100% | encode → decode → 验证相等 |

**零 mockito**：使用 `NativeDatabase.memory()` 和 Provider override。

---

## Code Review Checklist

- [ ] `flutter analyze` 通过
- [ ] 新增表已添加到 `@DriftDatabase(tables: [...])`
- [ ] DAO 不包含业务逻辑
- [ ] Repository 通过 DAO 组合，不直接访问数据库
- [ ] 测试使用 `NativeDatabase.memory()` + `setUp`/`tearDown`
- [ ] `schemaVersion` 自动计算（非硬编码）
- [ ] 迁移策略正确处理 onUpgrade
- [ ] 时间戳字段符合命名规范
- [ ] 软删除使用 `archivedAt` 字段
