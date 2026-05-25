# Phase 6 PRD：内容收藏数据能力增强规划

> 阶段目标：在 UI 稳定后，为星标、标签、备注、导入、分页等能力设计数据层  
> 前置条件：Phase 1-5 UI 迁移完成并稳定  
> 本阶段是规划文档，实施时应拆成多个独立 PR

---

## 1. 背景

Phase 1-5 主要以 UI 迁移为主，不修改数据库。

但目标图中包含一些当前数据模型不具备的真实能力：

1. 星标。
2. 标签。
3. 备注。
4. 收藏夹计数。
5. 导入。
6. 分页。
7. 可能的缩略图 / favicon 展示。
8. 内容类型更强的分类。

这些不应混在 UI 迁移阶段实现，否则会增加 migration 风险。

---

## 2. 数据能力拆分

建议拆成独立子阶段：

```text
Phase 6.1 星标
Phase 6.2 备注
Phase 6.3 标签
Phase 6.4 收藏夹计数
Phase 6.5 导入
Phase 6.6 分页 / 查询优化
```

---

## 3. Phase 6.1 星标

### 3.1 数据字段

在 `SavedItemsTable` 新增：

```dart
BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
```

### 3.2 Repository

新增：

```dart
Future<void> updateFavorite(int itemId, bool isFavorite)
```

### 3.3 UI

1. `SavedItemCard` 星标按钮真实可用。
2. `SavedItemDetailPanel` 星标按钮真实可用。
3. 可选新增“星标收藏”筛选。

### 3.4 验收

- [ ] 星标状态可保存。
- [ ] 列表和详情同步。
- [ ] 重启应用后星标仍存在。

---

## 4. Phase 6.2 备注

### 4.1 数据字段

在 `SavedItemsTable` 新增：

```dart
TextColumn get note => text().nullable()();
```

### 4.2 Repository

新增：

```dart
Future<void> updateNote(int itemId, String? note)
```

### 4.3 UI

1. 右侧详情备注 TextField 启用。
2. 支持最多 500 字。
3. 防抖保存或失焦保存。

### 4.4 验收

- [ ] 备注可输入。
- [ ] 备注可保存。
- [ ] 备注可清空。
- [ ] 重启后仍存在。

---

## 5. Phase 6.3 标签

### 5.1 新表

```dart
class TagsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}
```

### 5.2 多对多表

```dart
class SavedItemTagsTable extends Table {
  IntColumn get itemId => integer().references(SavedItemsTable, #id)();
  IntColumn get tagId => integer().references(TagsTable, #id)();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {itemId, tagId};
}
```

### 5.3 Repository

新增：

```dart
Future<List<TagsTableData>> getTags()
Future<List<int>> getTagIdsForItem(int itemId)
Future<void> setItemTags(int itemId, Set<int> tagIds)
Future<TagsTableData> createTag(String name)
```

### 5.4 UI

1. 详情面板支持添加标签。
2. 内容卡片显示标签。
3. 中栏搜索可搜索标签。
4. Header 搜索可搜索标签。

### 5.5 验收

- [ ] 标签可创建。
- [ ] 标签可绑定内容。
- [ ] 标签可移除。
- [ ] 标签可搜索。
- [ ] 标签在列表和详情同步显示。

---

## 6. Phase 6.4 收藏夹计数

### 6.1 目标

左侧收藏夹栏显示真实计数：

```text
全部收藏 186
待整理 24
稍后阅读 38
AI 30
开发 28
```

### 6.2 实现方式

新增 Repository 查询：

```dart
Future<CollectionFolderCounts> getFolderCounts()
```

或多个轻量方法：

```dart
Future<int> countAll()
Future<int> countInbox()
Future<int> countUnread()
Future<Map<int, int>> countByBox()
```

### 6.3 Provider

```dart
final collectionFolderCountsProvider = FutureProvider<...>
```

### 6.4 验收

- [ ] 左侧计数准确。
- [ ] 新增收藏后计数刷新。
- [ ] 归档 / 移动收藏夹后计数刷新。
- [ ] 性能可接受。

---

## 7. Phase 6.5 导入

### 7.1 支持格式

第一版建议：

```text
.txt
.csv
.html bookmark export
```

### 7.2 导入字段

```text
url
title optional
folder optional
tags optional
```

### 7.3 UI

点击“导入”打开文件选择器。

需要确认项目已有 `file_picker` 依赖。若已有可复用；若没有，单独评估依赖。

### 7.4 验收

- [ ] 可导入多个 URL。
- [ ] 重复 URL 不重复创建。
- [ ] 可选择导入到指定收藏夹。
- [ ] 导入后进入 enrichment job。

---

## 8. Phase 6.6 分页 / 查询优化

### 8.1 当前问题

如果收藏项变多，当前一次性读取所有 items 再内存过滤会带来性能问题。

### 8.2 目标

Repository 支持分页：

```dart
Future<PagedSavedItems> queryItemsPaged({
  required int page,
  required int pageSize,
  ...
})
```

### 8.3 UI

中栏底部分页：

```text
1 2 3 4 5 ... 16 >
```

### 8.4 验收

- [ ] 列表支持分页。
- [ ] 筛选后分页总数正确。
- [ ] 页面切换不卡顿。

---

## 9. Migration 策略

每次数据库变更必须：

1. 提升 schemaVersion。
2. 写 migration。
3. 保证老数据可升级。
4. 添加最小测试。
5. 手动测试 Windows 端。

禁止一次性合并星标、备注、标签、导入、分页。

---

## 10. 总结

Phase 6 不应与 Phase 1-5 混合开发。

推荐顺序：

```text
星标 -> 备注 -> 标签 -> 计数 -> 导入 -> 分页
```

每个能力单独 PR。
