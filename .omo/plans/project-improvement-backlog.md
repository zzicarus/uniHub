# UniHub 项目改进 Backlog

> 记录时间：2026-05-21  
> 来源：对当前仓库的只读探索。本文只记录问题和建议，不代表一次性修复计划。

## 总览

| 级别 | 分类 | 问题数量 | 优先处理理由 |
|------|------|----------|--------------|
| P0 | 验证环境 / 项目信息 | 2 | 影响每次 vibe coding 的闭环验证和项目理解 |
| P1 | 插件架构 / 真实数据闭环 | 4 | 影响 UniHub 作为插件化笔记应用的核心可信度 |
| P2 | UI/UX / 可维护性 / 测试 | 8 | 影响产品体验、agent 改动稳定性和回归风险 |
| P3 | 文档与流程 | 4（全部完成） | 影响后续 agent 协作效率和任务边界清晰度 |

## P0：必须先排除的阻塞

| # | 问题 | 证据位置 | 风险 | 建议 |
|---|------|----------|------|------|
| P0-1 | Flutter 验证链路不稳定 | `flutter analyze` / `flutter test` 访问 `/mnt/d/CodeTools/flutter` cache 失败 | 每次改动后无法可靠验证，agent 容易在未验证状态下继续堆改动 | 将 Flutter SDK 放到 WSL 原生路径，或修复 `/mnt/d` 挂载和 SDK cache 写权限 |
| P0-2 | README 与 pubspec 仍是模板项目描述 | `README.md`、`pubspec.yaml` | 新 agent / 新开发者无法快速理解产品定位、架构和运行方式 | 改写中文 README：产品定位、插件架构、目录导航、运行命令、当前功能状态、路线图 |

## P1：架构与真实数据闭环

| # | 问题 | 证据位置 | 风险 | 建议 |
|---|------|----------|------|------|
| P1-1 | 插件数据库声明未真正插件化 | `UniHubPlugin.tables/schemaVersion`、`ThoughtsPlugin.tables` 已存在，但 `AppDatabase` 仍硬编码 `ThoughtsTable` | 插件接口看起来支持 DB 扩展，实际新增插件仍要手改 core database，架构语义不一致 | 短期文档明确“DB 集中注册”；长期考虑 manifest/codegen 生成 `@DriftDatabase(tables: [...])` |
| P1-2 | 插件生命周期未接入启动流程 | `PluginRegistry.initAll()` 存在，但 `main.dart` 只 register 插件 | 后续插件如果依赖初始化钩子，会出现定义了但不执行的问题 | 增加启动 bootstrap，或用 `FutureProvider` 驱动插件初始化状态 |
| P1-3 | 首页仍混入硬编码业务数据 | `home_page.dart` 中今日待办、本周笔记、待办数、笔记数、最近活动等 TODO/mock | 用户会误以为数据真实，产品可信度下降 | 首页只展示真实 provider 数据；未实现插件显示空态或“未启用/即将推出” |
| P1-4 | 全局搜索仍是半成品 | `SearchResult` 与插件 `search()` 接口存在，但 `/search` 是占位页 | 搜索入口已经出现在首页和导航中，但核心能力不可用 | 建立 `SearchProvider`，遍历插件 `search()`；先支持 Thoughts 正文、标签、标题搜索 |

## P2：UI/UX 与产品体验

| # | 问题 | 证据位置 | 风险 | 建议 |
|---|------|----------|------|------|
| P2-1 | 部分控件看起来可点但没有行为 | 移动首页“添加标签 / 图片 / 待办”使用 `_PillButton`，没有回调 | UI 给出错误预期，降低可用性 | 不可用控件隐藏、禁用，或接入真实动作 |
| P2-2 | 通知入口只是未实现提示 | 首页、Thoughts 页面通知按钮 | 多处重复占位功能会稀释核心体验 | 暂时移除通知入口，或集中成一个真实的消息/提醒模块规划 |
| P2-3 | 首页信息架构偏“漂亮仪表盘”，但数据支撑不足 | `HomePage` 中多块统计卡、活动、待办、快捷入口 | 容易继续堆 mock，偏离“笔记工作台”主路径 | 首页优先做真实工作台：快速记录、最近内容、置顶内容、搜索 |
| P2-4 | 移动端有完整视觉，但核心交互不完整 | 移动首页与 Thoughts mobile layout | 移动端看起来成熟，但实际操作路径不完整 | 移动端只保留已闭环功能：记录、列表、搜索、编辑、归档 |
| P2-5 | 最近内容点击没有进入具体想法 | `DashboardItem.routePath` 当前多处为 `/thoughts` | 用户从首页点内容只能回列表，无法直达上下文 | Dashboard item 应携带 `/thoughts/:id`，并安全处理找不到的 id |
| P2-6 | 路由参数解析不健壮 | `ThoughtsPlugin` 中 `int.parse(state.pathParameters['id']!)` | 非法 URL 会直接抛异常 | 使用 `int.tryParse`，失败时展示 not-found/invalid-id 页面 |
| P2-7 | 搜索入口过多但功能缺失 | 首页搜索框、移动搜索、Thoughts header 搜索 | 入口多于能力，造成体验落差 | 先实现最小搜索闭环，再逐步增加筛选和快捷键 |
| P2-8 | 视觉系统仍偏“卡片堆叠” | Home、Thoughts、StyleGuide 多处 panel/card/shadow | 桌面工具产品的信息密度和层级可能被装饰元素稀释 | 减少装饰卡片，强化侧栏、主工作区、右侧上下文三栏结构 |

## P2：代码维护性与测试

