# Collections MVP 剩余缺口关闭

## Goal

关闭 Collections 插件 MVP 阶段的剩余缺口，补齐 Box-Inbox 联动和缺失测试覆盖，使插件达到可交付质量。

## What I already know

- Collections 插件的 MVP 基础闭环已实现（commit `8305954`），包括：数据库表、所有枚举值、CRUD DAO/Repository、Capture/Enrichment 服务、完整 UI（列表/筛选/捕获栏）。
- 语义修复 + job queue + 枚举补全已在 commit `d1228d9` 完成。
- 已有 5 个测试文件：Repository、PlatformDetector、UrlNormalizer、CaptureService、EnrichmentJobService。

## Decisions (ADR-lite)

### Box-Inbox 联动

**捕获栏添加 Box 选择器**：捕获时通过下拉框选择目标 Box（可选），选择了 Box 则该 item `isInInbox=false`（移出 Inbox 归入 Box）；未选择则默认 `isInInbox=true`（留在 Inbox）。

**卡片 PopupMenu 分配 Box**：在 SavedItemCard 上通过 PopupMenu 选择/取消 Box 分配。轻量交互，无需弹窗。

### 字段补充

`extractedText` 和 `summary` 列为未来 AI 摘要 / 全文搜索预留，当前 MVP 不填充，标记为 Out of Scope。

## Requirements

* [ ] 捕获栏添加 Box 下拉选择器
* [ ] 捕获时选 Box → `isInInbox=false`；不选 → `isInInbox=true`
* [ ] SavedItemCard 通过 PopupMenu 分配/移出 Box
* [ ] 测试补充：DAO 测试（CollectionBoxesDao、SavedItemsDao）、Widget 测试（CaptureBar、SavedItemCard）

## Acceptance Criteria

* [ ] 捕获栏显示 Box 选择器（仅在有可用 Box 时显示）
* [ ] 选择 Box 后捕获，item 的 isInInbox=false 且关联到该 Box
* [ ] 未选择 Box 捕获，item 的 isInInbox=true（默认行为）
* [ ] SavedItemCard 可以分配到已有 Box 或移出
* [ ] `flutter analyze` 0 error 0 warning
* [ ] 新增测试全部通过
* [ ] 现有测试不退化

## Definition of Done

- Box-Inbox 联动功能已实现（捕获栏 + 卡片）
- 测试已新增/更新（DAO + UI widget）
- Lint / typecheck 绿色

## Out of Scope

* 不新增数据库表或 migration
* 不改 enrichment_jobs 队列流程（已完成）
* 不改枚举值（已完成）
* 不改路由/插件注册
* `extractedText` 和 `summary` 字段暂不填充

## Technical Notes

### 代码结构
- `lib/src/plugins/collections/` — 21 个 dart 文件
- `test/plugins/collections/` — 5 个测试文件
- 表定义在 `lib/src/core/database/tables/`

### 关键决策
- 捕获时选 Box → `isInInbox=false`
- 捕获时不选 Box → `isInInbox=true`
- `CollectionCaptureBar` 是 ConsumerStatefulWidget，需添加 async Box 加载和选择
- `SavedItemCard` 是 ConsumerWidget，需添加 Box 管理 PopupMenu
- `CollectionsRepository.updateInboxState` 和 `setItemBoxes` 已存在，可直接复用
- `CollectionsRepository.createSavedItem` 需扩展支持从外部传入 `isInInbox`

### 实现计划
1. **CaptureBar 添加 Box 选择器**：加载可用 Box，捕获时传入选中的 boxId
2. **Repository 扩展**：createSavedItem 支持 `isInInbox` 参数
3. **SavedItemCard 添加 Box 管理**：PopupMenu 中列出已有 Box，勾选/取消
4. **DAO 测试**：CollectionBoxesDao、SavedItemsDao
5. **Widget 测试**：CollectionCaptureBar、SavedItemCard
