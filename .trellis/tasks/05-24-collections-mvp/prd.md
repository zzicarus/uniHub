# 实现 Collections MVP

## Goal

按照 `docs/unihub_collections_mvp_prd_architecture.md` 将 uniHub 的“收藏 / Collections”想法落地为插件化 MVP：支持 URL 快速收藏、本地持久化、基础元数据抓取、Inbox/Box/状态/来源/媒介筛选，并接入现有插件导航与数据库体系。

## What I already know

- 用户要求：按照 `docs/unihub_collections_mvp_prd_architecture.md` 实现想法。
- 项目是 Flutter + Riverpod + GoRouter + Drift(SQLite) 的桌面端优先插件架构。
- 新功能应作为 `lib/src/plugins/collections/` 插件实现，参考 `thoughts` 插件结构。
- PRD 文档已经拆出 Leaf 0–15+ 的单步任务，覆盖技术决策、插件骨架、domain、Drift 表、DAO/Repository、URL normalizer、platform detector、metadata provider、capture/enrichment service、providers、UI shell、捕获流程、列表、Box、筛选、状态切换等。
- MVP 明确不做：远程后端、浏览器插件、账号/同步、全文快照、截图/PDF、视频下载、微信公众号全文抓取、AI 摘要/标签、RSS、复杂批量导入、全文索引。

## Assumptions (temporary)

- 本任务先按本地后端化方案实现，不新增远程服务。
- 所有新增 PRD/指导说明按中文书写。
- 需要保持插件依赖方向：`plugins/ → shared/ → core/`，跨层使用 `package:` 路径。
- 数据库 schema 变更需要遵循 Drift/插件表注册规范，并同步生成代码。

## Requirements (evolving)

- 新增 Collections 插件并注册到现有插件系统与导航。
- 新增 domain 枚举/模型：媒介类型、来源平台、消费状态、抓取状态、平台识别结果、捕获结果等。
- 新增 Drift 表：`saved_items`、`collection_boxes`、`saved_item_boxes`、`enrichment_jobs`。
- 新增 DAO/Repository，支持 URL 去重、创建收藏、更新元数据/状态/Inbox、设置 Box、多维查询、任务入队/更新。
- 新增 URL normalizer 与 platform detector。
- 新增本地 metadata provider 抽象与实现，为未来远程 provider 预留替换点。
- 新增捕获服务与 enrichment job 服务，实现 URL 收藏与异步抓取流程。
- 新增 Riverpod providers，串联 DAO/Repository/services/UI filters/list。
- 新增 Collections 首页 UI：标题、URL 输入、系统视图、Box 区域、筛选栏、收藏卡片列表、状态/打开链接操作。
- 记录打开时间 `lastOpenedAt`，状态完成/归档时记录对应时间。

## Acceptance Criteria (evolving)

- [x] 应用中可看到“收藏”入口，并可打开 Collections 页面。
- [x] 输入 URL 后可以创建收藏项；重复 URL 通过 normalized URL 去重。
- [x] 收藏项保存到本地 SQLite，并在重启后仍可查询。
- [x] 基础 metadata 抓取状态可展示 pending/running/success/failed。
- [x] 列表可按 Inbox、Box、状态、来源平台、媒介类型、搜索词筛选。
- [x] 收藏项可打开原链接并记录 `lastOpenedAt`。
- [x] 收藏项可在未看 / 进行中 / 已看 / 归档之间切换。
- [x] `flutter analyze` 通过；新增/相关测试通过。

## Definition of Done

- Tests added/updated（DAO/Repository/service/provider/widget 视实际实现范围补齐）。
- `dart run build_runner build --delete-conflicting-outputs` 后生成代码一致。
- `flutter analyze` 0 error / 0 warning。
- 目标测试通过。
- 若产生可复用约定或踩坑，更新 `.trellis/spec/` 或任务记录。

## Out of Scope

