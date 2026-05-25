# Phase 5 PRD：右侧内容详情面板迁移

> 阶段目标：将 `SavedItemDetailPanel` 改造成目标图中的内容详情 / 整理面板  
> 前置条件：Phase 1-4 已完成  
> 主要文件：`saved_item_detail_panel.dart`、`collection_technical_info_section.dart`  
> 不改数据层

---

## 1. 目标

右侧详情面板应从“技术详情块堆叠”迁移为“内容整理面板”。

目标结构：

```text
内容身份区
├── icon / thumbnail
├── 标题
├── 来源 · 类型
├── 收藏时间
├── 星标
└── 打开外链

来源
├── URL
└── 复制

状态
├── 待看 / 阅读中 / 已看 / 归档

收藏夹
├── 当前收藏夹
└── 选择 / 下拉

标签
├── tag chips
└── + 添加标签

备注
└── TextField placeholder

底部操作
├── 打开内容
├── 编辑
└── 更多
```

---

## 2. 当前状态

当前 `SavedItemDetailPanel` 已有：

1. Header。
2. Link section。
3. Status section。
4. Box section。
5. Tags placeholder。
6. Notes placeholder。
7. Content tabs。
8. Technical info。

本阶段重点不是新增能力，而是：

```text
改命名
调顺序
弱化技术信息
强化内容整理动作
```

---

## 3. 非目标

Phase 5 不做：

1. 不新增 tags 表。
2. 不新增 note 字段。
3. 不新增 isFavorite 字段。
4. 不做真实编辑页。
5. 不做真实内容预览抓取。
6. 不改 Repository。
7. 不改 Drift schema。
8. 不重新引入 `TabBarView`。

---

## 4. 面板结构

### 4.1 外层

```dart
Container(
  decoration: ...
  child: Column(
    children: [
      Expanded(
        child: SingleChildScrollView(
          child: Column(
            children: [...]
          ),
      ),
      _BottomActionBar(),
    ],
  ),
)
```

底部操作栏固定在底部更接近目标图。

如果实现复杂，第一版可以仍在滚动内容底部展示。

---

## 5. 内容身份区

### 5.1 展示内容

```text
icon
title
sourcePlatform.label · mediaType.label
createdAt relative time
star icon
open icon
```

### 5.2 标题规则

```dart
maxLines: 2
overflow: TextOverflow.ellipsis
```

### 5.3 星标

UI 占位，不落库：

```dart
IconButton(
  tooltip: '星标功能稍后接入',
  icon: Icon(Icons.star_border_rounded),
  onPressed: showSnackBar,
)
```

---

## 6. 来源区

将原“链接”改名为：

```text
来源
```

展示：

```text
URL
复制按钮
```

如果 URL 很长：

```dart
maxLines: 2
overflow: TextOverflow.ellipsis
```

复制按钮保留：

```dart
Clipboard.setData(...)
```

---

## 7. 状态区

显示：

```text
待看 / 阅读中 / 已看 / 归档
```

映射：

| UI | 数据 |
|---|---|
| 待看 | unread |
| 阅读中 | inProgress |
| 已看 | done |
| 归档 | archived |

点击调用：

```dart
await repository.updateStatus(item.id, next);
ref.invalidate(savedItemsListProvider);
```

不修改 `isInInbox`。

---

## 8. 收藏夹区

将 Box 文案统一改为：

```text
收藏夹
```

数据仍用：

```dart
repository.getBoxIdsForItem
repository.setItemBoxes
repository.updateInboxState
collectionBoxesProvider
```

规则：

1. 显示当前内容所属收藏夹。
2. 支持切换收藏夹。
3. 无收藏夹时显示：
   ```text
   暂无收藏夹
   ```
4. 提供：
   ```text
   + 新建收藏夹
   ```
   可复用 createBox。

注意：

```text
不要使用 selectedCollectionBoxIdsProvider 表示当前 item 所属收藏夹。
```

---

## 9. 标签区

当前无 tags 数据。

第一版显示目标图风格：

```text
标签
[知识管理 ×] [思考 ×] [学习 ×] [+ 添加标签]
```

