# PRD：Collections CRUD 后即时软刷新重构

## 1. 目标

建立统一的 Collections Mutation Pipeline，所有 CRUD 操作不再由 UI 层直接调用 `ref.invalidate()`，而是经过统一的 mutation coordinator，由它决定：

1. 哪些列表需要局部 patch
2. 哪些 provider 需要 invalidate
3. 当前选中项是否需要更新/清空/回退
4. 当前筛选条件下该 item 是否仍应显示
5. 是否需要刷新左侧 counts

完成后必须保证以下操作都能即时更新 UI：

1. 修改状态 — 状态 chip 立即变化
2. 归档 — 非归档视图中 item 立即消失
3. 删除 — entry 立即消失，selectedId 选择下一条
4. 撤销删除 — 符合筛选则立即恢复显示
5. 分配收藏夹/移出收藏夹 — Box chip 立即变化；如果当前 Box 筛选不匹配则移除
6. 打开链接后更新 lastOpenedAt — 详情面板立即更新
7. 抓取重试/enrichment 完成 — title/site/media/logo 即时 patch
8. favicon/logo 缓存完成 — 列表图标即时更新
9. 新增收藏 — 符合筛选则插入顶部，刷新 counts
10. 修改备注/标签/标题 — 软 patch 当前 entry

## 2. 新增核心文件

### 2.1 collections_mutation_event.dart
定义 mutation 事件 sealed class 层次结构。

### 2.2 collections_mutation_notifier.dart
Mutation StateProvider — 每次 emit 增加 revision，widget 可监听事件流。

### 2.3 collections_refresh_coordinator.dart
Coordinator 封装所有 invalidation + patch 逻辑的编排。

### 2.4 saved_item_entry_factory.dart
统一的 entry 构建逻辑，供 list controller 和 detail provider 复用。

## 3. 改造现有文件

### 3.1 SavedItemActionsController
移除旧 invalidateLists/invalidateCounts/invalidateAll 方法，改为通过 CollectionsRefreshCoordinator 驱动刷新。

### 3.2 CollectionsListController
监听 collectionsMutationProvider，根据事件类型做局部 patch（_patchChangedItem / _removeDeletedItem / _maybeInsertRestoredItem），而不是每次都整页刷新。

### 3.3 EnrichmentQueueController
使用 coordinator 替代直接 invalidateLists。

### 3.4 collections_providers.dart
添加新 provider（mutation、coordinator），更新 controller provider 的依赖注入。

## 4. 测试矩阵

1. updateStatus 后，列表卡片状态立即变化
2. 当前筛选为"待看"时，把 item 改为"阅读中"，该 item 立即从列表移除
3. archiveItem 后，非归档视图中 item 立即消失
4. deleteItem 后，entry 立即消失，selectedId 选择下一条
5. undo restore 后，符合筛选则立即恢复显示
6. assignBoxes 后，卡片 Box chip 立即变化
7. 当前 Box 筛选下，移出该 Box 后 item 立即消失
8. openItem 后，lastOpenedAt 立即变化
9. logo cached 后，列表图标立即变化
10. 右侧详情在所有上述操作后同步更新
11. 连续快速操作不会出现旧状态覆盖新状态

## 5. 验收标准

- `flutter analyze` 0 error 0 warning
- 现有测试全部通过 (`flutter test`)
- 代码新增源文件完成，无 TODO 残留
