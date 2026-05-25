# Collections 插件

## 模块定位

Collections 是 uniHub 的收藏插件，负责 URL 快速收藏、本地持久化、基础元数据抓取、Inbox/Box/状态/来源/媒介筛选。

## 分层约定

```text
collections/
├── domain/      # 枚举、轻量模型、URL normalizer、platform detector
├── data/        # DAO + Repository，只通过 AppDatabase 访问 Drift
├── services/    # 捕获、元数据抓取、异步 enrichment 服务
├── providers/   # Riverpod providers，UI 不直接访问 DAO/Database
└── ui/          # 页面、布局、组件
```

## 数据库约定

- Drift Table 放在 `lib/src/core/database/tables/`，并由 `collections_plugin.dart` 的 `tables` 声明。
- 新增/修改表时同步更新 `lib/src/core/database/app_database.dart` 的 `@DriftDatabase(tables: [...])` 与 migration。
- DAO 只做 CRUD；业务语义放在 `CollectionsRepository`。

## UI 约定

- 使用 Material 3 `ColorScheme` 与 `app_tokens.dart` 间距/圆角。
- URL 捕获、筛选、列表都通过 `providers/collections_providers.dart` 访问状态。

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

## Website Logo 缓存服务

### 架构概览

```text
EnrichmentJobService._processJob()
  └─ ensureLogoCached()
       ├─ in-flight 去重（同 siteKey 并发仅一次网络请求）
       ├─ 缓存校验：_isEntryValid(success + 未过期 + 文件存在)
       ├─ _fetchAndCache()
       │    ├─ 协议限制：仅 http/https
       │    ├─ MIME charset 剥离 → 正确后缀
       │    └─ 写入 {appCacheDir}/website_logos/{base64(siteKey)}.{ext}
       └─ onLogoCached 回调 → websiteLogoRefreshProvider 递增

UI 层
  └─ websiteLogoForUrlProvider → WebsiteLogo(localPath: ...)
```

### 服务层行为

| 规则 | 说明 |
|------|------|
| 并发去重 | `_inFlight` 映射表，同 `siteKey` 并发只触发一次 `_fetchAndCache` |
| success 缓存复用 | 未过期 + `localLogoPath` 文件存在 → 直接返回，不请求网络 |
| success 文件缺失 | 视为无效，重新抓取 |
| failed 缓存 | 24 小时过期时间内不重试，直接返回 failed entry |
| MIME 兼容 | `_extensionForMimeType` 先 `split(';').first` 剥离 charset，再匹配类型 |
| URL 协议 | 只允许 `http`/`https`，其他协议被 `_fetchAndCache` 拒绝 |

### 测试策略

`website_logo_cache_service_test.dart` 使用以下模式：

- **内存数据库**：`AppDatabase(NativeDatabase.memory(), registry)`
- **Mock HTTP**：手动实现 `HttpClient` 接口的子类，通过构造函数注入
- **临时目录**：`Directory.systemTemp.createTempSync()` 指定 `logosDirectory`
- **协议覆盖**：注入不同 `remoteFaviconUrl` 测试 data:/file: 协议拒绝
- **MIME 覆盖**：注入 `image/png; charset=utf-8` 验证后缀识别

### favicon 候选优先级

`LocalMetadataProvider._favicon` 解析全部 `<link>` 标签，按分数排序：

| 类型 | 分数 |
|------|------|
| apple-touch-icon | 100 |
| .png URL | 80 |
| .webp URL | 75 |
| .jpg / .jpeg URL | 60 |
| .gif URL | 50 |
| .ico URL | 40 |
| .svg URL | 30 |
| 通用 icon link（无扩展名） | 70 |
| 其他 | 10 |
