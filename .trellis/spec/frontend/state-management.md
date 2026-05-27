# State Management

> UniHub 状态管理模式 — 基于 Riverpod + Provider 体系

---

## Overview

状态管理以 Riverpod（`flutter_riverpod` + `riverpod_annotation`）为核心：

- **全局状态**：应用级 Provider（数据库、插件注册、搜索）
- **功能状态**：插件级 Provider（thoughts 列表、过滤、编辑）
- **UI 状态**：Widget 内部 `StatefulWidget` 状态

---

## Provider 类型速查

| Provider 类型 | 用途 | 示例 |
|---------------|------|------|
| `Provider<T>` | 服务/依赖注入 | `databaseProvider`, `pluginRegistryProvider` |
| `FutureProvider<T>` | 异步数据 | `thoughtProvider(id)`, `allThoughtsProvider` |
| `StateProvider<T>` | 简单可变状态 | `thoughtStatusFilterProvider`, `archiveFilterProvider` |
| `NotifierProvider<T>` | 复杂可变逻辑 | 标签过滤等需要组合 State 的场景 |
| `StreamProvider<T>` | 流式数据更新 | `(暂无使用)` |

---

## Provider 层级依赖

```mermaid
flowchart LR
    DB[databaseProvider] --> DAO[thoughtDaoProvider]
    DAO --> REPO[thoughtsRepositoryProvider]
    REPO --> LIST[allThoughtsProvider]
    REPO --> FILTER[filteredThoughtsProvider]
    REPO --> PENDING[pendingReviewProvider]
    FILTER --> STATUS[thoughtStatusFilterProvider]
    FILTER --> TAG[selectedTagFiltersProvider]
```

### 依赖注入方式

```dart
// 基础 Provider（注入依赖）
@riverpod
ThoughtsDao thoughtDao(ThoughtDaoRef ref) {
  final db = ref.watch(databaseProvider);
  return ThoughtsDao(db);
}

// 异步数据 Provider
@riverpod
Future<List<Thought>> allThoughts(AllThoughtsRef ref) {
  final repo = ref.watch(thoughtsRepositoryProvider);
  return repo.getAll();
}

// 简单过滤状态
@riverpod
class ThoughtStatusFilter extends _$ThoughtStatusFilter {
  @override
  ThoughtStatus build() => ThoughtStatus.all;
  
  void select(ThoughtStatus status) => state = status;
}
```

---

## 状态访问规则

### UI 层

```dart
// ConsumerWidget 中监听
class ThoughtList extends ConsumerWidget {
  Widget build(BuildContext context, WidgetRef ref) {
    final thoughtsAsync = ref.watch(filteredThoughtsProvider);
    return thoughtsAsync.when(
      data: (thoughts) => ListView(...),
      error: (err, stack) => ErrorWidget(...),
      loading: () => LoadingWidget(),
    );
  }
}
```

### 事件处理器中（一次性读取 + 写操作）

```dart
// 点击事件触发写操作
onPressed: () {
  ref.read(thoughtsRepositoryProvider).archive(id);
  ref.invalidate(allThoughtsProvider); // 刷新列表
}
```

---

## Provider 生命周期

- 基础 Provider（`Provider`/`FutureProvider`）不需要手动 dispose
- 插件注册 Provider 关联 `ref.onDispose` 清理
- `NotifierProvider` 在不再被监听时自动释放

---

## 状态提升原则

| 场景 | 策略 |
|------|------|
| 多个 Widget 共享数据 | 提升到公共父级或全局 Provider |
| Widget 内部临时 UI 状态 | `StatefulWidget` + `setState` |
| 跨页面共享的过滤/排序状态 | 全局 `StateProvider` / `NotifierProvider` |
| 服务器/数据库数据 | 用 `FutureProvider`，不缓存到本地 state |

---

## Selected-Item Provider Pattern

> 参考实现：`lib/src/plugins/collections/providers/collections_providers.dart`

在列表 + 详情面板的工作台布局中，使用 `StateProvider<int?>` 持有当前选中项的 ID。

### 声明

```dart
final selectedSavedItemIdProvider = StateProvider<int?>((ref) => null);
```

### 使用模式

```dart
// Widget build 中读取当前选中项
final selectedId = ref.watch(selectedSavedItemIdProvider);

// 从列表同步查找显示项
final items = itemsAsync.asData?.value ?? <SavedItemsTableData>[];
SavedItemsTableData? displayItem;
if (selectedId != null) {
  displayItem = items.where((item) => item.id == selectedId).firstOrNull;
}
displayItem ??= items.isNotEmpty ? items.first : null;  // fallback

// 列表点击更新选中项
SavedItemCard(
  onTap: () {
    ref.read(selectedSavedItemIdProvider.notifier).state = item.id;
  },
)
```

**约定**：

| 规则 | 说明 |
|------|------|
| 选中的是 ID，不是对象 | 避免列表刷新时选中引用失效；从列表中按 ID 重新查找 |
| 不要在 FutureProvider 异步体内 `watch` UI 选中状态 | 见下面的「常见错误」表 |
| ID 无效时 fallback 到 `items.first` | 如果选中 ID 在过滤/刷新后消失，不保留过期引用 |
| null 初始值 | 启动时无选中项，由布局自动选择第一项 |
| 不重置筛选时保留选中 | 筛选 Provider 变更不 reset `selectedSavedItemIdProvider`，由 `fallback` 处理无效选中 |
| 只读模式 | UI 只通过 `ref.watch` 读取和 `ref.read(...notifier).state =` 写入，不做复杂操作 |

### 自动选中首项

```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final itemsAsync = ref.read(savedItemsListProvider);
    final currentSelectedId = ref.read(selectedSavedItemIdProvider);
    if (currentSelectedId != null) return;
    itemsAsync.whenData((items) {
      if (items.isNotEmpty && mounted) {
        ref.read(selectedSavedItemIdProvider.notifier).state = items.first.id;
      }
    });
  });
}
```

---

## 常见错误

| 错误 | 正确做法 |
|------|---------|
| `ref.read(provider)` 在 build 中 | 用 `ref.watch` 替代 |
| `ref.watch` 非 Provider 的变量 | 用 `ref.listen` + 回调 |
| `provider.future` 后不再 `.when` | AsyncValue 必须三态处理 |
| 手动 `setState` 管理数据库数据 | 应通过 Provider 链驱动 rebuild |
| 在 `FutureProvider` 异步体内 `watch` UI-only 的 `StateProvider`（如 `selectedId`） | 纯 UI 状态（如选中项 ID）放在 `FutureProvider` 的 `async` 函数体内 `watch`，会导致每次选中变化时 **整个异步 Provider 重新执行**（重新查询 DB、重新聚合数据），造成页面「刷新」闪烁和多余 I/O。**正确做法**：`FutureProvider` 只负责数据聚合，`selected` 等 UI 状态由 Widget 层通过 `copyWith` 在列表 `itemBuilder` 中合成。
