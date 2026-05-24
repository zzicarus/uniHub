# PRD + 技术架构：uniHub 收藏模块 MVP

> 模块名称：收藏 / Collections  
> 产品定位：个人外部内容收纳中心  
> 技术策略：Local-first + 本地后端化处理层  
> 目标平台：Windows / Android，优先 Windows 本地开发体验  
> 当前决策：不立即做独立远程后端，但从第一版开始按可抽离后端的方式设计

---

## 1. 背景

uniHub 当前已经具备 thoughts / 想法模块，产品方向逐渐从单纯记录工具转向个人信息组织工具。新的收藏模块需要解决外部内容分散的问题：网页、视频、微信公众号文章、GitHub 项目、PDF、图片等内容分布在不同平台，用户需要一个统一入口进行保存、整理、消费和后续沉淀。

收藏模块不应只是普通书签管理器，而应是：

```text
个人外部内容收纳中心
```

用户核心需求：

```text
1. 聚合收藏，支持不同平台和媒介类型
2. 支持 Box 多选，像不同的收藏盒 / 收藏夹
3. 支持未看、进行中、已看、归档四种状态
4. 支持 Inbox，先快速收进来，后续再整理
5. 支持来源平台、媒介类型、状态、Box 等维度筛选
```

---

## 2. 产品目标

### 2.1 一句话目标

```text
uniHub 收藏模块让用户把不同平台的外部内容快速收入 Inbox，再通过 Box、状态、来源平台和媒介类型进行组织，并在后续转化为想法、笔记或任务。
```

### 2.2 核心体验目标

用户粘贴一个链接后，应当立即看到收藏项出现在 Inbox 中，而不是等待网络抓取完成。

正确体验：

```text
粘贴 URL
→ 点击收藏
→ 立即进入 Inbox
→ 显示“正在抓取信息”
→ 后台补全标题、封面、描述、来源平台、媒介类型
```

错误体验：

```text
粘贴 URL
→ 点击收藏
→ 等待网页请求
→ 等待 HTML 解析
→ 等待封面抓取
→ 最后才创建收藏项
```

收藏模块必须保证“保存动作”足够快，metadata 增强可以异步完成。

---

## 3. 用户需求

### 3.1 已确认需求

| 需求 | 决策 |
|---|---|
| Box 是否多选 | 是，一个收藏项可属于多个 Box |
| 状态数量 | 四种：未看、进行中、已看、归档 |
| 微信公众号处理 | 第一版作为特殊网页链接，不承诺全文抓取 |
| Inbox | 必须做，所有新收藏默认进入 Inbox |

### 3.2 核心用户场景

#### 场景 1：快速收藏网页

```text
用户复制一个网页链接
打开 uniHub 收藏页
粘贴链接
点击收藏
收藏项立即出现在 Inbox
稍后自动补全标题、描述、封面和网站信息
```

#### 场景 2：收藏视频

```text
用户粘贴 B 站 / YouTube 链接
系统识别为 video
sourcePlatform = bilibili / youtube
status = unread
isInInbox = true
用户之后将其加入 Box：AI、视频、待学习
```

#### 场景 3：收藏微信公众号文章

```text
用户粘贴 mp.weixin.qq.com 链接
系统识别 sourcePlatform = wechat
mediaType = article
如果 metadata 抓取失败，仍保留链接
用户可以手动补标题、公众号名、摘要
```

#### 场景 4：整理 Inbox

```text
用户打开 Inbox
批量查看未整理收藏
给收藏项加入 Box
修改状态
添加标签
移出 Inbox
```

#### 场景 5：消费内容

```text
用户打开收藏项原链接
系统记录 lastOpenedAt
如果状态是 unread，可自动转为 inProgress
用户看完后标记为 done
不再需要时归档
```

---

## 4. 产品范围

### 4.1 MVP 必须做

```text
1. 收藏模块入口
2. URL 快速收藏
3. Inbox 视图
4. SavedItem 数据表
5. CollectionBox 数据表
6. SavedItemBox 多对多关系
7. EnrichmentJob 本地任务表
8. 四种状态：未看 / 进行中 / 已看 / 归档
9. Box 多选
10. 来源平台识别
11. 媒介类型识别
12. 基础 metadata 抓取：title / description / og:image / favicon
13. metadata 抓取异步化
14. 抓取状态展示：pending / running / success / failed
15. 按 Inbox / Box / 状态 / 来源平台 / 媒介类型筛选
16. 打开原链接
17. 记录 lastOpenedAt
```

