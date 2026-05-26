# 收藏模块架构治理 v1.5

> 归档日期：2026-05-27
> 来源：用户对话 PRD
> 状态：已确认，待排期
> 关联任务：05-25-ui（删除弹窗）、05-25-collections-delete（删除操作）

---

## 一句话目标

将收藏模块从"UI 直接驱动业务的页面实现"升级为"Controller + ViewModel + 稳定后台队列"的可维护架构。

## 核心三项改造

### 1. 新增 SavedItemActionsController

统一封装收藏项操作，UI 不再直接拼接删除、撤销、归档、移动 Box、复制链接等流程。
SavedItemCard 与 SavedItemDetailPanel 调用同一套 action。

文件：`lib/src/plugins/collections/application/saved_item_actions_controller.dart`

### 2. 新增收藏列表 ViewModel

将 SavedItemsTableData、所属 Box、Logo 缓存、状态展示、失败提示等聚合成列表展示模型。
消除列表卡片内的 N+1 查询。

文件：`lib/src/plugins/collections/application/saved_item_list_entry.dart`

### 3. 增强 Enrichment 队列恢复能力

- 应用启动后可恢复 pending jobs
- 收藏页进入时可主动扫描 pending jobs
- 失败项可手动重试
- drainPending 支持批量稳定执行

文件：`lib/src/plugins/collections/application/enrichment_queue_controller.dart`

## 三个阶段

| Phase | 内容 | 关键交付 |
|-------|------|----------|
| 1 | 抽离 Controller | SavedItemActionsController + Action Result + Undo Snapshot；改造 SavedItemCard 和 DetailPanel |
| 2 | ViewModel 化 | SavedItemListEntry + savedItemListEntriesProvider；消除 N+1；改造 UI 入参 |
| 3 | Enrichment 队列恢复 | EnrichmentQueueController；App 启动/页面进入触发；失败项重试 |

## 本阶段不做

- 不重写整个收藏模块
- 不重做 UI 视觉风格
- 不改数据库 schema（enrichment retry 极少的字段除外）
- 不引入远程后端 / AI 摘要 / 完整 tag 系统

## 完整 PRD 正文

见下方原文。

---

## 原文

（原 PRD 内容如下）

# 收藏删除确认弹窗 UI 改造

（此 PRD 说明该文档的来源背景——下面是被归档的完整 PRD 内容）

---

**PRD 正文：**

### 1. 项目背景

当前 uniHub 收藏模块已经具备基础收藏能力，包括快速收藏、收藏列表、收藏夹 Box、状态切换、详情面板、metadata enrichment、网站 logo 缓存等。模块已经不是从 0 到 1 的原型阶段，而是进入"需要稳定长期使用"的架构治理阶段。

当前主要问题不是功能完全缺失，而是：

- UI Widget 中混入大量业务操作。
- 列表 Provider 返回裸数据库对象，导致 UI 层反复查询附属数据。
- enrichment 队列依赖用户本次收藏后的临时触发，应用重启或网络失败后恢复能力不足。
- SavedItemCard 与 SavedItemDetailPanel 存在重复业务逻辑，例如删除、撤销、移动 Box、复制链接、归档等。相关逻辑目前直接写在 UI 组件中。
- savedItemsListProvider 当前返回 List\<SavedItemsTableData\>，但 UI 展示又需要 Box、Logo、状态、来源、metadata 等聚合信息。
- enrichment 当前主要在快速收藏后通过 \_triggerEnrichmentQueue() 触发，属于页面交互驱动，不是稳定的后台任务机制。

### 2. 本 PRD 目标

#### 2.1 一句话目标

将收藏模块从"UI 直接驱动业务的页面实现"升级为"Controller + ViewModel + 稳定后台队列"的可维护架构。

#### 2.2 核心目标

本阶段需要完成三项架构治理：

1. 新增 SavedItemActionsController
2. 新增收藏列表 ViewModel
3. 增强 Enrichment 队列恢复能力

### 3. 本阶段不做

本阶段是架构治理，不做大范围产品扩展。

明确不做：

- 不重写整个收藏模块。
- 不重做 UI 视觉风格。
- 不新增浏览器插件。
- 不引入远程后端。
- 不实现 AI 摘要。
- 不大改数据库 schema，除非为了 enrichment retry 必须新增极少字段。
- 不引入复杂任务调度框架。
- 不重构 thoughts 模块。
- 不实现完整 tag 系统。
- 不实现完整 notes 富文本系统。

### 4. 当前问题分析

#### 4.1 UI 层业务逻辑过重

