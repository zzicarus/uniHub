# uniHub 内容收藏模块迁移总 PRD：从“收藏页”到“三栏内容收藏工作台”

> 目标参考：最新目标图中的“内容收藏”页面  
> 适用仓库：`zzicarus/uniHub`  
> 适用模块：`lib/src/plugins/collections/`  
> 当前阶段：已有稳定渲染版；下一步按阶段迁移到“内容收藏”三栏工作台  
> 核心原则：先迁移信息架构，再优化视觉，最后补数据能力

---

## 1. 当前代码基础

当前收藏模块已经具备以下基础：

1. `CollectionsDesktopLayout` 已经存在，并且已经不是最初单栏结构。
2. 当前结构已经包含：
   - Header
   - `CollectionCaptureBar`
   - `CollectionViewChips`
   - `CollectionBoxBar`
   - `CollectionSearchFilterBar`
   - 左侧收藏列表
   - 右侧 `SavedItemDetailPanel`
3. `SavedItemDetailPanel` 的 `TabBarView` 无界高度问题已经修复。
4. `RenderFlex overflow` 问题也已进入可控修复阶段。
5. Repository / Provider / Drift 数据结构已经支持当前收藏模块主要能力。
6. `CollectionBoxBar` 已能读取 Box、创建 Box、进行 Box 筛选。
7. `CollectionSearchFilterBar` 已能搜索、来源筛选、媒介筛选、清空筛选。
8. `CollectionViewChips` 已能切换 Inbox / 全部 / 未看 / 进行中 / 已看 / 归档。
9. `SavedItemCard` 和 `SavedItemDetailPanel` 已经能正常渲染。

---

## 2. 新目标图的信息架构变化

新目标图不再是单纯“网页收藏”，而是更泛化的：

```text
内容收藏
```

覆盖对象包括：

```text
网页 / 视频 / 公众号 / 文章 / 工具 / 其他内容来源
```

目标结构：

```text
DesktopShell
├── 左侧全局导航
└── 内容收藏页面
    ├── Header
    │   ├── 内容收藏标题
    │   ├── 副标题
    │   ├── 顶部全局搜索
    │   ├── 导入按钮
    │   └── 刷新按钮
    │
    ├── 快速收藏输入条
    │   ├── 粘贴链接、文章地址或内容来源
    │   └── 记录想法 / 收藏按钮
    │
    └── 主体三栏
        ├── 左栏：收藏夹
        ├── 中栏：内容列表
        └── 右栏：内容详情 / 整理面板
```

---

## 3. 当前 UI 与目标 UI 差异

| 区域 | 当前 | 目标 | 迁移方式 |
|---|---|---|---|
| 页面标题 | 收藏 | 内容收藏 | 改文案 |
| 顶部搜索 | 在筛选条中 | Header 中间 | 上移，复用 `collectionSearchQueryProvider` |
| 导入 | 无 | Header 右侧 | 第一版 UI 占位 |
| 快速收藏 | 已有 | 保留，改文案和视觉 | 复用 `CollectionCaptureBar` |
| Box | 顶部横向条 | 左侧收藏夹栏 | 新增 `CollectionFolderSidebar` |
| 状态筛选 | 页面顶部 | 中栏内容列表顶部 | 新增/改造状态 tabs |
| 内容类型筛选 | 下拉为主 | chips：全部 / 网页 / 视频 / 公众号 / 文章 / 工具 | 新增 `CollectionContentTypeChips` |
| 收藏列表 | 当前卡片 | 新内容卡片 | 改造 `SavedItemCard` |
| 详情面板 | 当前整理面板 | 新内容详情面板 | 改造 `SavedItemDetailPanel` |
| 标签/备注 | 占位 | 图中核心区 | 先做 UI，占位不落库 |
| 星标 | 无 | 有 | 先 UI 占位 |
| 导入/分页 | 无 | 有 | 先 UI 占位，后续单独数据 PRD |

---

## 4. 总迁移原则

### 4.1 必须遵守

1. 不修改数据库 schema，除非进入后续数据增强阶段。
2. 不修改 Drift migration。
3. 不重写 Repository。
4. 不重写 CollectionCaptureService。
5. 不重写 EnrichmentJobService。
6. 不引入新依赖。
7. 不修改 DesktopShell。
8. 不重新引入无界 `TabBarView`。
9. 不破坏当前已修复的 RenderBox / Overflow 问题。
10. 每个阶段必须可以单独 `flutter analyze` 并可运行。

