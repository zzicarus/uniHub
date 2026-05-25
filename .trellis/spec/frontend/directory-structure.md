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
│   ├── app/                    # 应用壳、ShellRoute、页面
│   │   ├── home/               # 首页各区块
│   │   │   ├── focus_section.dart
│   │   │   ├── header.dart
│   │   │   ├── mobile_home.dart
│   │   │   ├── recent_section.dart
│   │   │   └── right_rail.dart
│   │   ├── settings/
│   │   │   └── appearance_settings_section.dart
│   │   ├── adaptive_shell.dart
│   │   ├── app.dart
│   │   ├── dashboard_providers.dart
│   │   ├── desktop_shell.dart
│   │   ├── home_page.dart
│   │   ├── mobile_placeholder_pages.dart
│   │   ├── mobile_shell.dart
│   │   └── settings_page.dart
│   ├── database/               # Drift 数据库入口 + 表定义
│   │   ├── app_database.dart
│   │   ├── database_provider.dart
│   │   └── tables/
│   │       ├── collection_boxes_table.dart
│   │       ├── enrichment_jobs_table.dart
│   │       ├── saved_item_boxes_table.dart
│   │       ├── saved_items_table.dart
│   │       └── thoughts_table.dart
│   ├── plugin/                 # 插件系统接口与注册
│   │   ├── plugin_interface.dart
│   │   └── plugin_registry.dart
│   ├── router/                 # GoRouter 路由定义
│   │   ├── app_router.dart
│   │   └── route_names.dart
│   ├── search/
│   │   └── search_result.dart
│   └── theme/                  # Material 3 主题配置与 Token
│       ├── app_breakpoints.dart       # 响应式断点（900/1280 三档）
│       ├── app_theme.dart             # AppTheme.build() + 子主题
│       ├── app_theme_preset.dart      # 6 套主题预设
│       ├── app_theme_registry.dart    # 预设→颜色映射（亮/暗×6）
│       ├── app_theme_tokens.dart      # UniHubThemeColors extensions
│       ├── app_tokens.dart            # 所有 Token 常量
│       └── theme_settings_provider.dart  # 主题偏好
├── shared/                   # 共享组件层
│   ├── editor/               # AppFlowy 编辑器集成
│   │   ├── appflowy_document_tools.dart
│   │   └── appflowy_thought_editor.dart
│   ├── layouts/              # 响应式布局组件
│   │   └── app_layout.dart
│   ├── tags/                 # TagKit 核心层（纯函数，无 UI 依赖）
│   │   ├── tag_models.dart           # AppTagStat、TagMatchMode、TagValidationResult
│   │   ├── tag_codec.dart            # 标签编解码
│   │   └── tag_filter_logic.dart     # 过滤逻辑
│   ├── ui/                   # 可复用 UI 组件
│   │   ├── rich_text_editor/ # 富文本编辑器
│   │   └── style_guide_screen.dart
│   └── widgets/              # 通用 Widget
│       ├── adaptive_layout.dart      # AdaptiveLayout(mobile/desktop)
│       ├── app_compact_list_item.dart # 紧凑列表项（图标+标题+副标题+onTap）
│       ├── app_icon_bubble.dart      # 图标气泡
│       ├── app_panel.dart            # Panel 容器
│       ├── app_search_box.dart       # 搜索框
│       ├── app_section_header.dart   # 区域标题（可选图标+尾部操作）
│       ├── sidebar.dart              # 侧栏导航
│       ├── uni_icon_badge.dart       # 图标角标
│       ├── uni_panel.dart            # Uni Panel 容器
│       ├── uni_pill.dart             # 标签状徽章
│       ├── uni_status_panel.dart     # 状态面板（加载/空/错误通用）
│       ├── website_logo.dart         # 站点 Logo 展示（只读本地缓存文件）
│       └── tags/             # TagKit UI 组件（无 Provider 依赖）
│           ├── app_tag_chip.dart
│           ├── app_tag_filter_bar.dart
│           ├── app_selected_tags_bar.dart
│           ├── app_common_tags_panel.dart
│           ├── app_tag_input.dart
│           └── app_more_tags_popover.dart
├── plugins/
│   ├── thoughts/             # Thoughts 功能插件
│   │   ├── data/             # DAO+Repository+Service
│   │   ├── providers/        # Riverpod Provider 定义
│   │   └── ui/
│   │       ├── layouts/      # 响应式页面（desktop/mobile/shared）
│   │       └── widgets/      # 可复用组件
│   └── collections/          # 内容收藏功能插件
│       ├── data/             # DAO
│       ├── domain/           # 值对象/枚举（MediaType, SourcePlatform 等）
│       ├── providers/        # Riverpod Provider
│       ├── services/         # 元数据抓取、收藏等服务
│       └── ui/
│           ├── layouts/      # 桌面工作台
│           └── widgets/      # 卡片、面板、筛选栏
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
| TagKit 组件 | snake_case + `app_` 前缀 | `app_tag_chip.dart`, `app_tag_filter_bar.dart` |
| TagKit 核心 | snake_case | `tag_codec.dart`, `tag_filter_logic.dart` |
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

参考 `lib/src/shared/tags/` 和 `lib/src/shared/widgets/tags/` — TagKit 组件复用模式：

- `tags/`: 纯函数核心，零依赖，方便跨插件复用过滤逻辑
- `widgets/tags/`: 无 Provider 依赖的 UI 组件，通过回调与业务层通信
- 插件通过 adapter（如 `ThoughtCommonTagsPanel`）将 provider 数据转为组件 props
