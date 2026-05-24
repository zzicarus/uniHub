# 错误学习记录

> agent 在运行过程中遇到的错误记录于此，避免重复犯错。

## 2026-05-24: InkWell 在动画布局中触发的 RenderBox layout 断言失败

**场景**：侧栏 `_NavItem` 和 `_UserTile` 使用 `Material` + `InkWell` 模式。`_ExpandableNavItem` 使用 `AnimatedCrossFade` + `AnimatedRotation` 实现展开/折叠动画。当用户在动画期间点击 `_NavItem`，InkWell 创建涟漪效果（`InkDecoration.paintFeature` → `RenderPhysicalModel.paint`），尝试绘制到子 `RenderPadding` 上，但子组件尚未完成布局 → `RenderBox was not laid out: RenderPadding#9a240 NEEDS-LAYOUT NEEDS-PAINT`。

**根因**：InkWell 的涟漪绘制需要子组件的布局已就绪。在动画进行中（`AnimatedCrossFade` 改变布局），布局逐帧变化，子组件可能处于未完成布局状态。`Material` + `InkWell` 组合将涟漪的绘制区域绑定到 Material 的子节点，而非明确的装饰边界，导致在布局未完成时尝试绘制。

**修复**：
1. `sidebar.dart _NavItem`：`Material` + `InkWell` → `GestureDetector`。导航项使用自定义颜色表示选中态，不需要 Material 涟漪效果。
2. `sidebar.dart _UserTile`：`Material` + `InkWell` → `GestureDetector`。
3. `saved_item_card.dart`：`Material` + `InkWell` → `Ink` + `InkWell`。`Ink` widget 正确管理涟漪绘制边界在装饰范围内，避免绘制到未布局的子组件上。

**避免**（强制检查清单）：
1. 在动画/变化布局中（AnimatedCrossFade, AnimatedSize, AnimatedContainer），优先使用 `GestureDetector` 而非 `InkWell` —— 除非 Material 涟漪是明确 UX 需求
2. 如果 InkWell 在动画上下文中是必需的，使用 `Ink` + `InkWell` 模式（而非 `Material` + `InkWell`），将涟漪绘制绑定到装饰边界，避免依赖子组件布局
3. 对于使用自定义颜色的导航/选择按钮（非 Material 涟漪），`GestureDetector` + 自定义 `Container` 装饰更安全、性能更好
4. 这是 Flutter 渲染管线特有的问题 —— InkWell 涟漪绘制要求子组件布局完成，这在动画过渡中未必成立

---

## 2026-05-22: GridView childAspectRatio 导致卡片内容溢出

**场景**：Desktop 首页 `_ShortcutCard` 在 GridView 中产生 `A RenderFlex overflowed by 11 pixels on the bottom`。Column 约束为 w=108.6, h=58.8（由 `childAspectRatio: 1.6` 推导），而内容高度约 70px（icon 42px + spacing 8px + text ~20px）。

**根因**：`GridView.builder` 的 `childAspectRatio: 1.6` 决定了每个网格项的高宽比，但卡片内部使用了固定尺寸的子组件（`AppIconBubble(size: 42)`、`SizedBox(height: 8)`），导致：
- 网格项高度 = 宽度 / 1.6
- 减去卡片 padding 后，可用空间不足容纳固定内容
- 修改卡片布局时，常增大图标/间距但没有同步调整 aspectRatio，造成重复溢出

**修复**：
1. 将 `AppIconBubble` 的 `size` 从 42 降到 30、`iconSize` 从 22 降到 16
2. 将 `SizedBox` 间距从 `xs(8)` 缩到 `xxs(4)`
3. 将 `Text` 包裹在 `Flexible` 中，让文本能在空间不足时自动收缩
4. 总内容高度约 54px，可安全放入 58.8px

**避免**（强制检查清单）：
1. 使用 `childAspectRatio` 时，先根据网格宽度和 padding 推算出可用内容高度
2. 用公式验证：`cellHeight = cellWidth / aspectRatio` → `contentAvailable = cellHeight - padding` → `contentAvailable ≥ totalContentHeight`
3. 对文本类子组件始终使用 `Flexible`/`Expanded` 包裹，不要假设文本一定适配套件大小
4. 卡片内固定尺寸组件（图标、头像、装饰框）优先用较小的 Token（`AppSizes`），不要超 36px 除非有明显设计理由
5. 修改卡片布局后，在最小容器宽度（约 108px — 对应 6 列快捷入口）下验证是否溢出

## 格式

每条记录包含：
- **场景**：做了什么遇到了这个错误
- **根因**：为什么出错
- **修复**：怎么解决的
- **避免**：以后怎么防止

---

## 2026-05-20: 代码库全面缺陷分析与修复

**场景**：对 UniHub 代码库进行首次系统性缺陷扫描，发现 18 项问题（P0-P4），并完成 P0-P3 共 13 项的修复。

### 1. core→plugins 依赖方向不可逆

- **场景**：`core/database/app_database.dart` 直接 `import` `plugins/thoughts/data/thoughts_table.dart`
- **根因**：Thoughts 插件的 drift 表定义放在 plugins 层，core 层需要引用它来注册到 database，形成了反向依赖
- **修复**：将 `ThoughtsTable` 类从 `plugins/thoughts/data/` 移入 `core/database/tables/`（新建目录），core 层引用兄弟目录，plugins 层通过 `package:` 导入 core 层
- **避免**：数据模型（drift 表、DTO、shared 枚举）如果有多个层引用，应放在 `core/` 或 `shared/` 层，不要放在 plugins 中

### 2. Attribute\<dynamic\> ≠ Attribute\<Object?\>