### 4.2 UI 命名与数据命名

第一阶段只改 UI 命名，不改数据层：

```text
UI：收藏夹
数据层：Box
```

即：

```text
collectionBoxesProvider 仍然表示收藏夹数据
selectedCollectionBoxIdsProvider 仍然表示当前选中的收藏夹筛选
```

### 4.3 分阶段交付原则

每一阶段必须是可运行状态，不允许“半重构”。

---

## 5. 分阶段路线图

### Phase 1：三栏信息架构迁移

目标：将页面从当前“两栏主体”迁移为：

```text
收藏夹栏 + 内容列表栏 + 详情栏
```

交付：

1. 新增 `CollectionFolderSidebar`
2. `CollectionsDesktopLayout` 改为三栏
3. 顶部移除 `CollectionBoxBar`
4. 中栏保留 `CollectionViewChips` / `CollectionSearchFilterBar` / 列表
5. 右栏保留 `SavedItemDetailPanel`

详见：`phase_1_three_column_folder_sidebar_prd.md`

---

### Phase 2：Header 与快速收藏区迁移

目标：使顶部接近目标图。

交付：

1. 标题改为“内容收藏”
2. 副标题改为“收集网页、视频、公众号、文章与其他值得保存的内容。”
3. Header 中间加入全局搜索框
4. Header 右侧加入“导入”和“刷新”
5. `CollectionCaptureBar` 改文案和视觉

详见：`phase_2_header_capture_prd.md`

---

### Phase 3：中栏筛选与内容列表迁移

目标：把中栏变成目标图中的内容管理区。

交付：

1. 新增 `CollectionContentTypeChips`
2. 新增或改造 `CollectionStatusTabs`
3. 改造 `CollectionSearchFilterBar` 为列表工具栏
4. 状态语义从 `Inbox/全部/未看...` 调整为 `全部/待看/阅读中/已看/归档`
5. 内容类型 chips 支持：全部 / 网页 / 视频 / 公众号 / 文章 / 工具 / 更多

详见：`phase_3_center_list_filters_prd.md`

---

### Phase 4：内容卡片视觉迁移

目标：将 `SavedItemCard` 从普通收藏卡片改成目标图内容卡片。

交付：

1. 内容图标 / 来源图标
2. 标题一行
3. 副信息：来源 / 类型 / 时间
4. 标签 chips
5. 状态 chip
6. 星标 UI 占位
7. 更多菜单 UI 占位
8. 避免 Row overflow

详见：`phase_4_saved_item_card_prd.md`

---

### Phase 5：右侧详情面板迁移

目标：右侧面板接近目标图的“内容整理详情”。

交付：

1. 内容身份区
2. 来源链接区
3. 状态区
4. 收藏夹区
5. 标签区
6. 备注区
7. 底部操作：打开内容 / 编辑 / 更多
8. 技术信息继续弱化

详见：`phase_5_detail_panel_prd.md`

---

### Phase 6：数据增强规划

目标：在 UI 稳定后，再设计真正的数据能力。

可能新增：

1. 星标字段 `isFavorite`
2. 备注字段 `note`
3. 标签表 `tags`
4. 多对多 `saved_item_tags`
5. 收藏夹计数
6. 导入能力
7. 分页 / 虚拟列表

详见：`phase_6_data_enhancement_prd.md`

---

## 6. 推荐执行顺序

```text
Phase 1 -> Phase 2 -> Phase 3 -> Phase 4 -> Phase 5 -> Phase 6
```

不要跳过 Phase 1 直接做视觉。

理由：

1. 新目标图的核心变化是三栏信息架构。
2. 现有 Box 顶部横条不符合目标图。
3. 只有先把收藏夹迁移到左栏，后续卡片和详情视觉才有稳定上下文。

---

## 7. 总验收标准

完成 Phase 1-5 后，页面应满足：

1. 页面标题为“内容收藏”。
2. 页面主体为三栏：
   - 收藏夹栏
   - 内容列表栏
   - 详情栏
3. 左侧收藏夹能进行筛选。
4. 中栏可按内容类型、状态、来源、媒介、关键词筛选。
5. 中栏内容卡片接近目标图。
6. 右栏详情面板接近目标图。
7. 快速收藏仍可用。
8. Box / 收藏夹创建仍可用。
9. 状态切换仍可用。
10. 不出现 RenderBox / RenderFlex overflow。
11. `flutter analyze` 通过。
