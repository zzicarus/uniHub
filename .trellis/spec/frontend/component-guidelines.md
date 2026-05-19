# Widget 规范

> UniHub Flutter Widget 编写约定。

---

## Widget 类型选择

| 场景 | 使用 | 原因 |
|------|------|------|
| 需要读取 Riverpod Provider | `ConsumerWidget` / `ConsumerStatefulWidget` | 直接访问 `WidgetRef ref` |
| 纯 UI，不需要状态 | `StatelessWidget` | 最小化依赖 |
| 需要局部 UI 状态 | `ConsumerStatefulWidget` | 如果需要 Riverpod + 局部状态 |
| 不需要 Riverpod 但有局部状态 | `StatefulWidget` | 标准 Flutter |

**当前代码中全部使用 `ConsumerWidget`**（参考 `HomePage`、`Sidebar`、`AppLayout` 等），即使在不需要读取 Provider 的场景也使用它——这保持了一致性，但以后可以灵活选择。

---

## Widget 结构

### 页面 Widget

```dart
// lib/src/plugins/thoughts/ui/thoughts_list_page.dart
class ThoughtsListPage extends ConsumerWidget {
  const ThoughtsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // 从 Provider 读取状态
    // final thoughtsAsync = ref.watch(thoughtsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Thoughts')),
      body: /* 内容 */,
    );
  }
}
```

### 可复用组件

```dart
// lib/src/plugins/thoughts/ui/widgets/thought_card.dart
class ThoughtCard extends ConsumerWidget {
  final Thought thought;
  final VoidCallback onTap;

  const ThoughtCard({
    required this.thought,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ...
  }
}
```

**约定**：
- 全部使用 `const` 构造器（`super.key`）
- 回调使用 `VoidCallback` / `ValueChanged<T>` 类型
- 数据对象通过构造器传入（不在 Widget 中查询数据库）

---

## Props 约定

Flutter 中没有 "props" 概念——构造器参数即 Props：

| 规则 | 示例 |
|------|------|
| 必传数据用 `required` | `required this.thought` |
| 可选数据用默认值 | `this.color = AppColors.primary` |
| 回调用命名参数 | `this.onTap`、`this.onDelete` |
| key 始终使用 `super.key` | `const ThoughtCard({super.key})` |

---

## 设计 Token

**始终使用 Token，禁止硬编码值**：

```dart
// ✅ 正确
const SizedBox(height: AppSpacing.md)
color: AppColors.primary
BorderRadius.circular(AppRadius.sm)

// ❌ 错误
const SizedBox(height: 16)
color: Color(0xFF2563EB)
BorderRadius.circular(8)
```

Token 定义在 `lib/src/core/theme/app_tokens.dart`：

| Token 类 | 内容 |
|-----------|------|
| `AppColors` | 颜色（primary、text、background、border 等） |
| `AppSpacing` | 间距（xxs=4 → section=40） |
| `AppRadius` | 圆角（xs=6 → full=999） |
| `AppSizes` | 尺寸（buttonHeight、inputHeight、listItem 等） |
| `AppDesktopSizes` | 桌面端尺寸（sidebarWidth=240 等） |
| `AppFonts` | 字体族（decorative、fallback 列表） |

---

## 响应式布局

```dart
// 参考 lib/src/shared/layouts/app_layout.dart
final isDesktop = MediaQuery.of(context).size.width >= 720;

if (isDesktop) {
  // 侧栏布局（Windows）
} else {
  // 底部导航布局（Android / 移动端）
}
```

**约定**：
- 桌面端断点：`>= 720px`
- 桌面端：侧栏（`Sidebar`）始终可见
- 移动端：主导航使用底部 `NavigationBar`，常用入口保持在底部；暂未实现的功能可先通过 Core 占位页保留入口
- 不硬编码平台判断（`Platform.isWindows`），使用宽度判断
- 桌面 Shell 必须提供外层 `Scaffold` 或 `ColoredBox` 背景，不能只返回裸 `Row`；否则 Home 这类非 `Scaffold` 子页面在 Windows 上可能露出黑色默认窗口背景

```dart
// ✅ 正确：Shell 自身负责铺底色，子页面是否 Scaffold 都不会黑底
return Scaffold(
  backgroundColor: AppColors.background,
  body: Row(
    children: [
      const Sidebar(),
      Expanded(
        child: ColoredBox(
          color: AppColors.background,
          child: child,
        ),
      ),
    ],
  ),
);

// ❌ 错误：非 Scaffold 子页面可能露出平台默认黑底
return Row(
  children: [
    const Sidebar(),
    Expanded(child: child),
  ],
);
```

---

## 避免模式

| 禁止 | 原因 | 正确做法 |
|------|------|----------|
| 在 `build` 中执行异步操作 | build 应该是纯函数 | 使用 Riverpod Provider 提前加载数据 |
| `MediaQuery.of(context)` 在深层 Widget 中 | 可能导致不必要的 rebuild | 在布局层判断，通过参数向下传递 |
| 硬编码颜色/间距/字号 | Token 变更时遗漏 | 始终使用 `AppColors`、`AppSpacing` 等 |
| `Container` 无意义使用 | 性能浪费 | 有明确需求时才用 Container（装饰、约束等） |
| 深层嵌套超过 4 层 | 可读性差 | 提取子 Widget |

---

## 实际代码参考

- `lib/src/core/app/home_page.dart` — 简单页面示例
- `lib/src/shared/widgets/sidebar.dart` — 复杂组件示例（包含私有 `_NavItem` 组件）
- `lib/src/shared/layouts/app_layout.dart` — 响应式布局示例
- `lib/src/plugins/thoughts/thoughts_placeholder_page.dart` — 插件页面示例


---

## UI Pattern: Material 3 Tonal Cards (Google Style)

**What**: When implementing Material 3 style cards using tonal background colors (e.g. \AppColors.surfaceSubtle\), avoid using \Container(color: ...)\ inside an \InkWell\ if the background is opaque. Instead, wrap the \InkWell\ inside a \Material(color: ...)\ widget.

**Why**: Using an opaque \Container\ inside an \InkWell\ will block the native Material 3 interaction feedback (hover darkening and ripple/splash effects). Applying the color to the ancestor \Material\ widget ensures proper flat visual feedback via color-darkening without any shadows or scaling.

**Example**:
\\dart
// ✅ 正确: 颜色应用在 Material 上，交互反馈正常
Material(
  color: AppColors.surfaceSubtle,
  borderRadius: BorderRadius.circular(AppRadius.lg),
  child: InkWell(
    onTap: () {},
    borderRadius: BorderRadius.circular(AppRadius.lg),
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: child,
    ),
  ),
);

// ❌ 错误: 内部 Container 的颜色遮挡了 InkWell 的涟漪和悬停效果
Material(
  borderRadius: BorderRadius.circular(AppRadius.lg),
  child: InkWell(
    onTap: () {},
    child: Container(
      color: AppColors.surfaceSubtle,
      child: child,
    ),
  ),
);
\