### 4.2 MVP 暂不做

```text
1. 不做独立远程后端
2. 不做浏览器插件
3. 不做账号系统
4. 不做多设备同步
5. 不做网页全文快照
6. 不做网页截图 / PDF 快照
7. 不做视频下载
8. 不做微信公众号全文抓取
9. 不做 AI 摘要
10. 不做 AI 自动标签
11. 不做 RSS 定时抓取
12. 不做复杂批量导入
13. 不做全文索引
```

---

## 5. 核心概念

### 5.1 SavedItem：收藏项

收藏项是外部内容在 uniHub 中的记录。它可以是网页、文章、视频、公众号文章、GitHub 仓库、PDF、图片、音频或普通链接。

### 5.2 CollectionBox：收藏盒

Box 是长期组织容器。一个收藏项可以属于多个 Box。

例如：

```text
一个 B 站 AI 视频
→ Box: AI
→ Box: 视频
→ Box: 待学习
```

### 5.3 Inbox：待整理区

Inbox 不是普通 Box，而是工作流状态。

建议使用字段：

```dart
bool isInInbox;
```

语义：

```text
Inbox = 待整理
Box = 分类归属
Status = 消费进度
```

新收藏默认：

```text
isInInbox = true
status = unread
boxIds = []
```

### 5.4 ConsumptionStatus：消费状态

```text
unread      未看
inProgress 进行中
done        已看
archived    归档
```

### 5.5 SourcePlatform：来源平台

```text
web / wechat / bilibili / youtube / github / zhihu / xiaohongshu / twitter / douban / pdf / localFile / unknown
```

### 5.6 MediaType：媒介类型

```text
article / video / webpage / image / pdf / audio / post / repository / document / unknown
```

---

## 6. 信息架构

### 6.1 收藏首页

```text
收藏

[ 粘贴链接，快速收藏...                         收藏 ]

系统视图：
[ Inbox ] [ 全部 ] [ 未看 ] [ 进行中 ] [ 已看 ] [ 归档 ]

Box：
[ AI ] [ 视频 ] [ 论文 ] [ 产品 ] [ 设计 ] [ + 新建 Box ]

筛选：
来源平台：全部 / 微信公众号 / B站 / YouTube / GitHub / 网页
媒介类型：全部 / 文章 / 视频 / PDF / 图片
排序：最近收藏 / 最近打开 / 标题
```

### 6.2 收藏卡片

卡片信息：

```text
封面 / favicon
标题
描述
来源平台
媒介类型
状态
Box chips
添加时间
抓取状态
打开原文按钮
更多菜单
```

### 6.3 收藏详情面板

MVP 可做轻量详情面板，不必使用复杂编辑器。

详情内容：

```text
标题
封面
原始链接
标准化链接
描述
来源平台
媒介类型
状态
Box 多选
是否在 Inbox
打开原文
抓取状态
抓取失败原因
重新抓取
转为想法
转为任务
```

---

## 7. 技术架构总览

### 7.1 核心结论

收藏模块不先做独立远程后端，但必须从第一版开始按“本地后端化架构”实现。

```text
Flutter UI
  ↓
CollectionCaptureService
  ↓
CollectionsRepository
  ↓
Drift SQLite

异步处理：
EnrichmentJobService
  ↓
PlatformAdapter
  ↓
MetadataProvider
  ↓
更新 SavedItem
```

### 7.2 为什么不直接做独立后端

MVP 不需要远程后端，因为：

```text
1. 当前应用是本地优先工具
2. URL 保存、Box、状态、筛选都可以本地完成
3. Drift SQLite 足够支撑第一版数据量
4. 远程后端会引入账号、同步、部署、API、安全等额外复杂度
```

但必须预留后端抽离能力，因为未来这些能力倾向需要后端：

```text
1. 浏览器插件一键收藏
2. 多设备同步
3. 网页快照 / 截图 / PDF 归档
4. 视频 metadata 深度解析
5. 公众号正文抓取
6. AI 摘要 / AI 标签
7. RSS 定时抓取
```

---

## 8. 推荐目录结构

