# 数据库规范

> UniHub 使用 drift(SQLite) 作为本地持久化方案。本文件记录建表、查询、迁移的约定。

---

## 技术栈

| 组件 | 包 | 版本（参考 pubspec.yaml） |
|------|-----|------|
| ORM | `drift` | ^2.25.1 |
| 代码生成 | `drift_dev` + `build_runner` | ^2.25.2 / ^2.4.14 |
| SQLite 原生库 | `sqlite3_flutter_libs` | ^0.5.28 |
| 数据库路径 | `path_provider` + `path` | ^2.1.5 / ^1.9.1 |

---

## Table 定义

### 基础模式

```dart
// lib/src/core/database/tables/thoughts_table.dart
import 'package:drift/drift.dart';

class ThoughtsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get content => text()();
  TextColumn get tags => text().nullable()();
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn? get archivedAt => dateTime().nullable()();
}
```

### 约定

| 规则 | 说明 |
|------|------|
| 表名 | 自动从类名派生（`ThoughtsTable` → `thoughts_table`） |
| 主键 | 使用 `integer().autoIncrement()`，命名为 `id` |
| 时间戳 | 使用 `dateTime()`，命名 `createdAt` / `updatedAt` |
| 软删除 | 使用 `archivedAt` nullable datetime（NULL = 未归档） |
| 标签 | 逗号分隔存储（`tags` TEXT），不做多对多关联（首版简化） |
| 默认值 | 布尔字段使用 `withDefault(const Constant(false))()` |

---

## AppDatabase

数据库类在 `lib/src/core/database/app_database.dart`，是唯一的 drift Database 入口：

```dart
@DriftDatabase(tables: [ThoughtsTable, TodoTable])  // 编译期声明所有表
class AppDatabase extends GeneratedDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      // 各插件表的 onCreate 在此合并执行
    },
    onUpgrade: (Migrator m, int from, int to) async {
      // 按版本差执行迁移
    },
  );
}
```

---

## 迁移策略

| 策略 | 说明 |
|------|------|
| schemaVersion 计算 | `AppDatabase.schemaVersion` = 所有插件 `schemaVersion` 之和 |
| onCreate | 合并执行所有插件的建表逻辑 |
| onUpgrade | 按 `from` → `to` 版本差执行，必须幂等 |
| 插件迁移 | 每个插件通过 `UniHubPlugin` 的 `tables` / `schemaVersion` 贡献自己的表和版本 |

**Foundation 阶段约束**：当前 `AppDatabase` 为空骨架（`allTables => []`，`schemaVersion => 1`），不声明业务表。Thoughts Data Layer 任务接入真实表。

---

## DAO 模式

DAO 封装 drift 查询，只做数据访问，不含业务逻辑：

```dart
// plugins/thoughts/data/thoughts_dao.dart
class ThoughtsDao {
  final AppDatabase _db;

  ThoughtsDao(this._db);

  Future<List<ThoughtsTableData>> getAll() =>
      (_db.select(_db.thoughtsTable)
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
      .get();

  Future<void> insert(ThoughtsTableCompanion entry) =>
      _db.into(_db.thoughtsTable).insert(entry);
}
```

**约定**：
- DAO 接收 `AppDatabase` 实例（构造器注入）
- 使用 drift 的类型安全查询 API（`select().get()`、`into().insert()`）
- 不抛出异常之外的业务错误（Repository 负责错误转换）

---

## Repository 模式

Repository 封装用例级 API，组合 DAO 调用：

```dart
// plugins/thoughts/data/thoughts_repository.dart
class ThoughtsRepository {
  final ThoughtsDao _dao;

  ThoughtsRepository(this._dao);

  Future<void> pinThought(int id, bool pinned) async {
    await _dao.updatePinned(id, pinned);
  }

  Future<List<Thought>> getPinnedItems() async =>
      _dao.getAll().then((rows) => rows.where((r) => r.isPinned).toList());
}
```

**约定**：
- Repository 构造器注入 DAO（依赖倒置）
- 方法名使用业务语言（`pinThought`，不是 `updatePinnedColumn`）
- 返回值是业务模型（可不同于 Table Data Class，后续可根据需要做映射）

---

## Scenario: Thoughts 富文本正文存储合同

### 1. Scope / Trigger

- Trigger：想法编辑器使用 WYSIWYG 富文本，`thoughts_table.content` 不再只表示纯 Markdown 文本。
- 范围：`ThoughtsTable.content`、Repository 读写、UI 编辑器、卡片摘要、搜索/首页摘要、图片索引字段 `imagePaths`。

### 2. Signatures

