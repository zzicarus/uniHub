# 修复文档与低风险一致性问题

## Goal

修复用户指出的问题中第一轮低风险且具备明确收益的部分，减少 README / pubspec / 启动流程 / 收藏业务逻辑与真实实现之间的不一致，提升后续 agent 与开发者接手时的可信度和安全性。

## What I already know

* README 当前声明状态管理为 `flutter_riverpod + riverpod_annotation`，但 `pubspec.yaml` 仅包含 `flutter_riverpod`。
* README 当前声明 Flutter / Dart 版本要求与 `pubspec.yaml` 的 `environment.sdk: ^3.11.5` 不一致。
* `pubspec.yaml` 的 description 仍是模板文本 `A new Flutter project.`。
* `lib/main.dart` 当前在 `runApp()` 前直接 `await registry.initAll()`，插件初始化失败会阻止应用进入 UI。
* `PluginRegistry.register()` 当前只是追加插件，缺少插件 ID / route / nav entry / table 等重复检测。
* Collections 插件存在多个低风险正确性问题：LIKE 搜索通配符未转义、打开收藏先写 DB 再 launch、状态恢复时 `archivedAt` 可能残留、收藏夹名称校验主要在 UI 层。
* 本轮不处理结构性优化：Thoughts 分页 DAO、Dashboard 统计 DAO 化、收藏无限滚动、QuickCreate intent 协议、URL 识别统一、归档过滤状态源合并。

## Assumptions

* 用户回复“继续”视为同意按上一轮建议先做“第一轮低风险修正”。
* README 应以当前 `pubspec.yaml` 为准，而不是引入未使用的 `riverpod_annotation` / generator。
* 启动失败兜底以“不崩溃 + 清晰错误提示 + 保留调试日志”为目标，不在本轮实现完整错误日志面板。
* 插件注册冲突检测优先在 debug/test 中快速暴露问题；如实现成本低，可同时提供 release 下可读异常。

## Requirements

* 更新 README，使状态管理与真实依赖一致，版本要求与 `pubspec.yaml` 一致。
* 更新 `pubspec.yaml` description 为：`A local-first personal toolbox for thoughts, collections, and tasks.`
* 为插件初始化增加失败兜底：捕获 `registry.initAll()` 异常，记录错误和堆栈，并让应用仍能进入一个可见的错误状态。
* 为 `PluginRegistry.register()` 增加重复/冲突检测，至少覆盖插件 ID；优先覆盖 route path/name、nav entry path/label、table type。
* 修复收藏搜索 LIKE 关键字中 `%` / `_` / `\` 的转义问题。
* 修复收藏打开流程：只有 URL 校验并成功 launch 后才更新 `lastOpenedAt` 并刷新列表。
* 修复 `updateStatus()`：从 archived 恢复到其他状态时清理 `archivedAt`；unread 时清理 `completedAt`。
* 在 Repository 层统一校验收藏夹名称：非空、最大长度、防重复，并返回清晰错误。
* 为新增/修改行为补充或更新 focused tests。

## Acceptance Criteria

* [x] README 不再提及未使用的 `riverpod_annotation` / `riverpod_generator`。
* [x] README 的 Flutter / Dart 要求与 `pubspec.yaml` 约束一致或明确以 `pubspec.yaml` 为准。
* [x] `pubspec.yaml` description 不再是 Flutter 模板残留。
* [x] 插件初始化失败不会导致 `runApp()` 前崩溃；UI 有可见 fallback。
* [x] 重复插件 ID / route / nav / table 注册在测试中能被检测出来。
* [x] 搜索 `%` 和 `_` 时不再作为 SQL LIKE 通配符扩大匹配范围。
* [x] 打开 URL 失败时不会写入 `lastOpenedAt`。
* [x] 收藏从 archived 状态恢复后 `archivedAt` 为 null。
* [x] 收藏夹空名、超长名、重复名在 Repository 层被拒绝。
* [x] `flutter analyze` 通过。
* [x] 相关 focused tests 通过。

## Definition of Done

* Tests added/updated where behavior changes.
* Lint / static analysis green.
* Docs updated when metadata or documented requirements change.
* No database schema migration unless required by implementation.
* Structural performance items explicitly left for later tasks.

## Verification Notes

* `flutter analyze`：通过。
* Focused tests：通过（core database/app/plugin + collections DAO/Repository/ActionController/widgets）。
* `dart fix --dry-run`：Nothing to fix。
* `git diff --check`：通过。
* 完整 `flutter test`：通过。
* `website_logo_cache_service_test.dart` 已按当前服务合同更新：debug 下 failed cache 会立即重试，data/file remote favicon URL 会被拒绝后继续尝试安全 host fallback。

## Out of Scope

* Thoughts 数据库索引、分页 DAO、搜索迁移到 DAO 层。
* Dashboard 统计从全表读取改为 DAO 聚合。
* 收藏真正的分页 / 无限滚动 / 加载更多。
* QuickCreate 协议升级为 intent / canHandle。
* URL 捕获输入统一到 `UrlNormalizer`。
* 移除 `archiveFilterProvider` 与 `thoughtStatusFilterProvider` 双状态源。
* 完整启动错误日志面板或崩溃恢复系统。

## Technical Approach

1. 文档与元数据先改：README 与 `pubspec.yaml`。
2. 核心启动与插件注册：在 `main.dart` / `core/app` / `core/plugin` 增加最小 fallback 和冲突检测，并补充插件注册测试。
3. Collections 低风险修复：DAO LIKE 转义、ActionController 打开顺序、Repository/DAO 状态与 Box 校验。
4. 运行 focused tests，再运行 `flutter analyze`。

## Technical Notes

* 已读取：`AGENTS.md`、`.trellis/workflow.md` 关键流程、`lib/src/core/AGENTS.md`、`lib/src/core/plugin/AGENTS.md`、`lib/src/plugins/collections/AGENTS.md`、`test/AGENTS.md`。
* 可能涉及文件：
  * `README.md`
  * `pubspec.yaml`
  * `lib/main.dart`
  * `lib/src/core/app/app.dart` 或新增启动错误 Widget
  * `lib/src/core/plugin/plugin_registry.dart`
  * `lib/src/core/plugin/plugin_interface.dart`（仅当需要读取 route/name/nav/table 类型）
  * `lib/src/plugins/collections/data/**`
  * `lib/src/plugins/collections/application/saved_item_actions_controller.dart`
  * `test/src/core/plugin/plugin_registry_test.dart`
  * `test/plugins/collections/**` 或对应现有测试文件
