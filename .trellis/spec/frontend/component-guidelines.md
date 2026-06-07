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

### ConsumerStatefulWidget 的 State 复用陷阱

`ConsumerStatefulWidget`（和 `StatefulWidget`）的 State 对象在父级重建传入
不同 widget 配置时**会被复用**（Flutter 按 `Widget.key` + `Widget.runtimeType` 匹配
已有 State）。这意味着：

```dart
// ❌ 危险：State 挂载时初始化一次，widget.entry 变化后永远不会更新
class _DetailPanelState extends ConsumerState<DetailPanel> {
  late final SavedItemsTableData item = widget.entry.item;
  late final List<CollectionBoxesTableData> boxes = widget.entry.boxes;
}

// ✅ 正确：每次 build 都读取最新的 widget 数据
class _DetailPanelState extends ConsumerState<DetailPanel> {
  SavedItemsTableData get item => widget.entry.item;
  List<CollectionBoxesTableData> get boxes => widget.entry.boxes;
}
```

**规则**：`ConsumerState` 中如果字段派生自 `widget.*`，必须使用 getter
（或通过 `didUpdateWidget` 更新），绝不能用 `late final` 一次初始化。

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

### AppToast 全局提示

全局浮动 Toast 组件，统一项目中所有临时消息提示。

**文件**：`lib/src/shared/widgets/app_toast.dart`

**用法**：

```dart
// 普通提示
AppToast.show(context, message: '已收藏');

// 成功
AppToast.show(context, message: '链接已复制', type: AppToastType.success);

// 错误
AppToast.show(context, message: '收藏失败', type: AppToastType.error);

// 带有撤销操作的删除提示
AppToast.undo(context, message: '已删除「文档」', onUndo: () async {
  await deleteResult.undo!.execute();
});
```

**类型枚举**：`AppToastType.info`（默认）、`success`、`warning`、`error`、`destructive`

**布局**：桌面端（≥600px）右对齐固定在右下角，宽度 420px；移动端底部居中全宽。

**约束**：
- 全仓库禁止业务代码直接 `new SnackBar(content: Text(...))`
- 所有临时提示必须通过 `AppToast.show` / `AppToast.undo`
- 删除/移除等可撤销操作使用 `AppToast.undo`（type 自动设为 `destructive`）
- 默认持续 5 秒

---

## Props 约定

Flutter 中没有 "props" 概念——构造器参数即 Props：

| 规则 | 示例 |
|------|------|
| 必传数据用 `required` | `required this.thought` |
| 可选数据用默认值 | `this.color` 可为 nullable，在 `build` 中 fallback 到 `colorScheme.primary` |
| 回调用命名参数 | `this.onTap`、`this.onDelete` |
| key 始终使用 `super.key` | `const ThoughtCard({super.key})` |

---

## 设计 Token

**始终使用 Token，禁止硬编码值**。但不同类型的值用不同的 Token：

### 颜色 → Widget 层优先用 `colorScheme`
Widget 层颜色必须优先通过 `Theme.of(context).colorScheme` 获取，**不应直接使用 `AppColors`**。`AppColors.primary` 仅用于 `app_theme.dart` 的 `ColorScheme.fromSeed(seedColor: ...)`；`AppColors.*Soft` 等无 M3 直接对应的颜色仅可用于非关键装饰。

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
| `AppColors.*Soft` | M3 无直接对应的装饰色 | 仅非关键装饰可用 |
| `AppSpacing` | 间距（xxs=4 → section=40） | ✅ 必须用 |
| `AppRadius` | 圆角（xs=6 → full=999） | ✅ 必须用 |
| `AppSizes` | 组件尺寸（buttonHeight、listItem 等） | ✅ 优先用 |
| `AppDesktopSizes` | 桌面端布局尺寸（sidebarWidth 等） | ✅ 必须用 |
| `AppMobileSizes` | 移动端布局尺寸 | ✅ 必须用 |
| `AppFonts` | 字体族（Inter + Noto Sans CJK） | ✅ 必须用 |
| `AppFontTokens` | 字号/行高/字重语义常量（display=28 → mini=10） | ✅ 必须用 |
| `AppShadows` | 阴影常量 | ✅ 优先用 |
| `AppBreakpoints` | 响应式断点（WindowSize.compact/medium/expanded） | 在 Shell 层使用 |

---

## 响应式布局

使用 `AppBreakpoints`（`lib/src/core/theme/app_breakpoints.dart`）作为统一断点来源。不硬编码 `MediaQuery` 或 `Platform` 判断。

### 三档断点系统

| 档位 | `WindowSize` | 宽度 | 布局策略 |
|------|-------------|------|----------|
| 紧凑 | `compact` | `< 900px` | 底部导航 + 全屏页面 |
| 中等 | `medium` | `900 - 1279px` | 两列布局（侧栏 + 内容） |
| 扩展 | `expanded` | `>= 1280px` | 三列布局（侧栏 + 内容 + 右栏） |

```dart
// 参考 lib/src/core/theme/app_breakpoints.dart
final size = AppBreakpoints.of(context);
// → WindowSize.compact / medium / expanded

// 或使用便捷方法
final isCompact = AppBreakpoints.isCompact(context);
```

```dart
// 参考 lib/src/shared/widgets/adaptive_layout.dart
// 自动切换 mobile/desktop builder
AdaptiveLayout(
  mobile: (context) => MobileHome(),
  desktop: (context) => DesktopHome(),
)
```

**约定**：
- 断点定义：`mobileMax = 899`、`tabletMin = 900`、`wideMin = 1280`
- 桌面端（≥900px）：侧栏（`Sidebar`）始终可见
- 移动端（<900px）：主导航使用底部 `NavigationBar`，常用入口保持在底部；暂未实现的功能可先通过 Core 占位页保留入口
- 不硬编码平台判断（`Platform.isWindows`），使用宽度判断
- 桌面 Shell 必须提供外层 `Scaffold` 或 `ColoredBox` 背景，不能只返回裸 `Row`；否则 Home 这类非 `Scaffold` 子页面在 Windows 上可能露出黑色默认窗口背景

