# PRD: 首页真实数据接入

## 背景与动机

首页（`lib/src/core/app/home_page.dart`）当前包含 5 处硬编码 mock 数据，标注了 `// TODO: 待插件实现后替换为真实数据`。这些数据包括统计卡片中的"今日待办 6 条"、"本周笔记 8 条"，待办面板的 5 行固定任务，活动面板的 4 条记录，以及数据概览中"待办 24"和"笔记 56"的假数值。用户打开首页看到的是演示数据，而非真实内容。

## 范围

### In Scope
- [ ] `_FocusGrid` 的"今日待办"卡片 — 从 Todo 插件 `dashboardStatsProvider` 读取真实数据
- [ ] `_FocusGrid` 的"本周笔记"卡片 — 统计本周创建的想法的数量
- [ ] `_TodoPanel` — 从 Todo 插件 Provider 读取今日待办列表
- [ ] `_ActivityPanel` — 从插件系统获取最近活动记录
- [ ] `_DataPanel` — 待办和笔记统计值接入真实数据

### Out of Scope
- 首页布局结构调整（不改动 `HomePage` 整体框架）
- 新增仪表盘组件类型
- 活动日志的持久化存储（先做运行时聚合）

## 技术方案

- **新增 Provider**：`lib/src/core/app/dashboard_providers.dart`
  - `weeklyThoughtsProvider` — `FutureProvider<int>`，统计本周 Thoughts 数量，调用 `ThoughtsDao` 按 `createdAt` 筛选
  - `todayTodosProvider` — `FutureProvider<List<DashboardItem>>`，取今日待办（`TodoPlugin.getRecentItems`）
  - `recentActivityProvider` — `FutureProvider<List<DashboardItem>>`，合并 Thoughts 近期变更和 Todo 变更
- **修改文件**：
  - `lib/src/core/app/home_page.dart`
    - `_FocusGrid`：`todayTodosCount` 改为 `ref.watch(todayTodosProvider).valueOrNull ?? 0`；`weeklyNotesCount` 改为 `ref.watch(weeklyThoughtsProvider).valueOrNull ?? 0`
    - `_TodoPanel`：改为 `ConsumerWidget`，从 `todayTodosProvider` 读取列表并渲染 `_TodoLine`
    - `_ActivityPanel`：从 `recentActivityProvider` 读取最近 4 条事件
    - `_DataPanel`：待办和笔记统计值从 `PluginStat` 获取，不再硬编码
  - `lib/src/plugins/thoughts/thoughts_plugin.dart`
    - 若本周统计需要，在 `getStat` 中补充本周计数
- **响应式处理**：所有新接入的 Provider 在 loading 态显示 shimmer 效果（参考 `_buildLoadingGrid` 已有模式），error 态沿用 `_buildErrorState` 的重试按钮

## 数据模型

- 无新增表。`ThoughtsTable` 已有的 `createdAt` 字段足够做本周筛选
- `TodoPlugin` 完成后其 Provider 自然提供待办数据，此处仅做消费方

## UI 变更

- `_FocusGrid`：两个 mock 卡片（今日待办、本周笔记）改为真实数据
- `_TodoPanel`：从 `StatelessWidget` 改为 `ConsumerWidget`，内容从 Provider 加载
- `_ActivityPanel`：从 `StatelessWidget` 改为 `ConsumerWidget`，内容从 Provider 加载
- `_DataPanel`：待办行和笔记行的 value 替换为 Provider 数据

## 测试计划

- [ ] 单元测试：`weeklyThoughtsProvider` — 本周/上周/空数据库边界
- [ ] Widget 测试：首页各面板在 loading/data/error 状态的渲染
- [ ] 集成测试：创建想法 → 首页"最近想法"面板显示新条目
- [ ] 回归测试：移除所有 mock 后现有 Widget 测试仍然通过

## 验收标准

- [ ] `flutter analyze` 通过
- [ ] `flutter test` 通过
- [ ] 首页"今日待办"卡片显示真实代办数量（0 个时显示 0）
- [ ] 首页"本周笔记"卡片显示本周创建的想法的真实数量
- [ ] 待办面板列出真实今日待办条目，不再显示假数据
- [ ] 数据概览显示真实统计
- [ ] 首页不会因为 Provider 报错而白屏（有 error state 兜底）
- [ ] UI 在桌面端（≥720px）和移动端均正常
