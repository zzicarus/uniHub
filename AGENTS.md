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

## 代码库导航

可按模块查阅对应的 AGENTS.md：

| 路径 | 内容 | 优先级 |
|------|------|--------|
| `lib/src/` | 分层架构总览、模块边界 | 第一站 |
| `lib/src/core/` | 基础设施总览（路由/启动/布局/生命周期） | 深度阅读 |
| `lib/src/core/plugin/` | **插件系统关键约定 + 已知陷阱** | 新增/修改插件必读 |
| `lib/src/plugins/thoughts/` | Thoughts 插件内部架构 + data/ui 分层 | 维护该插件必读 |
| `test/` | 测试隔离模式 + ProviderScope override | 新增测试必读 |

## 项目规范

项目开发规范位于 `.omo/guidelines/` 目录：

- `.omo/guidelines/database.md` — 数据库规范（drift/SQLite）
- `.omo/guidelines/widget.md` — Widget 编写规范（设计令牌、M3 ColorScheme、布局约定）

## 关键已知问题（Agent 需注意）

| # | 问题 | 位置 | 影响 |
|---|------|------|------|
| 1 | `AppBootstrap` 定义但从未调用 | `lib/src/core/app/app_bootstrap.dart` | 死代码，不要尝试使用 |
| 2 | `PluginRegistry.quickCreate` 硬编码 `id=='thoughts'` | `lib/src/core/plugin/plugin_registry.dart` | 新插件不会自动注册 |
| 3 | 三套布局机制并存：`AppLayout`（死）、`AdaptiveShell`（活）、`AdaptiveLayout`（在用） | `shared/layouts/` + `core/app/` | 新页面需确认使用哪个 |
| 4 | `dynamic ref` 在 `PluginInterface` | `lib/src/core/plugin/plugin_interface.dart` | 类型不安全，需运行时 cast |
| 5 | `core/database/app_database.dart` 直接 import `plugins/thoughts/table` | `lib/src/core/database/` | 架构层间循环依赖 |