```dart
// ✅ 正确：Shell 自身负责铺底色，子页面是否 Scaffold 都不会黑底
final colorScheme = Theme.of(context).colorScheme;

return Scaffold(
  backgroundColor: colorScheme.surface,
  body: Row(
    children: [
      const Sidebar(),
      Expanded(
        child: ColoredBox(
          color: colorScheme.surface,
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

### 字体排版系统：AppFontTokens

> 实现在 `lib/src/core/theme/app_tokens.dart` — `AppFontTokens` 抽象类。

统一字体尺寸、行高、字重的语义化常量，替代所有硬编码 `fontSize:`、`height:`、`FontWeight.wXXX`。

#### 字母表

| 类别 | 常量 | 值 | 对应 TextTheme | 使用场景 |
|------|------|-----|---------------|----------|
| 特大 | `display` | 28 | `headlineMedium` | 大型展示文字 |
| 标题 | `headline` | 22 | `titleLarge` | 模块标题 |
| 大标题 | `titleLg` | 16 | `titleMedium` | 列表主标题 |
| 中标题 | `titleMd` | 14 | `titleSmall` / `labelLarge` | 副标题、标签文字 |
| 大正文 | `bodyLg` | 16 | `bodyLarge` | 正文大 |
| 中正文 | `bodyMd` | 14 | `bodyMedium` | 正文中 |
| 小正文 | `bodySm` | 12 | `bodySmall` / `labelMedium` | 正文小 |
| 大标签 | `labelLg` | 14 | `labelLarge` | 大标签 |
| 小标签 | `labelMd` | 12 | `labelMedium` | 小标签 |
| 巨幅 | `hero` | 34 | — | 移动端欢迎语 |
| 品牌 | `brand` | 24 | — | Logo / 品牌标识 |
| 次标 | `subtitle` | 15 | — | 编辑器正文、导航项文字 |
| 说明 | `caption` | 11 | — | 状态徽章、时间戳 |
| 极小 | `mini` | 10 | — | 紧凑标签、数量角标 |

#### 行高

每个字号有配套的行高常量（`*Height`）：

```dart
AppFontTokens.bodyLgHeight  // 1.5（bodyLarge）
AppFontTokens.bodyMdHeight  // 1.57（bodyMedium）
AppFontTokens.titleMdHeight // 1.43（titleSmall）
```

#### 字重语义常量

```dart
AppFontTokens.bold       // FontWeight.w700
AppFontTokens.semiBold   // FontWeight.w600
AppFontTokens.medium     // FontWeight.w500
AppFontTokens.normal     // FontWeight.w400
```

#### 使用方式

```dart
// ✅ 正确：基于 theme.textTheme.*.copyWith
Text(
  title,
  style: theme.textTheme.titleMedium?.copyWith(
    fontWeight: AppFontTokens.bold,
  ),
)
Text(
  subtitle,
  style: theme.textTheme.bodySmall?.copyWith(
    color: colorScheme.onSurfaceVariant,
  ),
)

// ❌ 错误：bare TextStyle（不应出现）
// TextStyle(
//   fontSize: AppFontTokens.caption,
//   height: AppFontTokens.bodySmHeight,
// )

// ❌ 错误：硬编码
// fontSize: 14
// height: 1.4
// FontWeight.w700
```

### 字体族

| 常量 | 字体 | 用途 |
|------|------|------|
| `AppFonts.ui` | Noto Sans SC | 全局 UI 主字体，本地打包 |
| `AppFonts.latin` | Inter | 英文品牌、英文标题 |
| `AppFonts.mono` | JetBrains Mono | 代码/路径等宽字体 |

**约定**：全局默认字体通过 `ThemeData.fontFamily: AppFonts.ui` 设定，Widget 层不应直接指定 `fontFamily`。
中文 UI 由 Noto Sans SC 主导，Inter 作为英文品牌备选，不依赖系统 fallback。
字体文件通过 `pubspec.yaml > flutter.fonts` 本地打包，不运行时远程加载。

### 主题预设系统

> 实现在 `lib/src/core/theme/`：`app_theme_preset.dart`、`app_theme_registry.dart`、`app_theme.dart`。

UniHub 由单一种子色模式演变为多预设系统，每套预设包含 6 个颜色/主题变体。

#### 架构

```
AppThemePreset（枚举）—— 6 个预设
  └─ AppThemeRegistry.colorsOf(preset, brightness)
       └─  UniHubThemeColors → ThemeData.extensions 注册
            └─ context.appColors（快捷访问）

AppTheme.build(preset:, brightness:) → ThemeData
  └─ 内部调用 ColorScheme.fromSeed(seedColor: colors.primary)
       + .copyWith() 个性化
```

#### 预设枚举

| 预设 | label | 种子色 | 风格 |
|------|-------|--------|------|
| `uniBlue` ✅ 默认 | Uni Blue | `#3F6DF6` | 清爽蓝色 |
| `paper` | Paper | `#4B6382` | 柔和纸感 |
| `forest` | Forest | `#2F855A` | 绿色低刺激 |
| `sakura` | Sakura | `#D9468A` | 粉紫柔和 |
| `amber` | Amber | `#D97706` | 暖色琥珀 |
| `graphite` | Graphite | `#475569` | 克制灰蓝 |

每套预设同时定义浅色（Light）和深色（Dark）两组颜色。

#### UniHubThemeColors（ThemeExtension）

21 个产品级颜色，通过 `ThemeData.extensions` 注入，使用 `context.appColors` 便捷访问：

```dart
final colors = context.appColors;
colors.sidebarBackground  // 侧栏背景
colors.navSelectedBackground  // 导航选中态
colors.panelBackground        // 面板背景
```

**约定**：
- Widget 层颜色**优先使用** `colorScheme.*`（M3 语义色）
- 产品特有颜色（侧栏背景、导航选中态、面板背景）使用 `context.appColors.*`
- `AppTokens.*` 仅用于主题初始化和装饰例外
- 不得在 Widget 中直接引用 `UniHubThemeColors` 的构造器——始终通过 `context.appColors` 或 `Theme.of(context).extension<UniHubThemeColors>()`

#### 创建 ThemeData

```dart
// 统一入口
final theme = AppTheme.build(
  preset: AppThemePreset.uniBlue,
  brightness: Brightness.light,
);

// 兼容简化入口（Uni Blue 预设）
final light = AppTheme.light;
final dark = AppTheme.dark;

// MaterialApp 中使用
MaterialApp.router(
  theme: currentTheme,
  darkTheme: darkTheme,
  themeMode: ThemeMode.system,
);
```

#### Theme 子组件主题

`AppTheme.build()` 统一配置以下子主题，组件层不应覆盖：

| 子主题 | 配置内容 |
|--------|----------|
| `cardTheme` | `surfaceContainerLow` 背景、`AppRadius.xl` 圆角、`outlineVariant(0.25)` 边框或无边框（暗色模式）|
| `filledButtonTheme` | `AppSizes.buttonHeight`、primary 色、`AppRadius.sm` 圆角 |
| `outlinedButtonTheme` | `AppSizes.buttonHeight`、`AppRadius.sm` 圆角 |
| `inputDecorationTheme` | filled 输入框、`AppRadius.md` 圆角、border 配色 |
| `listTileTheme` | `AppSizes.listItem` 高度、`AppFontTokens` 字号 |
| `chipTheme` | `AppRadius.full` 圆角、`outlineVariant` 边框 |
| `appBarTheme` | 无 elevation、surface 背景 |
| `dividerTheme` | `AppColors.border` 色 |

**禁止**：不要在 Widget 层用 `Card(...)` 的 `shape`、`elevation` 或 `color` 参数覆盖默认主题——修改应通过修改 `AppTheme.build()` 中的主题配置集中生效。

---

## 占位页面规范

对于路由中存在但功能尚未实现的占位页面，遵循以下原则：

