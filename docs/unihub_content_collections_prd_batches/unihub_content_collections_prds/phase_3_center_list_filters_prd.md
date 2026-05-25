# Phase 3 PRD：中栏内容筛选区与状态 Tabs 迁移

> 阶段目标：将中栏改造成目标图中的内容管理列表区  
> 前置条件：Phase 1 三栏结构、Phase 2 Header 已完成  
> 主要改动：新增内容类型 chips、状态 tabs、列表工具栏  
> 不改数据层

---

## 1. 目标

目标图中栏顶部有两层筛选：

```text
类型 chips：
[全部] [网页] [视频] [公众号] [文章] [工具] [...]

工具栏：
[搜索标题、来源或内容] [全部来源] [所有类型] [最新收藏] [视图切换]
```

当前中栏仍使用：

```text
CollectionViewChips
CollectionSearchFilterBar
```

需要将它们改造成更贴近“内容收藏”的筛选系统。

---

## 2. 语义重构

### 2.1 左侧收藏夹负责

```text
全部收藏
待整理
稍后阅读
具体收藏夹 / Box
```

### 2.2 中栏状态 tabs 负责消费状态

```text
全部
待看
阅读中
已看
归档
```

对应：

| UI | 数据 |
|---|---|
| 全部 | `collectionStatusFilterProvider = null` |
| 待看 | `ConsumptionStatus.unread` |
| 阅读中 | `ConsumptionStatus.inProgress` |
| 已看 | `ConsumptionStatus.done` |
| 归档 | `ConsumptionStatus.archived` |

注意：

```text
不要在中栏状态 tabs 中显示 Inbox。
Inbox / 待整理 已经交给左侧收藏夹栏。
```

---

## 3. 新增组件

### 3.1 `collection_status_tabs.dart`

职责：

1. 显示消费状态 tabs。
2. 写入 `collectionStatusFilterProvider`。
3. 不修改 `collectionViewProvider`。
4. 不修改 Box 筛选。

UI：

```text
全部 / 待看 / 阅读中 / 已看 / 归档
```

伪代码：

```dart
class CollectionStatusTabs extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(collectionStatusFilterProvider);

    return Row(
      children: [
        ChoiceChip(
          label: Text('全部'),
          selected: selected == null,
          onSelected: (_) {
            ref.read(collectionStatusFilterProvider.notifier).state = null;
          },
        ),
        ...
      ],
    );
  }
}
```

### 3.2 `collection_content_type_chips.dart`

职责：

按内容类型筛选：

```text
全部 / 网页 / 视频 / 公众号 / 文章 / 工具 / 更多
```

MVP 映射：

| Chip | Provider 改动 |
|---|---|
| 全部 | `mediaType = null`, `platform = null` |
| 网页 | `mediaType = MediaType.webpage` |
| 视频 | `mediaType = MediaType.video` |
| 公众号 | `platform = SourcePlatform.wechat` |
| 文章 | `mediaType = MediaType.article` |
| 工具 | `mediaType = MediaType.repository` 或仅 UI 占位 |
| 更多 | UI 占位 |

注意：

```text
类型 chips 本质是筛选，不是 CollectionView。
```

### 3.3 `collection_list_toolbar.dart`

职责：

替代或包装 `CollectionSearchFilterBar`，形成目标图中的中栏工具条。

包含：

```text
搜索框
全部来源 dropdown
所有类型 dropdown
最新收藏 dropdown/label
视图切换 icon
```

---

## 4. `CollectionSearchFilterBar` 处理

现有 `CollectionSearchFilterBar` 已包含搜索、来源、媒介、排序、清空筛选。

可以二选一：

### 方案 A：改造原组件

将 `CollectionSearchFilterBar` 改造成目标图样式。

优点：文件少。  
缺点：职责变更较大。

### 方案 B：新增 `CollectionListToolbar`

保留 `CollectionSearchFilterBar`，新增新组件并在 DesktopLayout 使用新组件。

优点：迁移安全。  
推荐方案：B。

---

## 5. 中栏目标结构

