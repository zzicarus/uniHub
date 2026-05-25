# Phase 4 PRD：SavedItemCard 内容卡片视觉迁移

> 阶段目标：将中栏列表卡片改造成目标图中的“内容收藏卡片”  
> 前置条件：Phase 1-3 已完成  
> 主要文件：`saved_item_card.dart`  
> 不改数据层

---

## 1. 目标图卡片结构

目标图中单条内容卡片结构：

```text
[icon / thumbnail]  标题                                  [状态 chip] [星标] [...]
                    来源 · 类型 · 时间
                    标签 chips
```

示例：

```text
[Notion icon] Notion AI 最新功能全解析：提升效率的 10 个技巧      [待看] ☆ ...
              notion.so/blog · 网页 · 今天 10:23
              #生产力  #Notion  #效率工具
```

---

## 2. 当前问题

当前 `SavedItemCard` 已经能渲染，但仍存在：

1. 更像技术列表项，而不是内容收藏卡片。
2. 描述和 chips 信息密度还不稳定。
3. Box 分配按钮裸露在卡片右侧，目标图中更像“更多菜单”里的能力。
4. 状态、Box、星标、更多操作的视觉层级需重排。
5. 需要继续防止 Row overflow。

---

## 3. 非目标

Phase 4 不做：

1. 不新增 `isFavorite` 字段。
2. 不新增 tags 表。
3. 不保存星标。
4. 不保存标签。
5. 不新增真实缩略图缓存。
6. 不改 Repository。
7. 不改数据库。

星标、标签先做 UI 占位或复用已有数据。

---

## 4. 卡片目标布局

### 4.1 主结构

```dart
InkWell(
  child: Container(
    child: Row(
      children: [
        _SourceIconOrThumbnail(),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _ContentBlock(),
        ),
        const SizedBox(width: AppSpacing.sm),
        _RightActions(),
      ],
    ),
  ),
)
```

### 4.2 左侧 icon

根据内容类型显示：

| 类型 | icon |
|---|---|
| webpage | language |
| video | play circle / thumbnail |
| article | article |
| repository | code |
| pdf | picture_as_pdf |
| unknown | link |

如果有 `favicon` 或 `coverImage`，Phase 4 可以不加载真实图片，先用图标容器。

### 4.3 内容块

```text
标题
来源 · 类型 · 时间
标签 chips
```

标题：

```dart
maxLines: 1
overflow: TextOverflow.ellipsis
```

副信息：

```text
siteName/domain · mediaType.label · relativeTime(createdAt)
```

标签 chips：

当前无 tags 字段，因此使用以下 fallback：

1. Box 名称。
2. sourcePlatform。
3. mediaType。
4. 如果都没有，隐藏 chips。

---

## 5. 右侧操作区

目标：

```text
[状态 chip] [星标 icon] [更多 icon]
```

### 5.1 状态 chip

继续支持状态切换：

```dart
PopupMenuButton<ConsumptionStatus>
```

但样式要压缩：

```text
maxWidth: 72
文本 ellipsis
VisualDensity.compact
```

### 5.2 星标

第一版 UI 占位：

```dart
IconButton(
  tooltip: '星标功能稍后接入',
  icon: Icon(Icons.star_border_rounded),
  onPressed: () => show SnackBar
)
```

不要落库。

### 5.3 更多菜单

把部分动作放入更多菜单：

```text
打开内容
分配收藏夹
复制链接
归档
```

Phase 4 可先实现：

1. 复制链接。
2. 归档。
3. 分配收藏夹可复用现有 `_BoxAssignmentButton` 逻辑，也可保留原按钮但视觉隐藏为菜单项。

---

## 6. 选中态

选中态应接近目标图：

```text
淡蓝背景
蓝色描边
不是大面积强蓝
```

规则：

```dart
color: selected
  ? colorScheme.primaryContainer.withValues(alpha: 0.12)
  : colorScheme.surface

border: selected
  ? Border.all(color: colorScheme.primary, width: 1.2)
  : Border.all(color: colorScheme.outlineVariant)
```

---

## 7. 卡片尺寸

| 项 | 建议 |
|---|---|
| 高度 | 92-112 |
| icon | 48 x 48 |
| 内边距 | horizontal 14-16, vertical 12 |
| 标题 | 1 行 |
| 副信息 | 1 行 |
| tags | 1 行，可 wrap 或横向截断 |
| 右侧操作 | 固定宽度，避免撑爆 |

---

## 8. Overflow 防护

必须使用：

```dart
Expanded
Flexible
TextOverflow.ellipsis
ConstrainedBox
FittedBox 或 OverflowBar
```

右侧操作建议：

```dart
SizedBox(
  width: 128,
  child: Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [...]
  ),
)
```

如果宽度不足，改成：

```dart
Column(
  crossAxisAlignment: CrossAxisAlignment.end,
  children: [
    statusChip,
    Row(children: [star, more]),
  ],
)
```

---

## 9. 标签 chips 策略

当前无 tags 字段。

### 9.1 MVP 展示

用 Box 名称作为标签感 chips：

```text
AI / 设计 / 工具
```

再补充：

```text
mediaType.label
sourcePlatform.label
```

但不要显示太多：

```text
最多 3 个
超过显示 +N
```

---

## 10. 验收标准

- [ ] 卡片结构接近目标图。
- [ ] 标题一行截断。
- [ ] 副信息显示来源 / 类型 / 时间。
- [ ] 状态 chip 在右侧。
- [ ] 星标 UI 出现，但不落库。
- [ ] 更多菜单出现。
- [ ] Box 分配能力不丢失。
- [ ] 点击卡片仍能选中并更新右侧详情。
- [ ] 无 Row overflow。
- [ ] `flutter analyze` 通过。

---

## 11. Codex 执行指令

```text
只执行 Phase 4：将 SavedItemCard 改造成目标图中的内容收藏卡片。

修改：
lib/src/plugins/collections/ui/widgets/saved_item_card.dart

要求：
1. 卡片布局改为：
   左侧 icon/thumbnail
   中间标题、副信息、标签 chips
   右侧状态 chip、星标、更多菜单
2. 标题 maxLines=1，ellipsis。
3. 副信息显示 source/siteName/domain + mediaType + relativeTime。
4. tags 当前无数据，先用 Box 名称 / sourcePlatform / mediaType 作为 chips，最多 3 个。
5. 星标按钮只做 UI 占位，点击提示“星标功能稍后接入”，不落库。
6. 更多菜单包含：打开内容、复制链接、分配收藏夹、归档。
7. 保留状态切换功能。
8. 保留 selected/onTap 功能。
9. 不改数据库，不改 Repository，不新增字段。
10. 严格防止 Row overflow。
11. flutter analyze 通过。
```
