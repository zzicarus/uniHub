# 想法主页面重构计划

## Context

用户希望将「想法」页面改成与 `figure/windows预期效果/想法主页面.png` 基本一致：当前页面布局与视觉风格不符合预期，并且标签相关功能不完善。

初步扫描结果：
- 目标页面入口：`lib/src/plugins/thoughts/ui/thoughts_page.dart`
- 桌面布局：`lib/src/plugins/thoughts/ui/layouts/thoughts_desktop_layout.dart`
- 快速记录组件：`lib/src/plugins/thoughts/ui/layouts/thought_composer.dart`
- 状态筛选：`lib/src/plugins/thoughts/ui/layouts/thought_filter_bar.dart`
- 标签筛选：`lib/src/plugins/thoughts/ui/layouts/thought_tag_filter_bar.dart`
- 已选标签展示：`lib/src/plugins/thoughts/ui/layouts/thought_selected_tags_bar.dart`
- 想法卡片：`lib/src/plugins/thoughts/ui/widgets/thought_card.dart`
- 右侧栏面板：`lib/src/plugins/thoughts/ui/widgets/thought_pinned_panel.dart`、`thought_pending_review_panel.dart`、`thought_common_tags_panel.dart`
- 状态与数据来源：`lib/src/plugins/thoughts/providers/thoughts_providers.dart`

当前实现与预期图的主要差异：
- 顶部仍有大标题 Header，而预期图以「快速记录想法」卡片作为主内容顶部。
- 搜索、状态筛选、标签筛选、已选标签需要组合成更接近预期图的两层/三层筛选区域。
- 标签过滤目前只支持单选 `StateProvider<String?> tagFilterProvider`，预期图展示了多个已选标签。
- 想法列表当前列数最多 4 列，预期图主区域更接近 3 列卡片网格。
- 右侧栏已有置顶、待整理、常用标签等组件，但需要调整文案、图标、卡片样式和增加统计/热门标签信息以贴近预期图。
- 标签编辑对单条想法已有入口：`showThoughtTagDialog`，但缺少全局标签重命名/删除；现有表结构只有 `thoughts.tags` 逗号分隔字段，没有独立标签表。
- 多处创建/更新想法后仅 `invalidate(thoughtsListProvider)`，而列表数据源是 `allThoughtsProvider`；实现时应统一刷新 `allThoughtsProvider`，避免标签统计/右侧栏数据陈旧。

用户已确认的需求决策：
- 标签筛选：支持多选，并采用「交集」逻辑（想法需同时包含所有选中标签）。
- 标签管理：本次增加标签重命名和删除。
- 适配范围：先聚焦桌面端；移动端保持现状，只做兼容必要改动。

## Approach

推荐围绕现有 thoughts 插件重构桌面端 UI，不改动数据库结构，优先复用现有 Repository/Provider/组件，并补齐标签筛选状态能力。

核心方向：
1. 重排桌面布局：左侧主内容 + 右侧信息栏，主内容顶部直接展示快速记录卡片，移除或弱化现有大 Header。
2. 统一视觉：使用现有 `AppTokens`、`ThoughtPanel`、`ThoughtPillButton` 等基础组件，按预期图调整间距、圆角、边框、浅色背景、蓝紫主色状态。
3. 标签筛选：从单标签过滤升级为多标签集合，筛选逻辑为交集；提供常用标签快速选择、更多标签弹层、已选标签区域和清空筛选。
4. 标签管理：不新增数据库表，基于现有 `thoughts.tags` 字符串字段实现全局重命名/删除；操作时遍历受影响想法并批量更新标签字符串，完成后刷新 `allThoughtsProvider`。
5. 右侧栏：复用置顶/待整理/常用标签数据，并新增/调整为预期图中的「想法统计」「热门标签」等模块。
6. 移动端保持现状；如 provider 名称改动影响移动端，则提供兼容读写或最小同步调整，避免移动端编译失败。

## Files to modify

预计会修改：
- `lib/src/plugins/thoughts/providers/thoughts_providers.dart`
- `lib/src/plugins/thoughts/data/thoughts_repository.dart`
- `lib/src/plugins/thoughts/data/thoughts_dao.dart`（如需要事务/批量更新辅助）
- `lib/src/plugins/thoughts/ui/layouts/thoughts_desktop_layout.dart`
- `lib/src/plugins/thoughts/ui/layouts/thought_composer.dart`
- `lib/src/plugins/thoughts/ui/layouts/thought_filter_bar.dart`
- `lib/src/plugins/thoughts/ui/layouts/thought_tag_filter_bar.dart`
- `lib/src/plugins/thoughts/ui/layouts/thought_selected_tags_bar.dart`
- `lib/src/plugins/thoughts/ui/layouts/thoughts_shared_widgets.dart`
- `lib/src/plugins/thoughts/ui/widgets/thought_card.dart`
- `lib/src/plugins/thoughts/ui/widgets/thought_common_tags_panel.dart`
- `lib/src/plugins/thoughts/ui/widgets/thought_pending_review_panel.dart`
- `lib/src/plugins/thoughts/ui/widgets/thought_pinned_panel.dart`
- `lib/src/plugins/thoughts/ui/widgets/thought_context_menu.dart`（复用/扩展单条想法标签编辑入口）
- `lib/src/plugins/thoughts/ui/layouts/thoughts_mobile_layout.dart`（仅为 provider 兼容做最小调整）