```text
lib/src/plugins/collections/
├── collections_plugin.dart
├── data/
│   ├── tables/
│   │   ├── saved_items_table.dart
│   │   ├── collection_boxes_table.dart
│   │   ├── saved_item_boxes_table.dart
│   │   └── enrichment_jobs_table.dart
│   ├── saved_items_dao.dart
│   ├── collection_boxes_dao.dart
│   ├── enrichment_jobs_dao.dart
│   └── collections_repository.dart
├── domain/
│   ├── collection_models.dart
│   ├── media_type.dart
│   ├── source_platform.dart
│   ├── consumption_status.dart
│   ├── enrichment_status.dart
│   ├── url_normalizer.dart
│   └── platform_detector.dart
├── services/
│   ├── collection_capture_service.dart
│   ├── enrichment_job_service.dart
│   ├── metadata_provider.dart
│   ├── local_metadata_provider.dart
│   └── platform_adapters/
│       ├── platform_adapter.dart
│       ├── web_page_adapter.dart
│       ├── wechat_article_adapter.dart
│       ├── bilibili_adapter.dart
│       ├── youtube_adapter.dart
│       └── github_adapter.dart
├── providers/
│   └── collections_providers.dart
└── ui/
    ├── collections_page.dart
    ├── layouts/
    │   ├── collections_desktop_layout.dart
    │   └── collections_mobile_layout.dart
    └── widgets/
        ├── collection_capture_bar.dart
        ├── saved_item_card.dart
        ├── collection_box_bar.dart
        ├── collection_filter_bar.dart
        └── saved_item_detail_panel.dart
```

---

## 9. 数据库 Schema

### 9.1 saved_items

```dart
class SavedItems extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get originalUrl => text()();
  TextColumn get normalizedUrl => text().unique()();

  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get description => text().nullable()();
  TextColumn get author => text().nullable()();
  TextColumn get siteName => text().nullable()();
  TextColumn get coverImage => text().nullable()();
  TextColumn get favicon => text().nullable()();

  TextColumn get mediaType => text().withDefault(const Constant('unknown'))();
  TextColumn get sourcePlatform => text().withDefault(const Constant('unknown'))();

  TextColumn get status => text().withDefault(const Constant('unread'))();
  BoolColumn get isInInbox => boolean().withDefault(const Constant(true))();

  TextColumn get enrichmentStatus =>
      text().withDefault(const Constant('pending'))();

  TextColumn get extractedText => text().nullable()();
  TextColumn get summary => text().nullable()();
  TextColumn get metadataJson => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get lastOpenedAt => dateTime().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get archivedAt => dateTime().nullable()();
}
```

建议索引：

```text
normalizedUrl unique
status
isInInbox
sourcePlatform
mediaType
createdAt
updatedAt
```

### 9.2 collection_boxes

```dart
class CollectionBoxes extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get icon => text().nullable()();
  TextColumn get color => text().nullable()();

  BoolColumn get isSystem => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}
```

### 9.3 saved_item_boxes

```dart
class SavedItemBoxes extends Table {
  IntColumn get itemId => integer().references(SavedItems, #id)();
  IntColumn get boxId => integer().references(CollectionBoxes, #id)();

  DateTimeColumn get addedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {itemId, boxId};
}
```

### 9.4 enrichment_jobs

```dart
class EnrichmentJobs extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get itemId => integer().references(SavedItems, #id)();

  TextColumn get jobType => text()();
  TextColumn get status => text().withDefault(const Constant('pending'))();

  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();

  DateTimeColumn get nextRunAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}
```

第一版 jobType：

```text
fetchMetadata
```

后续可扩展：

```text
extractText
generateSummary
suggestTags
snapshotPage
fetchVideoMetadata
```

---

## 10. 枚举定义

### 10.1 ConsumptionStatus

```dart
enum ConsumptionStatus {
  unread,
  inProgress,
  done,
  archived,
}

extension ConsumptionStatusLabel on ConsumptionStatus {
  String get label => switch (this) {
    ConsumptionStatus.unread => '未看',
    ConsumptionStatus.inProgress => '进行中',
    ConsumptionStatus.done => '已看',
    ConsumptionStatus.archived => '归档',
  };
}
```

### 10.2 SourcePlatform

```dart
enum SourcePlatform {
  web,
  wechat,
  bilibili,
  youtube,
  github,
  zhihu,
  xiaohongshu,
  twitter,
  douban,
  pdf,
  localFile,
  unknown,
}
```

### 10.3 MediaType

```dart
enum MediaType {
  article,
  video,
  webpage,
  image,
  pdf,
  audio,
  post,
  repository,
  document,
  unknown,
}
```

### 10.4 EnrichmentStatus

```dart
enum EnrichmentStatus {
  pending,
  running,
  success,
  failed,
}
```

---

## 11. 核心服务

### 11.1 CollectionCaptureService

收藏入口服务。UI 只调用它。

职责：