| 层 | 签名 / 字段 | 合同 |
|----|-------------|------|
| DB | `ThoughtsTable.content: TEXT NOT NULL` | 存储 Quill Delta envelope JSON；旧数据可能仍是 Markdown 文本 |
| DB | `ThoughtsTable.imagePaths: TEXT NULL` | JSON string list，作为本地图片索引 |
| Data helper | `ThoughtContentCodec.documentFromStored(String)` | 读取 envelope / legacy Delta list / legacy Markdown，统一输出 `Document` |
| Data helper | `ThoughtContentCodec.encodeDocument(Document)` | 输出 envelope JSON |
| Data helper | `ThoughtContentCodec.plainTextFromStored(String)` | 输出 UI/搜索可展示纯文本，不泄漏 Delta JSON |

### 3. Contracts

新正文必须保存为 envelope JSON：

```json
{
  "format": "unihub.quill_delta.v1",
  "delta": [
    {"insert": "标题\n", "attributes": {"header": 1}},
    {"insert": "正文\n"}
  ]
}
```

兼容读取规则：

| 输入内容 | 处理 |
|----------|------|
| envelope JSON 且 `format == "unihub.quill_delta.v1"` | 从 `delta` 构造 Quill `Document` |
| 裸 Delta JSON list | 作为历史/中间格式读取 |
| 其他文本 | 按 legacy Markdown 转换为 Quill `Document` |
| Markdown 图片 `![](file:///...)` | 即使转换库忽略图片，也必须通过正则提取路径加入图片索引 |

### 4. Validation & Error Matrix

| 条件 | 处理 |
|------|------|
| `content` 为空字符串 | 返回空 `Document` |
| JSON 解析失败 | 降级为 Markdown 文本导入 |
| envelope 缺少 `delta` 或类型错误 | 降级为 Markdown 文本导入 |
| 图片路径不存在 | UI 缩略图过滤不存在文件，避免展示坏路径 |
| `imagePaths` 不是合法 JSON list | 视为空列表 |

### 5. Good/Base/Bad Cases

- Good：新建富文本想法，正文以 envelope JSON 写入；卡片/首页/搜索用 `plainTextFromStored` 展示摘要。
- Base：旧 Markdown 想法能打开编辑，保存后升级为 envelope JSON。
- Bad：直接把 `content` 原样显示到 UI，会把 Delta JSON 暴露给用户。

### 6. Tests Required

- Unit：Delta envelope encode/decode 往返，断言纯文本不丢失。
- Unit：legacy Markdown 转纯文本，断言标题/正文可读。
- Unit：legacy Markdown 本地图片路径提取，断言 `file:///...` 能进入图片索引。
- Widget/Smoke：首页和想法页面不能渲染 Delta JSON。
- Regression：`flutter analyze` 和 `flutter test` 必须通过。

### 7. Wrong vs Correct

#### Wrong

```dart
Text(thought.content); // 可能显示 {"format":"unihub.quill_delta.v1",...}
```

#### Correct

```dart
Text(ThoughtContentCodec.plainTextFromStored(thought.content));
```

---

## Provider 集成

数据库通过 Riverpod Provider 暴露：

```dart
// lib/src/core/database/database_provider.dart
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase(_createExecutor());
  ref.onDispose(() => db.close());
  return db;
});
```

**约定**：
- `appDatabaseProvider` 是全局唯一的数据库 Provider
- 使用 `ref.onDispose` 确保数据库关闭
- Executor 使用 `LazyDatabase`（延迟创建，只在首次访问时打开文件）
- 数据库文件路径：`getApplicationDocumentsDirectory()/unihub.db`
- 平台特定：Windows 使用 `NativeDatabase`，Android 使用 `Sqlite3FLutterLibs` 提供的 SQLite

---

## 常见错误

| 错误 | 原因 | 避免方法 |
|------|------|----------|
| 忘记在 `@DriftDatabase(tables: [...])` 中注册新表 | 新增 table 后未更新声明 | 每次新增 table 同步更新 `app_database.dart` |
| 数据库未关闭 | Provider dispose 未注册 | 始终在 Provider 中 `ref.onDispose(() => db.close())` |
| 直接在 Widget 中查询数据库 | 绕过 Repository/Provider 层 | 遵循 `UI → Provider → Repository → DAO` 分层 |
| 迁移漏写导致数据丢失 | schemaVersion 变了但 onUpgrade 未处理 | 每次改 schemaVersion 必须写对应的 onUpgrade 逻辑 |
| 测试中 DB 未关闭（缺少 tearDown） | 测试函数异常退出时 close() 不执行 | 使用 `late AppDatabase` + `setUp`/`tearDown` 模式，确保即使失败也释放资源 |

### 测试生命周期模式

测试中管理数据库资源的正确模式：

```dart
late AppDatabase database;

setUp(() async {
  database = AppDatabase(NativeDatabase.memory());
});

tearDown(() async {
  await database.close();
});

test('query returns data', () async {
  final result = await database.someQuery();
  expect(result, isNotNull);
});
```

使用 `late` + `setUp`/`tearDown` 模式可以确保：
- 每个测试获得独立的数据库实例
- 即使测试断言失败，`tearDown` 仍然执行
- 不会在测试间泄漏连接或状态
