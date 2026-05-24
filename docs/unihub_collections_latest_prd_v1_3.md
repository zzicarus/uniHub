# PRD：uniHub 收藏模块 v1.4 —— 按目标图实现“收藏整理工作台”

> 目标：基于当前最新代码，把收藏页从“单栏书签列表”升级为接近目标图的“收藏整理工作台”。  
> 范围：主要修改 Collections UI 层与少量 Provider，不改数据库 schema，不重写业务服务。  
> 目标页面：左侧收藏列表 + 右侧详情整理面板；顶部快速收藏；中部系统视图、Box、搜索筛选分区清晰。

---

## 1. 当前代码状态

### 1.1 当前已具备能力

当前 collections 模块已经具备以下基础能力：

1. `CollectionsDesktopLayout` 已存在，但仍是单栏结构：
   - Header
   - `CollectionCaptureBar`
   - `CollectionFilterBar`
   - `ListView<SavedItemCard>`

2. `CollectionFilterBar` 已包含：
   - CollectionView chips：Inbox / 全部 / 未看 / 进行中 / 已看 / 归档
   - 搜索框
   - 来源平台 Dropdown
   - 媒介类型 Dropdown
   - 状态 FilterChip
   - Box FilterChip

3. `SavedItemCard` 已包含：
   - 标题
   - 描述
   - 来源平台 chip
   - 媒介类型 chip
   - enrichment 状态 chip
   - 已打开 chip
   - URL 行
   - 打开按钮
   - 状态切换菜单
   - Box 分配按钮

4. Repository 已有关键方法：
   - `getSavedItem`
   - `getBoxIdsForItem`
   - `setItemBoxes`
   - `updateInboxState`
   - `createBox`
   - `queryItems`
   - `updateStatus`

5. `queryItems` 已使用 Box OR 语义：
   - 选中多个 Box 时，属于任意一个 Box 即可出现。

6. `updateStatus` 已不再修改 `isInInbox`。

7. `SourcePlatform` 和 `MediaType` 已扩展：
   - 支持网页、微信、Bilibili、YouTube、GitHub、知乎、小红书、Twitter、豆瓣、PDF、本地文件等来源。
   - 支持文章、视频、网页、图片、PDF、音频、帖子、代码仓库、文档等媒介。

8. `UrlNormalizer` 已支持清理常见 tracking 参数：
   - `utm_source`
   - `utm_medium`
   - `utm_campaign`
   - `utm_term`
   - `utm_content`
   - `spm`
   - `from`
   - `share_source`

9. `EnrichmentJobService.runPendingJobs()` 已存在，metadata 抓取不再需要在本 PRD 中重做。

---

## 2. 当前主要问题

当前页面的问题不是底层业务，而是 UI 信息架构：

1. 页面仍是单栏列表，不符合目标图中的左右工作台结构。
2. 筛选区堆叠过多，系统视图、Box、搜索、来源、媒介、状态没有清晰分层。
3. 右侧详情整理面板缺失，用户不能在一个稳定区域整理选中收藏项。
4. `SavedItemCard` 缺少 selected 态，无法与详情面板联动。
5. enrichment / metadata 状态仍在卡片主要 chip 中，视觉权重过高。
6. 状态、Box、标签、备注、摘要、技术信息没有在详情面板中按优先级组织。
7. 当前没有 `selectedSavedItemIdProvider`。
8. 当前没有 `SavedItemDetailPanel`、`CollectionViewChips`、`CollectionBoxBar`、`CollectionSearchFilterBar` 等目标结构组件。

---

## 3. 产品目标

### 3.1 一句话目标

```text
把收藏页做成“收藏整理工作台”：顶部快速收藏，中部清晰筛选，左侧浏览收藏，右侧整理选中内容。
```

### 3.2 用户心智

用户进入收藏页后，应该自然理解：

```text
1. Inbox 是待整理入口。
2. Box 是分类归属，一个收藏可以属于多个 Box。
3. 状态表示消费进度：未看 / 进行中 / 已看 / 归档。
4. 左侧是收藏列表，右侧是当前收藏项的整理面板。
5. metadata 抓取只是技术状态，不是核心用户功能。
```

---

## 4. 本阶段范围

### 4.1 必须做