```text
1. 接收用户输入 URL
2. 规范化 URL
3. 去重
4. 规则识别平台和媒介类型
5. 创建 SavedItem
6. 创建 enrichment job
7. 快速返回
```

关键约束：

```text
captureUrl 不抓 metadata。
captureUrl 不等待网络。
captureUrl 必须快速返回。
```

### 11.2 UrlNormalizer

用于去重和标准化 URL。

第一版规则：

```text
1. trim
2. 补全 scheme
3. 移除 fragment
4. 移除常见 tracking 参数
5. 保留必要 query 参数
```

### 11.3 PlatformDetector

纯规则识别，必须快。

规则：

```text
mp.weixin.qq.com -> wechat/article
bilibili.com 或 b23.tv -> bilibili/video
youtube.com 或 youtu.be -> youtube/video
github.com -> github/repository
其它 -> web/webpage
```

### 11.4 EnrichmentJobService

本地后台任务服务。

职责：

```text
1. 创建 metadata 抓取任务
2. 查询 pending job
3. 执行 job
4. 失败重试
5. 更新 SavedItem metadata
6. 更新 enrichmentStatus
```

执行策略：

```text
应用启动后 runPendingJobs
用户保存 URL 后触发 runPendingJobs
每次最多处理 3 个 pending jobs
单个请求 3-5 秒 timeout
失败最多重试 3 次
```

失败回退：

```text
第 1 次失败：30 秒后重试
第 2 次失败：2 分钟后重试
第 3 次失败：标记 failed
```

### 11.5 MetadataProvider

为了未来切换远程后端，应定义抽象接口：

```dart
abstract interface class MetadataProvider {
  Future<MetadataResult> fetchMetadata(String url);
}
```

本地实现：

```dart
class LocalMetadataProvider implements MetadataProvider {
  @override
  Future<MetadataResult> fetchMetadata(String url) async {
    // HTTP GET
    // parse HTML title
    // parse og:title / og:description / og:image
    // parse favicon
  }
}
```

未来远程实现：

```dart
class RemoteMetadataProvider implements MetadataProvider {
  final ApiClient client;

  @override
  Future<MetadataResult> fetchMetadata(String url) {
    return client.post('/metadata/fetch', {'url': url});
  }
}
```

---

## 12. Job 执行流程

### 12.1 正常流程

```text
runPendingJobs()
→ 查询 status = pending 且 nextRunAt <= now 的 jobs
→ 每次最多处理 N 个，比如 3 个
→ job.status = running
→ 读取 SavedItem
→ 根据 sourcePlatform 选择 adapter
→ adapter.fetchMetadata(url)
→ update SavedItem metadata
→ job.status = success
→ item.enrichmentStatus = success
```

### 12.2 失败流程

```text
catch error
→ attempts += 1
→ lastError = error
→ attempts < 3 ? status = pending, nextRunAt = now + backoff
→ attempts >= 3 ? status = failed
→ item.enrichmentStatus = failed
```

---

## 13. Repository 需求

### 13.1 CollectionsRepository

需要支持：

```dart
class CollectionsRepository {
  Future<SavedItem?> findByNormalizedUrl(String normalizedUrl);

  Future<SavedItem> createSavedItem(...);

  Future<void> updateMetadata(
    int itemId, {
    String? title,
    String? description,
    String? author,
    String? siteName,
    String? coverImage,
    String? favicon,
    String? metadataJson,
    required EnrichmentStatus enrichmentStatus,
  });

  Future<void> updateStatus(
    int itemId,
    ConsumptionStatus status,
  );

  Future<void> updateInboxState(
    int itemId,
    bool isInInbox,
  );

  Future<void> setItemBoxes(
    int itemId,
    Set<int> boxIds,
  );

  Future<List<SavedItemView>> queryItems({
    required CollectionView view,
    ConsumptionStatus? status,
    SourcePlatform? platform,
    MediaType? mediaType,
    Set<int> boxIds = const {},
    String query = '',
  });
}
```

### 13.2 Box 多选规则

MVP 采用 OR 模式：

```text
选中多个 Box 时，属于任意一个选中 Box 即可显示。
```

后续可加入 AND 模式。

---

## 14. Provider 设计

### 14.1 Data Providers

```dart
final savedItemsDaoProvider = Provider<SavedItemsDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return SavedItemsDao(db);
});

final collectionBoxesDaoProvider = Provider<CollectionBoxesDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return CollectionBoxesDao(db);
});

final enrichmentJobsDaoProvider = Provider<EnrichmentJobsDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return EnrichmentJobsDao(db);
});

final collectionsRepositoryProvider =
    Provider<CollectionsRepository>((ref) {
  return CollectionsRepository(
    savedItemsDao: ref.watch(savedItemsDaoProvider),
    boxesDao: ref.watch(collectionBoxesDaoProvider),
    jobsDao: ref.watch(enrichmentJobsDaoProvider),
  );
});
```

