# P0-Batch-B: _loadPage 统一入口 + _patchChangedItem 版本控制 + 搜索 debounce

## 背景

### #2: _loadPage 手写 entry 构造，logo key 使用 originalUrl
`CollectionsListController._loadPage()` 手写 box lookup + logo lookup + entry 构造，且 logo key 使用 `item.originalUrl` 而非 `normalizedUrl`，导致左侧列表 logo 可能查不到。

`SavedItemEntryFactory` 已有 `buildEntry()` 但尚未被 `_loadPage` 使用。需要新增批量 `buildEntries()` 方法并替换手写代码。

### #4: _patchChangedItem 无版本控制
`_patchChangedItem` 是 `unawaited` 异步操作，没有版本号机制。快速连续 mutation 时，慢的 patch 可能用旧数据覆盖新的。

### #5: 搜索刷新读到旧的 debounced query
桌面布局中 `ref.listen(collectionSearchQueryProvider)` → `refresh()` 立即触发。但 `_buildQuery` 读取 `collectionDebouncedSearchQueryProvider.valueOrNull`，该 provider 有 250ms 延迟，刚变化时返回旧值。

## 目标

1. `_loadPage` 改用 `SavedItemEntryFactory.buildEntries` 批量构建
2. `_patchChangedItem` 增加版本控制防止覆盖竞态
3. 搜索 debounce 归一到 controller 内部管理
4. 行为测试覆盖版本控制和 debounce

## 改动范围

### 文件列表

| 文件 | 改动 |
|------|------|
| `lib/src/plugins/collections/application/saved_item_entry_factory.dart` | 新增 `buildEntries` 批量方法 |
| `lib/src/plugins/collections/application/collections_list_controller.dart` | 3 处主要改动（见下） |
| `lib/src/plugins/collections/ui/layouts/collections_desktop_layout.dart` | 移除 `collectionSearchQueryProvider` 的 `listen` → `refresh` |
| `lib/src/plugins/collections/providers/collections_providers.dart` | 可移除 `collectionDebouncedSearchQueryProvider` 如果不再使用 |

### 具体改动

#### 1. SavedItemEntryFactory.buildEntries
```dart
/// Batch version of [buildEntry]. Resolves boxIds and logos once for all
/// items instead of N times individually.
Future<List<SavedItemListEntry>> buildEntries(
  List<SavedItemsTableData> items,
  Map<int, List<int>> boxIdsByItemId,
)
```

#### 2. CollectionsListController._loadPage
替换手写 for-loop entry 构造为：
```dart
final factory = ref.read(savedItemEntryFactoryProvider);
final entries = await factory.buildEntries(page.items, page.boxIdsByItemId);
```

移除原有的 box lookup、logo lookup 和手写 for-loop。

#### 3. CollectionsListController._patchChangedItem 版本控制
```dart
final _mutationSeqByItemId = <int, int>{};

Future<void> _patchChangedItem(int itemId) async {
  final seq = (_mutationSeqByItemId[itemId] ?? 0) + 1;
  _mutationSeqByItemId[itemId] = seq;

  // ... async work ...

  if (_mutationSeqByItemId[itemId] != seq) return; // stale
  // ... update state ...
}
```

#### 4. CollectionsListController 搜索 debounce
- Controller 内部添加 `_searchDebounceTimer`
- `build()` 中 `ref.listen(collectionSearchQueryProvider, ...)` 管理 debounce
- 移除 `collectionDebouncedSearchQueryProvider` 依赖
- 桌面布局中移除 `ref.listen(collectionSearchQueryProvider, ...)` → `refresh()`

### 不修改范围
- 其他 P0/P1 问题（Batch C/D）
- SavedItemActionsController 或 SavedItemCard
- 移动端布局（无搜索监听问题）

## 验收标准

1. `flutter analyze` 0 error 0 warning
2. `flutter test` 全部通过
3. `_loadPage` 不再手写 entry 构造
4. `_loadPage` logo key 使用 `normalizedUrl` fallback `originalUrl`（通过 factory）
5. `_patchChangedItem` 有版本控制，快速连续 mutation 不会旧覆盖新
6. 搜索 debounce 由 controller 管理
