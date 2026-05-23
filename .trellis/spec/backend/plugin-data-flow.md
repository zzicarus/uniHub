# 插件数据流规范

> 新增或修改插件数据层时遵循的端到端流程。目标是避免“表已写但未注册”“Provider 直连 DAO”“迁移漏写”等问题。

---

## 总览流程

```
Table → @DriftDatabase 注册 → UniHubPlugin.tables/schemaVersion → migration
      → DAO → Repository → Riverpod Provider → UI/插件入口 → Tests
```

任何新增持久化能力都必须沿这条链路逐项确认，不能只改其中一层。

---

## 1. Table 定义

- 表定义放在 `lib/src/core/database/tables/`，避免 `core/database` 反向依赖 `plugins/`。
- 使用 Drift 类型安全列：`IntColumn`、`TextColumn`、`DateTimeColumn`、`BoolColumn`。
- 主键使用 `integer().autoIncrement()`，命名 `id`。
- 时间戳统一使用 `createdAt` / `updatedAt`。
- 软删除/归档统一使用 nullable `archivedAt`。
- 新字段必须写清楚 nullable/default 策略；不要依赖 UI 层补默认值。

---

## 2. @DriftDatabase 集中注册

`lib/src/core/database/app_database.dart` 是 Drift 编译期唯一注册点：

```dart
@DriftDatabase(tables: [ThoughtsTable, TodoTable])
class AppDatabase extends _$AppDatabase { ... }
```

新增表后必须同步：

- import 对应 table 文件；
- 将表加入 `@DriftDatabase(tables: [...])`；
- 运行代码生成（如涉及生成文件更新）；
- 确认 debug assert 中插件声明表与数据库注册表一致。

不要尝试从运行时 `PluginRegistry` 动态注入 `tables` 注解；Drift 代码生成在编译期读取注解。

---

## 3. 插件 tables 与 schemaVersion

每个需要数据库表的插件必须在 `UniHubPlugin` 实现中声明：

```dart
@override
List<Type> get tables => [TodoTable];

@override
int get schemaVersion => 3;
```

约束：

- `tables` 返回插件拥有的所有表类型，用于运行时一致性验证。
- `schemaVersion` 表示插件数据结构版本；新增/删除/修改列时递增。
- `AppDatabase.schemaVersion` 取所有插件版本最大值，因此多个插件共存时迁移逻辑必须按版本条件幂等执行。
- 插件无持久化表时保留默认 `tables => []` 与 `schemaVersion => 0`。

---

## 4. Migration 迁移

在 `AppDatabase.migration` 中维护迁移：

- `onCreate` 首次安装使用 `m.createAll()` 或等价完整建表逻辑。
- `onUpgrade` 按 `from < targetVersion` 分段迁移，保持幂等和可重复推理。
- 新增 nullable/default 列使用 `m.addColumn(table, table.column)`。
- 删除/重命名列需要明确数据保留策略，避免静默丢数据。
- 迁移中不要调用 Repository 或 UI Provider，只使用数据库迁移 API。

示例：

```dart
onUpgrade: (Migrator m, int from, int to) async {
  if (from < 2) {
    await m.addColumn(thoughtsTable, thoughtsTable.imagePaths);
  }
  if (from < 3) {
    await m.createTable(todoTable);
  }
},
```

---

## 5. DAO 层

DAO 只负责数据访问：

- 构造器注入 `AppDatabase`。
- 使用 Drift 类型安全 API，不拼接 SQL 字符串（除非有充分理由并测试覆盖）。
- 方法以数据动作命名：`watchAll()`、`insertEntry()`、`updatePinned()`。
- 不包含业务规则、UI 文案或 Provider 读取。
- 返回 Drift row 或底层数据结构，业务模型转换可放 Repository。

---

## 6. Repository 层

Repository 封装业务用例：

- 构造器注入 DAO。
- 方法名使用业务语言：`createTodo`、`completeTodo`、`archiveThought`。
- 处理默认值、排序策略、模型转换、错误转换。
- 不直接依赖 Widget `BuildContext`，不读取 UI 状态。
- 对外返回业务模型、`Future` 或 `Stream`，供 Provider 暴露。

---

## 7. Provider 层

Riverpod Provider 负责组装依赖与生命周期：

- `appDatabaseProvider` 是全局数据库入口。
- DAO Provider 从 `appDatabaseProvider` 读取数据库。
- Repository Provider 从 DAO Provider 读取 DAO。
- UI 只 watch/read Repository 或用例 Provider，不直接访问 DAO/Database。
- 数据库 Provider 必须在 `ref.onDispose` 中关闭数据库（测试 override 例外按 test 规范处理）。

推荐依赖方向：

```
UI Widget → UseCase/Repository Provider → Repository → DAO → AppDatabase
```

---

## 8. 测试要求

新增插件数据层至少覆盖：

- Table/DAO：使用 `NativeDatabase.memory()` 或项目测试规范中的内存数据库。
- Repository：覆盖业务默认值、排序、过滤、错误转换。
- Provider：用 `ProviderScope(overrides: [...])` 注入测试数据库或 stub Repository。
- Migration：涉及 schemaVersion 变化时，至少覆盖从旧版本升级后的关键字段可读写。
- Plugin registry：新增表时验证插件 `tables` 与 `AppDatabase` 集中注册一致。

测试生命周期：

- `setUp` 创建独立数据库；
- `tearDown` 关闭数据库；
- 不复用跨测试可变数据库状态；
- 不用 mockito 伪造 Drift 生成对象，优先真实内存数据库或手写 stub。

---

## 新增插件数据层 Checklist

- [ ] Table 位于 `core/database/tables/`，字段命名和默认值符合规范。
- [ ] `app_database.dart` 已 import 并加入 `@DriftDatabase(tables: [...])`。
- [ ] 插件 `tables` 返回新表类型。
- [ ] 插件 `schemaVersion` 已按数据结构变化递增。
- [ ] `migration.onCreate/onUpgrade` 覆盖新表/新列，且不会丢数据。
- [ ] DAO 只做数据访问，无业务/UI 逻辑。
- [ ] Repository 封装业务语义并通过 Provider 暴露。
- [ ] UI 不直接访问 Database/DAO。
- [ ] DAO/Repository/Provider/Migration 测试按影响范围补齐。
- [ ] `flutter analyze` 与相关测试通过。
