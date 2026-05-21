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

两套布局——确定自己该用哪个：

| 你的页面类型 | 使用 |
|-------------|------|
| 顶层路由页面（从 GoRouter 导航过来） | 不直接选——GoRouter ShellRoute（`AdaptiveShell`）自动选择 DesktopShell/MobileShell |
| 插件页面内的子布局 | `AdaptiveLayout`（参考 ThoughtsPage 中的用法） |
| 任何地方都不要新建 | `AppLayout`（已删除） |

## 启动序列

```
main()
├─ WidgetsFlutterBinding.ensureInitialized()
├─ PluginRegistry (注册所有插件)
│  └─ registry.initAll() (各插件.onInit 按注册顺序执行)
└─ runApp(
     ProviderScope (顶层)
        ├─ AppDatabase (LazyDatabase → 延迟创建, 接收 PluginRegistry)
        ├─ PluginRegistry (overrideWithValue, 已初始化完毕)
        └─ UniHubApp (MaterialApp.router)
           └─ routerProvider (GoRouter + ShellRoute)
   )
```

## 已知死代码

- `app/mobile_placeholder_pages.dart` — 5 个轻量占位页面（用于未实现的移动端路由）
- `shared/ui/style_guide_screen.dart` — 组件目录页面（已接入路由，通过侧栏「组件目录」访问）

## 数据库

详见 `.omo/guidelines/database.md`。核心注意：

- `AppDatabase` 通过遍历插件 `tables` 合并所有表
- 表定义统一放在 `core/database/tables/` 下，插件不直接引入数据库表
- 使用 `LazyDatabase` 延迟创建，Provider dispose 时关闭
- 所有 DAO/Repository 使用构造器注入 `AppDatabase`

## 主题

- Material 3 + `ColorScheme.fromSeed(seedColor: AppColors.primary)`
- 亮/暗色通过 `ThemeMode.system` 自动切换
- 所有 Widget 使用 `Theme.of(context).colorScheme`（不直接使用 AppColors 常量）
- 设计令牌 Token 定义在 `app_tokens.dart`（AppSpacing、AppRadius、AppSizes 等）

---

## 近期变更

> 本 section 由 sync-knowledge 自动管理，按时间倒序追加。

### 2026-05-22: P1-1/P1-2 插件数据库与生命周期修复
- **AppDatabase** 现在接收 `PluginRegistry`，`schemaVersion` 动态计算（取所有插件版本的最大值），构造函数增加 debug 模式断言验证插件表与集中注册表一致性
- **main.dart** 启动序列改为 `async main()`，在 `runApp()` 之前调用 `registry.initAll()`，使用 `overrideWithValue` 传递已初始化的 registry
- **database_provider** 创建 `AppDatabase` 时传入 PluginRegistry
- 插件 `AGENTS.md` 和 `database.md` 规范文档同步更新
