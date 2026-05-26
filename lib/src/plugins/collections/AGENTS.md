# Collections 插件

## 模块定位

Collections 是 uniHub 的收藏插件，负责 URL 快速收藏、本地持久化、基础元数据抓取、Inbox/Box/状态/来源/媒介筛选。

## 分层约定

```text
collections/
├── domain/      # 枚举、轻量模型、URL normalizer、platform detector
├── data/        # DAO + Repository，只通过 AppDatabase 访问 Drift
├── services/    # 捕获、元数据抓取、异步 enrichment 服务
├── application/ # Controller + ViewModel + QueueController — 用例编排与展示数据聚合
├── providers/   # Riverpod providers，UI 不直接访问 DAO/Database
└── ui/          # 页面、布局、组件
```

### application/ 层说明

`application/` 层位于 `providers/` 和 `ui/` 之间，职责是：

- **Controller** — 封装业务操作（删除/归档/状态切换/Box 管理/复制链接等），UI 不再直接调用 Repository
- **ViewModel (ListEntry)** — 聚合跨多种数据源的展示模型（item + boxes + logo + selected），消除 N+1 查询
- **QueueController** — 统一调度异步后台任务（Enrichment 队列恢复），支持启动恢复、页面进入触发、手动重试

**原则**：
- Controller 返回 `SavedItemActionResult`（含 message + undo），不直接依赖 `BuildContext`
- ViewModel 在 Provider 中批量聚合数据，不在每个 Widget 中独立查询
- QueueController 内部使用 `_isRunning` 防止并发执行

## 数据库约定

- Drift Table 放在 `lib/src/core/database/tables/`，并由 `collections_plugin.dart` 的 `tables` 声明。
- 新增/修改表时同步更新 `lib/src/core/database/app_database.dart` 的 `@DriftDatabase(tables: [...])` 与 migration。
- DAO 只做 CRUD；业务语义放在 `CollectionsRepository`。

## UI 约定

- 使用 Material 3 `ColorScheme` 与 `app_tokens.dart` 间距/圆角。
- URL 捕获、筛选、列表都通过 `providers/collections_providers.dart` 访问状态。

## Controller 模式（SavedItemActionsController）

所有收藏项的业务操作必须通过 `SavedItemActionsController` 执行，不直接在 UI 中调用 Repository。

### 可用方法

| 方法 | 用途 | 返回值 |
|------|------|--------|
| `openItem(itemId)` | 打开原网页 + 标记已打开 | `message` |
| `copyUrl(itemId)` | 复制链接到剪贴板 | `message` |
| `updateStatus(itemId, status)` | 切换消费状态 | `message` |
| `archiveItem(itemId)` | 快速归档 | `message` |
| `assignBoxes(itemId, boxIds)` | 分配收藏夹 | undo action |
| `removeFromBox(itemId, boxId)` | 从收藏夹移除 | undo action |
| `deleteItem(itemId, {mode, boxId})` | 删除收藏（单条/多Box） | undo action |
| `restoreDeletedItem(snapshot)` | 撤销删除 | `message` |
| `retryEnrichment(itemId)` | 重试元数据抓取 | `message` |

### 使用模式

```dart
// UI 中调用
final result = await ref.read(savedItemActionsControllerProvider).deleteItem(item.id);

if (context.mounted && result.message != null) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(result.message!),
      action: result.undo == null
          ? null
          : SnackBarAction(
              label: result.undo!.label,
              onPressed: () => unawaited(result.undo!.execute()),
            ),
    ),
  );
}
```

### Controller 持有 Ref

Controller 需要持有 `Ref` 来调用 `ref.invalidate()` 刷新列表和计数。这是一个可接受的架构折中——短期加快落地速度，中期可改为回调/Notifier 模式。

## ViewModel 模式（SavedItemListEntry）

列表展示数据通过 `savedItemListEntriesProvider` 聚合，而非由每个 Widget 独立查询：

```dart
class SavedItemListEntry {
  final SavedItemsTableData item;
  final List<CollectionBoxesTableData> boxes;
  final WebsiteLogoCacheEntry? logo;
  final bool selected;
}
```

