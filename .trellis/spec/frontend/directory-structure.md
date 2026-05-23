# Directory Structure

> UniHub 前端代码的组织方式（Flutter + Riverpod + GoRouter）

---

## Overview

UniHub 采用三层架构：`core/` → `shared/` → `plugins/`。依赖方向不可逆（plugins → shared → core）。

| 层 | 路径 | 职责 |
|----|------|------|
| 基础设施 | `lib/src/core/` | 路由、启动、数据库、主题、插件系统 |
| 共享组件 | `lib/src/shared/` | UI 组件、工具函数、跨插件复用 |
| 功能插件 | `lib/src/plugins/` | 按功能域拆分（thoughts/、todo/ 等） |

---

## Directory Layout

```
lib/src/
├── core/
│   ├── app/                  # 应用壳、ShellRoute、页面
│   │   ├── home/             # 首页各区块（Header、Focus、Recent、RightRail）
│   │   ├── settings/         # 设置页面（外观设置等）
│   │   ├── adaptive_shell.dart
│   │   ├── app.dart
│   │   ├── dashboard_providers.dart
│   │   ├── desktop_shell.dart
│   │   ├── mobile_shell.dart
│   │   ├── mobile_placeholder_pages.dart
│   │   └── home_page.dart
│   ├── database/             # Drift 数据库入口 + 表定义
│   │   └── tables/           # 各表文件（thoughts_table.dart 等）
│   ├── plugin/               # 插件系统接口与注册
│   ├── router/               # GoRouter 路由定义
│   ├── search/               # 全局搜索
│   └── theme/                # Material 3 主题配置与 Token
├── shared/
│   ├── ui/                   # 可复用 UI 组件
│   │   ├── panels/           # AppPanel、SidebarPanel
│   │   ├── rich_text_editor/ # 富文本编辑器
│   │   └── widgets/          # 通用 Widget（AppIconBubble 等）
│   └── extensions/           # Dart extension 方法
├── plugins/
│   └── thoughts/             # Thoughts 功能插件
│       ├── data/             # DAO+Repository+Service
│       ├── providers/        # Riverpod Provider 定义
│       └── ui/
│           ├── pages/        # 页面级 Widget
│           └── widgets/      # 可复用组件
└── AGENTS.md                 # Agent 入口文档
```

---

## Module Organization

### 插件内部分层（以 thoughts 为例）

```
plugins/thoughts/
├── data/           # ✅ 数据层
│   ├── thoughts_repository.dart    # Repository（业务逻辑）
│   ├── thoughts_dao.dart           # DAO（数据访问）
│   ├── file_image_storage.dart     # Service（外部服务）
│   └── thought_content_codec.dart  # Codec（数据编解码）
├── providers/      # ✅ 状态管理层
│   ├── thoughts_providers.dart           # 主 Provider 定义
│   ├── thought_status_filter.dart        # 状态过滤
│   └── selected_tag_filters_provider.dart # 标签过滤
└── ui/             # ✅ 展示层
    ├── pages/      # 页面级 Widget（ConsumerStatefulWidget）
    └── widgets/    # 可复用组件（ConsumerWidget / StatelessWidget）
```

### 文件命名约定

| 类型 | 命名规则 | 示例 |
|------|----------|------|
| Widget | snake_case + `_page`/`_panel`/`_card` | `thought_list_page.dart`, `thought_card.dart` |
| Provider | 描述性名 + `_provider` | `thoughts_providers.dart`, `database_provider.dart` |
| DAO | 表名 + `_dao` | `thoughts_dao.dart` |
| Repository | 模块名 + `_repository` | `thoughts_repository.dart` |
| 数据模型 | `PascalCase` | `Thought`, `Todo` |
| 表定义 | `PascalCase + Table` | `ThoughtsTable`, `TodoTable` |

---

## Naming Conventions

- **文件**: `snake_case.dart` — 所有源文件
- **类/枚举**: `PascalCase` — Widget、Model、Provider、Service
- **函数/变量**: `camelCase` — 方法、属性、局部变量
- **常量/Token**: `camelCase` — `AppSpacing.sm`, `AppColors.surface`
- **私有**: 前缀 `_` — Dart 标准
- **导入**: package 路径（`package:uni_hub/src/...`），禁止 `../../../`

---

## Examples

参考 `lib/src/plugins/thoughts/` — 这是目前最完整的插件实现，可以作为新增插件的模板：

- `data/`: DAO → Repository → Service 的分层清晰
- `providers/`: 用 `@riverpod` 注解生成 Provider，filter state 用 `StateProvider`/`NotifierProvider`
- `ui/`: pages 层负责页面编排，widgets 层负责可复用组件