1. `CollectionsDesktopLayout` 改为目标图中的工作台结构。
2. 新增选中收藏项状态：`selectedSavedItemIdProvider`。
3. 左侧列表使用 `SavedItemCard(selected, onTap)`。
4. 右侧新增 `SavedItemDetailPanel`。
5. 拆分筛选区：
   - `CollectionViewChips`
   - `CollectionBoxBar`
   - `CollectionSearchFilterBar`
6. `SavedItemCard` 改为更紧凑的列表卡片。
7. enrichment 成功状态不再作为主要 chip 展示；失败时只弱提示。
8. 详情面板中实现：
   - 标题区
   - 链接区
   - 状态区
   - 所属 Box 区
   - 标签占位
   - 备注占位
   - 内容 Tabs
   - 底部技术信息折叠区
9. 摘要只在“摘要”tab 中出现。
10. 技术信息只在底部折叠区出现。

### 4.2 不做

1. 不修改数据库 schema。
2. 不新增 tags 字段。
3. 不新增 notes 字段。
4. 不修改 Drift migration。
5. 不重写 `CollectionCaptureService`。
6. 不重写 `EnrichmentJobService`。
7. 不实现远程后端。
8. 不实现 AI 摘要。
9. 不实现浏览器插件。
10. 不修改 thoughts 模块。
11. 不做移动端布局大改。
12. 不在本任务中重构 `SavedItemCard._openOriginalUrl` 为 `url_launcher`，除非项目已有依赖且改动很小。

---

## 5. 目标图结构拆解

目标图中的收藏页结构如下：

```text
左侧：全局导航栏
右侧主页面：
  Header
    标题：收藏
    副标题
    刷新按钮

  Quick Capture Card
    链接图标
    输入框：粘贴 URL，快速收藏到 Inbox...
    收藏按钮

  View Chips
    Inbox / 全部 / 未看 / 进行中 / 已看 / 归档

  Box Section
    标题：Box（可多选，一个收藏可属于多个 Box）
    AI 学习 / 视频 / 论文 / 产品设计 / 工具链 / + 新建 Box

  Search Filter Row
    搜索框
    全部来源
    全部媒介
    最新收藏
    清空筛选

  Main Body
    Left List
      SavedItemCard
      SavedItemCard
      SavedItemCard
      Bulk Action Bar

    Right Detail Panel
      顶部标题区
      链接区
      状态区
      Box 区
      标签区
      备注区
      Tabs：摘要 / 内容预览 / 笔记 / 相关
      技术信息折叠区
```

---

## 6. 视觉风格要求

### 6.1 总体风格

1. Material 3。
2. 浅色背景。
3. 白色卡片。
4. 细边框。
5. 轻阴影。
6. 柔和蓝色 / 靛蓝主色。
7. 低饱和 chip。
8. 信息密度比当前更高，但不拥挤。
9. 现代生产力工具风格，不要后台管理风。

### 6.2 具体风格

| 元素 | 要求 |
|---|---|
| 页面背景 | 使用当前 App 背景色，不要纯白大面积无层次 |
| 卡片 | `surface` + `outlineVariant` |
| 选中卡片 | primary outline 或 primaryContainer 淡背景 |
| Chip | pill 形，低饱和背景 |
| 主按钮 | FilledButton，蓝色主色 |
| 技术信息 | 低优先级、折叠、底部 |
| metadata 状态 | 不做主视觉 |

---

## 7. Provider 需求

### 7.1 新增 Provider

在 `collections_providers.dart` 中新增：

```dart
final selectedSavedItemIdProvider = StateProvider<int?>((ref) => null);
```

### 7.2 使用规则

1. 点击左侧 `SavedItemCard` 时更新 `selectedSavedItemIdProvider`。
2. 右侧详情面板根据 selected id 找到当前 item。
3. 当列表刷新后：
   - 如果 selected id 对应 item 仍存在，继续显示。
   - 如果不存在且列表非空，显示第一项。
   - 如果列表为空，显示 null 空状态。
4. 不要把 `selectedCollectionBoxIdsProvider` 当成当前 item 的所属 Box。

---

## 8. 文件修改清单

### 8.1 修改文件