这些标签不落库。

可选策略：

1. 从 Box 名称生成临时标签。
2. 从 mediaType/sourcePlatform 生成标签。
3. 静态占位。

推荐：

```text
用 Box 名称 + mediaType 生成只读 chips
+ 添加标签 点击提示“标签功能稍后接入”
```

---

## 10. 备注区

当前无 note 字段。

显示：

```text
备注
[写下你收藏这条内容的想法或要点...]
0/500
```

第一版不保存。

点击输入时可提示：

```text
备注功能稍后接入
```

或者使用 disabled `TextField`。

建议：

```dart
TextField(
  enabled: false,
  maxLines: 4,
  decoration: InputDecoration(
    hintText: '写下你收藏这条内容的想法或要点...',
  ),
)
```

---

## 11. 底部操作栏

目标图底部：

```text
打开内容    编辑    ...
```

### 11.1 打开内容

可以复用现有打开 URL 逻辑。若当前详情只复制链接，也可以先复制并提示。更推荐后续统一用 `url_launcher`，但本阶段不引入新依赖。

### 11.2 编辑

第一版 UI 占位：

```text
编辑功能稍后接入
```

### 11.3 更多

Popup menu：

```text
复制链接
归档
技术信息
```

技术信息可以放到更多菜单中，或继续底部折叠。

---

## 12. 技术信息

目标图中没有明显技术信息。因此：

1. 默认不展开。
2. 放在滚动内容最底部。
3. 或移动到“更多 -> 技术信息”。
4. 不要出现在核心视觉区域。

保留 `CollectionTechnicalInfoSection` 但弱化。

---

## 13. Content Tabs 的处理

新目标图右侧不再强调摘要 / 预览 / 笔记 / 相关 Tabs。可以选择：

### 方案 A：保留 tabs

优点：保留已有结构。  
缺点：不完全贴图。

### 方案 B：移除 tabs，将备注作为核心

优点：更贴图。  
缺点：改动稍多。

建议 Phase 5 使用折中：

```text
保留摘要/预览信息，但放到更多或底部弱化。
主区域优先状态、收藏夹、标签、备注。
```

不要再引入 `TabBarView`。

---

## 14. 验收标准

- [ ] 右侧标题区接近目标图。
- [ ] “链接”改为“来源”。
- [ ] “Box”改为“收藏夹”。
- [ ] 状态显示为 待看 / 阅读中 / 已看 / 归档。
- [ ] 标签区目标图风格但不落库。
- [ ] 备注区目标图风格但不落库。
- [ ] 底部有 打开内容 / 编辑 / 更多。
- [ ] 技术信息弱化。
- [ ] 不出现 RenderBox。
- [ ] 不出现 overflow。
- [ ] `flutter analyze` 通过。

---

## 15. Codex 执行指令

```text
只执行 Phase 5：将 SavedItemDetailPanel 迁移为目标图中的内容详情面板。

修改：
lib/src/plugins/collections/ui/widgets/saved_item_detail_panel.dart
lib/src/plugins/collections/ui/widgets/collection_technical_info_section.dart 可选

要求：
1. 右侧详情改为：
   内容身份区
   来源区
   状态区
   收藏夹区
   标签区
   备注区
   底部操作栏
2. “链接”文案改为“来源”。
3. “Box”文案改为“收藏夹”，但数据层仍用 Box。
4. 状态 chips 文案使用：待看 / 阅读中 / 已看 / 归档。
5. 收藏夹区继续使用 getBoxIdsForItem / setItemBoxes / updateInboxState。
6. 标签区只做 UI，占位或从 Box/mediaType 生成，不落库。
7. 备注区只做 UI，占位，不落库。
8. 底部操作栏包含：
   - 打开内容
   - 编辑
   - 更多
9. 编辑和标签添加第一版点击提示“稍后接入”。
10. 技术信息放到底部折叠或更多菜单，不要占核心区域。
11. 不使用 TabBarView。
12. 不改数据库，不改 Repository，不引入依赖。
13. flutter analyze 通过。
```
