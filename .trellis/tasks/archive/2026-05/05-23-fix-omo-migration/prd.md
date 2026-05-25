# PRD: 修复 OMO→Trellis 迁移缺陷

## 背景与动机

项目已从 OMO 工作流迁移到 Trellis，但部分忽略规则、任务上下文和活跃规范仍残留旧路径或缺少必要指南，可能导致 agent 读取错误上下文、漏提交项目工作流文件，或在新增 UI/插件数据层时缺少统一约束。本任务用于补齐迁移后的 Trellis 基础设施文档，并确保本轮不触碰业务代码。

## 范围

### In Scope

- [ ] 修复根 `.gitignore`，允许 `.trellis/` 项目工作流文件被 Git 跟踪，并明确 `.pi/` 配置与 runtime/npm 忽略策略。
- [ ] 补齐当前任务的 `prd.md`、`implement.jsonl`、`check.jsonl`，移除仅含 `_example` 的种子状态。
- [ ] 清理活跃 Trellis 工作流/规范中的旧 `.omo` 路径，保留历史 archive 中用于说明来源的 OMO 文本。
- [ ] 新增或补强前端 UI/UX 规范，并接入前端规范索引。
- [ ] 新增插件数据流规范，并接入后端规范索引。
- [ ] 修正 Widget 颜色规范中 `ColorScheme` 与 `AppColors` 的口径冲突。
- [ ] 运行静态扫描验证迁移修复结果。

### Out of Scope

- 不修改 `lib/`、`test/` 下业务代码或测试代码。
- 不改数据库 schema、插件接口实现、路由、Provider 或 UI 组件。
- 不运行完整 `flutter test`；本轮仅做文档/配置静态验证。
- 不提交、不推送、不合并 Git 分支。

## 技术方案

- 根 `.gitignore` 不再忽略整个 `.trellis/`，由 `.trellis/.gitignore` 管理本地 runtime、session、临时文件。
- `.pi/` 采用白名单跟踪：允许 `settings.json`、`agents/`、`skills/`、`prompts/`、`extensions/`；忽略 `.pi/npm/`、`node_modules`、runtime/cache。
- 将活跃规范里的旧 `.omo/...` 路径改为 `.trellis/...` 等当前路径，避免新会话继续引用旧体系。
- 前端新增 `uiux-guidelines.md`，覆盖可访问性、键盘焦点、交互态、空/加载/错误/重试、桌面/移动、触控尺寸、文案、对比度、表单反馈。
- 后端新增 `plugin-data-flow.md`，沉淀新增插件数据层从 Table 到 Provider 与测试的端到端流程。

## 验收标准

- [ ] `.trellis/tasks/05-23-fix-omo-migration/prd.md` 存在且为中文。
- [ ] `implement.jsonl` 与 `check.jsonl` 均至少包含一个带 `file` 字段的有效 JSONL 条目，不再只有 `_example`。
- [ ] `.trellis/workflow.md` 与 `.trellis/spec/` 活跃规范中不存在会误导 agent 的 `.omo` 路径。
- [ ] `.trellis/spec/frontend/index.md` 已引用 UI/UX 规范。
- [ ] `.trellis/spec/backend/index.md` 已引用插件数据流规范。
- [ ] 根 `.gitignore` 不忽略整个 `.trellis/`，且 `git status --porcelain -- .pi` 不出现 `.pi/npm/node_modules` 待跟踪项。