- **场景**：`thought_rich_editor.dart` 中使用 `Attribute<dynamic>? attribute` 绕过类型检查
- **根因**：`<dynamic>` 告诉 Dart "完全不要检查类型"，而需要表达的意思是"可以存放任何类型（包括 null）"
- **修复**：改为 `Attribute<Object?>? attribute`，只对上游 flutter_quill 的实验性 API 保留行级抑制
- **避免**：永远不要使用 `<dynamic>` 作为类型参数，它静默关闭了所有类型检查。如需可空任意类型，使用 `<Object?>`

### 3. 文件级 lint 抑制是危险信号

- **场景**：`thought_rich_editor.dart` 顶部有 `// ignore_for_file: experimental_member_use`，覆盖了整个文件
- **根因**：为了方便快速开发，直接将整个文件的检查禁用
- **修复**：删除了文件级抑制，只在具体使用上游实验性 API 的位置添加行级 `// ignore:` 并注释原因
- **避免**：永远不用 `// ignore_for_file:`（除非绝对必要且经过团队评审）。改用行级 `// ignore:` + 原因注释

### 4. 定义而未引用的文件会累积

- **场景**：`app_layout.dart`（36 行）和 `search_service.dart` + `search_result.dart` 定义了但零引用
- **根因**：`AppLayout` 被 `AdaptiveShell` 取代后未清理；搜索功能处于半成品状态，代码先合入了
- **修复**：删除 `app_layout.dart`（整体）和 `search_service.dart`（保留 `search_result.dart` 因为它被 `plugin_interface.dart` 引用）
- **避免**：引入替代方案后立即删除旧代码。"以后清理"永远不会发生。搜索功能开始前不要合入死亡代码

### 5. 占位页面保持极简

- **场景**：`mobile_placeholder_pages.dart` 1505 行包含大量硬编码 mock 内容
- **根因**：占位页面从真实页面复制改造而来，累积了过多无用内容
- **修复**：替换为 5 个共 120 行的极简桩页面（仅图标+标题+"即将推出"）
- **避免**：路由结构保留，但占位页面用最小化实现。mock 数据放在独立文件，不要混入路由/页面定义

### 6. 测试数据库连接需要正确生命周期

- **场景**：`database_test.dart` 无 `tearDown`，数据库连接在测试完成后未关闭
- **根因**：每个测试函数内手动调用 `close()`，如果测试中途失败则不会执行
- **修复**：使用 `late AppDatabase database` + `setUp` 初始化 + `tearDown` 关闭的 Riverpod 标准模式
- **避免**：任何涉及资源获取的测试都要使用 `setUp`/`tearDown` 模式，确保异常路径也能释放资源

### 7. `hide isNull, isNotNull` 在 drift import 上是有意为之

- **场景**：`thoughts_dao_test.dart` 的 `import 'package:drift/drift.dart' hide isNull, isNotNull;`
- **根因**：`drift` 导出的 `isNull`/`isNotNull` 与 `package:checks` 的 matcher 同名冲突，且 DAO 测试确实不需要 drift 的 null 匹配器
- **修复**：保留 `hide`，添加注释说明冲突原因
- **避免**：不要盲目移除 `hide` 子句。验证顶层 import 的每个冲突，有依据的 `hide` 是正确的

### 8. `unawaited()` 是正确的 fire-and-forget 模式

- **场景**：4 处 unawaited Future 调用被标记为"丢失错误处理"
- **根因**：初始分析认为缺少 `.catchError()` 属于缺陷
- **修复**：审计后确认它们使用 `dart:async` 的 `unawaited()` 函数显式标记为 fire-and-forget，且调用内容不涉及业务关键路径，属于正确用法
- **避免**：fire-and-forget 的正确模式是 `unawaited(fn())`，而不是丢弃 Future 或添加无意义的 `.catchError()`。分析时先确认是否使用了 `unawaited()`

### 9. 深层相对 import 不利于重构

- **场景**：plugins/ 到 core/ 的 18 处 import 使用 `../../../../core/...` 相对路径
- **根因**：开发时使用 IDE 自动补全的相对路径导入
- **修复**：全部改为 `package:uni_hub/src/core/...` 格式
- **避免**：项目中约定跨层引用统一使用 `package:` 导入，代碼审查时检查 `../../../` 的再次出现

### 10. isPinned 参数要验证后再修

- **场景**：分析将 `ThoughtsRepository.createThought` 缺少 `isPinned` 参数列为缺陷
- **根因**：参数名在抽象类/实现类间的传递路径中被忽略，初始扫描未追到底层签名
- **修复**：追查后发现 `bool isPinned = false` 已存在于接口和实现中，是误报
- **避免**：在报告"缺失参数"之前，检查抽象类和实现类的完整签名链，确认确实不存在

### 11. `ref.onDispose` 是 Riverpod 中清理资源的正确钩子

- **场景**：`PluginRegistry.disposeAll()` 定义了但从未被调用
- **根因**：没有将 disposeAll 挂接到 Riverpod 的生命周期中
- **修复**：在 `pluginRegistryProvider` 中添加 `ref.onDispose(() => registry.disposeAll())`
- **避免**：任何通过 Provider 获取的外部资源/Controller 都要通过 `ref.onDispose` 注册清理逻辑，遵循数据库 provider 的既有模式

### 12. 提取重复代码时注意命名冲突

- **场景**：`thoughts_editor_page.dart` 有 `_ColorDot` 类，`thought_editor_drawer.dart` 有 `_Cd` 类（同一件事两种不同的私有命名）
- **根因**：两个开发者分别实现了颜色选择器，各自起名习惯不同，后期未统一
- **修复**：提取为 `thought_color_picker.dart` 的 `ThoughtColorDot` 公共 widget，删除两份私有实现
- **避免**：DRY 原则——当同一模式出现两次（尤其是 UI 组件），立即提取为共享组件