### 14.2 Service Providers

```dart
final urlNormalizerProvider = Provider<UrlNormalizer>((ref) {
  return UrlNormalizer();
});

final platformDetectorProvider = Provider<PlatformDetector>((ref) {
  return PlatformDetector();
});

final metadataProviderProvider = Provider<MetadataProvider>((ref) {
  return LocalMetadataProvider();
});

final enrichmentJobServiceProvider =
    Provider<EnrichmentJobService>((ref) {
  return EnrichmentJobService(
    repository: ref.watch(collectionsRepositoryProvider),
    metadataProvider: ref.watch(metadataProviderProvider),
  );
});

final collectionCaptureServiceProvider =
    Provider<CollectionCaptureService>((ref) {
  return CollectionCaptureService(
    repository: ref.watch(collectionsRepositoryProvider),
    urlNormalizer: ref.watch(urlNormalizerProvider),
    platformDetector: ref.watch(platformDetectorProvider),
    enrichmentJobService: ref.watch(enrichmentJobServiceProvider),
  );
});
```

### 14.3 UI State Providers

```dart
final collectionViewProvider = StateProvider<CollectionView>((ref) {
  return CollectionView.inbox;
});

final collectionStatusFilterProvider =
    StateProvider<ConsumptionStatus?>((ref) => null);

final collectionPlatformFilterProvider =
    StateProvider<SourcePlatform?>((ref) => null);

final collectionMediaTypeFilterProvider =
    StateProvider<MediaType?>((ref) => null);

final selectedBoxIdsProvider = StateProvider<Set<int>>((ref) {
  return const {};
});

final collectionSearchQueryProvider = StateProvider<String>((ref) => '');
```

---

## 15. 查询规则

### 15.1 Inbox

```sql
WHERE is_in_inbox = true
AND archived_at IS NULL
```

### 15.2 全部

```sql
WHERE archived_at IS NULL
```

### 15.3 未看

```sql
WHERE status = 'unread'
AND archived_at IS NULL
```

### 15.4 进行中

```sql
WHERE status = 'inProgress'
AND archived_at IS NULL
```

### 15.5 已看

```sql
WHERE status = 'done'
AND archived_at IS NULL
```

### 15.6 归档

```sql
WHERE status = 'archived'
OR archived_at IS NOT NULL
```

### 15.7 Box 视图

```sql
JOIN saved_item_boxes
WHERE saved_item_boxes.box_id IN (...)
```

MVP 使用 OR 筛选。

---

## 16. 性能与速度要求

### 16.1 用户感知性能

| 操作 | 目标 |
|---|---:|
| 点击收藏后本地创建记录 | 100ms 内 |
| 收藏项出现在 Inbox | 立即 |
| URL 平台识别 | 5ms 内 |
| metadata 请求超时 | 3-5 秒 |
| 列表筛选 | 100ms 内 |
| 抓取失败 | 不影响收藏项创建 |

### 16.2 实现约束

```text
1. UI 不直接抓 metadata
2. Widget build 不执行网络请求
3. 保存按钮不 await metadata
4. metadata 抓取必须异步
5. 失败必须可重试
6. 失败不能导致收藏项丢失
```

---

## 17. 是否需要 Isolate

MVP 可以先不使用 isolate，但架构要允许迁移。

| 任务 | 是否需要 isolate |
|---|---:|
| URL pattern 识别 | 不需要 |
| SQLite 插入 | 不需要 |
| 单页 metadata 抓取 | 暂时不需要 |
| HTML 大文本解析 | 可能需要 |
| 批量导入几百条链接 | 需要 |
| 全文索引构建 | 需要 |
| AI 摘要 | 不在本地做，后端 / 云 API 更合适 |

---

## 18. 未来远程后端抽离点

未来需要独立后端时，优先抽离：

```text
1. MetadataProvider
2. EnrichmentJobService
3. PlatformAdapter
4. AI summary / AI tagging
5. Snapshot / screenshot service
```

本地接口应保持稳定：

```dart
abstract interface class MetadataProvider {
  Future<MetadataResult> fetchMetadata(String url);
}
```

切远程时只替换实现，不改 UI。

---

## 19. 验收标准

