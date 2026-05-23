# Quality Guidelines

> UniHub 前端代码质量标准（Flutter + Riverpod）

---

## Overview

所有代码必须通过 `flutter analyze`（0 error 0 warning）。`analysis_options.yaml` 基于 `package:flutter_lints/flutter.yaml`。此外强调：

- **禁止类型抑制**：不写 `as dynamic`、空 catch 块、行级 ignore 不加原因注释
- **禁止硬编码值**：颜色用 `colorScheme.*`，间距圆角用 `AppSpacing`/`AppRadius`
- **依赖方向不可逆**：`plugins/` ↛ `shared/` ↛ `core/`
- **跨层引用用 package 路径**：`package:uni_hub/src/...`，禁止 `../../../`

---

## Forbidden Patterns

| 模式 | 原因 | 替代 |
|------|------|------|
| 硬编码颜色 `Color(0xFF...)` | 无法适配暗色模式、主题切换 | `Theme.of(context).colorScheme.*` |
| 硬编码间距 `SizedBox(height: 8)` | 不一致的间距体系 | `AppSpacing.sm` / `AppSpacing.xs` |
| 硬编码圆角 `BorderRadius.circular(12)` | 不一致的圆角体系 | `AppRadius.md` / `AppRadius.lg` |
| `setState()` 管理全局状态 | 组件耦合、无法测试 | Riverpod Provider |
| `// ignore: ...` 无原因 | 隐藏真正的问题 | 明确注释原因或修复代码 |
| 空 `catch (e) {}` | 静默吞掉错误 | 至少 `debugPrint` 或记录日志 |
| `Navigator.push` 直接调用 | 绕过 GoRouter 路由体系 | `context.goNamed(routeNames.xxx)` |
| 三目运算符嵌套 3+ 层 | 不可读 | 提取变量或使用 switch 表达式 |

---

## Required Patterns

| 模式 | 要求 |
|------|------|
| `const` 构造器 | 所有 Widget 必须用 `const` 构造器 + `super.key` |
| `WidgetRef` | UI 中使用 `ref.watch` 监听、`ref.read` 执行一次性操作 |
| `.future` / `.value` | AsyncValue 使用 `.when(data:, error:, loading:)` 三态模式 |
| `ConsumerWidget`/`ConsumerStatefulWidget` | 需要访问 Provider 时用 Consumer 系列 Widget |
| `package:` 导入 | 所有跨文件引用必须用 package 路径 |
| 文件夹组织 | `data/` `providers/` `ui/pages/` `ui/widgets/` 分层 |
| 测试覆盖 | 数据层 → 单元测试；UI → widget 测试 |

---

## Testing Requirements

| 层级 | 测试类型 | 覆盖要求 |
|------|---------|---------|
| DAO/Repository | 单元测试（`NativeDatabase.memory()`） | 核心查询方法 100% |
| Provider | 单元测试（ProviderScope + overrides） | 主要 Provider |
| Widget | Widget 测试（`tester.pumpWidget`） | 关键页面组件 |
| 集成 | Flutter Driver 测试 | 主要用户流 |

### 测试隔离模式

```dart
// Database 测试：使用内存数据库，setUp/tearDown 生命周期
setUp(() async {
  db = NativeDatabase.memory();
  dao = ThoughtsDao(db);
});
tearDown(() async {
  await db.close();
});

// Provider 测试：使用 ProviderScope override
ProviderScope(
  overrides: [
    databaseProvider.overrideWithValue(db),
    thoughtDaoProvider.overrideWithValue(dao),
  ],
  child: MaterialApp(...),
);
```

**零 mockito**：手写 stub 或使用 override 替代 mock 框架。

---

## Code Review Checklist

- [ ] `flutter analyze` 通过（0 error 0 warning）
- [ ] 新增 Widget 有 `const` 构造器 + `super.key`
- [ ] 所有颜色来自 `colorScheme.*`，无硬编码
- [ ] 所有间距/圆角来自 `AppSpacing`/`AppRadius`
- [ ] 跨层引用使用 `package:` 路径
- [ ] 无 `// ignore` 不加原因
- [ ] 测试覆盖新增的关键路径
- [ ] 响应式布局测试通过（桌面端 720px+ 正常）
- [ ] 暗色模式无颜色冲突
