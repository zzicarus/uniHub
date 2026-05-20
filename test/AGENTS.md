# test/ — 测试约定

## 数据库隔离

所有测试使用 in-memory Drift 连接，避免依赖文件系统：

```dart
import 'package:drift/native.dart';

final db = AppDatabase(NativeDatabase.memory());
```

不在测试间共享数据库实例。每个测试套件独立创建。

## ProviderScope 注入模式

Widget 测试通过 `ProviderScope` overrides 注入测试依赖：

```dart
ProviderScope(
  overrides: [
    appDatabaseProvider.overrideWithValue(testDb),
    pluginRegistryProvider.overrideWithValue(PluginRegistry.withPlugins([...])),
  ],
  child: MaterialApp(...),
);
```

参考 `test/widget_test.dart` 中的完整示例。

## Mock 策略

**零 mockito**。所有 mock 通过以下方式实现：
- 手写 stub 插件实现 `UniHubPlugin` 接口
- 使用 `PluginRegistry.withPlugins([])` 构造测试专用 registry
- 数据库直接使用真实 Drift 查询（in-memory）

## 测试文件结构

测试目录镜像 `lib/src/` 结构：

```
test/
└── src/
    ├── core/
    │   ├── database/
    │   ├── plugin/
    │   └── search/
    └── plugins/
        └── thoughts/
            └── data/
```

## 当前覆盖情况（860 行，45 测试用例）

| 目录 | 覆盖 | 说明 |
|------|------|------|
| `core/database/` | 33% | (1/3 文件有测试) |
| `core/plugin/` | 50% | (1/2) |
| `core/search/` | 50% | (1/2) |
| `thoughts/data/` | 60% | (3/5) |
| `core/app/` | **0%** | **完全未覆盖** |
| `core/router/` | **0%** | **完全未覆盖** |
| `core/theme/` | **0%** | **完全未覆盖** |
| `thoughts/ui/` | **0%** | **完全未覆盖** |
| `shared/` | **0%** | **完全未覆盖** |

**新增功能时建议至少为对应目录添加基本覆盖。**

## 运行测试

```sh
# 所有测试
flutter test

# 单个文件
flutter test test/src/core/plugin/plugin_registry_test.dart
```
