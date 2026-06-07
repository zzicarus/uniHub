# UniHub 应用架构

> 统一架构视图：3 层分层、插件系统、编辑引擎。

---

## 分层架构

```
┌─────────────────────────────────────────────────────────┐
│                     plugins/                             │
│  thoughts  │  collections  │  (todo…)  │  (future…)     │
├─────────────────────────────────────────────────────────┤
│                     shared/                              │
│  编辑器集成   │  TagKit  │  通用 Widget  │  响应式布局   │
├─────────────────────────────────────────────────────────┤
│                     core/                                │
│  数据库  │  路由  │  主题  │  插件系统  │  Shell 布局    │
└─────────────────────────────────────────────────────────┘
```

## 插件能力接口（Capability）

自 2026-06-07 起，`UniHubPlugin` 拆分为 6 个独立的能力接口：

- `RouteContributor` — 贡献 GoRouter 路由
- `NavContributor` — 贡献侧边栏导航
- `DatabaseContributor` — 贡献 Drift 表
- `DashboardContributor` — 贡献首页面板
- `QuickCaptureHandler` — 支持快速创建
- `SearchProvider` — 支持全局搜索

`UniHubPlugin` 同时实现上述全部接口以保持向后兼容。
`PluginRegistry` 按 `whereType<T>()` 聚合而非直接遍历所有插件。

详见 `.trellis/spec/backend/plugin-data-flow.md` 第 9 节。

### 依赖方向（严格单向）

```
plugins/  →  shared/  →  core/
```

- **不允许**反向依赖：`core/` 不知道 `plugins/` 的存在。
- **不允许**跨层跳过：`plugins/` 不能直接引用 `core/router/` 的实现细节。
- 跨层引用必须使用 `package:` 路径（如 `package:uni_hub/src/core/database/app_database.dart`），禁止相对路径 `../../../`。
- 插件系统例外：`PluginRegistry`（core）通过 `UniHubPlugin` 接口间接引用插件。

### 各层职责

| 层 | 目录 | 职责 |
|----|------|------|
| core | `lib/src/core/` | 应用壳、数据库（Drift）、路由（GoRouter）、主题（M3 + 预设系统）、插件注册、Shell 布局、搜索基础 |
| shared | `lib/src/shared/` | 编辑器集成（AppFlowy）、TagKit（标签 UI + 逻辑）、通用 Widget（侧栏、卡片、面板、响应式布局） |
| plugins | `lib/src/plugins/` | 功能插件：thoughts（想法）、collections（内容收藏）、预留（todo 等） |

---

## 插件系统

`UniHubPlugin` 抽象类定义插件接口（`lib/src/core/plugin/plugin_interface.dart`）：

| 方法 | 用途 | 必须实现 |
|------|------|---------|
| `id` | 插件唯一标识符 | ✅ |
| `label` | 用户可见的名称 | ✅ |
| `routes` | GoRouter 路由扩展 | ❌ |
| `tables` | Drift 表定义 | ❌ |
| `getStat` / `getRecentItems` / `getPinnedItems` | Dashboard 数据贡献 | ❌ |
| `quickCreate` | 快速创建入口 | ❌ |
| `schemaVersion` | 数据库迁移版本 | ❌（默认 1） |

**已知约束**：
- Drift 表必须在 `@DriftDatabase(tables: [...])` 中编译期集中注册（`app_database.dart`），无法从运行时 PluginRegistry 动态注入。
- 插件注册顺序影响 Dashboard 中的排列顺序。

---

## 编辑引擎架构

UniHub 使用双编辑引擎过渡策略：

| 引擎 | 状态 | 用途 |
|------|------|------|
| **AppFlowy Editor** | 主线 | `/thoughts/:id` 编辑、Workspace modal 编辑、quickCreate |
| **flutter_quill** | 迁移遗留 | 不再被用户主路径引用；文件保留用于读取历史数据 |

详见 `editor-migration.md`。

---

## 状态管理（Riverpod）

| 模式 | Provider 类型 | 使用场景 |
|------|--------------|---------|
| 依赖注入 | `Provider<T>` | 数据库、DAO、Repository |
| 异步数据 | `FutureProvider<T>` | 列表查询、统计数据 |
| UI 状态 | `StateProvider<T>` | 筛选条件、选中项 ID |
| 复杂逻辑 | `NotifierProvider<T>` | 需要组合多个状态的场景 |

**规则**：
- 数据流：`Widget (ref.watch) → Provider → Repository → DAO → DB`
- AsyncValue 三态处理：`.when(data:, error:, loading:)`
- 读取 Provider 用 `ref.watch`（build 中），写操作用 `ref.read`（事件处理器中）

---

## 响应式布局

| 档位 | 宽度 | 布局 |
|------|------|------|
| compact | `< 900px` | 底部导航 + 全屏页面 |
| medium | `900 - 1279px` | 侧栏 + 内容（2 列） |
| expanded | `>= 1280px` | 侧栏 + 内容 + 右栏（3 列） |

断点来源：`AppBreakpoints.of(context)`（`lib/src/core/theme/app_breakpoints.dart`）。

---

## 主题系统

- 6 套预设（Uni Blue / Paper / Forest / Sakura / Amber / Graphite），每套含亮暗两个变体
- 预设切换通过 `themeSettingsProvider` 持久化，即时生效
- Widget 层颜色优先来自 `Theme.of(context).colorScheme`，产品特有颜色通过 `context.appColors`（`UniHubThemeColors` extension）
