# 内容收藏后台爬取链路稳定性修复

## 背景

当前内容收藏模块已经具备基本后台爬取链路：

```
用户输入 URL
→ CollectionCaptureService.captureUrl
→ UrlNormalizer.normalize
→ PlatformDetector.detect
→ CollectionsRepository.createSavedItem
→ enqueueEnrichmentJob
→ EnrichmentJobService.runPendingJobs
→ LocalMetadataProvider.fetchMetadata
→ HtmlMetadataParser.parse
→ CollectionsRepository.updateMetadata
→ WebsiteLogoCacheService.ensureLogoCached
→ websiteLogoForUrlProvider
→ WebsiteLogo 渲染本地 logo
```

## 已完成（Phase 1）

| # | 问题 | 文件 | Commit |
|---|------|------|--------|
| P0-1 | EnrichmentJobService 日志 `$job.attempts` 插值 bug | `enrichment_job_service.dart` | e11c36a |
| P0-2 | WebsiteLogoCacheService content-type 校验不严 | `website_logo_cache_service.dart` | e11c36a |
| P0-3 | appStoragePathsProvider requireValue 同步风险 | `collections_providers.dart`, `storage_cleanup_providers.dart` | e11c36a |
| P0-2b | WebsiteLogo 日志去重集合混用 | `website_logo.dart` | d506b7e |
| P0-4 | favicon scoring SVG 分数偏低 | `html_metadata_parser.dart` | d506b7e |
| P0-5 | `_readBody` 截断时 total 统计不完整 | `local_metadata_provider.dart` | d506b7e |

### P0-1: EnrichmentJobService 日志插值错误

新增 `static const int _maxAttempts = 3`，修复 `$job.attempts` → `$_maxAttempts`。
替换所有硬编码 `3`。

### P0-2: WebsiteLogoCacheService content-type 校验

在 `_tryFetchCandidate` 中新增白名单校验：只允许 `image/*` 和 `application/octet-stream`（仅 `.ico`）类型。

### P0-3: appStoragePathsProvider FutureProvider 安全

`websiteLogoCacheServiceProvider` 改为 `FutureProvider`，消费者通过 `.valueOrNull` / `.future` 安全访问。

### P0-4: favicon scoring 调整

| 类型 | 旧分数 | 新分数 |
|------|--------|--------|
| apple-touch-icon | 100 | 100 |
| .png | 80 | 90 |
| .webp | 75 | 85 |
| .svg | 30 | 80 |
| .ico | 40 | 70 |
| .jpg / .jpeg | 60 | 60 |
| .gif | 50 | 50 |

### P0-5: _readBody total 修正

截断分支添加 `total += remaining` 和 truncated 日志。

## 已完成（Phase 2 — 平台化爬取架构）

| # | 文件 | Commit |
|---|------|--------|
| Adapter 接口 | `platform_metadata_adapter.dart` | dfd9906 |
| Provider Router | `platform_aware_metadata_provider.dart` | dfd9906 |
| Bilibili | `platform_adapters/bilibili_metadata_adapter.dart` | dfd9906 |
| Weibo | `platform_adapters/weibo_metadata_adapter.dart` | dfd9906 |
| GitHub | `platform_adapters/github_metadata_adapter.dart` | dfd9906 |
| Provider wiring | `collections_providers.dart` | dfd9906 |

### 架构

```
metadataProviderProvider
  └─ PlatformAwareMetadataProvider
       ├─ BilibiliMetadataAdapter (bilibili.com, b23.tv)
       ├─ WeiboMetadataAdapter (weibo.com, m.weibo.cn)
       ├─ GitHubMetadataAdapter (github.com)
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

adapter 被平台限制（登录墙/412/403/429）时，返回 `PlatformAdapterResult(limited: true, reason: ...)`，包含最佳努力的 title/siteName/favicon，标记 `EnrichmentStatus.success`。避免反复 retry。

## 日志规范

所有日志使用 `CollectionDebugLogger`，格式参考：

- `metadata fetch start url=...`
- `metadata fetch response status=... contentType=... bodyLength=...`
- `logo cache start pageUrl=... siteKey=... remoteFaviconUrl=...`
- `logo candidate fetch url=...`
- `logo fetch bytesLength=... ext=...`

## 非目标

- 不做复杂全文抓取
- 不新增数据库 schema / status 字段
- 不引入浏览器内核
- 不批量刷新全部收藏