```text
lib/src/plugins/collections/ui/layouts/collections_desktop_layout.dart
lib/src/plugins/collections/ui/widgets/collection_filter_bar.dart
lib/src/plugins/collections/ui/widgets/saved_item_card.dart
lib/src/plugins/collections/ui/widgets/collection_capture_bar.dart
lib/src/plugins/collections/providers/collections_providers.dart
```

### 8.2 新增文件

```text
lib/src/plugins/collections/ui/widgets/collection_view_chips.dart
lib/src/plugins/collections/ui/widgets/collection_box_bar.dart
lib/src/plugins/collections/ui/widgets/collection_search_filter_bar.dart
lib/src/plugins/collections/ui/widgets/saved_item_detail_panel.dart
lib/src/plugins/collections/ui/widgets/collection_technical_info_section.dart
```

### 8.3 可选新增文件

```text
lib/src/plugins/collections/ui/widgets/collection_empty_detail.dart
lib/src/plugins/collections/ui/widgets/collection_bulk_action_bar.dart
```

---

## 9. CollectionsDesktopLayout 需求

### 9.1 目标结构

将当前单栏结构：

```text
Column
├── Header
├── CollectionCaptureBar
├── CollectionFilterBar
└── ListView
```

改为：

```text
Column
├── Header
├── CollectionCaptureBar
├── CollectionViewChips
├── CollectionBoxBar
├── CollectionSearchFilterBar
└── Expanded
    └── Row
        ├── Expanded List Panel
        └── SizedBox(width: 400) Detail Panel
```

### 9.2 详情面板宽度

```dart
const detailPanelWidth = 400.0;
```

允许范围：

```text
360 - 420
```

### 9.3 列表与详情联动

伪代码：

```dart
final selectedId = ref.watch(selectedSavedItemIdProvider);

final selectedItem = items.where((item) => item.id == selectedId).firstOrNull;
final fallbackItem = selectedItem ?? (items.isNotEmpty ? items.first : null);

if (selectedId == null && items.isNotEmpty) {
  // 不要在 build 同步写 state；可用 postFrameCallback
  WidgetsBinding.instance.addPostFrameCallback((_) {
    ref.read(selectedSavedItemIdProvider.notifier).state = items.first.id;
  });
}
```

如果不想自动设置 selected id，也可以仅让右侧显示 `items.first` 作为 fallback，但点击卡片才真正更新 selectedId。

### 9.4 空状态

1. items 为空：
   - 左侧显示 `_EmptyState`。
   - 右侧显示 `SavedItemDetailPanel(item: null)`。
2. error：
   - 主体区域显示 error state。
3. loading：
   - 主体区域显示 loading。

---

## 10. CollectionViewChips 需求

### 10.1 展示

```text
Inbox / 全部 / 未看 / 进行中 / 已看 / 归档
```

### 10.2 行为

1. 读取 `collectionViewProvider`。
2. 点击更新 `collectionViewProvider`。
3. 不要同时更新 `collectionStatusFilterProvider`。
4. 当前选中 chip 使用 primary 样式。
5. 不选中 chip 使用低饱和样式。

### 10.3 注意

主界面不再展示 `collectionStatusFilterProvider` 对应的第二套状态 chips。否则目标图会出现重复状态概念。

---

## 11. CollectionBoxBar 需求

### 11.1 结构

```text
Box（可多选，一个收藏可属于多个 Box）
[AI 学习] [视频] [论文] [产品设计] [工具链] [+ 新建 Box]
```

### 11.2 数据

使用：

```dart
collectionBoxesProvider
selectedCollectionBoxIdsProvider
collectionsRepositoryProvider.createBox
```

### 11.3 行为

1. Box chip 多选。
2. selectedBoxIds 为空表示全部 Box。
3. 不显示“全部 Box”chip。
4. 点击 `+ 新建 Box`：
   - 打开 dialog。
   - 输入名称。
   - 调用 `repository.createBox(name)`。
   - `ref.invalidate(collectionBoxesProvider)`。
5. Box 为空时显示：
   ```text
   暂无 Box，点击新建开始整理收藏。
   ```

### 11.4 重要约束

`CollectionBoxBar` 的 Box 是列表筛选，不是当前 item 的 Box 编辑。

---

## 12. CollectionSearchFilterBar 需求

### 12.1 结构

