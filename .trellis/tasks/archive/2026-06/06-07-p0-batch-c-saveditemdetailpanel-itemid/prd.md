# P0-Batch-C: SavedItemDetailPanel 全面改为 itemId 驱动

## 背景

`SavedItemDetailPanel` 当前接受 `SavedItemListEntry entry` 快照，底部抽屉打开后状态变更不会同步。同时桌面端的 `_DetailPanel` 已经用 `selectedSavedItemDetailProvider(selectedId)` 加载详情，但仍在调用处包装成 `SavedItemListEntry` 再传入 panel。

## 目标

1. `SavedItemDetailPanel` 改为接受 `int itemId`，内部 watch `selectedSavedItemDetailProvider`
2. 桌面详情、底部抽屉、移动端底部抽屉全部统一使用同一数据源
3. 移除冗余的 entry 到 detail 的转包层

## 改动范围

### 文件列表

| 文件 | 改动 |
|------|------|
| `lib/src/plugins/collections/ui/widgets/saved_item_detail_panel.dart` | 构造参数改为 `itemId`，内部 watch provider，移除 `widget.entry` 相关 getter |
| `lib/src/plugins/collections/ui/layouts/collections_desktop_layout.dart` | `_showDetailBottomSheet` + `_DetailPanel` 改为传 `itemId` |
| `lib/src/plugins/collections/ui/layouts/collections_mobile_layout.dart` | 底部抽屉改为传 `itemId` |

### 具体改动

#### 1. SavedItemDetailPanel 构造
```dart
class SavedItemDetailPanel extends ConsumerStatefulWidget {
  const SavedItemDetailPanel({required this.itemId, super.key});

  final int itemId;
}
```

#### 2. 内部状态
```dart
// build 中：
final detailAsync = ref.watch(selectedSavedItemDetailProvider(widget.itemId));
return detailAsync.when(
  loading: () => ...,
  error: (err, _) => ...,
  data: (detail) => _buildDetail(context, ref, detail),
);
```

`item` / `boxes` getter 移除，`_buildDetail` 接收 `SavedItemDetailVm detail` 参数。

### 不修改范围
- `SavedItemDetailVm` 数据模型
- `selectedSavedItemDetailProvider` provider
- 面板内的子组件（`_BoxSection` / `_TagsSection` 等）

## 验收标准

1. `flutter analyze` 0 error 0 warning
2. `flutter test` 全部通过
3. `SavedItemDetailPanel` 不再接受 `entry` 参数
4. 底部抽屉和桌面详情都通过 `selectedSavedItemDetailProvider` 获取实时数据
5. 状态/box/metadata 变更后底部抽屉自动刷新
