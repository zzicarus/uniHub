# P0-Batch-A: Box 分配统一走 Mutation Pipeline

## 背景

卡片上的收藏夹分配（`_CompactBoxButton._showBoxMenu`）仍然直接调用 repository 的 `setItemBoxes` / `updateInboxState` / `ref.invalidate(savedItemsPageProvider)`，绕过了 `SavedItemActionsController.assignBoxes` 和 `CollectionsRefreshCoordinator`。

同时 `AppToast.undo` 硬编码 `actionLabel: '撤销'`，不接收自定义 action label。

## 目标

1. 所有 box 分配入口统一使用 `SavedItemActionsController.assignBoxes` → `CrudResult` → `CrudFeedbackCoordinator`
2. `AppToast.undo` 支持自定义 `actionLabel`
3. `CrudFeedbackCoordinator` 正确传递 `undo.label`
4. 随改随加行为测试

## 改动范围

### 文件列表

| 文件 | 改动 |
|------|------|
| `lib/src/shared/widgets/app_toast.dart` | `AppToast.undo` 新增 `actionLabel` 参数，替代硬编码 |
| `lib/src/shared/crud/crud_feedback_coordinator.dart` | 传递 `undo.label` 到 `AppToast.undo` |
| `lib/src/plugins/collections/ui/widgets/saved_item_card.dart` | `_CompactBoxButton._showBoxMenu` 改用 `SavedItemActionsController.assignBoxes` |

### 具体改动

#### 1. AppToast.undo
```dart
// Before
static void undo(BuildContext context, {required String message, required FutureOr<void> Function() onUndo, ...}) {
  _show(context, message: message, ..., actionLabel: '撤销', onAction: onUndo);
}

// After
static void undo(BuildContext context, {required String message, required FutureOr<void> Function() onUndo, String actionLabel = '撤销', ...}) {
  _show(context, message: message, ..., actionLabel: actionLabel, onAction: onUndo);
}
```

#### 2. CrudFeedbackCoordinator.handle
传递 `undo.label` 给 `AppToast.undo` 的 `actionLabel` 参数。

#### 3. _CompactBoxButton._showBoxMenu
将三个分支中的：
```dart
await repository.setItemBoxes(itemId, next);
await repository.updateInboxState(itemId, ...);
ref.invalidate(savedItemsPageProvider);
```
替换为：
```dart
final result = await ref.read(savedItemActionsControllerProvider).assignBoxes(itemId, next);
ref.read(crudFeedbackCoordinatorProvider).handle(context, result);
```

### 不修改范围
- 其他 P0/P1 问题（Batch B/C/D）
- SavedItemDetailPanel 的 box 分配（已在下一批处理）
- CollectionsListController 相关代码

## 验收标准

1. `flutter analyze` 0 error 0 warning
2. `flutter test` 全部通过
3. `_CompactBoxButton` 不再直接调用 `repository.setItemBoxes` / `repository.updateInboxState`
4. `_CompactBoxButton` 不再直接 `ref.invalidate(savedItemsPageProvider)`
5. `AppToast.undo` 支持自定义 `actionLabel`
6. 新增行为测试验证 assignBoxes 触发了 CrudFeedbackCoordinator
