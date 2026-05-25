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
// lib/src/plugins/thoughts/data/thoughts_table.dart
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
@DriftDatabase(tables: [ThoughtsTable, TodoTable])  // 编译期集中注册所有表
class AppDatabase extends GeneratedDatabase {
  AppDatabase(super.e, PluginRegistry registry);

  @override
  int get schemaVersion => /* 自动取所有插件 schemaVersion 的最大值 */;

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

**重要**：`@DriftDatabase(tables: [...])` 是**编译期集中注册点**。由于 drift 代码生成器在编译时读取注解，表列表无法从运行时的 `PluginRegistry` 动态注入。因此：

1. 所有表必须在本文件的 `tables: [...]` 中显式列出
2. 插件的 `UniHubPlugin.tables` 返回对应 `Type` 用于运行时验证
3. `AppDatabase` 构造时通过 `assert` 检查两者一致性（debug 模式）
4. `schemaVersion` 自动从 `PluginRegistry` 计算（取所有插件版本的最大值）

---

## 迁移策略

| 策略 | 说明 |
|------|------|
| schemaVersion 计算 | `AppDatabase.schemaVersion` = 所有插件 `schemaVersion` 的最大值（运行时自动计算） |
| onCreate | 合并执行所有插件的建表逻辑 |
| onUpgrade | 按 `from` → `to` 版本差执行，必须幂等 |
| 插件迁移 | 每个插件通过 `UniHubPlugin` 的 `tables` / `schemaVersion` 贡献自己的表和版本 |
| 集中注册 | `@DriftDatabase(tables: [...])` 是编译期唯一注册点，新增表必须同步更新 |

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

- Trigger：想法编辑器从 Quill 迁移到 AppFlowy Editor，`thoughts_table.content` 不再只表示纯 Markdown 文本。
- 范围：`ThoughtsTable.content`、Repository 读写、UI 编辑器、卡片摘要、搜索/首页摘要、图片索引字段 `imagePaths`。
- 历史：旧数据可能为 `unihub.quill_delta.v1` 格式（已下线），当前主格式为 `unihub.appflowy_json.v1`。

### 2. Signatures

| 层 | 签名 / 字段 | 合同 |
|----|-------------|------|
| DB | `ThoughtsTable.content: TEXT NOT NULL` | 存储 AppFlowy JSON envelope（格式 `unihub.appflowy_json.v1`）；旧 Quill 数据可能仍存在 |
| DB | `ThoughtsTable.imagePaths: TEXT NULL` | JSON string list，作为本地图片索引 |
| Data helper | `ThoughtContentCodec.plainTextFromStored(String)` | 输出 UI/搜索可展示纯文本，优先使用 envelope 中 `plainText` 字段 |
| Data helper | `ThoughtContentCodec.titleFromStored(String)` | 从 plainText 取第一行生成标题 |
| Data helper | `ThoughtContentCodec.encodeAppFlowy({document:, plainText:})` | 生成 `unihub.appflowy_json.v1` envelope JSON |
| Data helper | `ThoughtContentCodec.documentJsonFromStored(String)` | 从 envelope 提取 AppFlowy document JSON |

### 3. Contracts

当前主格式为 AppFlowy JSON envelope：

```json
{
  "format": "unihub.appflowy_json.v1",
  "document": {
    "type": "page",
    "children": [
      {
        "type": "paragraph",
        "data": {
          "delta": [
            {"insert": "标题"}
          ]
        }
      }
    ]
  },
  "plainText": "标题"
}
```

兼容读取规则（`plainTextFromStored`）：

| 输入内容 | 处理 |
|----------|------|
| envelope JSON 且 `format == "unihub.appflowy_json.v1"` | 优先返回 `plainText` 字段；其次从 `document` 提取 |
| 其他非 AppFlowy 格式 | 返回空字符串（旧 Quill 数据被丢弃） |

> `titleFromStored` 取 plainText 的第一非空行，截断到 20 字符 + `...`，空时返回 `'无标题想法'`。

### 4. Validation & Error Matrix

| 条件 | 处理 |
|------|------|
| `content` 为空字符串 | `plainTextFromStored` 返回 `''`，`titleFromStored` 返回 `'无标题想法'` |
| JSON 解析失败 | 返回空字符串（非 JSON 的旧数据视为无效） |
| envelope 缺少 `plainText` 且 `document` 不完整 | 尝试从 `document` 提取，失败返回空字符串 |
| `document` 中没有 paragraph text | 返回空字符串 |
| `imagePaths` 不是合法 JSON list | 视为空列表 |

---

## 表：website_logo_cache

| 属性 | 值 |
|------|-----|
| 文件名 | `lib/src/core/database/tables/website_logo_cache_table.dart` |
| 用途 | 站点级 favicon 缓存，同一 host 只缓存一份 logo |
| siteKey 规则 | `lowerCase(host without leading www.)`，例如 `bilibili.com`、`chatgpt.com` |
| 后台填充 | `EnrichmentJobService` 在成功抓取 metadata 后触发 `WebsiteLogoCacheService.ensureLogoCached()` |
| UI 读取 | `WebsiteLogo` 组件通过 `websiteLogoForUrlProvider` 读取 `localLogoPath`，使用 `Image.file`，不发起网络请求 |

```dart
class WebsiteLogoCacheTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get siteKey => text().unique()();     // e.g. "bilibili.com"
  TextColumn get host => text()();                  // e.g. "www.bilibili.com"
  TextColumn get remoteLogoUrl => text().nullable()();
  TextColumn get localLogoPath => text().nullable()();
  TextColumn get mimeType => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get fetchedAt => dateTime().nullable()();
  DateTimeColumn get expiresAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}
```

### 缓存策略

| 状态 | 行为 |
|------|------|
| success 且未过期（默认 30 天） | 直接复用 |
| success 但过期 | 先返回旧 logo，后台刷新 |
| pending | UI 显示 fallback |
| failed 且未过重试时间（默认 24 小时） | UI 显示 fallback |
| failed 且可重试 | 后台重新抓取 |

### 注册与迁移

- `collections_plugin.dart`：`tables` 加入 `WebsiteLogoCacheTable`，`schemaVersion` 升至 4
- `app_database.dart`：`@DriftDatabase(tables: [...]` 加入 `WebsiteLogoCacheTable`，`onUpgrade` 新增 `from < 4 → createTable`
- logo 文件存于 `{appCacheDir}/website_logos/{base64(siteKey)}.{ext}`

### 5. Good/Base/Bad Cases

- Good：新建想法，正文以 `unihub.appflowy_json.v1` envelope 写入；卡片/首页/搜索用 `plainTextFromStored` 展示摘要。
- Base：调用 `quickCreate()` 直接生成纯文本段落 JSON，不经过富文本编辑器。
- Bad：直接把 `content` 原样显示到 UI，会把 AppFlowy JSON 暴露给用户。

### 6. Tests Required

- Unit：`encodeAppFlowy` + `plainTextFromStored` 往返，断言纯文本不丢失。
- Unit：`titleFromStored` 截断和空内容行为。
- Unit：非 AppFlowy 格式（旧 Quill delta、普通文本）返回空字符串。
- Widget/Smoke：首页和想法页面不能渲染 AppFlowy JSON。
- Integration：`quickCreate()` 写入的 content 格式验证为 `unihub.appflowy_json.v1`。
- Regression：`flutter analyze` 和 `flutter test` 必须通过。

### 7. Wrong vs Correct

#### Wrong

```dart
Text(thought.content); // 可能显示 {"format":"unihub.appflowy_json.v1",...}
```

#### Correct

```dart
Text(ThoughtContentCodec.plainTextFromStored(thought.content));
```

### 8. 历史遗留数据

- **`unihub.quill_delta.v1`** 格式（2026-05 及之前）：不再写入，读取时 `plainTextFromStored` 返回空字符串。
- 旧 Quill 数据的批量迁移不在当前 scope 内。
- 用户主路由 `/thoughts/:id` 已切到 AppFlowy，旧 Quill 编辑器不会再次打开旧数据。

### 9. Related

- 编辑引擎迁移说明见 `architecture/editor-migration.md`。
- 当前格式常量：`ThoughtContentCodec.format == 'unihub.appflowy_json.v1'`（`lib/src/plugins/thoughts/data/thought_content_codec.dart`）。

---

## Provider 集成

数据库通过 Riverpod Provider 暴露：

```dart
// lib/src/core/database/database_provider.dart
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final registry = ref.read(pluginRegistryProvider);
  final db = AppDatabase(_createExecutor(), registry);
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
  final registry = PluginRegistry();
  // registry.register(YourPlugin());
  database = AppDatabase(NativeDatabase.memory(), registry);
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
