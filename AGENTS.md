# Agents

## 项目概述

UniHub 是一个 **桌面端优先** 的 Flutter 笔记应用，基于插件架构构建。

| 维度 | 内容 |
|------|------|
| 技术栈 | Flutter + Riverpod + GoRouter + Drift(SQLite) + flutter_quill |
| 架构 | 3 层：`core/`（基础设施）→ `shared/`（共享组件）→ `plugins/`（功能插件） |
| 布局 | 响应式：桌面端侧栏 + 内容区（≥720px），移动端底部导航 |
| 主题 | Material 3 + `ColorScheme.fromSeed`，设计令牌在 `app_tokens.dart` |

## 输出要求

新增的 prd 与指导文件需要按照中文书写，方便阅读和修正。

## Agent 工作流

严格按照 `Plan → Code → Verify → Review → Ship` 闭环执行。完整细节见 `.omo/guidelines/workflow.md`，委派规则见 `.omo/guidelines/agent-workflow.md`。

1. **理解任务 + 加载技能** — 读 `.omo/skill-defaults.json` 确定 `load_skills`；视觉任务必须加载 `frontend-ui-ux`；读涉模块 AGENTS.md
2. **规划** — 2+ 步创建 `todowrite`；复杂变更在 `.omo/plans/` 写 PRD
3. **实现** — 依赖方向 `plugins/ → shared/ → core/`；跨层用 `package:` 路径；禁止类型抑制；同步写测试
4. **验证** — `flutter analyze → dart fix → flutter test → dart fix --dry-run`，0 error 0 warning 且无可修复 lint
5. **审查** — 触发 `/review-work`（内含 sync-knowledge 自动写入文档）
6. **提交** — 原子提交，格式 `type: 中文描述`

---

## 代码库导航

可按模块查阅对应的 AGENTS.md 及规划文档：

| 路径 | 内容 | 优先级 |
|------|------|--------|
| `lib/src/` | 分层架构总览、模块边界 | 第一站 |
| `lib/src/core/` | 基础设施总览（路由/启动/布局/生命周期） | 深度阅读 |
| `lib/src/core/plugin/` | **插件系统关键约定 + 已知陷阱** | 新增/修改插件必读 |
| `lib/src/plugins/thoughts/` | Thoughts 插件内部架构 + data/ui 分层 | 维护该插件必读 |
| `test/` | 测试隔离模式 + ProviderScope override | 新增测试必读 |
| `.omo/guidelines/` | 项目规范（数据库/Widget/工作流/代理委派/PRD 模板） | 任意任务前查阅 |
| `.omo/plans/` | PRD 示例与技术债跟踪 | 大型功能前查阅 |
| `.omo/knowledge-map.json` | 知识同步映射规则（sync-knowledge 自动使用） | Review 阶段自动 |
| `.omo/skill-defaults.json` | 任务类型到 Skills 的默认映射（委派前必须读取） | 每次委派子任务前 |
| `.omo/learnings/errors.md` | 错误学习记录（sync-knowledge 自动写入） | 修复已知问题前查阅 |

## 项目规范

项目开发规范位于 `.omo/guidelines/` 目录：

- `.omo/guidelines/database.md` — 数据库规范（drift/SQLite）
- `.omo/guidelines/widget.md` — Widget 编写规范（设计令牌、M3 ColorScheme、布局约定）
- `.omo/guidelines/workflow.md` — 完整开发流程规范（Plan → Code → Verify → Review → Ship）
- `.omo/guidelines/planning.md` — PRD 模板和命名约定
- `.omo/guidelines/agent-workflow.md` — 代理任务分类与委派指南（根据任务类型选择 category/skills）

> 最后核对日期：2026-05-21 | 当前无阻塞级别的已知问题。
