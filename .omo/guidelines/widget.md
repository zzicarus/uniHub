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

**始终使用 Token，禁止硬编码值**。但不同类型用不同的 Token：

### 颜色 → 用 `colorScheme`
所有颜色必须在 Widget 中通过 `Theme.of(context).colorScheme` 获取，**不应使用 `AppColors`**（`AppColors.primary` 仅用于 `app_theme.dart` 的 `ColorScheme.fromSeed(seedColor: ...)`）。

```dart
// ✅ 正确
color: colorScheme.primary
color: colorScheme.onSurface
color: colorScheme.surfaceContainerLow

// ❌ 错误
color: AppColors.primary
color: Color(0xFF4F6BFF)
Colors.white
```

例外：`AppColors.*Soft` 装饰色（没有 M3 colorScheme 直接对应）可继续使用，但仅限装饰性场景。

### 间距/圆角/尺寸 → 用 `AppToken`
```dart
// ✅ 正确
const SizedBox(height: AppSpacing.md)
BorderRadius.circular(AppRadius.sm)

// ❌ 错误
const SizedBox(height: 16)
BorderRadius.circular(8)
```

### 所有 Token 对照表

Token 定义在 `lib/src/core/theme/app_tokens.dart`：

| Token 类 | 用途 | Widget 中使用 |
|-----------|------|-------------|
| `colorScheme.*` | 颜色（primary/surface/onSurface/outline 等） | **优先使用** |
| `AppColors.primary` | 仅 `ColorScheme.fromSeed(seedColor:)` 参数 | 主题初始化 |
| `AppColors.*Soft` | M3 无直接对应的装饰色 | 可继续用 |
| `AppSpacing` | 间距（xxs=4 → section=40） | ✅ 必须用 |
| `AppRadius` | 圆角（xs=6 → full=999） | ✅ 必须用 |
| `AppSizes` | 组件尺寸（buttonHeight、listItem 等） | ✅ 优先用 |
| `AppDesktopSizes` | 桌面端布局尺寸（sidebarWidth 等） | ✅ 必须用 |
| `AppMobileSizes` | 移动端布局尺寸 | ✅ 必须用 |
| `AppFonts` | 字体族 | ✅ 必须用 |
| `AppShadows` | 阴影常量 | ✅ 优先用 |

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
| `Colors.white` / `Colors.black54` 在 widget 文件中 | 暗色模式下不可读，破坏 M3 主题一致性 | 使用 `colorScheme.onPrimary`、`colorScheme.onSurfaceVariant` |
| `Container` 无意义使用 | 性能浪费 | 有明确需求时才用 Container（装饰、约束等） |
| 深层嵌套超过 4 层 | 可读性差 | 提取子 Widget |
| 禁用 `surfaceTintColor` | 关闭 M3 elevation 视觉反馈层 | 移除覆盖，让 M3 默认处理 |

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

---

## M3 ColorScheme 使用模式

Widget 层必须使用 `Theme.of(context).colorScheme` 获取颜色，而非硬编码 `AppColors.*`，以支持暗色模式和动态颜色。

### 标准映射

| AppColors（旧） | ColorScheme（推荐） | 适用 |
|---|---|---|
| `primary` | `colorScheme.primary` | 主色按钮、强调元素 |
| `background` | `colorScheme.surface` | 页面背景 |
| `surface` | `colorScheme.surface` | 卡片背景 |
| `surfaceMuted` | `colorScheme.surfaceContainerHigh` | 次级表面 |
| `textPrimary` | `colorScheme.onSurface` | 主要文字 |
| `textSecondary` | `colorScheme.onSurfaceVariant` | 次要文字 |
| `textTertiary` | `colorScheme.outline` | 占位符、提示 |
| `border` / `borderSoft` | `colorScheme.outline` / `outlineVariant` | 边框 |
| `error` | `colorScheme.error` | 错误状态 |
| `*Soft` 装饰色 | 保留 `AppColors.*Soft` | 无 M3 直接对应，仅用于装饰 |