```text
[搜索标题、描述或 URL] [全部来源] [全部媒介] [最新收藏] [清空筛选]
```

### 12.2 数据

使用：

```dart
collectionSearchQueryProvider
collectionPlatformFilterProvider
collectionMediaTypeFilterProvider
collectionStatusFilterProvider
selectedCollectionBoxIdsProvider
```

### 12.3 清空筛选行为

点击清空筛选：

```dart
collectionSearchQueryProvider = ''
collectionPlatformFilterProvider = null
collectionMediaTypeFilterProvider = null
collectionStatusFilterProvider = null
selectedCollectionBoxIdsProvider = {}
```

不要重置：

```dart
collectionViewProvider
```

### 12.4 排序

排序第一版只做 UI 占位：

```text
最新收藏
```

不改 repository。

---

## 13. SavedItemCard 需求

### 13.1 新构造

```dart
class SavedItemCard extends ConsumerWidget {
  const SavedItemCard({
    required this.item,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final SavedItemsTableData item;
  final bool selected;
  final VoidCallback onTap;
}
```

### 13.2 展示内容

1. 左侧 checkbox 或 selected indicator。
2. 平台 / 媒介图标。
3. 标题。
4. 描述。
5. 平台 chip。
6. 媒介类型 chip。
7. 状态 chip。
8. Box chips。
9. 时间信息。
10. 打开按钮。
11. 抓取失败小提示。

### 13.3 Box chips

当前 `SavedItemCard` 没有直接拿到 item 所属 Box 名称。可选实现：

#### 方案 A：最小可执行

卡片不展示 Box chips，只在右侧详情展示。  
但目标图中需要 Box chips，因此此方案视觉不够完整。

#### 方案 B：推荐

新增一个 lightweight widget：

```dart
class _ItemBoxChips extends ConsumerWidget {
  final int itemId;
}
```

内部：

1. 调用 repository.getBoxIdsForItem(itemId)。
2. 读取 collectionBoxesProvider。
3. 匹配 box names。
4. 最多展示 2 个，超出显示 `+N`。

注意：这会在列表每个 item 上触发 Future。MVP 可接受，但后续应优化为 view model。

### 13.4 enrichment 展示

1. 不再常规展示 enrichmentStatus chip。
2. 如果 `EnrichmentStatus.failed`：
   - 显示小型红色/橙色 chip：`抓取失败`
3. success / pending / running 不在卡片主要区域展示。
4. 完整技术状态交给详情面板底部。

### 13.5 selected 样式

selected 时：

```text
side: BorderSide(color: theme.colorScheme.primary, width: 1.5)
background: theme.colorScheme.primaryContainer.withOpacity(...)
```

未选中：

```text
outlineVariant
surface
```

### 13.6 高度

目标高度：

```text
120 - 150px
```

避免当前卡片过高。

---

## 14. SavedItemDetailPanel 需求

### 14.1 文件

新增：

```text
lib/src/plugins/collections/ui/widgets/saved_item_detail_panel.dart
```

### 14.2 输入

```dart
class SavedItemDetailPanel extends ConsumerWidget {
  const SavedItemDetailPanel({
    required this.item,
    super.key,
  });

  final SavedItemsTableData? item;
}
```

### 14.3 空状态

当 `item == null`：

```text
选择一条收藏
在左侧列表中选择内容后，可在这里整理状态、Box 和备注。
```

### 14.4 有内容时整体结构

```text
Header
Link Section
Status Section
Box Section
Tags Placeholder
Notes Placeholder
Content Tabs
Technical Info Expansion
```

---

## 15. Detail Header 设计

### 15.1 内容

1. 图标：根据 MediaType。
2. 标题：`item.title.isEmpty ? item.normalizedUrl : item.title`
3. 副信息：
   ```text
   SourcePlatform.label · X 时间前收藏
   ```
4. 打开原文按钮。
5. 更多按钮占位。

### 15.2 规则

1. 标题最多 2 行。
2. 外部打开按钮放右上。
3. 不展示 metadata 抓取状态。

---

## 16. 链接区设计

### 16.1 内容

```text
链接
https://...
[复制]
```

### 16.2 行为

复制按钮使用：

```dart
Clipboard.setData(ClipboardData(text: item.originalUrl));
```

成功后 SnackBar：