| 规则 | 说明 | 示例 |
|------|------|------|
| 保持极简 | 只显示图标 + 标题 + 说明文字，不含任何 mock 数据 | `Icon` + `Text('即将推出')` |
| 保留路由结构 | 注册必要的路由路径，避免路由缺失导致导航断裂 | 5 个占位页面约 120 行 |
| 禁止硬编码 mock 内容 | 不写入假列表、假统计、假图表 | 1500 行 mock 数据 ❌ |
| 占位数据放在独立文件 | 如果确实需要展示 mock 预览，放在单独的数据文件 | 不与路由/页面定义混合 |

```dart
// ✅ 正确：极简占位页面
class ComingSoonPage extends StatelessWidget {
  final IconData icon;
  final String title;

  const ComingSoonPage({required this.icon, required this.title, super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: colorScheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('即将推出，敬请期待',
              style: TextStyle(color: colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
```

---

## 避免模式

| 禁止 | 原因 | 正确做法 |
|------|------|----------|
| 在 `build` 中执行异步操作 | build 应该是纯函数 | 使用 Riverpod Provider 提前加载数据 |
| `MediaQuery.of(context)` 在深层 Widget 中 | 可能导致不必要的 rebuild | 在布局层判断，通过参数向下传递 |
| 硬编码颜色/间距/字号 | Token 变更时遗漏 | 颜色用 `colorScheme`，间距/圆角/尺寸用 `AppSpacing`、`AppRadius`、`AppSizes` 等 |
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

**What**: When implementing Material 3 style cards using tonal background colors (e.g. `colorScheme.surfaceContainerLow`), avoid using `Container(color: ...)` inside an `InkWell` if the background is opaque. Instead, wrap the `InkWell` inside a `Material(color: ...)` widget.

**Why**: Using an opaque \Container\ inside an \InkWell\ will block the native Material 3 interaction feedback (hover darkening and ripple/splash effects). Applying the color to the ancestor \Material\ widget ensures proper flat visual feedback via color-darkening without any shadows or scaling.

**Example**:
\\dart
// ✅ 正确: 颜色应用在 Material 上，交互反馈正常
Material(
  color: colorScheme.surfaceContainerLow,
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
      color: colorScheme.surfaceContainerLow,
      child: child,
    ),
  ),
);
\

---

## UI Pattern: InkWell 在动画布局中的安全使用

**What**: 在包含 `AnimatedCrossFade`、`AnimatedSize`、`AnimatedContainer` 等动画 widget 的布局中，避免使用 `Material` + `InkWell` 组合。InkWell 的涟漪绘制在渲染管线中需要子组件的布局已就绪（`NEEDS-LAYOUT` 状态未完成时会触发断言失败）。

**Why**: Material + InkWell 将涟漪的绘制区域绑定到 Material 的子节点。当动画正在改变布局时（如 `AnimatedCrossFade` 切换展开/折叠），子组件可能处于未完成布局的状态。InkWell 尝试创建涟漪效果时 → `RenderBox was not laid out` 断言失败。

**规则**：

| 场景 | 推荐模式 | 原因 |
|------|----------|------|
| 动画布局中的导航/选择按钮 | `GestureDetector` + 自定义 `Container` 装饰 | 不需要 Material 涟漪，使用自定义颜色表示选中态 |
| 动画布局中的卡片，需要涟漪 | 本地 `Material` + `Ink` + `InkWell` | `Ink` 会注册到最近的 `Material`；必须由组件自己提供本地宿主，不能依赖 Scaffold |
| 静态布局中的卡片 | `Material` + `InkWell`（标准模式） | 子组件布局稳定，无竞争条件 |

```dart
// ✅ 正确（动画布局）：GestureDetector
GestureDetector(
  onTap: onTap,
  child: Container(
    decoration: BoxDecoration(
      color: isSelected ? colorScheme.primaryContainer : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.md),
    ),
    child: /* 内容 */,
  ),
);

// ✅ 正确（动画布局，需要涟漪）：本地 Material + Ink + InkWell
final borderRadius = BorderRadius.circular(AppRadius.lg);

Material(
  type: MaterialType.transparency,
  shape: RoundedRectangleBorder(borderRadius: borderRadius),
  clipBehavior: Clip.antiAlias,
  child: Ink(
    decoration: BoxDecoration(
      borderRadius: borderRadius,
      color: selected
          ? colorScheme.primaryContainer.withValues(alpha: 0.1)
          : Colors.transparent,
      border: Border.all(color: colorScheme.outlineVariant),
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: borderRadius,
      child: /* 内容 */,
    ),
  ),
);

// ❌ 在动画布局中禁止：Material + InkWell
Material(
  // color: ...,
  child: InkWell(
    onTap: onTap,
    child: /* 内容 */,
  ),
);
```

**例外**：纯静态布局（整个 widget 树不包含任何动画改变布局的组件）中，`Material` + `InkWell` 标准模式安全可用。但注意 `Ink` 不是本地 ink 宿主：Flutter 源码中 `Ink` 会通过 `Material.of(context)` 把 `InkDecoration` 注册到最近的 `Material`。如果组件自己没有提供本地 `Material`，`InkDecoration` 仍可能挂到 `Scaffold` 的 `_RenderInkFeatures` 上；当该 Scaffold 同时包含动画布局时，仍有触发断言的风险。

**安全模式**：项目中所有可点击的共享 Widget 优先使用“本地 `Material` 宿主 + `Ink`/`InkWell`”模式：

```dart
// ✅ 推荐：本地 Material + Ink + InkWell
Material(
  type: MaterialType.transparency,
  child: Ink(
    child: InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: onTap,
      child: /* 内容 */,
    ),
  ),
);

// ❌ 避免：只有 Ink + InkWell（InkDecoration 仍注册到祖先 Material）
Ink(
  child: InkWell(
    onTap: onTap,
    child: /* 内容 */,
  ),
);

// ❌ 避免：裸 InkWell（无本地 Material 宿主）
InkWell(
  onTap: onTap,
  child: /* 内容 */,
);
```

**测试要求**：修复或新增共享可点击 Widget 时，widget test 应覆盖目标 `Ink`/`InkWell` 在组件根节点以内存在 `Material` 祖先，避免只依赖 `Scaffold` 或页面级 `Material`。

### 测试模式：hasLocalMaterialAncestor 辅助函数

使用以下可复用 helper 进行断言。测试应在 `Scaffold`（或其他外层 `Material`）中包裹被测组件，然后从被测组件内部找 `Ink`/`InkWell` 的祖先中是否包含 `Material`。

```dart
/// 检测 target widget 组件树内是否存在 Material 祖先（且不在 component 之上）
bool hasLocalMaterialAncestor({
  required WidgetTester tester,
  required Finder component,
  required Finder target,
}) {
  final componentElement = tester.element(component);
  final targetElement = tester.element(target);
  var found = false;

  targetElement.visitAncestorElements((ancestor) {
    if (ancestor == componentElement) return false;
    if (ancestor.widget is Material) {
      found = true;
      return false;
    }
    return true;
  });

  return found;
}
```