**消除 N+1 查询**：
- Box 通过 `repository.getBoxIdsForItems()` 批量查询（一次查询所有 item 的 boxIds）
- Logo 通过 `logoDao.getLogosBySiteKeys()` 批量查询（一次查询所有 item 的 logo）
- `SavedItemCard` 不再 watch `websiteLogoForUrlProvider` 或 `collectionBoxesProvider`

## EnrichmentQueueController

Enrichment 队列调度统一通过 `EnrichmentQueueController`：

| 触发时机 | 位置 | 方式 |
|----------|------|------|
| App 启动 | `collections_desktop_layout.initState` | `drainPending(batchSize:5, maxBatches:3)` |
| 收藏成功 | `collection_capture_bar` | `drainPending(batchSize:5, maxBatches:3)` |
| 手动重试 | card / detail panel 的失败 chip | `retryItem(itemId)` |

`_isRunning` guard 防止并发 drain。每次 drain 完成后自动 `invalidate` 列表和 logo。

## 删除确认弹窗

删除操作使用 `DeleteConfirmDialog`（`lib/src/shared/widgets/delete_confirm_dialog.dart`），不再使用简陋的 `AlertDialog`。

### 三种弹窗模式

| 模式 | 触发条件 | 静态方法 |
|------|----------|----------|
| 单条确认 | item 属于 0-1 个收藏夹 | `showSingle()` |
| 批量确认 | 多选删除（后续支持） | `showBatch()` |
| 多收藏夹选择 | item 属于 2+ 个收藏夹 | `showMultiBox()` |

### 弹窗结构

- 红色警示图标（`delete_outline_rounded`，44×44，`errorContainer` 背景）
- 标题 + 说明（`titleLarge` bold + `bodyMedium`）
- 内容预览卡（logo + 标题 + 来源/类型/时间）
- 「以后不再提示」checkbox + "可在 设置 > 内容收藏 中重新开启" 辅助说明
- 取消（白底描边）+ 删除（红色 `colorScheme.error` 背景）按钮

### "不再提示" 偏好

- `confirmDeleteSingleItem: bool = true`
- `confirmDeleteBatchItems: bool = true`
- 存储在 `SharedPreferences`，通过 `DeleteConfirmPrefs` 读写
- Provider：`deleteConfirmPrefsProvider`（`lib/src/shared/preferences/`）

### 删除后撤销

所有删除操作后显示 5 秒 SnackBar 带「撤销」action：

| 操作 | SnackBar 文案 | 撤销行为 |
|------|--------------|----------|
| 单条删除 | `已删除「{title}」` | 重新 `createSavedItem()` 并恢复 box 关联 |
| 从收藏夹移除 | `已从「{folderName}」中移除` | 重新 `setItemBoxes(id, {..., boxId})` |

### 多收藏夹场景

当 `getBoxIdsForItem().length > 1` 时，优先展示操作选择弹窗：
- 「仅从当前收藏夹移除」→ `repository.removeItemFromBox(itemId, boxId)`
- 「删除这条收藏」→ `repository.deleteSavedItem(itemId)`

### 详细面板 Chip 展示规则（`saved_item_detail_panel.dart`）

**收藏夹区域（`_BoxSection`）**：
- 只显示当前 item 已归属的收藏夹 chip，不再展示所有可选收藏夹。
- 点击已选 chip 可移除此归属，移除后若全部清空则 `updateInboxState(true)`。
- 空态显示一个弱化 `[待整理]` chip。
- 末尾固定 `[+ 新建]`（不再显示 `+ 选择收藏夹`）。
- 使用 `LayoutBuilder` + 数量截断限制最多两行：宽度 < 260px 时最多 3 个 + `+ 新建`，≥ 260px 时最多 4 个 + `+ 新建`。

**标签区域（`_TagsSection`）**：
- 标签来源：当前 item 所属 Box 名称 + 媒体类型 + 来源平台。
- 严格去重，跳过空字符串和 `「未知」`。
- 使用 `LayoutBuilder` + 数量截断限制最多两行。
- 末尾固定 `[+ 添加标签]` 占位（功能稍后接入）。