```text
已复制链接
```

---

## 17. 状态区设计

### 17.1 内容

```text
状态
[未看] [进行中] [已看] [归档]
```

### 17.2 行为

点击后：

```dart
await repository.updateStatus(item.id, next);
ref.invalidate(savedItemsListProvider);
```

### 17.3 约束

状态切换不应修改 `isInInbox`。

---

## 18. 当前 item 的 Box 编辑区

### 18.1 内容

```text
所属 Box（可多选）
[AI 学习] [生活记录] [+ 选择 Box]
```

### 18.2 数据

使用：

```dart
repository.getBoxIdsForItem(item.id)
repository.setItemBoxes(item.id, next)
repository.updateInboxState(item.id, next.isEmpty)
collectionBoxesProvider
```

### 18.3 行为

1. 显示所有 Box。
2. 当前 item 所属 Box 高亮。
3. 点击 Box chip 切换选中。
4. 如果 next 非空：
   ```dart
   updateInboxState(item.id, false)
   ```
5. 如果 next 为空：
   ```dart
   updateInboxState(item.id, true)
   ```
6. 操作后：
   ```dart
   ref.invalidate(savedItemsListProvider);
   ref.invalidate(collectionBoxesProvider);
   ```

### 18.4 约束

不要使用 `selectedCollectionBoxIdsProvider` 来表示当前 item 所属 Box。

---

## 19. 标签与备注占位

### 19.1 标签区

当前没有 tags 字段。

显示：

```text
标签
标签功能稍后接入
```

可以做几个视觉占位 chip，但不要保存。

### 19.2 备注区

当前没有 notes 字段。

显示：

```text
备注
备注功能稍后接入
```

可以展示一个 disabled input 风格，不要保存。

---

## 20. 内容 Tabs

### 20.1 Tabs

```text
摘要 / 内容预览 / 笔记 / 相关
```

### 20.2 摘要 Tab

展示：

```dart
item.description?.trim().isNotEmpty == true
  ? item.description!
  : '暂无摘要'
```

### 20.3 内容预览 Tab

展示基础信息：

```text
标题
站点
作者
原链接
标准化链接
```

### 20.4 笔记 Tab

占位：

```text
笔记功能稍后接入
```

### 20.5 相关 Tab

占位：

```text
相关想法 / 待办 / 笔记稍后接入
```

### 20.6 关键约束

摘要只在“摘要”Tab 中展示。  
不要在 Tab 上方额外增加摘要块。

---

## 21. 技术信息区

### 21.1 位置

右侧详情面板底部。

### 21.2 形式

使用：

```dart
ExpansionTile
```

或弱化 Card。

默认 collapsed。

### 21.3 内容

```text
抓取状态：enrichmentStatus.label
来源平台：sourcePlatform.label
媒介类型：mediaType.label
最后打开：lastOpenedAt
更新时间：updatedAt
创建时间：createdAt
```

### 21.4 视觉权重

1. 不使用大面积色块。
2. 不放在右侧中部核心区。
3. 不抢状态、Box、摘要的视觉权重。
4. 不在卡片和详情中重复展示完整 metadata。

---

## 22. Bulk Action Bar

目标图底部左侧有已选择项操作条。

### 22.1 本阶段建议

第一版可以只做 UI 占位，不实现多选批量逻辑。

显示条件：

```text
当 selectedSavedItemId != null
```

内容：

```text
已选择 1 项
[标记已看] [移动] [添加到 Box] [归档]
```

### 22.2 可执行行为

最小实现：

1. 标记已看：调用 `updateStatus(done)`
2. 归档：调用 `updateStatus(archived)`
3. 移动 / 添加到 Box：可暂时 disabled 或打开右侧 Box 区提示

如果觉得超范围，本阶段可以不做 Bulk Action Bar，但目标图一致性会降低。

---

## 23. CollectionCaptureBar 微调

当前快速收藏逻辑可保留。

只做视觉和文案微调：

1. placeholder：
   ```text
   粘贴 URL，快速收藏到 Inbox...
   ```
2. 主按钮：
   ```text
   收藏
   ```
3. 不等待 metadata 完成。
4. 保存成功提示：
   ```text
   已加入 Inbox
   ```
5. duplicate 提示：
   ```text
   已收藏
   ```

