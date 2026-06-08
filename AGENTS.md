# Agents

## 项目概述

UniHub 是一个 **桌面端优先** 的 Flutter 个人工具箱，基于插件架构构建。

| 维度 | 内容 |
|------|------|
| 定位 | 本地优先的个人知识管理工具，离线可用，数据完全归用户 |
| 技术栈 | Flutter + Riverpod + GoRouter + Drift(SQLite) + AppFlowy Editor (主) / flutter_quill (迁移遗留) |
| 架构 | 3 层：`core/`（基础设施）→ `shared/`（共享组件）→ `plugins/`（功能插件） |
| 布局 | 响应式：桌面端侧栏 + 内容区（≥900px 三列，900-1279px 两列），移动端底部导航（<900px） |
| 主题 | Material 3 + 6 套主题预设，设计令牌在 `app_tokens.dart` |
| 编辑器方向 | 已从 Quill 切到 AppFlowy Editor 为主线；旧 Quill 组件保留为迁移遗留代码，不再被用户主路径引用 |

## 输出要求

新增的 prd 与指导文件需要按照中文书写，方便阅读和修正。

## Agent 工作流

严格按照 `Plan → Execute → Finish` 三阶段闭环执行，使用 Trellis 驱动。完整工作流见 `.trellis/workflow.md`。

### Vibe Coding 入口协议

`AGENTS.md` 是本仓库唯一总入口。agent 接到任务后，先在这里完成模式判断和上下文路由，再进入具体 guideline。

| 步骤 | 要求 | 跳转 |
|------|------|------|
| 1. 判断任务模式 | 区分直接回答/创建任务/内联变更；用户未授权实现时不得修改代码 | `.trellis/workflow.md` |
| 2. 声明执行边界 | 开始前说明任务模式、预计涉及文件、禁止改动范围、验证方式 | `.trellis/workflow.md` |
| 3. 加载上下文 | 读取涉模块 `AGENTS.md`、相关 spec guideline、必要源码；不要凭经验猜测行为 | `.trellis/workflow.md` |
| 4. 确定 skills | Trellis 根据 workflow.md 的 Skill Routing 规则自动匹配技能 | `.trellis/workflow.md#skill-routing` |
| 5. 执行闭环 | 按 Phase 1 (Plan) → Phase 2 (Execute) → Phase 3 (Finish) 推进 | `.trellis/workflow.md` |

### 任务输入建议

用户给任务时，建议尽量包含以下字段；缺失时 agent 应做保守假设，设计不确定时先确认。

| 字段 | 说明 | 示例 |
|------|------|------|
| 目标 | 本次要完成什么 | 实现 Thoughts 列表空态 |
| 模式 | 只读分析 / 方案 / 实现 / 验证 / 审查 / 提交 | 先只读分析，不改代码 |
| 范围 | 允许改哪些模块或文件 | 只改 `lib/src/plugins/thoughts/ui/**` |
| 禁止 | 明确不能碰的内容 | 不改数据库 schema，不加 mock 数据 |
| 验收 | 用什么命令或现象判断完成 | `flutter analyze` 与目标 widget test 通过 |
| 提交 | 是否允许 commit / push | 完成后先汇报，不提交 |

### Agent 执行前声明

进入实现或委派前，agent 需要简短声明：

```text
任务模式: Build
任务分类: visual-engineering
加载技能: flutter-dev, flutter-build-responsive-layout, frontend-ui-ux
前置文档: AGENTS.md, .trellis/spec/frontend/component-guidelines.md, test/AGENTS.md
执行边界: 只改目标 Widget 与对应测试，不改数据库和路由
验证方式: focused widget test + flutter analyze
```

### 边界控制

| 场景 | 必须动作 |
|------|----------|
| 发现需要扩大改动范围 | 停止实现，说明新增影响面，等待用户确认 |
| 设计方案有多个合理选项 | 给出 2-3 个方案和取舍，让用户决定 |
| 用户明确说"先分析/先计划/不要改" | 只读，不 patch，不运行会产生写入的命令 |
| 验证连续失败 3 次 | 停止试错，总结失败证据，询问下一步 |
| 需要破坏性命令或外部权限 | 先说明原因并请求确认 |