### 使用方式

```dart
await tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: Center(
        child: MyComponent(onTap: () {}),
      ),
    ),
  ),
);

// 断言：MyComponent 内部的 Ink 有本地 Material 宿主
expect(
  hasLocalMaterialAncestor(
    tester: tester,
    component: find.byType(MyComponent),
    target: find.descendant(
      of: find.byType(MyComponent),
      matching: find.byType(Ink),
    ),
  ),
  isTrue,
);

// 断言：点击回调仍正常工作
await tester.tap(find.text('...'));
await tester.pump();
expect(tapped, isTrue);
```

**注意**：
- `hasLocalMaterialAncestor` 中 `visitAncestorElements` 在找到 `componentElement` 时返回 `false` 停止遍历，防止越过组件边界找到 `Scaffold` 的 `Material`。
- 如果组件内没有 `Ink`（例如仅用 `Material` + `InkWell`），可将 `target` 改为查找 `InkWell`。
- 组件必须通过 `const` 构造器使 `find.byType` 可以准确定位，避免 Finder 匹配到过多实例。

---

## 配色系统

### 种子色机制

整个配色由单一种子色驱动。Current: `Color(0xFF64B5F6)`（小清新蓝）。

```
app_tokens.dart: AppColors.primary = 0xFF64B5F6
  └─ app_theme.dart: ColorScheme.fromSeed(seedColor: AppColors.primary)
       └─ 自动生成: primary / secondary / tertiary / error / surface / outline 等
            └─ 各组件通过 colorScheme.xxx 引用
```

**改动种子色即可全局换色**。修改 `app_tokens.dart:4` 的 hex 值后 `flutter run` 热重载即时生效。

### AppColors 边界

`app_tokens.dart` 保留以下颜色常量，但它们不是 Widget 层的默认取色 API：主题初始化使用 `AppColors.primary` 作为 seedColor；无 M3 直接对应的柔和/装饰色可在非关键装饰中少量使用；其余语义、表面、文字、边框颜色在 Widget 中应改用 `colorScheme`。

| 类别 | 示例 | 数量 |
|------|------|------|
| 语义色 | `primary`, `secondary`, `error`, `success`, `warning` | 7 |
| 表面色 | `background`, `surface`, `surfaceElevated`, `surfaceMuted`, `surfaceSubtle` | 5 |
| 柔和变体 | `primarySoft`, `secondarySoft`, `blueSoft`, `greenSoft` 等 | 10+ |
| 文字色 | `textPrimary`, `textSecondary`, `textTertiary` | 3 |
| 边框色 | `border`, `borderSoft` | 2 |
| 装饰色 | `purple`, `purpleSoft` | 2 |

### 卡片与边框色值速查

| 元素 | 边框值 | 阴影 |
|------|--------|------|
| 首页卡片 (Panel/Metric/Shortcut/Thought) | `outlineVariant` alpha 0.25 | `AppShadows.cardSoft` |
| 移动端卡片 | `outlineVariant` alpha 0.25 | `AppShadows.cardSoft` |
| 搜索框 / 通知按钮 | `outlineVariant` alpha 0.25 | `AppShadows.cardSoft` |
| CardTheme 全局默认 | `outlineVariant` alpha 0.25 | shadow 0.06 |
| 侧栏分隔线 / 右栏分隔线 | `outlineVariant` alpha 0.5 | — |
| 全局 CardTheme 背景 | `surfaceContainerLow` | — |
| 桌面框架背景 | `surfaceContainerLowest` | — |

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

## UI Pattern: Soft Shadow Cards with Subtle Border

**What**: 卡片采用「弥散阴影 + 极淡边框」组合来实现漂浮感和区域界定。默认边框为 `outlineVariant.withValues(alpha: 0.25)`（极淡灰色），视觉上几乎无感但能确保卡片在浅色背景上边界清晰。框架分隔线（侧栏右边缘、右栏左边缘）使用 `outlineVariant.withValues(alpha: 0.5)`。

**Why**: 弥散阴影提供深度层次，极淡边框在阴影不足的场景（密排列、移动端小屏）下保持区域辨识。设计意图是「漂浮但不模糊」——卡片之间靠边框轻微界定，靠阴影区分层级。

### 标准卡片模板

```dart
Material(
  color: colorScheme.surface,
  borderRadius: BorderRadius.circular(AppRadius.xl),  // 20px
  elevation: 0,
  child: DecoratedBox(
    decoration: BoxDecoration(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      boxShadow: const [AppShadows.cardSoft],
    ),
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: /* 内容 */,
    ),
  ),
);
```

### 可交互卡片（InkWell + 阴影）

```dart
Material(
  color: colorScheme.surface,
  borderRadius: BorderRadius.circular(AppRadius.xl),
  elevation: 0,
  child: DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(AppRadius.xl),
      boxShadow: const [AppShadows.cardSoft],
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(AppRadius.xl),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: /* 内容 */,
      ),
    ),
  ),
);
```

### 统计卡片（Metric Card）

统计卡片使用纵向（`Column`）布局，图标在上，数值/副标题依次排列：

```dart
Material(
  color: colorScheme.surface,
  borderRadius: BorderRadius.circular(AppRadius.xl),
  elevation: 0,
  child: DecoratedBox(
    decoration: BoxDecoration(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      boxShadow: const [AppShadows.cardSoft],
    ),
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 大图标在上（52×52）
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(title, style: theme.textTheme.labelLarge),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(note, style: theme.textTheme.bodySmall),
        ],
      ),
    ),
  ),
);
```

### 阴影系统

阴影定义在 `app_tokens.dart` 中，全表如下：

| Token | blurRadius | offset | 透明度 | 用途 |
|-------|-----------|--------|--------|------|
| `AppShadows.cardSoft` | 16px | (0, 4) | 2%（浅色） | 默认卡片、面板 |
| `AppShadows.cardElevated` | 24px | (0, 8) | 3%（浅色） | 悬停/交互态 |
| `AppShadows.card` | 32px | (0, 16) | 3%（浅色） | 浮动元素、弹窗 |

> 暗色模式下阴影透明度相应提高（`alpha: 0.15`），保持层次感。

### 可接受的使用差异

- 最小圆角变体：对于紧凑场景（侧栏选中态等）可使用 `AppRadius.lg`(16px)
- 无阴影变体：非浮层表面（面板内部元素）可以不设 `boxShadow`
- 边框使用规则：
  - 独立卡片（首页各面板、统计卡、快捷入口）：使用 `outlineVariant.withValues(alpha: 0.25)`
  - 框架分隔线（侧栏、右栏边缘）：使用 `outlineVariant.withValues(alpha: 0.5)`（更明显但不到 1.0）
  - **禁止**：使用全不透明边框 `alpha: 1.0` 的 `outlineVariant`——这会破坏通透感

---

