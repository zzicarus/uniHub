# 同步 UniHub Trellis 项目规范

## Goal

将所有用户可见和 Agent 可见的项目文档与当前代码库现实对齐，消除「文档描述笔记应用+flutter_quill」但「代码实现个人工具箱+AppFlowy」的偏差。

## 现有文档状态 vs 代码现实

| 文档 | 现状（描述什么） | 应描述什么 | 优先级 |
|------|-----------------|-----------|--------|
| `README.md` | Flutter 默认模板 | 项目简介、定位、快速开始 | P0 |
| `AGENTS.md` | 「桌面端优先 Flutter **笔记**应用，技术栈 **flutter_quill**」 | 「**个人工具箱**，技术栈 **AppFlowy Editor**（主） + flutter_quill（迁移遗留）」 | P0 |
| `database-guidelines.md` | 「富文本正文存储合同」场景写的是 Quill Delta envelope | 更新为 AppFlowy JSON envelope，调整兼容读取规则 | P1 |
| `app-architecture.md` | 不存在 | 创建：3 层架构 + 插件系统 + 编辑引擎架构演进说明 | P1 |
| `editor-migration.md` | 不存在 | 创建：Quill→AppFlowy 迁移记录、`ThoughtContentCodec` 合同、遗留组件清单 | P1 |
| `roadmap.md` | 不存在 | 创建：当前方向、近期目标、已知缺口 | P2 |
| `component-guidelines.md` | 已在近期更新 | 确认 `flutter_quill` 相关引用是否已清理 | P2 |

## 涉及文件

| 文件 | 操作 | 说明 |
|------|------|------|
| `README.md` | 重写 | 取消 Flutter 模板，写项目定位和架构简介 |
| `AGENTS.md` | 编辑 | 更新项目概述表（定位、技术栈、方向）、代码库导航表、最后核对日期 |
| `.trellis/spec/backend/database-guidelines.md` | 编辑 | Scenario 5「富文本正文存储合同」更新为 AppFlowy JSON envelope |
| `.trellis/spec/architecture/app-architecture.md` | 创建 | 3 层架构 + 插件系统 + 编辑引擎架构说明 |
| `.trellis/spec/architecture/editor-migration.md` | 创建 | Quill→AppFlowy 迁移记录、`ThoughtContentCodec` 合同、遗留组件清单 |
| `.trellis/spec/guides/roadmap.md` | 创建 | 当前方向、近期目标、已知缺口 |
| `.trellis/spec/frontend/component-guidelines.md` | 审核清理 | 确认无过时 Quill 引用 |
| `.trellis/spec/index.md` | 更新 | 加入 architecture/ 路径引用 |

## Definition of Done

- [ ] `README.md` 不再是 Flutter 默认模板，包含项目定位、技术栈、架构简述
- [ ] `AGENTS.md` 项目概述表更新为「个人工具箱」定位 + AppFlowy 技术栈，最后核对日期更新
- [ ] `database-guidelines.md` Scenario 5 中 envelope 合同从 `unihub.quill_delta.v1` 更新为 `unihub.appflowy_json.v1`
- [ ] `app-architecture.md` 创建，涵盖 3 层架构、插件系统、编辑引擎架构说明
- [ ] `editor-migration.md` 创建，涵盖迁移背景、`ThoughtContentCodec` 合同、遗留组件清单
- [ ] `roadmap.md` 创建，涵盖当前方向、近期目标、已知缺口
- [ ] `component-guidelines.md` 中无过时 Quill 引用
- [ ] `.trellis/spec/index.md` 引用 `architecture/` 路径
- [ ] 不对代码库做任何实现变更（纯文档任务）

## Out of Scope

- 不修改任何 `lib/` 下的源码
- 不修改测试文件
- 不修改 workflow 或 CI 配置
- 不做数据库迁移