### 白色/黑色硬编码替换

```dart
// ✅ 正确
color: colorScheme.onPrimary,        // 替代 Colors.white（在 primary 背景上）
color: colorScheme.onSurface,        // 替代 Colors.black87（主文字）
color: colorScheme.onSurfaceVariant.withValues(alpha: 0.54),  // 替代 Colors.black54
color: Colors.transparent,            // 保持透明（用于 InkWell 背景切换等）

// ❌ 错误
color: Colors.white,                  // 暗色模式下不可读
color: Colors.black54,               // 暗色模式下不可读
```

### Widget 中使用模式

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  final colorScheme = Theme.of(context).colorScheme;

  return Container(
    color: colorScheme.surfaceContainerLow,
    child: Text(
      'Hello',
      style: TextStyle(color: colorScheme.onSurface),
    ),
  );
}
```

### 动态色板与颜色选择器

当 UI 需要一组强调色（例如卡片 fallback 色板、颜色选择器、统计卡图标色）时，不要在 Widget 文件中维护 `AppColors.primary / success / warning / purple` 数组。改为从当前 `ColorScheme` 派生，并把 `ColorScheme` 显式传入 helper。

```dart
// ✅ 正确：色板跟随当前亮色/暗色主题
List<Color> availableColors(ColorScheme colorScheme) => [
  colorScheme.primary,
  colorScheme.secondary,
  colorScheme.tertiary,
  colorScheme.error,
  colorScheme.primaryContainer,
  colorScheme.secondaryContainer,
  colorScheme.tertiaryContainer,
];

Color cardAccent(int index, ColorScheme colorScheme) {
  final accents = [
    colorScheme.tertiary,
    colorScheme.secondary,
    colorScheme.primary,
    colorScheme.error,
  ];
  return accents[index % accents.length];
}

// ❌ 错误：Widget 层固定旧 palette，暗色模式和动态主题无法跟随
const accents = [
  AppColors.warning,
  AppColors.success,
  AppColors.primary,
  AppColors.purple,
];
```

### 暗色主题实现模式

```dart
// ✅ 正确：使用 fromSeed + Brightness.dark 自动生成
static ThemeData get dark {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    ).surface,
  );
}

// MaterialApp 中启用
MaterialApp.router(
  theme: AppTheme.light,
  darkTheme: AppTheme.dark,
  themeMode: ThemeMode.system,
);
```

### Elevation Surface Tint

不要禁用 `surfaceTintColor`（`Colors.transparent`），M3 的 surface tint 层为 AppBar、Card、NavigationBar 等带 elevation 的组件提供了微妙的色调叠加，是 M3 视觉语言的重要组成。

---

## ColorScheme vs AppTokens 决策树

```
我要设置一个颜色值
│
├─ 是 Widget 中的颜色吗？
│   ├─ ✅ → 用 colorScheme.*
│   │   ├─ 卡片背景 → colorScheme.surface
│   │   ├─ 页面背景 → colorScheme.surface
│   │   ├─ 主按钮 → colorScheme.primary
│   │   ├─ 文字 → colorScheme.onSurface / onSurfaceVariant
│   │   ├─ 边框 → colorScheme.outline / outlineVariant
│   │   ├─ 次级表面 → colorScheme.surfaceContainerLow/High
│   │   ├─ 错误 → colorScheme.error
│   │   └─ 装饰色且 M3 无对应 → AppColors.*Soft（例外）
│   │
│   └─ ❌ 是 Theme 初始化？
│       └─ ✅ → AppColors.primary（seedColor）
│
├─ 我要设置间距
│   └─ ✅ → AppSpacing.xxs/xs/sm/md/lg/xl/xxl/section
│
├─ 我要设置圆角
│   └─ ✅ → AppRadius.xs/sm/md/lg/xl/full
│
├─ 我要设置尺寸
│   └─ ✅ → AppSizes / AppDesktopSizes / AppMobileSizes
│
└─ 我要设置字体
    └─ ✅ → AppFonts.decorative + fallback 或默认 textTheme
```