## Layout Overflow 预防

禁止 GridView/ListView 卡片内容溢出（"RenderFlex overflowed"）。以下规则必须遵守：

### 1. GridView childAspectRatio 内容验证公式

每次使用 `childAspectRatio` 时，先做数学验证：

```
cellHeight = cellWidth / aspectRatio
contentAvailable = cellHeight - 卡片垂直padding总和
Assert: contentAvailable ≥ 所有固定尺寸子组件高度之和
```

**示例**：桌面端 `_ShortcutGrid` 中 `childAspectRatio: 1.6`，卡片 padding `vertical: 12`：
- 网格宽度 132px → `cellHeight = 132 / 1.6 ≈ 82.5px`
- 可用内容高度 = `82.5 - 24(padding) ≈ 58.5px`
- 内容（icon 42 + spacing 8 + text ~20）≈ 70px ❌ → **调整 spacing 或 icon 尺寸，或降低 aspectRatio 使单元格变高**

### 2. 固定尺寸组件必须缩放到适配

卡片内的图标、头像、间距等固定尺寸组件必须能适应最小单元格。规则：

| 场景 | 建议最大尺寸 | 替代方案 |
|------|------------|---------|
| GridView 卡片内的图标气泡 | 36px | 更紧凑时用 28-32px |
| GridView 卡片内的间距 | `AppSpacing.xxs(4)` | 不用超过 `AppSpacing.xs(8)` |
| Row/Column 中的文本 | `Flexible` 包裹 | 不使用固定 SizedBox 装文本 |

### 3. 使用 Flexible 包裹文本做溢出保护

任何出现在固定约束空间内的文本，必须用 `Flexible` 或 `Expanded` 包裹：

```dart
// ✅ 正确：Flexible 允许文本在空间不足时自动收缩
Column(
  children: [
    Icon(...),
    SizedBox(height: AppSpacing.xxs),
    Flexible(
      child: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,  // 必须有
      ),
    ),
  ],
)

// ❌ 错误：文本被抛出约束，导致 RenderFlex overflow
Column(
  children: [
    Icon(...),
    Text(title),  // 无 Flexible，固定高度可能溢出
  ],
)
```

### 4. 固定尺寸内容用 FittedBox 安全缩放

当图标/装饰需要保持比例但又必须匹配空间时，使用 `FittedBox` + `overflow: TextOverflow.ellipsis`：

```dart
// ✅ 安全：FittedBox 缩放内容到可用空间
FittedBox(
  fit: BoxFit.scaleDown,
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 24),
      SizedBox(width: 4),
      Text(label),
    ],
  ),
)
```

### 5. 每次修改卡片布局后的验证步骤

| # | 检查项 | 方法 |
|---|--------|------|
| 1 | `flutter analyze` 通过 | 0 error 0 warning |
| 2 | 在最小布局宽度下测试 UI | Desktop 卡片最小列宽 ≈ 108px |
| 3 | 确认无黄色/黑色溢出条纹 | Debug mode 目视检查 |
| 4 | `childAspectRatio` 重新验证 | 用上述公式重新计算内容是否仍适配 |

### 6. 工具栏/操作条溢出：LayoutBuilder + 水平滚动 + compact 模式

当 `Row` 内按钮数量过多导致固定宽度超出父容器时，使用 `LayoutBuilder` 检测容器宽度并启用 compact 模式或水平滚动：

```dart
LayoutBuilder(
  builder: (context, constraints) {
    final isCompact = constraints.maxWidth < 520;

    return Row(
      children: [
        // 左侧固定内容
        Text('已选择 1 项'),
        const SizedBox(width: AppSpacing.sm),
        // 右侧可滚动按钮区域
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _ActionButton(
                  label: isCompact ? '已看' : '标记已看',
                  ...
                ),
                _ActionButton(label: '归档', ...),
                _ActionButton(label: isCompact ? 'Box' : '添加到 Box', ...),
              ],
            ),
          ),
        ),
      ],
    );
  },
)
```

**原则**：
- 始终用 `LayoutBuilder` 检测可用宽度，而不是假设固定宽度
- compact 模式下缩短按钮标签文字
- `Expanded(SingleChildScrollView(horizontal))` 防止 Row 溢出
- 不依赖 `Spacer` 在窄空间中撑开（Spacer 在固定宽度已满时会变为 0，导致后续元素溢出）

### 7. 卡片右侧操作区紧缩

当卡片内右侧操作按钮过多时（状态 pill + Box 按钮 + open 按钮等），应采用 Column 垂直排列：

```dart
// ✅ 右侧 Column + ConstrainedBox 限制最大宽度
ConstrainedBox(
  constraints: const BoxConstraints(maxWidth: 72),
  child: StatusPill(
    child: Text(status.label, maxLines: 1, overflow: TextOverflow.ellipsis),
  ),
),
const SizedBox(height: 4),
BoxIconButton(constraints: BoxConstraints.tightFor(width: 28, height: 28)),
const SizedBox(height: 4),
OpenIconButton(size: 28),
```

**原则**：
- 状态 pill 用 `ConstrainedBox(maxWidth: 72)` + `TextOverflow.ellipsis` 防止宽标签溢出
- 操作按钮用 `BoxConstraints.tightFor(width: 28, height: 28)` 缩小到最低可点击尺寸
- `padding: EdgeInsets.zero` 移除按钮内部额外间距

### 8. 禁止的溢出修复方式

| 禁止的做法 | 原因 | 正确做法 |
|-----------|------|---------|
| 给溢出 Column/Row 加 `overflow: ...` | 仅裁剪视觉，实际约束冲突仍在 | 缩小固定内容尺寸或用 Flexible |
| 增加 `clipBehavior: Clip.hardEdge` | 隐藏问题而非解决 | 重新计算内容 vs 容器大小 |
| 无依据地降低 `childAspectRatio` | 可能让其他卡片变得过高 | 先验证固定内容的必要尺寸，再做调整 |

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

---

## TagKit Widget Patterns

TagKit 是一组可复用的标签相关组件，位于 `lib/src/shared/widgets/tags/`，核心逻辑位于 `lib/src/shared/tags/`。所有 UI 组件不依赖任何 Provider，通过回调与业务层通信。

### 组件层级

| 层 | 文件 | 职责 | 使用方 |
|----|------|------|--------|
| **核心逻辑** | `shared/tags/tag_models.dart` | `AppTagStat`、`TagMatchMode`、`TagValidationResult` | 所有层 |
| | `shared/tags/tag_codec.dart` | 标签 normalize、parse、encode、validate | 数据层、Provider |
| | `shared/tags/tag_filter_logic.dart` | toggle、matches、countTags、sortStats | Provider、测试 |
| **基础组件** | `app_tag_chip.dart` | `AppTagChip`（单选标签 chip）、`AppSelectedTagChip`（已选标签带删除）、`AppMoreTagsButton`（更多按钮） | 所有组合组件 |
| **组合组件** | `app_tag_filter_bar.dart` | 标签筛选栏：label + chip 列表 + 更多按钮 | 插件页 |
| | `app_selected_tags_bar.dart` | 已选标签栏：显示选中标签 + 逐个/批量清除 + +N 溢出指示 | 插件页 |
| | `app_common_tags_panel.dart` | 常用标签面板：标题 + 图标 + 辅助文字 + 标签列表 | 侧栏 |
| | `app_more_tags_popover.dart` | 更多标签弹层 Content（当前 showDialog，后续 anchored popover） | 筛选栏 |
| **插件 Adapter** | `thoughts/.../thought_common_tags_panel.dart` | 将 provider 数据转为 `AppCommonTagsPanel` props | thoughts 侧栏 |

