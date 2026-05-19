# 安卓端 UI 设计实现

## Goal

基于 `figure/安卓预期效果` 的移动端视觉稿，为 UniHub Flutter 应用补齐 Android 端主界面设计：移动端使用底部导航、卡片化内容、搜索与快捷入口；现阶段尚未实现的数据功能先以静态占位和轻提示保留，不阻塞真实页面浏览。

## What I already know

| 类别 | 已知信息 |
|---|---|
| 项目形态 | 单仓 Flutter 应用，使用 Material 3、Riverpod、go_router、drift。 |
| 现有页面 | 已有首页、设置、Thoughts 插件列表与编辑页。 |
| 现有桌面布局 | `AppLayout` 在宽屏展示左侧 Sidebar；移动端目前只有 Drawer，没有专门 Android 视觉。 |
| 参考图 | `figure/安卓预期效果` 包含首页、想法、待办、笔记、日历、收藏、搜索 7 个 Android 视图。 |
| 功能边界 | 用户要求“暂时未实现的功能先留存”，因此未落库模块以静态 UI/占位反馈呈现。 |

## Requirements

| 编号 | 需求 |
|---|---|
| R1 | Android/窄屏端使用底部导航作为主入口，包含首页、想法、待办、笔记、更多/搜索等参考图中的入口。 |
| R2 | 首页移动端应接近参考图：品牌头部、问候语、搜索框、快速记录、今日聚焦、最近想法、今日待办、快捷入口。 |
| R3 | 想法页移动端应接近参考图：标题头部、快速记录、分类筛选、排序/视图按钮、两列想法卡片；真实想法数据继续接入现有 Provider。 |
| R4 | 待办、笔记、日历、收藏、搜索页面先提供完整 Android UI 外观和静态示例内容，并保留未实现提示。 |
| R5 | 桌面端现有 Sidebar/右侧信息栏布局应保持可用，不因移动端改造退化。 |
| R6 | 页面需要适配窄屏宽度，避免横向溢出、文字重叠、底部导航遮挡内容。 |

## Acceptance Criteria

| 状态 | 标准 |
|---|---|
| [x] | Android 宽度下首页展示底部导航和参考图风格内容。 |
| [x] | Android 宽度下想法页能展示真实想法列表，快速记录仍能创建想法。 |
| [x] | 待办/笔记/日历/收藏/搜索路由可打开，并显示静态占位 UI。 |
| [x] | 桌面宽度下首页和想法页仍使用原有桌面布局。 |
| [x] | `flutter analyze` 通过。 |
| [x] | 关键 Widget smoke/navigation 测试通过。 |

## Definition of Done

| 项目 | 要求 |
|---|---|
| 代码质量 | 遵循 `.trellis/spec/frontend` 与 Flutter Widget 规范。 |
| 验证 | 至少运行 `flutter analyze` 和相关 Flutter 测试。 |
| 范围控制 | 不实现待办/笔记/日历/收藏真实数据层，不新增无关依赖。 |
| 可维护性 | 移动端 UI 复用共享组件/常量，避免把所有占位页硬塞到既有业务文件里。 |

## Technical Approach

| 方向 | 说明 |
|---|---|
| 响应式壳层 | 在 `AppLayout` 中按宽度选择桌面 Sidebar 或移动底部导航。 |
| 路由 | 在 Core 路由增加待办、笔记、日历、收藏、搜索占位页面；Thoughts 继续由插件提供。 |
| 移动端首页 | 为窄屏分支抽出移动端首页 Widget，复用现有 Dashboard Provider 获取想法统计与最近想法。 |
| 移动端想法 | 在 `ThoughtsListPage` 的窄屏分支渲染移动端 Composer/Toolbar/Card Grid，保留现有创建、标签筛选、归档/恢复能力。 |
| 占位模块 | 新增 Core 移动占位页面，静态数据呈现参考图外观，交互以 Snackbar/不可用态保留。 |

## Decision (ADR-lite)

| 项目 | 决策 |
|---|---|
| Context | 参考图包含多个尚未实现模块，但用户明确要求先完成 Android UI。 |
| Decision | 不新增真实业务层；移动端通过 Core 路由与静态页面补齐视觉入口，已有 Thoughts 数据继续真实接入。 |
| Consequences | 可快速得到完整 Android 原型；未来实现模块时需要把静态页面逐步替换为插件/真实 Provider。 |

## Out of Scope

| 内容 | 原因 |
|---|---|
| 待办/笔记/日历/收藏真实数据模型与持久化 | 本轮仅做 UI，功能暂留。 |
| 全局搜索真实索引与结果联动 | 参考图先以静态搜索 UI 呈现。 |
| Android 原生状态栏/导航栏深度定制 | 当前在 Flutter 层完成主要 UI。 |
| 提交 Git commit | 需要用户确认提交计划后再执行。 |

## Technical Notes

| 路径 | 说明 |
|---|---|
| `lib/src/shared/layouts/app_layout.dart` | 全局 Shell 布局，移动端底部导航入口。 |
| `lib/src/core/router/app_router.dart` | Core 路由，需新增未实现模块占位路由。 |
| `lib/src/core/app/home_page.dart` | 首页现有桌面布局，需加移动端分支。 |
| `lib/src/plugins/thoughts/ui/thoughts_list_page.dart` | 想法列表与创建逻辑，需加移动端分支。 |
| `figure/安卓预期效果/*.png` | Android 视觉参考图。 |
