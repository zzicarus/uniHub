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

## 关键陷阱

### 1️⃣ `PluginRegistry.quickCreate` 硬编码
`quickCreate` 方法目前只处理 `id == 'thoughts'` 的插件。
**新插件不会自动通过 quickCreate 注册**，需在 `main.dart` 中显式 `register()`。

### 2️⃣ `dynamic ref` 类型不安全
`UniHubPlugin.init(WidgetRef ref)` 参数为 `dynamic` 类型。
provider 返回 `[UniHubPlugin]` 时需调用方运行时 cast。
**不要依赖编译期类型检查**，插件方法调用后需验证结果。

### 3️⃣ 插件贡献表的注册
插件通过 `get tables` 贡献表定义给 `AppDatabase`。
`AppDatabase` 当前在构造时遍历所有插件的 tables 并合并。
⚠️ 当前 `AppDatabase` 直接 import `plugins/thoughts/` 的表——这违反了依赖方向。

## 如何新增一个插件

1. 实现 `UniHubPlugin` 抽象类
2. 在 `main.dart` 中调用 `registry.register(YourPlugin())`
3. 在 `PluginRegistry.quickCreate` 中添加该插件的创建逻辑
4. 如果需要数据库表，在 `get tables` 中返回
    - 同时在 `AppDatabase` 的 `@DriftDatabase(tables: [...])` 中添加
5. 实现 `routes()` 返回 GoRoute 列表
6. 实现 `init()` 做初始化（如创建默认数据）
7. 添加测试：参考 `test/src/core/plugin/plugin_registry_test.dart`