### 组件设计约束

```dart
// ✅ 正确：无 Provider 依赖，全部通过构造器 + 回调
AppTagFilterBar(
  tags: tagStats,
  selectedTags: selectedTags,
  onTagToggle: (tag) => /* 处理切换 */,
  onMoreTap: () => /* 打开弹层 */,
)

// ❌ 错误：组件内部读取 Provider
class AppTagFilterBar extends ConsumerWidget { /* ... */ }
```

### 使用规则

| 规则 | 说明 | 实际代码 |
|------|------|----------|
| 数据传入而非查询 | 组件通过 `required` 参数接收数据，不在内部读取 Provider 或数据库 | `AppTagFilterBar.tags`、`AppSelectedTagsBar.selectedTags` |
| 回调而非直接写状态 | 用户交互通过 `ValueChanged<String>` / `VoidCallback` 通知父级 | `onTagToggle`、`onRemove`、`onClear` |
| 纯 Widget 布局 | 组件只负责渲染和交互反馈，不包含业务逻辑 | `AppCommonTagsPanel.build()` 仅组合子组件 |
| Shared 层组件用 `StatelessWidget` | 不需要 Riverpod，保持复用性 | `AppTagChip`、`AppTagFilterBar` 全部继承 `StatelessWidget` |
| `UniHubThemeColors` extension 注册 | 需要 `context.appColors` 的组件要求 `ThemeData.extensions` 注册 | `AppPanel`、`AppCommonTagsPanel` |

### 插件接入模式

插件通过 **Adapter Widget** 接入 TagKit：

1. 在插件 `providers/` 中定义数据 Provider（如 `commonTagsProvider`、`selectedTagFiltersProvider`）
2. 在插件 `ui/widgets/` 中创建 Adapter Widget（如 `ThoughtCommonTagsPanel`）
3. Adapter 内部读取 Provider，将数据转为 `AppTagStat` 等组件参数
4. 将组件参数传入 `AppCommonTagsPanel` 等通用组件

参考 `lib/src/plugins/thoughts/ui/widgets/thought_common_tags_panel.dart`。

```dart
// 标准 Adapter 模式
class ThoughtCommonTagsPanel extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commonTags = ref.watch(commonTagsProvider).take(8).toList();
    final selectedTags = ref.watch(selectedTagFiltersProvider);

    final tagStats = commonTags
        .map((e) => AppTagStat(name: e.key, count: e.value))
        .toList();

    return AppCommonTagsPanel(
      tags: tagStats,
      selectedTags: selectedTags,
      onTagToggle: (tag) {
        final current = ref.read(selectedTagFiltersProvider);
        ref.read(selectedTagFiltersProvider.notifier).state =
            toggleTagInFilter(current, tag);
      },
      // 默认参数 title/helperText/icon/maxVisibleTags/emptyText
    );
  }
}
```

### 标签输入校验模式

在 `ThoughtComposerController.handleTagInput()` 和 `ThoughtEditorController.handleTagInput()` 中调用 `TagCodec.validate()` 过滤无效标签。

```dart
// 标准校验模式
void handleTagInput(String value) {
  if (value.isEmpty) {
    tagErrorMessage = null;
    notifyListeners();
    return;
  }
  final shouldCommit = value.endsWith(',') || value.endsWith(' ');
  if (!shouldCommit) return;

  final candidates = value
      .split(RegExp('[, ]+'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty);

  for (final tag in candidates) {
    final validation = TagCodec.validate(tag);
    if (!validation.isValid) {
      tagErrorMessage = validation.message;  // 显示给用户
      notifyListeners();
      continue;
    }
    if (!_tagChips.contains(tag)) {
      _tagChips.add(tag);
    }
  }
  tagTextController.clear();
  notifyListeners();
}
```

**校验规则**（`TagCodec.validate()`）：
- 空标签 -> 拒绝
- 长度 > 20 字符 -> 拒绝
- 包含非法字符（非中文/英文/数字/_-） -> 拒绝
- 自动去除 `#` 前缀

**UI 侧**：控制器需要暴露 `tagErrorMessage` 字段，UI 在标签输入框的 `InputDecoration.errorText` 或独立的 `Text` widget 中展示。错误信息应在下次有效输入时自动清除。

### 标签自动补全模式

在标签输入框中，输入时显示已有标签候选列表，帮助用户快速选择已存在的标签，避免创建同义标签。

```dart
// 在 ConsumerWidget build() 中计算建议
final existingTags = ref.watch(commonTagsProvider);
final tagInput = composer.tagTextController.text.trim().toLowerCase();
final tagSuggestions = tagInput.isEmpty
    ? const <String>[]
    : existingTags
        .map((e) => e.key)
        .where((tag) =>
            tag.toLowerCase().contains(tagInput) &&
            !composer.tagChips.contains(tag))
        .take(5)
        .toList();
```

**UI 侧**：在标签输入框下方，用一个 `Wrap` + 小号 `Material` chip 展示候选标签，点击后调用 `handleTagInput('$tag,')` 添加。仅在无校验错误时显示。

```dart
// 建议标签渲染
Padding(
  padding: const EdgeInsets.only(top: 4),
  child: Wrap(
    spacing: AppSpacing.xs,
    runSpacing: AppSpacing.xxs,
    children: tagSuggestions.map((tag) {
      return Material(
        color: colorScheme.tertiaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: InkWell(
          onTap: () {
            tagTextController.clear();
            handleTagInput('$tag,');
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xxs,
            ),
            child: Text('#$tag',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onTertiaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      );
    }).toList(),
  ),
)
```

### 移动端标签 Widget 接入模式

移动端标签 Widget 应与桌面端使用同一套共享组件（`shared/widgets/tags/`），保持视觉和行为一致。接入策略是**轻量替换**——保留当前布局结构，只将内部 Widget 替换为共享组件。

| 位置 | 旧 Widget | 新 Widget |
|------|-----------|-----------|
| `_TagChip`（移动端标签筛选行） | `ThoughtFilterChip` | `AppTagChip(compact: true)` |
| `_MoreTagsButton`（移动端"更多标签"按钮） | `ThoughtFilterChip` | `AppMoreTagsButton` |
| `_SelectedTagBanner`（移动端已选标签行） | 原始 `Chip` | `AppSelectedTagsBar`（含 +N 溢出、批量清除） |
| 底部弹出层（`_showTagsBottomSheet`） | `ThoughtFilterChip` | `AppMoreTagsPopoverContent` |