---

## 24. 验收标准

### 24.1 页面结构

- [ ] 页面顶部有标题、副标题、刷新按钮。
- [ ] 顶部有快速收藏输入栏。
- [ ] 系统视图 chips 独立成区。
- [ ] Box 区独立成区。
- [ ] 搜索/来源/媒介/排序筛选独立成区。
- [ ] 主体为左列表 + 右详情面板。
- [ ] 右详情面板宽度约 400px。

### 24.2 交互

- [ ] 点击左侧卡片后，右侧详情显示对应 item。
- [ ] selected 卡片有明显选中态。
- [ ] 列表为空时有 empty state。
- [ ] 无选中项时详情面板有 empty state。
- [ ] 快速收藏仍可用。
- [ ] 现有筛选仍可用。
- [ ] 状态切换仍可用。
- [ ] Box 筛选仍可用。
- [ ] 当前 item 的 Box 编辑不误用列表 Box 筛选状态。

### 24.3 详情面板

- [ ] 展示标题、来源、链接。
- [ ] 支持复制链接。
- [ ] 支持状态切换。
- [ ] 支持当前 item Box 多选编辑。
- [ ] 标签显示占位。
- [ ] 备注显示占位。
- [ ] 有摘要 / 内容预览 / 笔记 / 相关 tabs。
- [ ] 摘要只在摘要 tab 中出现。
- [ ] 技术信息在底部折叠。
- [ ] metadata/enrichment 状态不在核心区域突出展示。

### 24.4 代码约束

- [ ] 不修改数据库 schema。
- [ ] 不修改 migration。
- [ ] 不重写业务服务。
- [ ] 不新增 tags/notes 字段。
- [ ] 不修改 thoughts 模块。
- [ ] `flutter analyze` 通过。

---

## 25. 推荐任务拆分

### Task 1：Provider + 布局骨架

```text
新增 selectedSavedItemIdProvider。
CollectionsDesktopLayout 改为 Header + Capture + View + Box + Search + Body Row。
新增 SavedItemDetailPanel 空壳。
SavedItemCard 支持 selected/onTap。
```

### Task 2：筛选组件拆分

```text
新增 CollectionViewChips。
新增 CollectionBoxBar。
新增 CollectionSearchFilterBar。
CollectionFilterBar 改为组合组件或停止在 DesktopLayout 使用。
移除主界面重复状态 chips。
```

### Task 3：详情面板完整实现

```text
SavedItemDetailPanel 实现：
Header
Link Section
Status Section
Box Section
Tags Placeholder
Notes Placeholder
Tabs
Technical Info Expansion
```

### Task 4：卡片视觉与信息降权

```text
SavedItemCard 压缩高度。
增加 selected 态。
隐藏常规 enrichment success chip。
failed 时显示轻提示。
展示 Box chips。
```

### Task 5：目标图一致性修正

```text
对齐间距、圆角、边框、chip 风格。
补 Bulk Action Bar 占位或最小行为。
确保整体接近目标图。
```

---

## 26. 直接给 AI 的执行提示词

```text
只执行收藏模块 UI 工作台重构。

当前底层已经基本完成：
- updateStatus 不污染 isInInbox
- Box 筛选已是 OR
- getBoxIdsForItem / setItemBoxes 已存在
- UrlNormalizer 已清理 tracking 参数
- SourcePlatform / MediaType 已扩展
- EnrichmentJobService.runPendingJobs 已存在

不要再修这些底层问题。

本次目标是严格按目标图重构收藏页 UI：
1. CollectionsDesktopLayout 从单栏改为工作台布局。
2. 顶部保留标题、副标题、刷新、快速收藏。
3. 中部拆成 ViewChips、BoxBar、SearchFilterBar。
4. 主体改为左侧 SavedItem 列表 + 右侧 SavedItemDetailPanel。
5. SavedItemCard 增加 selected/onTap，点击后右侧详情更新。
6. 右侧详情面板聚焦整理：状态、Box、链接、标签占位、备注占位、内容 tabs。
7. 摘要只在“摘要”tab 中展示。
8. metadata/enrichment 只放到底部“技术信息”折叠区。
9. 不修改数据库 schema，不新增 tags/notes 字段。
10. 完成后运行 flutter analyze。
```
