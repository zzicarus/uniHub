# Directory Structure

> UniHub 后端代码的组织方式（Drift/SQLite + Dart）

---

## Overview

UniHub 的"后端"指数据层与基础设施层，全部在 `lib/src/core/` 中实现。没有独立的后端服务 — 数据全部本地存储在 SQLite 中。

| 路径 | 职责 |
|------|------|
| `lib/src/core/database/` | Drift 数据库入口 + 表定义 |
| `lib/src/core/plugin/` | 插件系统（注册、生命周期） |
| `lib/src/core/theme/` | Material 3 主题系统 |
| `lib/src/core/router/` | GoRouter 路由定义 |
| `lib/src/core/search/` | 全局搜索接口 |
| `lib/src/core/app/` | 应用壳、布局、页面编排 |

---

## Directory Layout

```
lib/src/core/
├── app/                     # 应用壳 + ShellRoute 布局
│   ├── home/                # 首页区块（Focus、Recent、RightRail）
│   ├── settings/            # 设置页面
│   ├── adaptive_shell.dart  # 响应式布局壳
│   ├── app.dart             # 应用入口
│   ├── dashboard_providers.dart
│   ├── desktop_shell.dart
│   ├── mobile_shell.dart
│   ├── mobile_placeholder_pages.dart
│   └── home_page.dart
├── database/                # 数据库 — Drift
│   ├── tables/              # 表定义文件
│   ├── app_database.dart    # Drift Database 入口
│   └── database_provider.dart
├── plugin/                  # 插件系统
│   ├── plugin_interface.dart   # UniHubPlugin 抽象
│   └── plugin_registry.dart    # 注册与生命周期
├── router/                  # GoRouter
│   ├── app_router.dart      # 路由配置
│   └── route_names.dart     # 路由名常量
├── search/                  # 全局搜索
│   └── search_result.dart
└── theme/                   # Material 3 主题
    ├── app_theme.dart
    ├── app_theme_preset.dart
    ├── app_theme_registry.dart
    ├── app_theme_tokens.dart
    ├── app_tokens.dart       # 设计令牌（Spacing、Radius、Colors）
    ├── app_breakpoints.dart  # 响应式断点
    └── theme_settings_provider.dart
```

---

## Module Organization

### 数据库模块（`database/`）

```
database/
├── tables/
│   ├── thoughts_table.dart    # Thoughts 表定义
│   └── ...                    # 其他插件表（按需添加）
├── app_database.dart          # @DriftDatabase 注解入口
└── database_provider.dart     # Riverpod Provider
```

> **关键约束**：`@DriftDatabase(tables: [...])` 是编译期集中注册点。各插件表必须在 launch 前手动添加到 `tables:` 数组中。

### 插件模块（`plugin/`）

```
plugin/
├── plugin_interface.dart     # abstract class UniHubPlugin
└── plugin_registry.dart      # PluginRegistry — 管理所有插件的注册与 dispose
```

> 插件系统是项目架构的核心。新增插件必须：
> 1. 实现 `UniHubPlugin` 接口
> 2. 在 `PluginRegistry` 中注册
> 3. 表定义添加到 `AppDatabase.tables`

---

## Naming Conventions

| 类型 | 命名规则 | 示例 |
|------|----------|------|
| 表定义 | `PascalCase + Table` | `ThoughtsTable` |
| 数据库类 | `PascalCase` | `AppDatabase` |
| DAO | `PascalCase + Dao` | `ThoughtsDao` |
| Repository | `PascalCase + Repository` | `ThoughtsRepository` |
| Provider 文件 | `snake_case + _provider` | `database_provider.dart` |
| 表定义文件 | `snake_case + _table` | `thoughts_table.dart` |

---

## Examples

- `lib/src/core/database/app_database.dart` — Drift 数据库入口（集中注册点）
- `lib/src/core/plugin/plugin_interface.dart` — 插件接口定义
- `lib/src/core/plugin/plugin_registry.dart` — 插件注册与管理
