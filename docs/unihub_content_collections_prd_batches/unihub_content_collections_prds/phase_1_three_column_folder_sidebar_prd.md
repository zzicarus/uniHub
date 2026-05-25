# Phase 1 PRD：三栏信息架构迁移与收藏夹侧栏

> 阶段目标：把当前收藏页从“顶部 Box + 左列表 + 右详情”迁移为“三栏内容收藏工作台”  
> 优先级：P0  
> 改动范围：UI 结构为主，不改数据层  
> 主要文件：`collections_desktop_layout.dart`、新增 `collection_folder_sidebar.dart`

---

## 1. 目标

将当前主体结构：

```text
顶部筛选区
├── CollectionViewChips
├── CollectionBoxBar
└── CollectionSearchFilterBar

主体
├── 左侧 SavedItem 列表
└── 右侧 SavedItemDetailPanel
```

迁移为：

```text
Header
CollectionCaptureBar

主体三栏
├── 左栏 CollectionFolderSidebar
├── 中栏 内容列表区
└── 右栏 SavedItemDetailPanel
```

---

## 2. 非目标

本阶段不做：

1. 不改数据库 schema。
2. 不改 Drift migration。
3. 不新增 tags / notes / favorite 字段。
4. 不做真正收藏夹计数。
5. 不做真实导入。
6. 不重做卡片视觉。
7. 不重做右侧详情视觉。
8. 不修改 Repository 业务逻辑。
9. 不引入新依赖。

---

## 3. 新增组件

### 3.1 文件

```text
lib/src/plugins/collections/ui/widgets/collection_folder_sidebar.dart
```

### 3.2 组件职责

`CollectionFolderSidebar` 负责展示模块内部的“收藏夹”导航。

它不是全局 Sidebar。全局 Sidebar 仍由 `DesktopShell` / `Sidebar` 管理。

### 3.3 UI 结构

```text
收藏夹                         +   搜索
────────────────────────────────
[选中] 全部收藏                 186
       待整理                   24
       稍后阅读                 38

       AI                      30
       开发                    28
       设计                    21
       生活                    15

+ 新建收藏夹

[快速捕捉]
```

### 3.4 MVP 计数规则

第一阶段计数可以先做占位：

```text
全部收藏：可暂时显示空，或使用当前列表长度
待整理：可暂时显示空
Box 计数：可暂时不显示，或固定隐藏
```

如果实现真实计数会引入更多查询，不属于 Phase 1 必须项。

建议第一版：

```text
全部收藏
待整理
稍后阅读
AI
开发
设计
生活
```

先不显示数字，或数字置于 UI 占位。

---

## 4. 数据与 Provider

### 4.1 复用现有 Provider

```dart
collectionBoxesProvider
selectedCollectionBoxIdsProvider
collectionViewProvider
collectionsRepositoryProvider
```

### 4.2 点击行为

#### 全部收藏

```dart
ref.read(selectedCollectionBoxIdsProvider.notifier).state = {};
ref.read(collectionViewProvider.notifier).state = CollectionView.all;
```

#### 待整理

```dart
ref.read(selectedCollectionBoxIdsProvider.notifier).state = {};
ref.read(collectionViewProvider.notifier).state = CollectionView.inbox;
```

#### 稍后阅读

MVP 映射为未看：

```dart
ref.read(selectedCollectionBoxIdsProvider.notifier).state = {};
ref.read(collectionViewProvider.notifier).state = CollectionView.unread;
```

#### 点击某个收藏夹 / Box

```dart
ref.read(selectedCollectionBoxIdsProvider.notifier).state = {box.id};
ref.read(collectionViewProvider.notifier).state = CollectionView.all;
```

### 4.3 UI 命名

数据层仍为 Box：

```text
collectionBoxesProvider
selectedCollectionBoxIdsProvider
```

UI 显示为：

```text
收藏夹
```

不要在 Phase 1 改数据库命名。

---

## 5. 新建收藏夹

### 5.1 行为

点击：

```text
+ 新建收藏夹
```

弹出 Dialog：

```text
标题：新建收藏夹
输入框：收藏夹名称
按钮：取消 / 创建
```

创建逻辑：

```dart
await ref.read(collectionsRepositoryProvider).createBox(name);
ref.invalidate(collectionBoxesProvider);
```

### 5.2 错误处理

1. 空名称不创建。
2. 创建失败显示 SnackBar。
3. 创建成功后刷新收藏夹列表。

---

## 6. 修改 `CollectionsDesktopLayout`

### 6.1 当前结构保留内容

保留：

1. Header。
2. `CollectionCaptureBar`。
3. `SavedItemCard` 列表。
4. `SavedItemDetailPanel`。
5. `CollectionBulkActionBar`。
6. `selectedSavedItemIdProvider` 逻辑。
7. `LayoutBuilder` 的详情宽度 clamp 逻辑。

### 6.2 移除 / 迁移

从顶部移除：

```dart
CollectionBoxBar()
```