1. **理解任务** — 参考 `.trellis/workflow.md` 确定流程；读涉模块 AGENTS.md 和相关 spec
2. **规划** — 使用 `task.py create` 创建任务；复杂变更在 `.trellis/tasks/` 下写 prd.md
3. **实现** — 依赖方向 `plugins/ → shared/ → core/`；跨层用 `package:` 路径；禁止类型抑制；同步写测试
4. **验证** — `flutter analyze → dart fix → flutter test → dart fix --dry-run`，0 error 0 warning 且无可修复 lint
5. **审查** — 触发 `/review-work`（trellis 内置）
6. **提交** — 按 Phase 3.4 流程提交，格式 `type: 中文描述`

### Typography 强制约束

所有新增或修改的 Flutter UI 必须遵守 `.trellis/spec/frontend/component-guidelines.md` 中的 Typography 字体规范：

- 普通 UI 文本使用 `Theme.of(context).textTheme.*`
- 不在 Widget 层使用 `GoogleFonts.*`
- 不在 Widget 层直接写 `fontFamily`
- 不使用裸数字 `fontSize`
- 不直接使用 `FontWeight.wXXX`
- 字重必须使用 `AppFontTokens`
- 代码/路径/命令才允许使用 `AppFonts.mono`

---

## 代码库导航

可按模块查阅对应的 AGENTS.md 及规划文档：

| 路径 | 内容 | 优先级 |
|------|------|--------|
| `lib/src/` | 分层架构总览、模块边界 | 第一站 |
| `lib/src/core/` | 基础设施总览（路由/启动/布局/生命周期） | 深度阅读 |
| `lib/src/core/plugin/` | **插件系统关键约定 + 已知陷阱** | 新增/修改插件必读 |
| `lib/src/plugins/thoughts/` | Thoughts 插件内部架构 + data/ui 分层 | 维护该插件必读 |
| `lib/src/shared/widgets/website_logo.dart` | WebsiteLogo 组件（只读本地缓存，不网络请求） | 了解站点 Logo 展示机制 |
| `lib/src/plugins/collections/services/website_logo_cache_service.dart` | 站点级 favicon 缓存服务（抓取、缓存、TTL） | 理解 Logo 后台获取流程 |
| `.trellis/spec/architecture/` | 架构设计文档（编辑引擎迁移、3 层架构说明） | 理解架构演进必读 |
| `test/` | 测试隔离模式 + ProviderScope override | 新增测试必读 |
| `.trellis/spec/` | 项目规范（数据库/Widget/工作流等） | 任意任务前查阅 |
| `.trellis/tasks/` | 任务目录与 PRD 文件 | 大型功能前查阅 |
| `.trellis/tasks/archive/plans/` | 历史规划文档（从 OMO 恢复，含 Thoughts Inbox V2、Todo 插件等 PRD） | 启动同类新功能前查阅 |
| `.trellis/knowledge-map.json` | 代码到文档的同步映射规则 | review 阶段查阅 |
| `.trellis/skill-defaults.json` | 任务类别→Skills 默认映射 | 委派子任务前查阅 |
| `.trellis/spec/guides/agent-workflow.md` | 任务分类与委派指南 | 确定任务策略前查阅 |
| `.trellis/workspace/alan/learnings/errors.md` | Bug 根因分析与预防清单 | 遇到已知错误模式时查

## 项目规范

项目开发规范位于 `.trellis/spec/` 目录：

| 文件 | 内容 |
|------|------|
| `.trellis/spec/frontend/component-guidelines.md` | Widget 编写规范（设计令牌、M3 ColorScheme、布局约定、配色系统、Overflow 预防、Typography 字体规范） |
| `.trellis/spec/backend/database-guidelines.md` | 数据库规范（drift/SQLite、DAO/Repository 模式、迁移、测试生命周期） |
| `.trellis/workflow.md` | 完整 Trellis 开发流程规范（Plan → Execute → Finish） |

> 最后核对日期：2026-06-08 | 当前无阻塞级别的已知问题。
