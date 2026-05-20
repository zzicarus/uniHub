# lib/src — 源码分层架构

```
lib/src/
├── core/           ← 基础设施层：数据库、路由、主题、插件系统
├── shared/         ← 共享 UI 层：可复用布局 + 通用组件
└── plugins/        ← 功能插件层：业务功能以插件形式实现
```

## 核心约定

### 依赖方向
`plugins/ → shared/ → core/`（插件可依赖 shared 和 core，core 不可依赖 plugins）

✅ 已修复：`ThoughtsTable` 移至 `core/database/tables/`，依赖方向恢复正常。

### 布局系统

| 机制 | 状态 | 说明 |
|------|------|------|
| `AdaptiveShell` → `DesktopShell` / `MobileShell` | ✅ **使用中** | GoRouter ShellRoute 接入，桌面端布局 |
| `AdaptiveLayout` | ✅ 被 ThoughtsPage 使用 | 插件页面内的响应式布局 |

- **新增页面**：顶层路由页面 → 使用 `AdaptiveShell`（已注册在 GoRouter ShellRoute）
- **插件内部**：插件页面内容 → 使用 `AdaptiveLayout`（ThoughtsPage 模式）

### 路由模式
- `GoRouter` + `ShellRoute`（在 `app_router.dart` 中定义）
- `AdaptiveShell.build()` 根据宽度分发到 DesktopShell/MobileShell
- 插件通过 `UniHubPlugin.routes()` 贡献自己的路由
- 所有非插件路由在 `app_router.dart` 中定义

### 测试注意事项
- 数据库隔离：使用 `NativeDatabase.memory()`（in-memory SQLite）
- Provider 注入：使用 `ProviderScope` overrides 注入 test DB 和 PluginRegistry
- 零 mockito：目前全部通过手写 stub 实现
- 详细测试约定见 [`test/AGENTS.md`](../../test/AGENTS.md)
- 代理任务分类与委派指南见 [`.omo/guidelines/agent-workflow.md`](../../.omo/guidelines/agent-workflow.md)
- 知识同步映射规则见 [`.omo/knowledge-map.json`](../../.omo/knowledge-map.json)

---

## 近期变更

> 本 section 由 sync-knowledge 自动管理，按时间倒序追加。