Box 功能迁移到：

```dart
CollectionFolderSidebar()
```

### 6.3 目标布局代码形态

```dart
Expanded(
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SizedBox(
        width: 220,
        child: CollectionFolderSidebar(),
      ),
      const SizedBox(width: AppSpacing.md),
      Expanded(
        child: Column(
          children: [
            const CollectionViewChips(),
            const SizedBox(height: AppSpacing.xs),
            const CollectionSearchFilterBar(),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: itemsAsync.when(...),
            ),
            const CollectionBulkActionBar(),
          ],
        ),
      ),
      const SizedBox(width: AppSpacing.lg),
      LayoutBuilder(
        builder: (context, constraints) {
          final detailWidth = (constraints.maxWidth * 0.36).clamp(420.0, 540.0);
          return SizedBox(
            width: detailWidth,
            child: SavedItemDetailPanel(item: displayItem),
          );
        },
      ),
    ],
  ),
)
```

### 6.4 注意

`LayoutBuilder` 放在 Row 子节点中时，其 constraints 可能不是你预期的剩余总宽度。若出现右栏宽度异常，改为在 `Expanded` 外层或 `body` 区整体 `LayoutBuilder` 计算：

```dart
LayoutBuilder(
  builder: (context, constraints) {
    final detailWidth = (constraints.maxWidth * 0.32).clamp(380.0, 500.0);
    final folderWidth = constraints.maxWidth < 1200 ? 200.0 : 220.0;
    ...
  },
)
```

---

## 7. 响应式规则

### 7.1 宽度规则

| 主内容宽度 | 收藏夹栏 | 详情栏 | 行为 |
|---|---:|---:|---|
| > 1400 | 240 | 500 | 完整三栏 |
| 1100-1400 | 220 | 420-480 | 三栏紧凑 |
| 900-1100 | 200 | 380-420 | 三栏压缩 |
| < 900 | 可隐藏左栏或详情栏 | 后续处理 | Phase 1 可不完全支持 |

### 7.2 防 overflow

使用：

```dart
Expanded
Flexible
SingleChildScrollView(scrollDirection: Axis.horizontal)
TextOverflow.ellipsis
ConstrainedBox
LayoutBuilder
```

禁止：

```dart
Row 中直接塞大量固定宽度按钮
无约束 TabBarView
无限宽 Text
```

---

## 8. 验收标准

### 8.1 UI 骨架

- [ ] 页面主体变成三栏。
- [ ] 左栏显示“收藏夹”。
- [ ] 中栏显示内容列表。
- [ ] 右栏显示详情面板。
- [ ] 顶部不再直接展示 `CollectionBoxBar`。
- [ ] `CollectionCaptureBar` 仍在 Header 下方。

### 8.2 交互

- [ ] 点击“全部收藏”显示全部。
- [ ] 点击“待整理”显示 Inbox。
- [ ] 点击“稍后阅读”显示未看。
- [ ] 点击已有收藏夹按 Box 筛选。
- [ ] 新建收藏夹可用。
- [ ] 选中内容卡片后右侧详情更新。

### 8.3 稳定性

- [ ] `flutter analyze` 通过。
- [ ] Windows 运行无 `RenderBox was not laid out`。
- [ ] 无明显 `RenderFlex overflow`。
- [ ] 之前修复过的详情 Tab 不回退。

---

## 9. 给 Codex 的执行指令

```text
只执行 Phase 1：将收藏页迁移为三栏结构，并新增收藏夹侧栏。

新增：
lib/src/plugins/collections/ui/widgets/collection_folder_sidebar.dart

修改：
lib/src/plugins/collections/ui/layouts/collections_desktop_layout.dart

要求：
1. 新增 CollectionFolderSidebar。
2. CollectionFolderSidebar 复用 collectionBoxesProvider、selectedCollectionBoxIdsProvider、collectionViewProvider、collectionsRepositoryProvider.createBox。
3. UI 文案使用“收藏夹”，数据层仍使用 Box。
4. 点击全部收藏：清空 box 筛选，collectionView = all。
5. 点击待整理：清空 box 筛选，collectionView = inbox。
6. 点击稍后阅读：清空 box 筛选，collectionView = unread。
7. 点击某个收藏夹：selectedCollectionBoxIdsProvider = {box.id}，collectionView = all。
8. 新建收藏夹调用 repository.createBox，并 invalidate collectionBoxesProvider。
9. CollectionsDesktopLayout 移除顶部 CollectionBoxBar。
10. 主体 Row 改为三栏：收藏夹栏 + 列表栏 + 详情栏。
11. 保留 CollectionViewChips、CollectionSearchFilterBar、SavedItemCard、CollectionBulkActionBar、SavedItemDetailPanel。
12. 不改数据库，不改 Repository，不改 EnrichmentJobService，不引入依赖。
13. 保持 flutter analyze 通过。
14. 不出现 RenderBox / RenderFlex overflow。
```