```dart
Column(
  children: [
    const CollectionContentTypeChips(),
    const SizedBox(height: AppSpacing.sm),
    const CollectionListToolbar(),
    const SizedBox(height: AppSpacing.sm),
    Expanded(child: SavedItemList()),
    const CollectionPaginationBar(), // Phase 3 可选 UI 占位
  ],
)
```

---

## 6. 视图切换按钮

目标图右侧有九宫格/视图切换图标。

第一版只做 UI：

```dart
IconButton(
  tooltip: '切换视图',
  onPressed: () {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('视图切换稍后接入')),
    );
  },
  icon: const Icon(Icons.grid_view_rounded),
)
```

---

## 7. 分页

目标图有分页：

```text
1 2 3 4 5 ... 16 >
```

Phase 3 第一版只做 UI 占位，不改 repository 查询。

建议：

```text
默认显示底部分页条，但按钮不真实分页。
或暂时不实现，放到 Phase 6。
```

如果实现 UI 占位，要保证不误导用户：

```text
第一页高亮，其他不可用或点击提示“分页稍后接入”。
```

---

## 8. 防冲突规则

### 8.1 左侧收藏夹和中栏状态不能互相污染

点击左侧“待整理”：

```text
collectionViewProvider = inbox
```

点击中栏“待看”：

```text
collectionStatusFilterProvider = unread
```

这两个可能叠加。要避免用户困惑。

推荐：

当点击左侧：

```dart
collectionStatusFilterProvider = null;
```

这样左侧导航切换时重置状态 tabs。

点击中栏状态 tabs 时不改左侧收藏夹。

### 8.2 内容类型 chips 与 Dropdown 同步

如果用户点击“视频”：

```dart
collectionMediaTypeFilterProvider = MediaType.video
```

Dropdown 应显示“视频”。

如果 Dropdown 改为“全部媒介”，类型 chip 应回到“全部”或不高亮。

第一版可以允许轻微不同步，但最好使用同一 provider 推导 selected 状态。

---

## 9. 验收标准

- [ ] 中栏顶部显示内容类型 chips。
- [ ] 类型 chips 包含：全部 / 网页 / 视频 / 公众号 / 文章 / 工具 / 更多。
- [ ] 中栏状态 tabs 显示：全部 / 待看 / 阅读中 / 已看 / 归档。
- [ ] 中栏不再显示 Inbox 状态 chip。
- [ ] 搜索框仍可搜索。
- [ ] 来源筛选仍可用。
- [ ] 媒介类型筛选仍可用。
- [ ] 清空筛选仍可用。
- [ ] 不出现 Row overflow。
- [ ] `flutter analyze` 通过。

---

## 10. Codex 执行指令

```text
只执行 Phase 3：改造中栏内容筛选区。

新增：
1. collection_status_tabs.dart
2. collection_content_type_chips.dart
3. collection_list_toolbar.dart

要求：
1. 中栏顶部显示内容类型 chips：
   全部 / 网页 / 视频 / 公众号 / 文章 / 工具 / 更多。
2. 类型 chips 写入现有 provider：
   - 全部：platform=null, mediaType=null
   - 网页：mediaType=webpage
   - 视频：mediaType=video
   - 公众号：platform=wechat
   - 文章：mediaType=article
   - 工具：mediaType=repository 或 UI 占位
3. 新增 CollectionStatusTabs：
   全部 / 待看 / 阅读中 / 已看 / 归档。
4. CollectionStatusTabs 写入 collectionStatusFilterProvider。
5. 不再在中栏展示 Inbox。Inbox/待整理由左侧收藏夹栏负责。
6. 新增 CollectionListToolbar，包含：
   - 搜索框
   - 全部来源
   - 所有类型
   - 最新收藏
   - 视图切换按钮
7. 复用 collectionSearchQueryProvider、collectionPlatformFilterProvider、collectionMediaTypeFilterProvider。
8. 不改数据库，不改 Repository，不引入依赖。
9. 使用 SingleChildScrollView / Wrap / Flexible 防止横向 overflow。
10. flutter analyze 通过。
```
