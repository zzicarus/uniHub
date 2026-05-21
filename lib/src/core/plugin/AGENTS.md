# core/plugin — 插件系统

这是 UniHub 最核心的架构层。所有业务功能以插件形式集成。

## UniHubPlugin 接口

```dart
abstract class UniHubPlugin {
  String get id;                    // 唯一标识，如 'thoughts'
  String get name;                  // 显示名称
  List<NavEntry> get navEntries => [];   // 侧栏导航条目
  List<GoRoute> get routes => [];        // 贡献的路由
  List<Type> get tables => [];           // 贡献的数据库表类型
  int get schemaVersion => 0;            // 数据库版本号
  Future<void> onInit() async {}         // 启动初始化钩子
  Future<void> onDispose() async {}      // 清理钩子
  Future<List<SearchResult>> search(String query) async => [];
  Future<List<DashboardItem>> getRecentItems(Ref ref, {int count = 4}) async => [];
  Future<List<DashboardItem>> getPinnedItems(Ref ref, {int count = 3}) async => [];
  Future<PluginStat?> getStat(Ref ref) async => null;
  Future<DashboardItem?> quickCreate(Ref ref, {required String content, String? tags}) async => null;
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
3. **启动流程**：`main.dart` 会在 `runApp()` 之前自动调用 `registry.initAll()`，插件的 `onInit()` 钩子会按注册顺序执行
4. 如果需要数据库表
    - 表定义放在 `core/database/tables/` 中
    - 在插件的 `get tables` 中返回对应 `Type`
    - **同步更新** `AppDatabase` 的 `@DriftDatabase(tables: [...])` 注解（集中注册点）
    - **同步更新** 插件的 `schemaVersion`（`AppDatabase` 会自动取所有插件版本的最大值）
5. 实现 `routes()` 返回 GoRoute 列表
6. 实现 `onInit()` 做初始化（如创建默认数据）
7. 添加测试：参考 `test/src/core/plugin/plugin_registry_test.dart`

### 数据库集中注册说明

由于 `@DriftDatabase` 注解在**编译期**由 `drift_dev` 代码生成器读取，表列表无法在运行时从 `PluginRegistry` 动态注入。因此：

- **集中注册点**：`lib/src/core/database/app_database.dart` 的 `@DriftDatabase(tables: [...])`
- **运行时验证**：`AppDatabase` 构造时会通过 `assert` 检查插件声明的表与集中注册表是否一致（debug 模式）
- **schemaVersion 联动**：`AppDatabase.schemaVersion` 自动取所有插件 `schemaVersion` 的最大值，无需手动同步

如果新增表后忘记同步更新 `app_database.dart`，debug 模式下会触发断言失败，提示集中注册点与插件声明不一致。

---

## 近期变更

> 本 section 由 sync-knowledge 自动管理，按时间倒序追加。
