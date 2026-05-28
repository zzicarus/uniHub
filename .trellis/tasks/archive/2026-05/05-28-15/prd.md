# 修复收藏模块运行时体验与架构一致性 15 项问题

## Goal

修复用户在深度审查中发现的 15 个问题，覆盖三类：运行时 Bug/体验退化（#1-3,#8,#10）、功能缺口/架构设计（#4-7,#9）、性能/基础设施隐患（#11-15）。目标是消除收藏模块的"刷新感"、修复数据流不一致、补齐移动端入口、清理调试日志，并为基础性能问题建立最小修复。

## Requirements

### 运行时 Bug / 体验退化

* **#1 卡片选中引起整页重建** — `CollectionsDesktopLayout` 直接 watch `selectedSavedItemIdProvider`，每次点击导致父布局、列表、详情栏全部重建。改为卡片内部使用 `ref.watch(selectedSavedItemIdProvider.select((id) => id == entry.item.id))` 判断选中态，父级只传 `entry.item`，不在父级 `copyWith(selected: ...)`。
* **#2 详情页 FutureBuilder 重查数据库** — `_TagsSection` 和 `_BoxSection` 在 widget build 中用 `FutureBuilder` 调用 `repository.getBoxIdsForItem(item.id)`，切换卡片时出现短暂加载态。改为让详情页直接吃 `selectedSavedItemEntryProvider`（已包含 `boxes`），不再额外查询。
* **#3 初次自动选中不可靠** — `_autoSelectFirstItem()` 只在 `initState` 的 post-frame 执行一次。改为 `ref.listenManual(savedItemListEntriesProvider, ...)` 持续监听，数据就绪后发现 selectedId 仍为 null 时自动选中第一条。
* **#8 搜索框和 provider 不同步** — `_clearFilters` 直接清空 `collectionSearchQueryProvider`，但 `_controller.text` 未同步。改为在 `initState` 用 `ref.listenManual` 同步 provider → controller (`_controller.text = next`)。
* **#10 编辑器标题异步错误未处理** — `_onTitleChanged()` 调用 `updateFirstParagraphText(value)` 未 `await` 也未 `catchError`。加上 `unawaited()` 包装 + `.catchError()` 上报 `FlutterError`。

### 功能缺口 / 架构设计

* **#4 无分页加载** — `savedItemsPageProvider` 固定 `limit: 50, offset: 0`。最小修复：列表底部显示"加载更多"按钮，追加查询 next page。长期改 infinite scroll 不在本轮。
* **#5 无移动端布局** — `CollectionsPage` 直接返回 `CollectionsDesktopLayout`。新增 `AdaptiveLayout` 分支，mobile 下返回简化布局（暂不包含收藏夹侧栏），至少保证可访问。移动端 shell 底部导航增加 `/collections` 入口。
* **#6 导航命名冲突** — 侧栏硬编码 `/favorites` label "收藏"，插件 `/collections` label 也是"收藏"。改为：插件 `/collections` → label "收藏库"，侧栏 `/favorites` → label "星标"。
* **#7 quickCreate 分流缺失** — `PluginRegistry.quickCreate()` 顺序遍历，Thoughts 在前且不判断内容类型，URL 也会被创建成想法。给 `UniHubPlugin` 协议增加 `bool canHandleQuickCreate(String content)` 方法；Collections 对 URL 返回 true，Thoughts 对非 URL 返回 true。`PluginRegistry.quickCreate()` 先过滤再调用。
* **#9 两套 URL 判断** — 输入框用 `_detectUrl()`，真正收藏用 `UrlNormalizer.normalize()`。改为输入框调用 `ref.read(urlNormalizerProvider).tryNormalize(text)` 判断是否为 URL 候选。

### 性能 / 基础设施

* **#11 Thoughts 全量统计** — `getRecentItems()` / `getPinnedItems()` / `getStat()` 均先 `getThoughts(archived: false)` 全量读取再内存过滤。DAO 增加 `countActive()`、`getRecent(limit:)`、`getPinned(limit:)` 方法，Repository/Plugin 改为调用 DAO 层边界查询。
* **#12 Thoughts 缺索引** — `thoughts_table` 无索引。加迁移：`idx_thoughts_archive_pinned_created` (archived_at, is_pinned, created_at DESC) 和 `idx_thoughts_updated` (updated_at DESC)。
* **#13 schemaVersion 架构风险** — 当前 `AppDatabase.schemaVersion` 取所有插件 `schemaVersion` 最大值。本轮不改架构，但记录为已知风险到 spec。在 `AppDatabase` 注释中显式标注此设计决策。
* **#14 调试日志默认开启** — `CollectionDebugLogger.enabled` 默认 `true`，会打印 URL 等敏感信息。改为仅在 `kDebugMode` 下输出（或 `defaultValue: false`）。
* **#15 缺 CI** — 新增 `.github/workflows/ci.yml`：`flutter analyze` → `dart fix --dry-run` → `flutter test`。

