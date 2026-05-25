# Phase 2 PRD：Header 与快速收藏区迁移

> 阶段目标：将顶部区域迁移为目标图中的“内容收藏”Header 与快速收藏条  
> 前置条件：Phase 1 三栏结构已完成  
> 改动范围：`CollectionsDesktopLayout`、`CollectionCaptureBar`、新增 Header 子组件可选  
> 优先级：P1

---

## 1. 目标

目标图顶部结构：

```text
内容收藏                              [搜索收藏内容（标题 / 来源 / 标签 / URL）  ⌘ K]    [导入] [刷新]
收集网页、视频、公众号、文章与其他值得保存的内容。

[🔗 粘贴链接、文章地址或内容来源，按 Enter 快速收藏]            [记录想法 / 收藏]
```

---

## 2. 当前状态

当前 Header 中已有：

1. 标题。
2. 副标题。
3. 刷新按钮。
4. `CollectionCaptureBar`。
5. 搜索仍在 `CollectionSearchFilterBar` 内。

需要迁移：

1. 页面标题改为“内容收藏”。
2. 副标题改为目标图文案。
3. Header 中间增加搜索框。
4. Header 右侧增加导入按钮。
5. 快速收藏条改文案和视觉。
6. 中栏筛选区仍保留一个局部搜索，但后续 Phase 3 可弱化或保留。

---

## 3. Header 文案

### 3.1 标题

```text
内容收藏
```

### 3.2 副标题

```text
收集网页、视频、公众号、文章与其他值得保存的内容。
```

### 3.3 顶部搜索 placeholder

```text
搜索收藏内容（标题 / 来源 / 标签 / URL）
```

### 3.4 快速收藏 placeholder

```text
粘贴链接、文章地址或内容来源，按 Enter 快速收藏
```

### 3.5 快速收藏按钮

建议第一版仍使用：

```text
收藏
```

目标图里是“记录想法”，但当前业务链路是 URL 收藏。除非同时接入 thoughts，否则不建议改成“记录想法”。

可选折中：

```text
快速收藏
```

---

## 4. 新增 Header 搜索框

### 4.1 数据绑定

复用：

```dart
collectionSearchQueryProvider
```

### 4.2 行为

输入时：

```dart
ref.read(collectionSearchQueryProvider.notifier).state = value;
```

### 4.3 快捷键提示

右侧显示视觉提示：

```text
⌘ K
```

Windows 下可以显示：

```text
Ctrl K
```

但 Phase 2 不要求实现真实快捷键。

### 4.4 样式

```text
宽度：360-480
高度：40
圆角：AppRadius.md
背景：surface
边框：outlineVariant
prefix icon：search
```

---

## 5. 导入按钮

### 5.1 第一版行为

导入功能第一版只做 UI 占位。

```dart
OutlinedButton.icon(
  onPressed: null,
  icon: const Icon(Icons.download_rounded),
  label: const Text('导入'),
)
```

或启用但提示：

```dart
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(content: Text('导入功能稍后接入')),
);
```

推荐启用提示，不要 disabled，因为 disabled 视觉太弱。

### 5.2 后续规划

真实导入能力放到 Phase 6 数据增强，不在本阶段实现。

---

## 6. 刷新按钮

保留当前行为：

```dart
onPressed: () => ref.invalidate(savedItemsListProvider)
```

文案：

```text
刷新
```

图标：

```dart
Icons.refresh_rounded
```

---

## 7. `CollectionCaptureBar` 修改

### 7.1 保留业务逻辑

不改：

1. URL normalize。
2. createSavedItem。
3. enqueue job。
4. runPendingJobs。
5. duplicate 处理。

### 7.2 修改文案

输入框 placeholder：

```text
粘贴链接、文章地址或内容来源，按 Enter 快速收藏
```

按钮：

```text
收藏
```

### 7.3 Enter 行为

如果当前 `CollectionCaptureBar` 尚未支持 Enter 提交，本阶段可以增加：

```dart
onSubmitted: (_) => _submit()
```

若实现较复杂，可以放到后续，但目标图强调“按 Enter”。

### 7.4 视觉

快速收藏条应是一整条横向卡片：

```text
左侧 link icon
中间 Expanded TextField
右侧 FilledButton
```

高度约：

```text
56-64
```

---

## 8. 布局目标

### 8.1 Header Row

```dart
Row(
  children: [
    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('内容收藏'),
          Text('收集网页、视频、公众号、文章与其他值得保存的内容。'),
        ],
      ),
    ),
    SizedBox(
      width: 420,
      child: HeaderSearchField(),
    ),
    const SizedBox(width: AppSpacing.sm),
    OutlinedButton.icon(...导入...),
    const SizedBox(width: AppSpacing.sm),
    FilledButton.icon(...刷新...),
  ],
)
```

### 8.2 响应式

当宽度不足时：

1. Header 搜索框宽度降低到 300。
2. 导入按钮可只显示 icon。
3. 标题块保持最优先。
4. 不允许 Row overflow。

建议用 `LayoutBuilder`：

```dart
final compact = constraints.maxWidth < 1100;
```

compact 时：

```text
搜索框 300
导入按钮 icon-only 或隐藏 label
刷新按钮 icon-only 或短文案
```

---

## 9. 验收标准

- [ ] 标题显示“内容收藏”。
- [ ] 副标题显示新文案。
- [ ] Header 中间出现搜索框。
- [ ] 搜索框能修改 `collectionSearchQueryProvider` 并影响列表。
- [ ] 右侧有导入按钮。
- [ ] 右侧有刷新按钮且可刷新列表。
- [ ] 快速收藏输入框文案更新。
- [ ] 快速收藏原有逻辑不破坏。
- [ ] 无 Row overflow。
- [ ] `flutter analyze` 通过。

---

## 10. Codex 执行指令

```text
只执行 Phase 2：迁移 Header 与快速收藏区。

前提：
Phase 1 三栏结构已完成。

修改：
- CollectionsDesktopLayout
- CollectionCaptureBar
可选新增：
- collection_header.dart
- header_search_field.dart

要求：
1. 页面标题改为“内容收藏”。
2. 副标题改为“收集网页、视频、公众号、文章与其他值得保存的内容。”
3. Header 中间加入搜索框，绑定 collectionSearchQueryProvider。
4. 搜索框 placeholder：搜索收藏内容（标题 / 来源 / 标签 / URL）。
5. Header 右侧加入“导入”按钮，第一版点击提示“导入功能稍后接入”。
6. 保留刷新按钮，继续 invalidate savedItemsListProvider。
7. CollectionCaptureBar placeholder 改为：粘贴链接、文章地址或内容来源，按 Enter 快速收藏。
8. 快速收藏按钮文案用“收藏”或“快速收藏”。
9. 如成本低，支持 TextField onSubmitted 提交。
10. 不改数据库、不改 Repository、不改 EnrichmentJobService。
11. 使用 LayoutBuilder 防止 Header Row overflow。
12. flutter analyze 通过。
```
