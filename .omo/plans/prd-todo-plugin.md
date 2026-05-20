# PRD: Todo 插件

## 背景与动机

UniHub 当前仅有一个 Thoughts 插件。首页 `_TodoPanel`、`_DataPanel` 和移动端 `_MobileTodayTodos` 均使用硬编码 mock 数据（标注 3 处 `// TODO: 待插件实现后替换为真实数据`）。用户需要统一管理待办事项，包含创建、完成、归档等基本功能。

## 范围

### In Scope
- [ ] 创建 `TodoTable` 数据表（`lib/src/core/database/tables/todo_table.dart`）
- [ ] 实现 Todo 插件 `TodoPlugin`（`lib/src/plugins/todo/`），包含 data/providers/ui 三层
- [ ] 实现创建、完成/取消完成、删除、归档待办
- [ ] 在 `main.dart` 中注册 `TodoPlugin`
- [ ] Todo 数据接入首页仪表盘（`dashboardItemsProvider`、`dashboardStatsProvider`、`dashboardPinnedProvider`）
- [ ] 提供 `/todos` 路由页面替代现有占位页

### Out of Scope
- 重复/循环待办（Recurring todos）
- 待办标签/分类管理
- 日历视图集成
- 通知/提醒

## 技术方案

- **数据结构**：参照 `ThoughtsPlugin` 模式，新建 `lib/src/plugins/todo/` 目录
  ```
  plugins/todo/
  ├── data/
  │   ├── todo_dao.dart          — 纯数据访问
  │   └── todo_repository.dart   — 业务语义 API
  ├── providers/
  │   └── todo_providers.dart    — Provider 定义
  └── ui/
      ├── todo_list_page.dart    — 待办列表页
      └── widgets/               — 可复用组件
  ```
- **表定义**：`lib/src/core/database/tables/todo_table.dart`
  - 字段：`id`（autoIncrement）、`title`（非空）、`isDone`（默认 false）、`dueDate`（可选）、`createdAt`、`updatedAt`、`archivedAt`
  - 严格遵循 `database.md` 约定（`withDefault(const Constant(false))`、`dateTime()` 等）
- **注册**：`AppDatabase` 在 `@DriftDatabase(tables: [...])` 中添加 `TodoTable`；`main.dart` 中 `registry.register(TodoPlugin())`
- **Router**：`TodoPlugin.routes()` 贡献 `/todos`（列表页）和 `/todos/:id`（详情/编辑页）
- **Dashboard 集成**：`TodoPlugin` 实现 `getRecentItems`（今日待办）、`getStat`（待办总数/完成数）、`getPinnedItems`（未完成的置顶项）

## 数据模型

- 新增 `lib/src/core/database/tables/todo_table.dart`
- `AppDatabase.schemaVersion` 从 2 升至 3（TodoTable schemaVersion = 1）
- 迁移逻辑：`onUpgrade` 中 `if (from < 3) await m.create(todoTable);`

## UI 变更

- 新增 `lib/src/plugins/todo/ui/todo_list_page.dart`
  - 桌面端（≥720px）：左侧列表（带完成/未完成筛选）+ 右侧详情面板
  - 移动端：全屏列表 + FAB 快速添加
- 首页 `_TodoPanel` 和 `_DataPanel` 中的硬编码 mock 数据替换为 Provider 数据
- 侧栏导航添加 Todo 入口（通过 `navEntries` 贡献）

## 测试计划

- [ ] 单元测试：`TodoDao` CRUD 操作
- [ ] 单元测试：`TodoRepository` 业务方法（toggle done、归档、统计）
- [ ] Widget 测试：待办列表渲染、勾选完成、新建待办
- [ ] 集成测试：创建待办 → 列表可见 → 勾选完成 → 归档

## 验收标准

- [ ] `flutter analyze` 通过
- [ ] `flutter test` 通过
- [ ] 用户可创建、完成、删除待办
- [ ] 首页今日待办面板显示真实数据，不再 hardcode
- [ ] 数据概览面板显示真实待办统计
- [ ] 插件注册后 `/todos` 路由正常工作
- [ ] UI 在桌面端（≥720px）和移动端均正常
- [ ] 与现有 Thoughts 功能不冲突
