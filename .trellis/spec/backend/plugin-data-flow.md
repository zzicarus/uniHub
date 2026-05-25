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

## Scenario: AppDatabase 集中注册与测试插件子集

### 1. Scope / Trigger

- Trigger：新增插件表后，`@DriftDatabase(tables: [...])` 必须集中注册所有表，但单元测试经常只注册当前被测插件（例如只注册 Thoughts 或只注册 Collections）。
- 范围：`AppDatabase._validatePluginTables()`、`UniHubPlugin.tables`、`PluginRegistry` 测试夹具、所有使用 `NativeDatabase.memory()` 的数据层测试。

### 2. Signatures

| 位置 | 签名 / 字段 | 合同 |
|------|-------------|------|
| DB | `@DriftDatabase(tables: [...])` | 编译期注册全量表，不能按测试插件子集动态变化 |
| Plugin | `List<Type> get tables` | 只声明该插件拥有的表 |
| Runtime check | `_validatePluginTables(): bool` | 校验“插件声明的表已存在于集中注册表”，不要要求“集中注册表必须全部被当前 registry 声明” |
| Test | `AppDatabase(NativeDatabase.memory(), registry)` | registry 可以只注册被测插件；不要求注册所有生产插件 |

### 3. Contracts

- 生产启动：`main.dart` 应注册所有生产插件，`schemaVersion` 取这些插件版本最大值。
- 数据层测试：可以构造最小 `PluginRegistry`，只注册被测插件，避免测试被无关插件耦合。
- 一致性断言：必须发现“插件声明了某张表，但 `@DriftDatabase` 漏注册”的错误。
- 一致性断言：不应因为“`@DriftDatabase` 有其他插件表，而测试 registry 没注册其他插件”失败。

### 4. Validation & Error Matrix

| 条件 | 处理 |
|------|------|
| 插件 `tables` 包含未集中注册的表 | debug assert 失败，提示同步 `@DriftDatabase(tables: [...])` |
| `@DriftDatabase` 包含其他插件表，但当前测试 registry 未注册对应插件 | 允许；测试可继续运行 |
| 生产入口漏注册某个插件 | 对应插件功能/路由/版本不生效，应由插件注册/路由测试覆盖 |
| 新增表但未递增插件 `schemaVersion` | migration 可能不执行；review 时必须按 checklist 拦截 |

### 5. Good/Base/Bad Cases

- Good：Collections 数据层测试只注册 `CollectionsPlugin()`，AppDatabase 仍包含 Thoughts 表，但断言通过。
- Base：生产入口同时注册 Thoughts 与 Collections，所有声明表都能在 `allSchemaEntities` 中找到。
- Bad：校验 DB 中每张表都必须被当前 registry 声明，会导致“只注册被测插件”的隔离测试无故失败。

### 6. Tests Required

- Unit：新增插件表时，`database_test.dart` 覆盖 `schemaVersion` 最大值和 migration strategy。
- Unit：保留“插件声明不存在表时 assert 失败”的负例。
- Data：新插件 DAO/Repository 使用 `NativeDatabase.memory()` + 最小 registry 覆盖 CRUD/过滤。
- Router/Plugin：新增 route name 和插件路由时补齐 route 测试。

### 7. Wrong vs Correct

#### Wrong

```dart
for (final dbTable in dbTables) {
  final declared = pluginTableTypes.any(
    (type) => dbTable.runtimeType.toString().contains(type.toString()),
  );
  if (!declared) return false; // 会破坏只注册被测插件的测试
}
```

#### Correct

```dart
for (final tableType in pluginTableTypes) {
  final typeName = tableType.toString();
  final hasMatch = dbTables.any(
    (table) => table.runtimeType.toString().contains(typeName),
  );
  if (!hasMatch) return false;
}
```

---

## Enrichment + Logo 缓存数据流

```
用户收藏 URL
  ↓
CollectionCaptureService.captureUrl()
  ├─ createSavedItem()          → saved_items 表
  └─ enqueueEnrichmentJob()     → enrichment_jobs 表
  ↓
_triggerEnrichmentQueue()
  └─ EnrichmentJobService.runPendingJobs()
       ├─ LocalMetadataProvider.fetchMetadata()
       │    → 解析 title / description / favicon / ...
       ├─ CollectionsRepository.updateMetadata()
       │    → 写回 saved_items
       ├─ WebsiteLogoCacheService.ensureLogoCached()
       │    ├─ 下载 favicon（远程 URL 或 fallback /favicon.ico）
       │    ├─ 保存到本地文件 {appCacheDir}/website_logos/{base64(siteKey)}.{ext}
       │    └─ 写入 website_logo_cache 表
       └─ EnrichmentJobsDao.markSuccess()
  ↓
UI 自动刷新
  ├─ websiteLogoRefreshProvider 递增 → 所有 family provider 重取
  └─ savedItemsListProvider 无效化 → 卡片列表重建
```

### 关键约束

| 规则 | 说明 |
|------|------|
| UI 不抓取 | `WebsiteLogo` 只读 `localPath` + `Image.file`，不发起任何网络请求 |
| 站点级复用 | 同一 siteKey（host 去 www.、小写）只缓存一份 logo 文件 |
| 不阻塞收藏 | logo 在 enrichment 后台异步补全，收藏流程不受影响 |
| 后台下载限制 | 最大 512KB、超时 8s、仅 http/https |
| TTL 管理 | 成功 30 天、失败 24 小时重试间隔 |

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