## Acceptance Criteria

### 运行时 Bug
* [ ] #1: 点击卡片不触发 `CollectionsDesktopLayout.build()` 重建（通过 Flutter DevTools repaint 或 `debugPrint` 验证）
* [ ] #2: 切换选中卡片时 `_TagsSection` / `_BoxSection` 无 FutureBuilder 加载态，直接使用 `selectedSavedItemEntryProvider.boxes`
* [ ] #3: 进入收藏页时，数据异步返回后自动选中第一条，selectedId 不为 null
* [ ] #8: 点击"清空筛选"后搜索输入框文本也清空
* [ ] #10: `updateFirstParagraphText` 异常被 `FlutterError.reportError` 捕获，不为未处理 async error

### 功能缺口
* [ ] #4: 列表底部有"加载更多"按钮，点击后追加下一页数据（>50 条场景可验证）
* [ ] #5: 移动端宽度下 `CollectionsPage` 使用 mobile 布局；移动端底部导航有收藏入口
* [ ] #6: 侧栏 `/favorites` label 显示"星标"，插件注册的 nav entry label 显示"收藏库"
* [ ] #7: URL 输入在 dashboard quickCreate 中创建为收藏而非想法；普通文本仍创建为想法
* [ ] #9: 输入框 URL 判断与 `UrlNormalizer.tryNormalize` 结果一致

### 基础设施
* [ ] #11: `getRecentItems` / `getPinnedItems` / `getStat` 调用 DAO 层边界查询，不执行全表读取
* [ ] #12: `thoughts_table` 存在 `idx_thoughts_archive_pinned_created` 和 `idx_thoughts_updated` 索引
* [ ] #13: `AppDatabase` 代码注释标注 schemaVersion = max(插件 schemaVersion) 的设计决策
* [ ] #14: Release 模式下 `CollectionDebugLogger` 不输出日志
* [ ] #15: CI workflow 文件存在，`flutter analyze` + `dart fix --dry-run` + `flutter test` 可通过

### 整体
* [ ] `flutter analyze` 0 error 0 warning
* [ ] `dart fix --dry-run` Nothing to fix
* [ ] `flutter test` 通过（含新增测试）
* [ ] 针对性 focused tests 覆盖修改行为

## Definition of Done

* Tests added/updated where behavior changes
* Lint / static analysis green
* No database migration errors
* CI workflow 语法正确

## Technical Approach

按三类分组实现，按优先级顺序：

1. **Runtime bugs (#1, #2, #3, #8, #10)** — 无 schema 变更，纯 Widget/Provider 重构
2. **Feature gaps (#4, #5, #6, #7, #9)** — 含少量 schema 变更 (#7 加协议方法)
3. **Infrastructure (#11-15)** — schema 迁移 (#12)、CI 新增 (#15)、代码注释 (#13)

### 关键文件

| 文件 | 涉及问题 |
|------|----------|
| `lib/src/plugins/collections/ui/layouts/collections_desktop_layout.dart` | #1, #3 |
| `lib/src/plugins/collections/ui/widgets/saved_item_card.dart` | #1 |
| `lib/src/plugins/collections/ui/widgets/saved_item_detail_panel.dart` | #2, #10 |
| `lib/src/plugins/collections/ui/collections_page.dart` | #5 |
| `lib/src/plugins/collections/collections_plugin.dart` | #6, #7 |
| `lib/src/plugins/collections/providers/collections_providers.dart` | #4 |
| `lib/src/plugins/collections/ui/widgets/collection_capture_bar.dart` | #9 |
| `lib/src/plugins/collections/ui/widgets/collection_search_filter_bar.dart` | #8 |
| `lib/src/plugins/collections/services/collection_debug_logger.dart` | #14 |
| `lib/src/plugins/thoughts/thoughts_plugin.dart` | #7, #11 |
| `lib/src/plugins/thoughts/data/thoughts_repository.dart` | #11 |
| `lib/src/core/plugin/plugin_interface.dart` | #7 |
| `lib/src/core/plugin/plugin_registry.dart` | #7 |
| `lib/src/core/data/app_database.dart` | #12, #13 |
| `lib/src/shared/widgets/sidebar.dart` | #6 |
| `lib/src/core/app/mobile_shell.dart` | #5 |
| `lib/src/core/router/route_names.dart` | #5 |
| `.github/workflows/ci.yml` | #15 |

## Out of Scope

* Infinite scroll 替换"加载更多"按钮
* 收藏移动端完整布局（收藏夹侧栏、详情面板）
* schemaVersion 架构重构（插件隔离迁移）
* 完整 CI/CD pipeline（deploy、integration test 等）