## 调试日志系统

### CollectionDebugLogger

所有 collection 插件相关日志集中在 `lib/src/plugins/collections/services/collection_debug_logger.dart`，通过 `CollectionDebugLogger` 统一管理。

| 方法 | 前缀 | 用途 |
|------|------|------|
| `log()` | `[CollectionDebug]` | 普通信息日志 |
| `warn()` | `[CollectionWarn]` | 警告日志 |
| `error()` | `[CollectionError]` | 错误日志（带异常和堆栈）|

**开关控制**：通过环境变量 `UNIHUB_COLLECTION_DEBUG=false` 可关闭，默认开启（`defaultValue: true`）。

**启用方式（Windows PowerShell）**：
```powershell
$env:UNIHUB_COLLECTION_DEBUG='true'
flutter run -d windows
```

### 缓存清理

`WebsiteLogoCacheService.clearCache()` 统一清理网站 Logo 缓存：
- 丢弃所有 in-flight 下载
- 删除 `website_logos` 目录所有文件
- 清空 `website_logo_cache` 表
- 触发 `websiteLogoRefreshProvider` 刷新 UI
- 返回 `CacheClearResult`（删除文件数、释放空间、错误列表）

目录路径通过 `AppStoragePaths.websiteLogosDir` 注入，不再直接调用 `path_provider`。

### 存储注册

Collections 插件在 `StorageRegistry` 中注册一项可清理缓存：

| ID | 名称 | 类型 | clearable |
|---|---|---|---|
| `collections.website_logos` | 网站 Logo 缓存 | cache | ✅ |

### 日志覆盖的完整链路

```text
CollectionCaptureService.captureUrl                    → 输入/归一化/创建/入队
  └─ EnrichmentJobService.runPendingJobs / _processJob → job 生命周期、metadata 结果
       └─ LocalMetadataProvider.fetchMetadata           → 请求头/响应/favicon 候选
            └─ WebsiteLogoCacheService.ensureLogoCached → 缓存命中、候选尝试
                 └─ _tryFetchCandidate                   → 单次抓取/校验/保存
                      └─ WebsiteLogo Image.file          → UI 解码/文件缺失
```

## 平台化爬取架构（Platform Adapters）

### 架构

```
metadataProviderProvider
  └─ PlatformAwareMetadataProvider
       ├─ BilibiliMetadataAdapter (bilibili.com, b23.tv)
       │    ├─ b23.tv → follow redirect
       │    ├─ 412/403/429 → limited success（不反复 retry）
       │    └─ siteName="Bilibili", favicon fallback
       ├─ WeiboMetadataAdapter (weibo.com, m.weibo.cn)
       │    ├─ 登录墙/非2xx → limited success
       │    ├─ siteName="微博", favicon=weibo.com/favicon.ico
       │    └─ 检测 .login / 请登录 等登录墙特征
       ├─ GitHubMetadataAdapter (github.com)
       │    ├─ URL类型识别: repo/issue/pull_request/blob
       │    ├─ title 结构化: owner/repo / owner/repo#123
       │    └─ siteName="GitHub", favicon=github.com/favicon.ico
       └─ LocalMetadataProvider（通用 fallback）
```

### Adapter 接口

```dart
abstract interface class PlatformMetadataAdapter {
  bool canHandle(Uri uri);
  Future<PlatformAdapterResult> fetch(Uri uri);
}
```

### limited success 机制

Adapter 被平台限制（登录墙/412/403/429）时，返回 `PlatformAdapterResult(limited: true, reason: ...)`，包含最佳努力的 title/siteName/favicon，标记 `EnrichmentStatus.success`。

避免：
1. 反复 retry（retry 次数耗尽后 failed，用户看到失败状态）
2. 平台特殊逻辑污染 `LocalMetadataProvider`

### 日志前缀

| Adapter | 日志前缀 |
|---------|----------|
| `BilibiliMetadataAdapter` | `bilibili ...` |
| `WeiboMetadataAdapter` | `weibo ...` |
| `GitHubMetadataAdapter` | `github ...` |

