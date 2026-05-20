# core/plugin — 插件系统

这是 UniHub 最核心的架构层。所有业务功能以插件形式集成。

## UniHubPlugin 接口

```dart
abstract class UniHubPlugin {
  String get id;              // 唯一标识，如 'thoughts'
  String get name;            // 显示名称
  String get icon;            // 图标标识
  String? get routePath;      // 根路由路径，如 '/thoughts'
  List<GoRoute> routes();     // 贡献的路由
  List<TableInfo> get tables; // 贡献的数据库表
  int get schemaVersion;      // 数据库版本号
  List<Override> providers(); // 贡献的 Riverpod Provider
  Future<void> init(WidgetRef ref);  // 初始化钩子
  Future<void> dispose();     // 清理钩子
}
```

## 插件注册流程

```
main.dart → PluginRegistry.register(ThoughtsPlugin())
         → PluginRegistry.allPlugins（Provider 暴露）
         → routerProvider 遍历插件收集 routes()
         → AppDatabase 遍历插件收集 tables
```

## 已修复的历史问题

以下架构违规已修复：

| # | 问题 | 修复方式 |
|---|------|---------|
| 1 | `PluginRegistry.quickCreate` 硬编码 `id == 'thoughts'` | 改为遍历所有插件，调用 `plugin.quickCreate()` |
| 2 | `UniHubPlugin` 接口使用 `dynamic ref` | 改为 `Ref` 编译期类型 |
| 3 | `AppDatabase` 直接 import `plugins/thoughts/` 的表 | `ThoughtsTable` 移至 `core/database/tables/`，双向依赖消除 |

## 如何新增一个插件

1. 实现 `UniHubPlugin` 抽象类
2. 在 `main.dart` 中调用 `registry.register(YourPlugin())`
3. 如果需要数据库表
    - 表定义放在 `core/database/tables/` 中
    - 在 `get tables` 中返回
    - 同时在 `AppDatabase` 的 `@DriftDatabase(tables: [...])` 中添加
5. 实现 `routes()` 返回 GoRoute 列表
6. 实现 `init()` 做初始化（如创建默认数据）
7. 添加测试：参考 `test/src/core/plugin/plugin_registry_test.dart`
