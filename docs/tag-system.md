# TagKit 标签系统设计说明

## 概述

TagKit 是 uniHub 的可复用标签系统，提供标签编解码、过滤逻辑、UI 组件和插件适配层。设计目标是保持核心层无状态、纯函数化，让各插件（thoughts、notes、todos、favorites 等）按需接入。

---

## 一、当前 TagKit 结构

### 1.1 `shared/tags/` — 核心层（无 UI 依赖）

| 文件 | 职责 |
|------|------|
| `tag_models.dart` | 数据模型：`AppTagStat`（统计数据）、`TagMatchMode`（匹配模式枚举）、`TagValidationResult`（校验结果） |
| `tag_codec.dart` | 编解码：`TagCodec.normalize()`、`parseCommaSeparated()`、`encodeCommaSeparated()`、`validate()` |
| `tag_filter_logic.dart` | 纯函数过滤逻辑：`toggle()`、`remove()`、`rename()`、`matches()`（按 mode 检查多标签匹配）、`countTags()`、`sortStats()` |

核心层不持有任何状态，所有数据通过参数传入并返回新值。

### 1.2 `shared/widgets/tags/` — UI 组件层

| 组件 | 职责 |
|------|------|
| `AppTagChip` | 单个标签 chip，支持 # 前缀、count 数字、选中态、leadingIcon、compact 等 |
| `AppSelectedTagChip` | 已选标签 chip，带 close 图标，继承 `InputChip` |
| `AppMoreTagsButton` | "更多标签" 圆形按钮，触发弹层 |
| `AppTagFilterBar` | 标签筛选栏：label + tag chips + 可选更多按钮，支持 `horizontalScroll` |
| `AppSelectedTagsBar` | 已选标签栏：显示被选中的标签 + 逐个/批量清除，超过 `maxVisibleTags` 显示 `+N` |
| `AppMoreTagsPopover` | 更多标签弹层（当前为 `showDialog`，后续可改造为 anchored popover） |
| `AppCommonTagsPanel` | 通用常用标签面板：带标题、图标、辅助文字，用于侧栏等场景 |

所有组件不依赖任何 Provider，通过回调（`ValueChanged<String>` / `VoidCallback`）与业务层通信。

### 1.3 `plugins/thoughts/` — 插件适配层

| 适配点 | 说明 |
|--------|------|
| `thoughts_providers.dart` — `selectedTagFiltersProvider` | 当前选中标签集合，类型 `Set<String>` |
| `thoughts_providers.dart` — `commonTagsProvider` | 常用标签统计数据，类型 `List<MapEntry<String, int>>` |
| `thoughts_providers.dart` — `_filterByTags()` | 调用 `TagFilterLogic.matches()` 执行标签过滤 |
| `thoughts_providers.dart` — helper 函数 | `toggleTagInFilter()`、`renameTagInFilter()`、`removeTagInFilter()` 封装对 `TagFilterLogic` 的调用 |
| `ThoughtCommonTagsPanel` | `AppCommonTagsPanel` 的 adapter 封装，读取 provider 并将数据转为 `List<AppTagStat>` 后传入通用组件 |

---

## 二、多标签筛选语义

### 2.1 默认模式：`TagMatchMode.all`（交集）

当前 thoughts 模块固定使用 `TagMatchMode.all`，即：

> 选中多个标签时，笔记/卡片**必须同时包含所有选中标签**才被认为是匹配的。

```dart
// thoughts_providers.dart — _filterByTags()
TagFilterLogic.matches(
  itemTags: tags,
  selectedTags: selectedTags,
  mode: TagMatchMode.all,
);
```

例如选中 `#产品` 和 `#灵感`，则只显示**同时**包含 "产品" 和 "灵感" 的笔记。

**选择理由**：交集筛选在管理大量笔记时能逐步缩小结果范围，用户每次加入新标签都减少结果，适合精准定位场景。

### 2.2 `TagMatchMode.all` 行为

- 无选中标签 → 不过滤，显示全部
- 选中 1 个标签 → 显示包含该标签的笔记（单标签退化为元匹配）
- 选中 N 个标签 → 显示**同时**包含所有 N 个标签的笔记
- 有笔记不含其中任一标签 → 被过滤掉

---

## 三、未来可选模式

`TagFilterLogic.matches()` 已完整支持 `TagMatchMode.any`，但 thoughts 插件未接入 UI 切换：

### 3.1 `TagMatchMode.any`（并集）

> 选中多个标签时，笔记/卡片**只要包含其中任一标签**即视为匹配。

```dart
TagFilterLogic.matches(
  itemTags: tags,
  selectedTags: selectedTags,
  mode: TagMatchMode.any,
);
```

例如选中 `#产品` 和 `#灵感`，则包含 "产品" **或** "灵感" 的笔记都会展示。

**适用场景**：全览模式，用户想看多个标签维度下的所有内容。

### 3.2 `TagMatchMode.all`（交集）

即当前模式，行为不变。

---

## 四、暂不做的功能

以下功能已评估但不在当前范围：

| 功能 | 理由 |
|------|------|
| **全局 tags table** | 当前标签按需在 feature 内部存储（如 thoughts 表 tags 列为逗号分隔字符串），无独立 tags 表。全局表引入 migration 成本和同步复杂度 |
| **标签颜色** | 标签颜色依赖全局 tags 表做元数据存储，当前基础设施不支持 |
| **标签分组** | 标签分组（如 "工作/产品"、"个人/运动"）依赖层级结构，需全局表 + 树形存储 |
| **标签别名** | 同一标签多个别名（如 "产品"="PRD"）涉及命名冲突和归一化，需全局映射表 |
| **标签批量管理** | 重命名/合并/删除标签在多 feature 间的联动需全局 tags 表支持 |

以上功能均依赖**全局 tags table** 作为前提，当前阶段不适合引入。

---

## 五、未来 UI 规划

当引入模式切换时，应在**标签筛选栏**加入切换控件：

> **"匹配任一 / 匹配全部"**

交互设想：

1. 当前筛选栏下方增加一个 `SegmentedButton` 或 `ToggleButtons`
2. 两档切换：`TagMatchMode.any`（任一）/ `TagMatchMode.all`（全部）
3. 切换后实时刷新列表
4. 当前选中状态可持久化或保持 session 内状态

可能的 UI 位置：

- `AppTagFilterBar` 内部（水平空间允许时在 label 旁）
- 筛选栏下方独立一行
- `AppSelectedTagsBar` 尾部（与 "清除标签" 并列）

具体方案待阶段推进时依据实际布局决定。