| # | 问题 | 证据位置 | 风险 | 建议 |
|---|------|----------|------|------|
| ~~P2-9~~ | ~~`home_page.dart` 文件过大~~ | ✅ **已完成** | ~~`lib/src/core/app/home_page.dart` 超过 2200 行~~ | 已拆分为 `home_page.dart` (723行) + 5 个 part 文件：`home/header.dart`、`home/focus_section.dart`、`home/recent_section.dart`、`home/right_rail.dart`、`home/mobile_home.dart`，使用 Dart `part`/`part of` 机制 |
| P2-10 | Thoughts desktop/mobile layout 参数过多 | `ThoughtsDesktopLayout`、`ThoughtsMobileLayout` 构造器参数列表很长 | 新增字段要同步多处，容易漏传 | 提取 `ThoughtsLayoutState` / `ThoughtsLayoutActions`，减少构造器噪声 |
| ~~P2-11~~ | ~~独立编辑页与抽屉编辑器存在重复状态逻辑~~ | ✅ **已完成** | ~~`thoughts_editor_page.dart`、`thought_editor_drawer.dart`~~ | ~~保存、图片、标签、归档逻辑容易分叉~~ | 已提取 `ThoughtEditorController` (294行) 和 `ThoughtEditorImageStrip` (74行)，页面/抽屉纯化为布局容器 (281 + 276 行)。UI 代码从 1044 行降至 557 行，重复业务逻辑完全消除 |
| P2-12 | Provider 层仍偏简单 FutureProvider | `thoughts_providers.dart` | 增删改后依赖手动 invalidate，复杂度上升后易漏刷新 | Thoughts 列表可迁移到 `AsyncNotifier`，集中封装 create/update/archive/restore |
| P2-13 | 测试覆盖不足 | `test/AGENTS.md` 记录 core/app、router、theme、thoughts/ui、shared 为 0% | UI 和路由变更缺少回归保护 | 优先补 provider、router、home smoke、Thoughts composer/editor widget 测试 |
| P2-14 | 全量冒烟测试过脆 | `test/widget_test.dart` 直接加载整 App 并依赖具体文案 | UI 文案微调会导致测试失败，定位不精准 | 保留 1 个 App smoke，其余拆成组件级 widget 测试 |
| P2-15 | 图片服务对文件系统和平台依赖较硬 | `ThoughtImageService` 直接使用 `ImagePicker`、`File`、`path_provider` | 测试和桌面/移动差异处理不方便 | 抽象 picker/storage 接口，测试中注入 fake storage |
| P2-16 | 内容 codec 中存在吞异常降级路径 | `ThoughtContentCodec` 多处 `catch (_)` | 兼容旧数据合理，但坏数据难以追踪 | 保留降级，但增加可观测日志或 debug-only warning |

## P3：文档、规范与 vibe coding 流程

| # | 问题 | 状态 | 证据位置 | 风险 | 建议 |
|---|------|------|----------|------|------|
| ~~P3-1~~ | ~~`.omo` 技术债文档有路径滞后~~ | ✅ **已完成** | ~~`remaining-technical-debt.md` 写到旧路径~~ | ~~agent 会按旧路径查找~~ | 已修正路径、添加核对日期和“当前真实状态”小节 |
| ~~P3-2~~ | ~~AGENTS / guidelines 中部分状态描述可能滞后~~ | ✅ **已完成** | ~~多处文档记录“已修复/待确认/当前覆盖”~~ | ~~状态漂移后会误导~~ | 已更新 AGENTS.md 和 test/AGENTS.md，所有问题标记为 ✅ |
| ~~P3-3~~ | ~~缺少按任务类型调用 skill/agent 的本地指南~~ | ✅ **已完成** | `.omo/guidelines/agent-workflow.md` | ~~vibe coding 任务边界不清~~ | 已创建，覆盖 6 类任务 + 速查表 + 委派策略 |
| ~~P3-4~~ | ~~缺少 PRD 到实现的验收模板实例~~ | ✅ **已完成** | `.omo/plans/prd-global-search.md`、`prd-todo-plugin.md`、`prd-home-real-data.md` | ~~复杂功能容易泛泛~~ | 已创建 3 个 PRD 示例，基于真实代码路径 |

## 建议的分批处理顺序

| 批次 | 目标 | 包含问题 |
|------|------|----------|
| Batch 1 | 恢复可验证开发环境 | P0-1 |
| Batch 2 | 修正文档入口和项目状态 | P0-2、P3-1、P3-2 |
| Batch 3 | 首页真实数据化 | P1-3、P2-1、P2-2、P2-3、P2-5 |
| Batch 4 | 全局搜索最小闭环 | P1-4、P2-7 |
| Batch 5 | 插件架构边界决策 | P1-1、P1-2 |
| Batch 6 | 大文件拆分与测试补强 | P2-9、P2-10、P2-11、P2-13、P2-14 |
| Batch 7 | 数据与平台细节加固 | P2-12、P2-15、P2-16 |

## vibe coding 协作建议

| 方向 | 建议 |
|------|------|
| 任务粒度 | 每次只给 agent 一个原子目标，明确涉及文件、禁止改动范围、验收命令 |
| Agent 分工 | 建议固定四类：架构审计、Flutter UI、Data/Drift、Verifier |
| Skill 管理 | 可新增 repo-local skills：`unihub-read-context`、`unihub-plugin-feature`、`unihub-widget-polish`、`unihub-drift-migration`、`unihub-verification` |
| 设计输入 | UI 任务先写“页面目的、真实数据来源、不可用功能如何呈现”，再让 agent 实现 |
| 防止 mock 蔓延 | 任何 mock 数据必须放独立 demo/story 文件，不进入真实路由页面 |
| 验收截图 | 桌面固定 1440x900，移动固定 393x852；首页和 Thoughts 页都要截图检查 |
| 回归策略 | 数据层改动必须带 DAO/Repository 测试；UI 改动至少带一个 widget smoke |