**规则**：
- 不创建 mobile-specific adapter widget，在 `build` 方法中就地转换数据类型（`MapEntry` → `AppTagStat`）
- 共享组件 `AppMoreTagsPopoverContent` 已改用 `ConstrainedBox(maxWidth: 420)`，同时适配桌面 Dialog 和移动端 BottomSheet
- `AppTagChip(compact: true)` 为移动端水平布局提供更小的 chip 尺寸

### 测试要求

每个 TagKit widget 必须有对应的 widget 测试文件：

| 组件 | 测试文件 | 覆盖要求 |
|------|----------|----------|
| `AppTagChip` | `test/shared/widgets/tags/app_tag_chip_test.dart` | label、count、selected、onTap、compact、leadingIcon |
| `AppTagFilterBar` | `test/shared/widgets/tags/app_tag_filter_bar_test.dart` | label、empty、onTagToggle、showCounts、maxVisibleTags、onMoreTap、horizontalScroll |
| `AppSelectedTagsBar` | `test/shared/widgets/tags/app_selected_tags_bar_test.dart` | label、empty、onRemove、onClear、+N、clearLabel |
| `AppCommonTagsPanel` | `test/shared/widgets/tags/app_common_tags_panel_test.dart` | title、helperText、empty、tag chips、count、selected、maxVisibleTags |

---

## Collections Workbench UI Layout

> 参考实现：`lib/src/plugins/collections/ui/layouts/collections_desktop_layout.dart`

Collections 插件使用「左侧列表 + 右侧详情面板」的桌面工作台布局。参考 `saved_item_detail_panel.dart`、`saved_item_card.dart`、`collection_capture_bar.dart`、`collection_box_bar.dart`、`collection_view_chips.dart`、`collection_search_filter_bar.dart`。

### Workbench 主布局

```dart
// Desktop layout 模式：Column (header + controls) → Expanded (Row [list panel | detail panel])
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    // ---- Header ----
    Row(children: [title, refresh button]),
    // ---- Capture bar ----
    CollectionCaptureBar(),
    // ---- View chips ----
    CollectionViewChips(),
    // ---- Box bar ----
    CollectionBoxBar(),
    // ---- Search / filter bar ----
    CollectionSearchFilterBar(),
    // ---- Split pane ----
    Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: scrollable item list
          Expanded(
            child: Column(children: [
              Expanded(child: ListView.separated(...)),
              CollectionBulkActionBar(),
            ]),
          ),
          SizedBox(width: AppSpacing.lg),
          // Right: detail panel, LayoutBuilder-based width (maxWidth*0.36, clamped 420-540)
          LayoutBuilder(
            builder: (context, constraints) {
              final detailWidth = (constraints.maxWidth * 0.36)
                  .clamp(420.0, 540.0);
              return SizedBox(
                width: detailWidth,
                child: SavedItemDetailPanel(item: displayItem),
              );
            },
          ),
        ],
      ),
    ),
  ],
)
```

**约定**：

| 规则 | 说明 |
|------|------|
| 左侧列表 + 右侧详情面板 | 置于 `Expanded > Row` 中，左右通过 `SizedBox(width: AppSpacing.lg)` 分隔 |
| 详情面板宽度 | `LayoutBuilder` 动态计算：`constraints.maxWidth * 0.36`，clamp 至 `420-540`。使用 `LayoutBuilder` 包裹 `SizedBox`，不硬编码固定宽度 |
| 选中项状态 | 由 `selectedSavedItemIdProvider`（`StateProvider<int?> `）管理，Widget 通过 `ref.watch/read` 访问 |
| 自动选中首项 | `initState` 中通过 `addPostFrameCallback` 调用 `_autoSelectFirstItem()`；已有选中项时跳过 |
| 列表点击驱动选中 | `SavedItemCard.onTap` 中将 `ref.read(selectedSavedItemIdProvider.notifier).state = item.id` |
| 显示项计算 | `displayItem` 由 `selectedId` 在 `items` 列表中查找得到；`selectedId` 无效时 fallback 到 `items.first` |
| 右侧为空态 | displayItem 为 null 时，`SavedItemDetailPanel` 显示 「选择一条收藏」占位（图标 + 标题 + 说明） |

### Box 筛选 vs Box 编辑分离

| 场景 | 使用的 Provider / Repository 方法 | 说明 |
|------|----------------------------------|------|
| **列表级筛选** | `selectedCollectionBoxIdsProvider`（`StateProvider<Set<int>>`） | 仅用于过滤列表显示哪些 item。空集合 = 不过滤（显示全部） |
| **Item 级 Box 编辑** | `repository.setItemBoxes(id, Set)` + `repository.getBoxIdsForItem(id)` | 直接写数据库，不通过筛选 Provider。详见 `_BoxSection`（`saved_item_detail_panel.dart`） |
| **Item 级 Inbox 联动** | `repository.updateInboxState(id, bool)` | 给 item 分配第一个 Box 时自动设 `isInInbox=false`；移出所有 Box 时设 `isInInbox=true` |

```dart
// 正確：Item 级 Box 编辑不写入筛选 Provider
onSelected: (selected) {
  if (selected) {
    final next = {...currentSet, box.id};
    repository.setItemBoxes(item.id, next);
    if (currentSet.isEmpty) {
      repository.updateInboxState(item.id, false);  // 移出 Inbox
    }
  } else {
    final next = {...currentSet}..remove(box.id);
    repository.setItemBoxes(item.id, next);
    if (next.isEmpty) {
      repository.updateInboxState(item.id, true);  // 回到 Inbox
    }
  }
  ref.invalidate(savedItemsListProvider);  // 刷新列表
}
```

### Detail Panel 结构

结构自上而下（`saved_item_detail_panel.dart`）：