预计会更新测试：
- `test/plugins/thoughts/providers/thoughts_providers_test.dart`
- `test/plugins/thoughts/ui/thoughts_integration_test.dart`
- `test/plugins/thoughts/ui/thoughts_qa_test.dart`
- 可能新增标签管理 repository/provider 测试

可能新增：
- `lib/src/plugins/thoughts/ui/widgets/thought_tag_management_dialog.dart`
- `lib/src/plugins/thoughts/ui/widgets/thought_stats_panel.dart`
- `lib/src/plugins/thoughts/ui/widgets/thought_hot_tag_panel.dart`

## Reuse

已发现可复用内容：
- 数据读取/写入：`ThoughtsRepository`、`ThoughtsDao`
- 标签统计：`commonTagsProvider`、`tagStatsProvider`
- 状态过滤：`thoughtStatusFilterProvider`、`ThoughtStatusFilter`
- 搜索过滤：`thoughtSearchQueryProvider`、`thoughtSearchDebouncedProvider`
- 内容解析：`ThoughtContentCodec.titleFromStored`、`plainTextFromStored`、`mergeImagePaths`
- 单条想法标签编辑：`showThoughtTagDialog` / `_TagDialog`
- 通用 UI：`AppSpacing`、`AppRadius`、`AppColors`、`AppShadows`、`ThoughtPanel`、`ThoughtPillButton`、`ThoughtPanelHeader`
- 现有右侧栏数据组件：置顶、待整理、常用标签、随机回顾、快捷操作

## Steps

- [ ] 将标签过滤状态改为多选集合，例如 `selectedTagFiltersProvider = StateProvider<Set<String>>`，并为移动端/旧调用点提供清晰替换路径。
- [ ] 更新 `thoughtsListProvider` 的标签筛选逻辑为交集：已选标签集合为空时不过滤；非空时想法标签需包含所有已选标签。
- [ ] 增加标签管理能力：
  - [ ] 重命名标签：校验新名称非空、去重、避免同名冲突；批量替换所有受影响想法中的标签。
  - [ ] 删除标签：二次确认后从所有受影响想法中移除该标签；标签为空时写回 `null`。
  - [ ] 操作完成后刷新 `allThoughtsProvider`，并同步清理/更新当前已选标签集合。
- [ ] 将桌面主布局调整为预期图结构：快速记录卡片、搜索/状态筛选、标签筛选、已选标签、想法列表。
- [ ] 调整快速记录卡片：标题、图标、输入框高度、底部按钮组和 `Ctrl + Enter` 提示贴近预期图。
- [ ] 改造状态筛选栏：`全部 / 未整理 / 置顶 / 有图片 / 待办` 的视觉与预期图一致；其中「待办/转待办」若仍未实现跨插件转换，则保持禁用或仅作为未来入口。
- [ ] 改造标签栏：展示高频标签、更多标签入口、选中态、已选标签区域和清空筛选。
- [ ] 改造卡片网格和想法卡片视觉，使其接近预期图的 3 列紧凑卡片，保留图片标识、置顶、更多菜单、标签点击筛选。
- [ ] 改造右侧栏面板：置顶、待整理、常用标签、想法统计、热门标签、隐私提示。
- [ ] 补充/更新 provider、repository 和 UI 测试，覆盖多标签交集筛选、标签重命名、标签删除、刷新联动和核心交互。
- [ ] 运行格式化、静态分析和相关测试。

## Verification

- 运行 `dart format` 检查格式。
- 运行 `flutter analyze` 检查静态问题。
- 运行相关测试：
  - `flutter test test/plugins/thoughts/providers/thoughts_providers_test.dart`
  - `flutter test test/plugins/thoughts/ui/thoughts_integration_test.dart`
  - `flutter test test/plugins/thoughts/ui/thoughts_qa_test.dart`
- 手动启动桌面端，核对：
  - 页面结构、间距、色彩、卡片样式与预期图基本一致。
  - 快速记录、置顶、图片、搜索、状态筛选可用。
  - 多标签选择、取消选择、更多标签、清空筛选可用。
  - 右侧栏数据与主列表联动符合预期。