### AC-1：快速收藏

```text
Given 用户输入一个 URL
When 点击收藏
Then 100ms 左右创建 SavedItem
And item 出现在 Inbox
And enrichmentStatus = pending
And 不等待 metadata 抓取完成
```

### AC-2：平台识别

```text
Given URL 是 mp.weixin.qq.com
Then sourcePlatform = wechat
And mediaType = article

Given URL 是 bilibili.com 或 b23.tv
Then sourcePlatform = bilibili
And mediaType = video

Given URL 是 youtube.com 或 youtu.be
Then sourcePlatform = youtube
And mediaType = video

Given URL 是 github.com
Then sourcePlatform = github
And mediaType = repository
```

### AC-3：去重

```text
Given 已存在 normalizedUrl 相同的收藏项
When 再次收藏同一 URL
Then 不创建重复 SavedItem
And 返回 duplicate result
```

### AC-4：metadata 增强

```text
Given SavedItem enrichmentStatus = pending
When EnrichmentJobService 执行 fetchMetadata
Then 抓取成功后更新 title / description / coverImage / favicon
And enrichmentStatus = success
```

### AC-5：metadata 失败

```text
Given metadata 请求失败
When attempts < 3
Then job 回到 pending
And nextRunAt 设置为未来时间

Given attempts >= 3
Then job.status = failed
And item.enrichmentStatus = failed
And 收藏项仍保留
```

### AC-6：Box 多选

```text
Given 一个收藏项
When 用户选择多个 Box
Then saved_item_boxes 中存在多条关系
And 收藏项可以在任意相关 Box 视图中出现
```

### AC-7：Inbox

```text
Given 用户新收藏一个 URL
Then isInInbox = true

Given 用户将收藏项加入普通 Box
Then MVP 默认可将 isInInbox 改为 false
```

### AC-8：状态切换

```text
Given 收藏项状态是 unread
When 用户标记进行中
Then status = inProgress

Given 收藏项状态是 inProgress
When 用户标记已看
Then status = done
And completedAt != null

Given 用户归档收藏项
Then status = archived
And archivedAt != null
```

---

## 20. 单步任务拆分

### Leaf 0：收藏模块技术决策文档

```text
只执行 Leaf 0：新增收藏模块技术决策文档，不改代码。

新增：
docs/collections-mvp-architecture.md

内容包含：
1. 收藏模块定位
2. 本地后端化架构
3. 不立即做远程后端的原因
4. 未来后端抽离点
5. MVP 范围
6. 非目标
7. 性能目标

完成后运行：
flutter analyze
```

### Leaf 1：新增 collections plugin scaffold

```text
只执行 Leaf 1：新增 collections 插件目录和插件注册骨架。

新增：
lib/src/plugins/collections/
lib/src/plugins/collections/collections_plugin.dart
lib/src/plugins/collections/AGENTS.md

要求：
1. 参考 thoughts plugin 结构
2. 注册插件基本信息
3. 暂不加 UI
4. 暂不加数据库表

完成后运行：
flutter analyze
```

### Leaf 2：新增 domain 枚举与模型

```text
只执行 Leaf 2：新增收藏模块 domain 枚举与基础模型。

新增：
lib/src/plugins/collections/domain/media_type.dart
lib/src/plugins/collections/domain/source_platform.dart
lib/src/plugins/collections/domain/consumption_status.dart
lib/src/plugins/collections/domain/enrichment_status.dart
lib/src/plugins/collections/domain/collection_models.dart

实现：
1. MediaType
2. SourcePlatform
3. ConsumptionStatus
4. EnrichmentStatus
5. PlatformDetection
6. CaptureResult

完成后运行：
flutter analyze
```

### Leaf 3：新增 Drift 表

```text
只执行 Leaf 3：新增收藏模块 Drift 表。

新增：
lib/src/plugins/collections/data/tables/saved_items_table.dart
lib/src/plugins/collections/data/tables/collection_boxes_table.dart
lib/src/plugins/collections/data/tables/saved_item_boxes_table.dart
lib/src/plugins/collections/data/tables/enrichment_jobs_table.dart

要求：
1. saved_items 按 PRD 字段实现
2. collection_boxes 按 PRD 字段实现
3. saved_item_boxes 使用 itemId + boxId 复合主键
4. enrichment_jobs 按 PRD 字段实现
5. collections_plugin 注册这些 tables
6. 运行 build_runner 生成 drift 代码

完成后运行：
dart run build_runner build --delete-conflicting-outputs
flutter analyze
```