| 区域 | Widget / 实现 | 说明 |
|------|--------------|------|
| `item == null` | `_buildEmpty()` | 居中图标 + 「选择一条收藏」+ 说明文字，用 `Container(border, borderRadius)` 包裹 |
| Content Identity | `_buildContentIdentity()` | 窄宽优先的信息头：媒体类型图标、标题（最多 2 行）、平台/类型/相对时间、星标占位、打开图标按钮 |
| Primary Action | `_buildTopActionRow()` | 高强调 `FilledButton.icon`「打开原网页」；点击后调用 `markOpened`、invalidate `savedItemsListProvider`，再用外部浏览器打开 |
| Link | `_buildLinkSection()` | 左侧固定标签「来源」，右侧 URL（最多 2 行）+ 复制按钮 |
| Status | `_buildStatusSection()` | `AppPillChip` 选择 `ConsumptionStatus`，选中后写数据库并 invalidate 列表 |
| Box | `_BoxSection` (私有 `ConsumerWidget`) | 左侧固定标签「收藏夹」；用 `FutureBuilder` 加载当前 item 的 Box IDs，只显示已归属的 `AppPillChip`（`selected: true`，点击可移除），`LayoutBuilder` + 数量截断实现最多两行；空态显示「待整理」chip；末尾固定 `[+ 新建]`（移除 `+ 选择收藏夹`） |
| Tags | `_TagsSection` (私有 `ConsumerWidget`) | 左侧固定标签「标签」；从当前 Box 名称 + 媒体类型 + 来源平台构造标签列表，严格去重（跳过空字符串和「未知」），`LayoutBuilder` + 数量截断实现最多两行；末尾固定 `[+ 添加标签]` 占位 |
| Linkage Placeholder | `_buildNotesBridgeSection()` | 左侧固定标签「备注」；仅显示「暂未关联笔记、想法或 Todo。」预留文案，不写数据库、不新增备注字段 |
| Timeline | `_buildTimelineSection()` | 两个等宽信息卡：`createdAt` 收藏时间、`lastOpenedAt` 最后访问；空值显示「尚未访问」 |
| Quick Actions | `_buildQuickActionsSection()` | 5 个稳定等宽入口：复制链接、分享占位、移动（Box 菜单）、归档、删除占位 |

**Key rule**：备注/笔记/想法/Todo 属于后续跨插件联动，本面板只保留预留入口；不要为了详情页视觉改造新增 `saved_items` 备注字段或数据库迁移。

### Filter 组件模式

Collections 插件的筛选组件各司其职，分别维护独立 provider（`collections_providers.dart`）：

```dart
// 6 个独立的 StateProvider，一个 FutureProvider 合成查询
final collectionViewProvider = StateProvider<CollectionView>(
  (ref) => CollectionView.inbox,
);
final collectionStatusFilterProvider = StateProvider<ConsumptionStatus?>(
  (ref) => null,
);
final collectionPlatformFilterProvider = StateProvider<SourcePlatform?>(
  (ref) => null,
);
final collectionMediaTypeFilterProvider = StateProvider<MediaType?>(
  (ref) => null,
);
final selectedCollectionBoxIdsProvider = StateProvider<Set<int>>(
  (ref) => const <int>{},
);
final collectionSearchQueryProvider = StateProvider<String>(
  (ref) => '',
);

// 合成查询
final savedItemsListProvider = FutureProvider<List<SavedItemsTableData>>((ref) {
  final repository = ref.watch(collectionsRepositoryProvider);
  return repository.queryItems(
    view: ref.watch(collectionViewProvider),
    status: ref.watch(collectionStatusFilterProvider),
    platform: ref.watch(collectionPlatformFilterProvider),
    mediaType: ref.watch(collectionMediaTypeFilterProvider),
    boxIds: ref.watch(selectedCollectionBoxIdsProvider),
    query: ref.watch(collectionSearchQueryProvider),
  );
});
```

| 组件 | Widget | Provider 和模式 |
|------|--------|----------------|
| View chips | `CollectionViewChips` | 单选的 `ChoiceChip` 行。读写 `collectionViewProvider`。clear filters 时**不**重置此 provider |
| Box bar | `CollectionBoxBar` | 多选的 `FilterChip` 行 +「+ 新建 Box」ActionChip。读写 `selectedCollectionBoxIdsProvider`。空集合 = 不过滤 |
| Search / filter bar | `CollectionSearchFilterBar` | `TextField(搜索)` + `DropdownButton(来源)` + `DropdownButton(媒介)` + 「清空筛选」按钮。clear 重置除 `collectionViewProvider` 外的所有 filter provider |

**清空筛选规则**（`_clearFilters` in `CollectionSearchFilterBar`）：

```dart
void _clearFilters(WidgetRef ref) {
  ref.read(collectionSearchQueryProvider.notifier).state = '';
  ref.read(collectionPlatformFilterProvider.notifier).state = null;
  ref.read(collectionMediaTypeFilterProvider.notifier).state = null;
  ref.read(collectionStatusFilterProvider.notifier).state = null;
  ref.read(selectedCollectionBoxIdsProvider.notifier).state = {};
  // DO NOT reset collectionViewProvider — view selection is NOT a filter
}
```

### Auto-select 首项模式

```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _autoSelectFirstItem();
  });
}

void _autoSelectFirstItem() {
  final itemsAsync = ref.read(savedItemsListProvider);
  final currentSelectedId = ref.read(selectedSavedItemIdProvider);

  if (currentSelectedId != null) return;  // 已有选中项，不覆盖

  itemsAsync.whenData((items) {
    if (items.isNotEmpty && mounted) {
      ref.read(selectedSavedItemIdProvider.notifier).state = items.first.id;
    }
  });
}
```

**约定**：
- 使用 `addPostFrameCallback` 延迟执行，避免在 build 期间写 Provider
- 已有选中项时跳过（`currentSelectedId != null`），防止刷新列表覆盖用户选择
- 列表为空时不操作
- 使用 `mounted` 检查防止异步回调在 dispose 后写 Provider

---

## Typography 字体规范

### 全局字体策略

- 普通 UI 文本统一使用 `Theme.of(context).textTheme.*`
- 中文 UI 主字体为 `AppFonts.ui`（Noto Sans SC）
- 英文品牌可使用 `AppFonts.latin`（Inter）
- 代码、命令、路径使用 `AppFonts.mono`（JetBrains Mono）
- 字体文件必须通过 `pubspec.yaml > flutter.fonts` 本地打包，不运行时远程加载
- 不允许在 Widget 中调用 `GoogleFonts.*`
- 不允许在 Widget 中直接写 `fontFamily`
- 不允许在 Widget 中直接写裸数字 `fontSize: 12`
- 不允许在 Widget 中直接写 `FontWeight.wXXX`（应使用 `AppFontTokens` 语义常量）
- 局部样式只能基于 `theme.textTheme.xxx?.copyWith(...)` 修改颜色/字重

### 正确写法

```dart
Text(
  label,
  style: theme.textTheme.labelSmall?.copyWith(
    color: colorScheme.onSurfaceVariant,
    fontWeight: AppFontTokens.medium,
  ),
)
```

### 错误写法

```dart
// ❌ 禁止：Widget 层直接调用 GoogleFonts
GoogleFonts.inter(textStyle: ...)
GoogleFonts.notoSansSc(...)

// ❌ 禁止：直接指定 fontFamily
style: TextStyle(fontFamily: 'Inter')

// ❌ 禁止：裸数字 fontSize
style: TextStyle(fontSize: 12)

// ❌ 禁止：裸 FontWeight
FontWeight.w600

// ❌ 禁止：不基于 theme.textTheme 的 TextStyle
TextStyle(color: Colors.blue, fontSize: 14)
```

### 例外文件

以下文件作为字体基础设施允许使用 `fontFamily`、`GoogleFonts.*`、`fontSize` 裸值：

- `lib/src/core/theme/app_theme.dart`
- `lib/src/core/theme/app_tokens.dart`