- 独立远程后端、账号系统、多设备同步。
- 浏览器插件、复杂批量导入、RSS 定时抓取。
- 网页全文快照/截图/PDF、视频下载、微信公众号全文抓取。
- AI 摘要、AI 自动标签、全文索引。
- 复杂详情页与高级阅读器体验。

## Technical Approach (draft)

- 以 `lib/src/plugins/collections/` 作为插件根目录，沿用 `thoughts` 的 `data/ providers/ ui/` 分层，并补充 `domain/ services/`。
- 数据层使用 Drift 表 + DAO + Repository，插件通过 `UniHubPlugin.tables` 声明表，同时同步 `AppDatabase` 集中注册。
- UI 使用 Riverpod provider 组合 filters 与列表查询；组件遵循 Material 3、`app_tokens.dart`、响应式断点规范。
- Metadata 抓取先本地实现，抽象 `MetadataProvider` 以便未来替换为远程后端。

## Decision (ADR-lite)

**Context**: 源文档覆盖完整 Collections MVP，涉及插件、数据库、服务、Provider、UI 与测试，单次全量实现风险较高。

**Decision**: 采用“分阶段闭环”推进。首批目标先实现可运行的基础闭环：插件入口、核心 schema/DAO/Repository、URL 收藏、基础列表 UI 与关键测试；随后再逐步补齐 metadata、Box、筛选与状态增强。

**Consequences**: 首轮交付更容易验证和回滚，但完整 MVP 会拆成多个增量；首批实现需要保留 service/provider 抽象，避免后续补功能时重构。

## Open Questions

- 暂无阻塞问题；实现中若发现需要扩大数据库迁移或路由范围，会先暂停确认。

## Implementation Notes

### Phase 1 基础闭环（已实现）

- 新增 `CollectionsPlugin`，注册 `/collections` 路由与侧栏入口。
- 新增 `saved_items`、`collection_boxes`、`saved_item_boxes`、`enrichment_jobs` Drift 表，并更新 `AppDatabase` schemaVersion 3 迁移。
- 新增 domain 枚举/模型、URL normalizer、platform detector。
- 新增 DAO、Repository、capture service、metadata provider 抽象、本地 metadata provider、enrichment service 与 Riverpod providers。
- 新增 Collections 首页基础 UI：URL 输入、视图/状态/来源/媒介/Box/搜索筛选、列表卡片、状态切换、打开原链接并记录 `lastOpenedAt`。
- URL 收藏成功后触发后台 metadata enrichment；`LocalMetadataProvider` 由 Provider 生命周期关闭 `HttpClient`。
- 错误态补齐可恢复的“重试”按钮。
- 新增 Collections domain/data/service 测试，并补充 route name 断言。

### Validation

- `dart run build_runner build --delete-conflicting-outputs`：通过，已生成 `app_database.g.dart`。
- `flutter analyze`：通过。
- `dart fix --dry-run`：Nothing to fix。
- Focused tests：`flutter test test/plugins/collections test/core/database/database_test.dart test/core/router/route_names_test.dart test/core/router/app_router_test.dart` 通过（20 tests passed）。
- Check agent 已复核并修复 in-scope 问题；复跑 `flutter analyze`、`dart fix --dry-run`、focused tests 均通过。
- Full `flutter test`：仍失败在既有 Thoughts provider/UI 测试（搜索/筛选/card 期望）。本任务未修改 `lib/src/plugins/thoughts/**` 或 `test/plugins/thoughts/**`，focused Collections/Core 验证通过；若要纳入需扩大范围到 Thoughts 测试/实现修复。

## Technical Notes

- 源文档：`docs/unihub_collections_mvp_prd_architecture.md`
- 任务目录：`.trellis/tasks/05-24-collections-mvp/`
- 需要遵循：`AGENTS.md`、`.trellis/workflow.md`、`.trellis/spec/backend/*`、`.trellis/spec/frontend/*`、`test/AGENTS.md`
- 已确认前置清单：backend/frontend spec index、插件系统 AGENTS、thoughts 插件 AGENTS、测试 AGENTS。
