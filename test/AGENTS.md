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

## 当前覆盖情况（约 41 测试用例，6 个测试文件）

> 最后核对日期：2026-05-21

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

# 单个测试用例（按名称过滤）
flutter test --name "test case name"
```

## 完整验证顺序

提交前按以下顺序验证（参考 `.omo/guidelines/workflow.md`）：

```sh
# Step 1: 静态分析
flutter analyze

# Step 2: 自动修复 lint
dart fix --dry-run   # 预览
dart fix --apply     # 应用

# Step 3: 运行测试
flutter test

# Step 4: 确认工作区干净
git status
```

### 验证失败处理
| 失败类型 | 处理方式 |
|----------|----------|
| analyze warning | `dart fix --apply` 自动修复 |
| analyze error | 按错误信息修改代码 |
| 测试失败 | 确认是代码问题还是测试问题 |
| 3 次连续失败 | 停止 → 咨询 Oracle |

---

## 近期变更

> 本 section 由 sync-knowledge 自动管理，按时间倒序追加。

### 2026-05-22: 增加数据库测试覆盖
- `database_test.dart` 新增 3 个测试用例（schemaVersion 计算、跨插件取最大值、缺失表断言）
- 更新 5 个已有测试文件适配 `AppDatabase` 构造函数签名变更