## Website Logo 缓存服务

### 架构概览

```text
EnrichmentJobService._processJob()
  └─ ensureLogoCached()
       ├─ in-flight 去重（同 siteKey 并发仅一次网络请求）
       ├─ 缓存校验：_isSuccessEntryUsable(success + 未过期 + 文件存在) → 复用
       ├─                 _shouldSkipFailedRetry(failed + 冷却中 + 无新 URL + debug 关闭) → 跳过
       ├─                 否则 → 重试
       ├─ _fetchAndCache()
       │    ├─ 4 候选 URL 依次尝试
       │    │    (1) metadata 解析的 favicon URL
       │    │    (2) https://$host/favicon.ico
       │    │    (3) https://www.$host/favicon.ico
       │    │    (4) https://$host/favicon.png
       │    ├─ HTML 响应检测（反爬 / 中间页面）
       │    ├─ 协议限制：仅 http/https
       │    ├─ MIME charset 剥离 → 正确后缀
       │    ├─ SVG 可渲染（UI 侧通过 flutter_svg 的 SvgPicture.file 支持）
       │    └─ 写入 {websiteLogosDir}/{base64(siteKey)}.{ext}（路径通过 AppStoragePaths）
       └─ onLogoCached 回调 → websiteLogoRefreshProvider 递增

UI 层
  └─ websiteLogoForUrlProvider → WebsiteLogo(localPath: ...)
       ├─ .svg → SvgPicture.file (flutter_svg)
       └─ 其他 → Image.file

UI 层
  └─ websiteLogoForUrlProvider → WebsiteLogo(localPath: ...)
```

### 元数据解析架构（DOM-based）

Metadata 解析分为两层：

```text
LocalMetadataProvider.fetchMetadata(url)
  ├─ 1. HTTP GET（8s timeout，设置浏览器级 User-Agent / Accept / Accept-Language）
  ├─ 2. 非 2xx 响应 → 抛出 MetadataFetchException
  ├─ 3. 非 HTML Content-Type → 抛出 MetadataFetchException
  ├─ 4. 读取 Body（最多 1 MB）
  ├─ 5. _detectCharset() — 编码探测：Content-Type header → BOM → meta charset → meta http-equiv → UTF-8
  └─ 6. HtmlMetadataParser.parse(decodedHtml, baseUrl: url)
       ├─ _parseTitle() / _parseDescription() / _parseCoverImage()
       ├─ _parseSiteName() / _parseAuthor()
       └─ _parseFavicon() → 评分排序 + URL resolve
```

不再使用正则解析——所有 HTML 解析通过 `package:html` 的 DOM API（querySelector）进行，对属性顺序不敏感。

### favicon 候选优先级（HtmlMetadataParser._parseFavicon）

| 类型 | 分数 | 说明 |
|------|------|------|
| apple-touch-icon | 100 | 高分辨率 PNG，优先选择 |
| .png URL | 90 | 显式 PNG |
| .webp URL | 85 | WebP 格式 |
| .svg URL | 80 | SVG（flutter_svg 渲染，参见 WebsiteLogo） |
| .ico URL | 70 | 传统 ICO |
| .jpg / .jpeg URL | 60 | JPEG 格式 |
| .gif URL | 50 | GIF 格式 |
| 通用 icon link（无扩展名） | 70 | rel="icon" / "shortcut icon" 但无扩展名 |
| 其他 | 10 | 兜底 |

**强制重试**：即使有未过期 failed entry，只要 metadata 解析出新的 `remoteFaviconUrl`（如 `i0.hdslb.com/.../512.png`），`_shouldSkipFailedRetry` 返回 false，立即执行重抓。

### 多候选 favicon fallback（WebsiteLogoCacheService._fetchAndCache）

按顺序尝试 4 个候选 URL，第一个成功即返回；全部失败抛出异常：