### Leaf 4：新增 DAO 和 Repository

```text
只执行 Leaf 4：新增 DAO 和 Repository，不做 UI。

新增：
lib/src/plugins/collections/data/saved_items_dao.dart
lib/src/plugins/collections/data/collection_boxes_dao.dart
lib/src/plugins/collections/data/enrichment_jobs_dao.dart
lib/src/plugins/collections/data/collections_repository.dart

实现：
1. findByNormalizedUrl
2. createSavedItem
3. updateMetadata
4. updateStatus
5. updateInboxState
6. setItemBoxes
7. queryItems
8. enqueue / update enrichment job 基础方法

完成后运行：
flutter analyze
```

### Leaf 5：新增 UrlNormalizer 和 PlatformDetector

```text
只执行 Leaf 5：新增 URL 规范化和平台识别逻辑。

新增：
lib/src/plugins/collections/domain/url_normalizer.dart
lib/src/plugins/collections/domain/platform_detector.dart

要求：
UrlNormalizer:
1. trim
2. 补 scheme
3. 移除 fragment
4. 移除 utm / spm / from / share_source 等 tracking 参数

PlatformDetector:
1. mp.weixin.qq.com -> wechat/article
2. bilibili.com 或 b23.tv -> bilibili/video
3. youtube.com 或 youtu.be -> youtube/video
4. github.com -> github/repository
5. 其它 -> web/webpage

新增测试：
test/plugins/collections/domain/url_normalizer_test.dart
test/plugins/collections/domain/platform_detector_test.dart

完成后运行：
flutter analyze
flutter test test/plugins/collections/domain/
```

### Leaf 6：新增 CollectionCaptureService

```text
只执行 Leaf 6：新增快速收藏服务，不做 UI。

新增：
lib/src/plugins/collections/services/collection_capture_service.dart

要求：
1. captureUrl(input)
2. normalize URL
3. 查重
4. detect platform/mediaType
5. create SavedItem
6. isInInbox = true
7. status = unread
8. enrichmentStatus = pending
9. enqueue fetchMetadata job
10. 不抓 metadata
11. 不等待网络

完成后运行：
flutter analyze
```

### Leaf 7：新增 MetadataProvider 和 LocalMetadataProvider

```text
只执行 Leaf 7：新增 metadata 抓取抽象和本地实现。

新增：
lib/src/plugins/collections/services/metadata_provider.dart
lib/src/plugins/collections/services/local_metadata_provider.dart

要求：
1. 定义 MetadataProvider interface
2. 定义 MetadataResult
3. LocalMetadataProvider 支持 HTTP GET + timeout
4. 解析 title
5. 解析 og:title
6. 解析 og:description
7. 解析 og:image
8. 解析 favicon
9. 失败抛出明确异常

如果当前项目没有 http/html 解析依赖：
1. 添加必要依赖
2. 保持最小实现

完成后运行：
flutter analyze
```

### Leaf 8：新增 EnrichmentJobService

```text
只执行 Leaf 8：新增 enrichment job 执行服务。

新增：
lib/src/plugins/collections/services/enrichment_job_service.dart

要求：
1. enqueueFetchMetadata(itemId)
2. runPendingJobs()
3. retryFailedJob(jobId)
4. 每轮最多处理 3 个 job
5. running / success / failed 状态更新
6. attempts + lastError
7. 失败 backoff
8. 成功后更新 SavedItem metadata 和 enrichmentStatus

完成后运行：
flutter analyze
```

### Leaf 9：新增 collections providers

```text
只执行 Leaf 9：新增收藏模块 providers。

新增：
lib/src/plugins/collections/providers/collections_providers.dart

实现：
1. dao providers
2. repository provider
3. urlNormalizerProvider
4. platformDetectorProvider
5. metadataProviderProvider
6. enrichmentJobServiceProvider
7. collectionCaptureServiceProvider
8. collectionViewProvider
9. status/platform/mediaType/box/search filters
10. savedItemsListProvider

完成后运行：
flutter analyze
```

### Leaf 10：新增收藏首页 UI shell

```text
只执行 Leaf 10：新增收藏首页 UI shell，不接真实数据也可以。

新增：
lib/src/plugins/collections/ui/collections_page.dart
lib/src/plugins/collections/ui/layouts/collections_desktop_layout.dart
lib/src/plugins/collections/ui/widgets/collection_capture_bar.dart
lib/src/plugins/collections/ui/widgets/collection_filter_bar.dart
lib/src/plugins/collections/ui/widgets/saved_item_card.dart

要求：
1. 页面标题：收藏
2. 顶部 URL 输入框
3. 系统视图：Inbox / 全部 / 未看 / 进行中 / 已看 / 归档
4. Box 区域占位
5. 来源平台筛选占位
6. 收藏卡片占位
7. 不做复杂详情页

完成后运行：
flutter analyze
```