当前 SavedItemCard 和 SavedItemDetailPanel 都包含大量业务操作：打开链接、标记已打开、复制链接、切换状态、归档、删除、删除确认、多 Box 删除判断、撤销删除、分配 Box、从 Box 移除、snackbar 反馈。

#### 4.2 Provider 返回裸数据，UI 需要二次查询

#### 4.3 Enrichment 队列恢复能力不足

### 5. 功能需求

#### 5.1 新增 SavedItemActionsController

```dart
class SavedItemActionsController {
  Future<SavedItemActionResult> openItem(int itemId);
  Future<SavedItemActionResult> copyUrl(int itemId);
  Future<SavedItemActionResult> updateStatus(int itemId, ConsumptionStatus status);
  Future<SavedItemActionResult> archiveItem(int itemId);
  Future<SavedItemActionResult> assignBoxes(int itemId, Set<int> boxIds);
  Future<SavedItemActionResult> removeFromBox(int itemId, int boxId);
  Future<SavedItemActionResult> deleteItem(int itemId, {DeleteMode mode, int? boxId});
  Future<SavedItemActionResult> restoreDeletedItem(SavedItemUndoSnapshot snapshot);
  Future<SavedItemActionResult> retryEnrichment(int itemId);
  Future<SavedItemActionResult> toggleFavorite(int itemId);
}
```

#### 5.2 Action Result 设计

```dart
class SavedItemActionResult {
  final bool success;
  final String? message;
  final SavedItemUndoAction? undo;
  final Object? error;
}

class SavedItemUndoAction {
  final String label;
  final Future<void> Function() execute;
}

class SavedItemUndoSnapshot {
  final SavedItemsTableData item;
  final List<int> boxIds;
}
```

#### 5.3 删除与撤销改造

删除前保存完整 snapshot，撤销时恢复所有字段。

```dart
Future<SavedItemsTableData> restoreSavedItem(SavedItemsTableData item, List<int> boxIds);
```

### 6. ViewModel 化需求

```dart
class SavedItemListEntry {
  final SavedItemsTableData item;
  final List<CollectionBoxesTableData> boxes;
  final WebsiteLogoCacheEntry? logo;
  final bool selected;
}
```

### 7. Enrichment 队列恢复需求

```dart
class EnrichmentQueueController {
  Future<void> runOnce({int limit = 5});
  Future<void> drainPending({int batchSize = 5, int maxBatches = 5});
  Future<void> retryItem(int itemId);
}
```

### 8. 文件修改清单

#### 新增文件
- `lib/src/plugins/collections/application/saved_item_actions_controller.dart`
- `lib/src/plugins/collections/application/saved_item_action_result.dart`
- `lib/src/plugins/collections/application/saved_item_undo_snapshot.dart`
- `lib/src/plugins/collections/application/saved_item_list_entry.dart`
- `lib/src/plugins/collections/application/enrichment_queue_controller.dart`

#### 修改文件
- `lib/src/plugins/collections/providers/collections_providers.dart`
- `lib/src/plugins/collections/data/collections_repository.dart`
- `lib/src/plugins/collections/data/collection_boxes_dao.dart`
- `lib/src/plugins/collections/data/enrichment_jobs_dao.dart`
- `lib/src/plugins/collections/services/enrichment_job_service.dart`
- `lib/src/plugins/collections/ui/layouts/collections_desktop_layout.dart`
- `lib/src/plugins/collections/ui/widgets/saved_item_card.dart`
- `lib/src/plugins/collections/ui/widgets/saved_item_detail_panel.dart`
- `lib/src/plugins/collections/ui/widgets/collection_capture_bar.dart`

### 9. 详细改造步骤

#### Phase 1：抽离 SavedItemActionsController
- Step 1：新增 Action Result 类型
- Step 2：新增 Controller
- Step 3：改造 SavedItemCard
- Step 4：改造 SavedItemDetailPanel

#### Phase 2：Provider ViewModel 化
- Step 1：新增 SavedItemListEntry
- Step 2：CollectionBoxesDao 增加批量方法
- Step 3：新增 savedItemListEntriesProvider
- Step 4：改造 SavedItemCard 入参
- Step 5：移除卡片内 FutureBuilder 查询 Box

#### Phase 3：Enrichment 队列恢复
- Step 1：修改 runPendingJobs 返回值
- Step 2：新增 EnrichmentQueueController
- Step 3：收藏页进入时 drain pending
- Step 4：CaptureBar 改造
- Step 5：失败项重试

### 10. 交互规范

### 11. 技术验收标准

### 12. 风险与处理

---

*以上为完整 PRD 原文，使用场景分析、技术规范与验收标准详见正文。*