| 优先级 | URL | 说明 |
|--------|-----|------|
| 1 | metadata 解析的 favicon URL | 从 `<link>` 标签解析的最高分候选 |
| 2 | `https://$host/favicon.ico` | 标准根路径 |
| 3 | `https://www.$host/favicon.ico` | 若 host 不以 www 开头 |
| 4 | `https://$host/favicon.png` | PNG 兜底 |

### 服务层行为

| 规则 | 说明 |
|------|------|
| 并发去重 | `_inFlight` 映射表，同 `siteKey` 并发只触发一次请求 |
| success 缓存复用 | `_isSuccessEntryUsable`：未过期 + 文件存在 → 直接返回 |
| success 文件缺失 | 视为无效，重新抓取 |
| failed 冷却跳过 | `_shouldSkipFailedRetry`：仅当**无新 `remoteFaviconUrl`** + **debug 禁用**时才跳过 |
| 新 URL 强制重试 | 即使有未过期 failed entry，只要 metadata 解析出新的 `remoteFaviconUrl` → 立即重试 |
| failed TTL | debug **10 分钟**，生产 **24 小时**（`_failedTtl`） |
| SVG 正常缓存 | `.svg` 后缀和 `image/svg+xml` 的响应正常保存为 success；UI 通过 flutter_svg 渲染 |
| failed 清理 | `markFailed` 清除 `localLogoPath` 和 `mimeType` 字段，UI 不会继续加载无效文件 |
| MIME 兼容 | `_extensionForMimeType` 先 `split(';').first` 剥离 charset，再匹配类型 |
| URL 协议 | 只允许 `http`/`https` |
| HTML 检测 | 响应 content-type 含 `text/html` 或 body 开头为 `<!doctype html` → 拒绝 |
| 内容类型白名单 | 响应必须为 `image/*` 或 `application/octet-stream`（仅 `.ico` 结尾）→ 放行；其余（`application/json`、`application/xml`、`binary/octet-stream` 等）→ 拒绝 |
| application/octet-stream | 仅当 URL 以 `.ico` 结尾时放行（部分服务器行为） |

### WebsiteLogo UI 组件

位于 `lib/src/shared/widgets/website_logo.dart`：

- 当 `localPath` 不为空且文件存在时：根据扩展名分派渲染器。
  - `.svg` → `SvgPicture.file`（flutter_svg 包），支持本地 SVG favicon 渲染。
  - 其他（`.ico`/`.png`/`.jpg`/`.webp`/`.gif`）→ `Image.file`。
- `placeholderBuilder` / `errorBuilder` 均 fallback 到 `_fallbackContainer`。
- 错误日志使用两个独立的静态 Set 去重：
  - `_reportedMissingFiles`：文件不存在 warning，同路径只打印一次
  - `_reportedDecodeFailures`：decode 失败 error（SvgPicture.file / Image.file），同路径只打印一次
- 文件缺失 warning 不会吞掉后续 decode 失败日志（使用不同的 Set）。
- 不允许 UI 层直接联网。

### 测试策略

`website_logo_cache_service_test.dart` 使用以下模式：

- **内存数据库**：`AppDatabase(NativeDatabase.memory(), registry)`
- **Mock HTTP**：手动实现 `HttpClient` 接口的子类，通过构造函数注入
- **临时目录**：`Directory.systemTemp.createTempSync()` 指定 `logosDirectory`
- **协议覆盖**：注入不同 `remoteFaviconUrl` 测试 data:/file: 协议拒绝
- **MIME 覆盖**：注入 `image/png; charset=utf-8` 验证后缀识别

### Provider 注入

`collections_providers.dart` 中：
```dart
final enrichmentJobServiceProvider = Provider<EnrichmentJobService>((ref) {
  return EnrichmentJobService(
    // FutureProvider 通过 valueOrNull 安全读取（启动未就绪时为 null）
    logoCacheService: ref.watch(websiteLogoCacheServiceProvider).valueOrNull,
    onLogoCached: () {
      ref.read(websiteLogoRefreshProvider.notifier).state++;
    },
  );
});
```

通过 `websiteLogoRefreshProvider` 计数器递增触发 UI 重新读取本地缓存 logo，不引入网络请求。
