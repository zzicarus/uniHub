# 收藏列表 SQL 化分页查询

## 背景与目标

Collections 插件的收藏列表原先在 Dart 层全量加载后作内存过滤，存在性能瓶颈和数据加载冗余问题。本次重构将查询逻辑下推到 SQL 层，利用数据库索引实现服务端分页，同时保留全量筛选能力。

**核心目标**:
- 将所有筛选条件（view、status、platform、mediaType、box、search）在数据库侧完成
- 支持基于 `limit + offset` 的分页，只查询当前页数据 + 额外一条判断 hasMore
- Box 关系只查询当前页的 item，避免全量 item box 关系加载
- 保留与旧 `queryItems` 完全一致的语义

## 改动范围

| 文件 | 类型 | 说明 |
|------|------|------|
| `lib/src/core/database/app_database.dart` | 修改 | 迁移 v5，新增 6 个覆盖分页查询的索引 |
| `lib/src/plugins/collections/collections_plugin.dart` | 修改 | schemaVersion 4 → 5 |
| `lib/src/plugins/collections/domain/saved_items_page.dart` | 新增 | 分页响应模型 |
| `lib/src/plugins/collections/domain/saved_items_query.dart` | 新增 | 统一查询参数模型 |
| `lib/src/plugins/collections/data/saved_items_dao.dart` | 修改 | 新增 `queryItemsPage()` SQL 驱动查询 |
| `lib/src/plugins/collections/data/collections_repository.dart` | 修改 | `queryItems()` 改调用 SQL 分页，剔 Old 内存过滤 |
| `lib/src/plugins/collections/providers/collections_providers.dart` | 修改 | 新增 `savedItemsPageProvider` + 搜索防抖 |
| `test/plugins/collections/data/collections_repository_test.dart` | 修改 | 适配新 API |
| `test/plugins/collections/data/collections_repository_query_test.dart` | 新增 | Repository 层分页集成测试 |
| `test/plugins/collections/data/saved_items_dao_query_test.dart` | 新增 | DAO 层全面单元测试 |
| `test/plugins/collections/application/saved_item_actions_controller_test.dart` | 修改 | 适配新 API |

## 架构决策

### 1. Page + Query 模型分离

- **SavedItemsQuery**：封装所有查询参数（view、status、platform、mediaType、boxIds、searchQuery、sort、limit、offset），通过 `copyWith()` 支持增量修改
- **SavedItemsPage**：封装返回结果（items、boxIdsByItemId、hasMore），只包含当前页数据

### 2. 全 SQL 执行路径

DAO 层 `queryItemsPage()` 使用 Drift 的 `select()` + `where()` + `orderBy()` + `limit/offset` 组合：
- View 筛选：`switch (query.view)` → 6 种视图分发
- 附加筛选：status / platform / mediaType 用 `equals` 条件拼装
- Box 筛选：子查询 `EXISTS (SELECT 1 FROM saved_item_boxes WHERE box_id IN (...))`
- 搜索：6 列的 `LIKE %keyword%` OR 组合
- 排序：5 种排序方式（updatedDesc / createdDesc / createdAsc / titleAsc / lastOpenedDesc）

### 3. 数据库索引（迁移 v5）

为覆盖所有排序 + 筛选组合路径，创建 6 个复合索引：

| 索引 | 覆盖场景 |
|------|----------|
| `idx_saved_items_status_updated` | status 筛选 + 常见排序 |
| `idx_saved_items_inbox_updated` | inbox view + 排序 |
| `idx_saved_items_platform_updated` | platform 筛选 + 排序 |
| `idx_saved_items_media_type_updated` | mediaType 筛选 + 排序 |
| `idx_saved_items_updated_created` | 纯 updated_at 排序回退 |
| `idx_saved_item_boxes_box_item` | box 关系查询 |

### 4. Box 关系按需加载

旧方案：查询所有 item 的 box 关系 → 全量 map。新方案：只查询当前页 item 的 box 关系，减少查询量和内存占用。

### 5. 搜索防抖

`collections_providers.dart` 新增 `collectionDebouncedSearchQueryProvider`，将搜索输入 250ms 防抖后传给数据库查询，避免每次按键触发的数据库查询。

## 迁移说明

- `savedItemsListProvider` 保持兼容，内部从 `savedItemsPageProvider` 取 `.items`
- 所有调用 `repository.queryItems()` 的地方已适配新 `SavedItemsQuery` 参数
- 外部 Consumer 可通过 `savedItemsPageProvider` 直接获取 `SavedItemsPage` 以利用 hasMore / boxIdsByItemId

## 验证

- `flutter analyze` — 0 error 0 warning
- DAO 层单元测试：view 筛选（6 种）、status / platform / mediaType 筛选、box 筛选（any-of）、搜索（title/description/url/siteName/author）、limit/offset 分页、5 种排序
- Repository 层集成测试：page + hasMore 语义、boxIdsByItemId 按需加载、多条件组合、旧语义回归
- `saved_item_actions_controller_test` 适配通过