### Leaf 11：接入快速收藏 UI

```text
只执行 Leaf 11：让收藏首页 URL 输入框接入 CollectionCaptureService。

修改：
collections_page / collection_capture_bar / providers

要求：
1. 输入 URL
2. 点击收藏
3. 调用 captureUrl
4. 立即刷新 Inbox 列表
5. duplicate 时提示“已收藏”
6. created 时提示“已加入 Inbox”
7. 不等待 metadata 抓取完成

完成后运行：
flutter analyze
```

### Leaf 12：接入真实列表查询

```text
只执行 Leaf 12：让收藏首页展示真实 SavedItem 列表。

要求：
1. savedItemsListProvider 驱动列表
2. 展示 title
3. 展示 description
4. 展示 sourcePlatform
5. 展示 mediaType
6. 展示 status
7. 展示 enrichmentStatus
8. pending 显示“正在抓取”
9. failed 显示“抓取失败”

完成后运行：
flutter analyze
```

### Leaf 13：接入 EnrichmentJobService 自动运行

```text
只执行 Leaf 13：让 metadata job 在合适时机自动运行。

要求：
1. 应用启动或收藏页进入时 runPendingJobs
2. captureUrl 成功后触发 runPendingJobs
3. job 成功后刷新列表
4. job 失败后显示 failed 状态
5. 不阻塞 UI

完成后运行：
flutter analyze
```

### Leaf 14：Box 管理 MVP

```text
只执行 Leaf 14：实现 Box 创建和收藏项加入多个 Box。

要求：
1. 新建 Box
2. 收藏项详情/菜单中选择多个 Box
3. setItemBoxes
4. Box 筛选 OR 模式
5. 加入普通 Box 后默认 isInInbox = false

完成后运行：
flutter analyze
```

### Leaf 15：状态切换 MVP

```text
只执行 Leaf 15：实现收藏项四态切换。

要求：
1. unread
2. inProgress
3. done
4. archived
5. done 设置 completedAt
6. archived 设置 archivedAt
7. UI 可切换状态
8. 筛选视图可正确显示

完成后运行：
flutter analyze
```

### Leaf 16：打开原链接

```text
只执行 Leaf 16：实现打开原链接和 lastOpenedAt。

要求：
1. 收藏卡片提供打开原链接按钮
2. 使用 url_launcher
3. 打开后更新 lastOpenedAt
4. 如果 status = unread，可以转为 inProgress
5. 不做内置浏览器

完成后运行：
flutter analyze
```

### Leaf 17：测试

```text
只执行 Leaf 17：补收藏模块核心测试。

测试：
1. UrlNormalizer
2. PlatformDetector
3. CollectionCaptureService captureUrl 创建 item + job
4. duplicate URL 不重复创建
5. EnrichmentJobService 成功更新 metadata
6. EnrichmentJobService 失败重试
7. Box 多选关系
8. 状态切换

完成后运行：
flutter analyze
flutter test test/plugins/collections/
```

---

## 21. 推荐执行顺序

```text
Leaf 0  技术决策文档
Leaf 1  collections 插件骨架
Leaf 2  domain 枚举与模型
Leaf 3  Drift 表
Leaf 4  DAO + Repository
Leaf 5  UrlNormalizer + PlatformDetector
Leaf 6  CollectionCaptureService
Leaf 7  MetadataProvider
Leaf 8  EnrichmentJobService
Leaf 9  Providers
Leaf 10 收藏首页 UI shell
Leaf 11 快速收藏 UI
Leaf 12 真实列表
Leaf 13 job 自动运行
Leaf 14 Box 管理
Leaf 15 状态切换
Leaf 16 打开原链接
Leaf 17 测试
```

---

## 22. 最小首批执行包

为了降低风险，第一轮建议只做：

```text
Leaf 0
Leaf 1
Leaf 2
Leaf 3
Leaf 4
Leaf 5
Leaf 6
```

第一轮验收目标：

```text
1. 数据表存在
2. Repository 可创建 SavedItem
3. URL 可 normalize
4. 平台可识别
5. captureUrl 可快速创建收藏项
6. enrichment job 可入队
7. 不涉及 UI
```

这一步完成后，再进入 UI 与 metadata 抓取。
