# core/ — 基础设施层

贯穿应用核心功能：数据库、路由、主题、插件系统、搜索。

## 模块一览

| 模块 | 路径 | 用途 |
|------|------|------|
| app/ | `core/app/` | 应用入口、App 组件、Shell 布局、HomePage |
| database/ | `core/database/` | Drift 数据库定义 + Provider |
| plugin/ | `core/plugin/` | **插件系统（详见 plugin/AGENTS.md）** |
| router/ | `core/router/` | GoRouter 配置 + 路由 Provider |
| search/ | `core/search/` | 全局搜索基础设施 |
| theme/ | `core/theme/` | Material 3 主题 + 设计令牌 |

## 布局系统（重要）

三套布局并存——确定自己该用哪个：

| 你的页面类型 | 使用 |
|-------------|------|
| 顶层路由页面（从 GoRouter 导航过来） | 不直接选——GoRouter ShellRoute（`AdaptiveShell`）自动选择 DesktopShell/MobileShell |
| 插件页面内的子布局 | `AdaptiveLayout`（参考 ThoughtsPage 中的用法） |
| 任何地方都不要新建 | `AppLayout`（已废弃/死代码） |

## 启动序列

```
main()
└─ ProviderScope (顶层)
   ├─ AppDatabase (LazyDatabase → 延迟创建)
   ├─ PluginRegistry (注册所有插件)
   │  └─ 各插件.init(ref) —— 注意 ref 是 dynamic
   └─ UniHubApp (MaterialApp.router)
      └─ routerProvider (GoRouter + ShellRoute)
```

## 已知死代码

- `app_bootstrap.dart` — `AppBootstrap` 定义但未在任何地方调用
- `app/app_layout.dart` — 旧的布局实现，未被引用
- `app/style_guide_screen.dart` — 1162 行占位页面（可能是开发期产物）
- `app/mobile_placeholder_pages.dart` — 5 个硬编码占位页面（1505 行）

## 数据库

详见 `.omo/guidelines/database.md`。核心注意：

- `AppDatabase` 通过遍历插件 `tables` 合并所有表
- ⚠️ `app_database.dart` 直接 import `plugins/thoughts/` 的表——架构违规
- 使用 `LazyDatabase` 延迟创建，Provider dispose 时关闭
- 所有 DAO/Repository 使用构造器注入 `AppDatabase`

## 主题

- Material 3 + `ColorScheme.fromSeed(seedColor: AppColors.primary)`
- 亮/暗色通过 `ThemeMode.system` 自动切换
- 所有 Widget 使用 `Theme.of(context).colorScheme`（不直接使用 AppColors 常量）
- 设计令牌 Token 定义在 `app_tokens.dart`（AppSpacing、AppRadius、AppSizes 等）
