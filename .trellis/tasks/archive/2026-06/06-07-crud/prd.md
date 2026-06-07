# uniHub 全局 CRUD 边界条件与反馈系统

## Goal

建立一套全局一致、可复用、可测试的 CRUD 边界条件处理、用户反馈、删除撤销、冲突处理与软刷新机制，优先收敛 Collections 与 Thoughts 两条核心业务线，并为后续 Notes / Todos / Calendar / Storage / 新插件提供统一工程框架。

## What I already know

- 用户提供了完整 PRD 草案，目标覆盖：Collections、Thoughts、Tags、Collection Boxes、Notes、Todos、Calendar、Storage 与后续插件。
- 核心问题是当前 CRUD 反馈与刷新分散：`SnackBar` / `showSnackBar` / 私有 `_showUndoSnackBar`、错误字符串、刷新散落、重名与关联删除策略不统一。
- 当前代码中已经存在 `lib/src/shared/widgets/app_toast.dart`：
  - 右下角/底部浮动 `SnackBarBehavior.floating` 实现。
  - 默认 5 秒。
  - 支持 `AppToastType` 与 `AppToast.undo()`。
  - 新 Toast 会 `hideCurrentSnackBar()` 后替换旧 Toast。
- 当前代码中尚未发现 `CrudResult`、`AppFailure`、`CrudFeedbackCoordinator`、`CrudMutationEvent` 等全局 CRUD 模型。
- `rg "SnackBar\(|showSnackBar|ScaffoldMessenger" lib test` 当前仍有约 33 处命中，其中业务遗留主要集中在：
  - `lib/src/plugins/collections/ui/widgets/saved_item_card.dart`
  - `lib/src/plugins/collections/ui/widgets/saved_item_detail_panel.dart`
  - `lib/src/plugins/collections/ui/widgets/collection_bulk_action_bar.dart`
  - `lib/src/core/storage/ui/storage_management_page.dart`
  - `lib/src/plugins/collections/AGENTS.md` 中仍保留旧用法示例。
- Collections 已有 `SavedItemActionResult` / `SavedItemUndoAction`，可作为迁移到通用 `CrudResult` 的桥接起点。
- Collections 已有 `SavedItemActionsController`，当前约定 UI 通过 controller 执行业务操作，但 controller 仍以 `message + undo + error` 返回，尚未区分 `duplicate`、`referenced`、`database` 等结构化错误。
- Thoughts 已有共享标签系统：`TagCodec`、`AppTagInput`、`TagFilterLogic`；标签校验与错误提示已经部分存在，但最大长度等规则需与本 PRD 统一。
- 项目强制要求所有新增/修改 UI 遵守 `.trellis/spec/frontend/component-guidelines.md` 的 Typography 规则：使用 `Theme.of(context).textTheme.*`、字重用 `AppFontTokens`、禁止 Widget 层直接写 `fontFamily` / 裸 `fontSize` / `FontWeight.wXXX`。

## Requirements

### R1. 全局实体与策略模型

- 新增共享 CRUD 实体枚举与策略配置，至少覆盖：
  - `thought`
  - `savedItem`
  - `collectionBox`
  - `tag`
  - `note`
  - `todo`
  - `calendarEvent`
  - `attachment`
  - `themeProject`
  - `storageItem`
- 新增 `NameUniqueScope` 与 `CrudEntityPolicy`，用于定义名称唯一范围、软删除、撤销、删除确认、合并能力。
- MVP 内优先让 `savedItem`、`collectionBox`、`tag`、`thought` 有明确默认策略。

### R2. 统一结果模型

- 新增 `AppFailureCode` / `AppFailure`，将 validation、duplicate、notFound、conflict、referenced、permissionDenied、network、fileSystem、database、cancelled、unknown 等错误结构化。
- 新增 `CrudResult<T>`，统一承载：
  - 成功/失败状态
  - 数据
  - 用户文案
  - 结构化失败
  - undo action
  - side effects
- 新增 `BatchCrudResult<T>`，支持批量操作全部成功、全部失败、部分成功。
- Collections 现有 `SavedItemActionResult` 必须在五阶段完成时完全替换并删除；允许实现中短期使用 adapter 过渡，但最终 Controller/UI 对外统一使用 `CrudResult`。

### R3. 全局反馈组件与使用边界

- `AppToast` 已存在，本任务不再视为“从零新增”，而是确认/补齐其接口与测试：
  - 支持 `actionLabel` / `onAction` 的通用 action Toast（当前仅 `_show` 内部支持，公开 `show()` 尚未暴露）。
  - 保持 `undo()` 默认文案为「撤销」。
  - 桌面宽度约 420px，窄屏自适应。
  - 默认 5 秒。
  - 新 Toast 替换旧 Toast。
- 新增或统一 `AppConfirmDialog`：用于永久删除、批量删除、有关联数据删除、覆盖、合并等危险操作。
- 新增 `AppConflictDialog`：用于重复名称、合并、覆盖、并发冲突、删除引用关系处理。
- 业务代码禁止直接创建 `SnackBar`、调用 `ScaffoldMessenger.showSnackBar` 或直接创建原生 `AlertDialog`；验收时业务层引用必须清零，例外仅限共享底层组件内部。

### R4. 全局边界条件规范

- 创建/重命名时对非法输入优先使用 Inline Field Error：为空、过长、非法字符、URL 格式错误等。
- 对名称重复默认不自动创建重复项：
  - 收藏夹：同级不可重名。
  - 标签：全局归一后不可重名。
  - 主题/笔记：按对应策略限制。
- URL 已收藏时不重复创建 `SavedItem`，而是定位/选中已有项；当前筛选不包含时提供 Toast action「查看」。
- 普通软删除应：UI 立即移除、显示 Undo Toast、撤销后恢复列表/详情/计数。
- 删除存在关联数据的实体必须按策略处理：禁止删除、解除关联、迁移、合并或软删除，必要时二次确认。
- 永久删除、清空回收站、批量删除、合并、覆盖必须二次确认，且永久删除不可撤销。
- 批量操作必须支持部分成功摘要与详情。
- 数据库/文件/网络技术错误不得直接展示技术异常信息；用户侧显示可理解文案，debug 日志记录技术细节。

### R5. NameNormalizer 与标签/收藏夹规则

- 新增 `NameNormalizer`：trim、多空白合并、大小写归一。
- 标签规则需要与现有 `TagCodec` 对齐并统一：
  - 不允许空、空格、换行、仅 `#`。
  - 允许中文、英文、数字、下划线、短横线。
  - 最大长度统一为 24 字符（已决策）；需同步调整 `TagCodec`、输入文案与测试。
- 收藏夹名称：不能为空、不能只包含空白、同级不可重名、第一阶段不允许 `/`、最大 30 字符。

### R6. CrudFeedbackCoordinator

- 新增 `CrudFeedbackCoordinator` 与 provider。
- UI 层只负责：
  - 调用 controller/repository 操作。
  - 表单内展示字段错误。
  - 把 `CrudResult` 交给 coordinator。
  - 执行页面级动作（选中、关闭、清空选择等）。
- Coordinator 根据 `CrudResult`：
  - 成功 + undo → `AppToast.undo()`。
  - 成功 + message → success toast（可 suppress）。
  - validation / duplicate → 表单已处理则静默，否则 info toast。
  - conflict / referenced → warning toast 或后续引导到 dialog。
  - database / network / fileSystem / permission 等 → error toast。

### R7. 分层责任

- DAO：只负责数据库访问，不负责用户文案。
- Repository：负责业务一致性与可预测业务异常，如重名、引用关系、唯一约束、允许删除/恢复。
- Controller：负责将业务异常或技术异常转换成 `CrudResult`，并触发 mutation event。
- UI：不解释异常，不拼接技术错误，仅展示表单错误、调用 coordinator 和执行页面级动作。

### R8. 收藏夹 CRUD 边界

- 创建收藏夹：空名、过长、同级重名使用 Inline Error；成功后列表插入，可选中新收藏夹，Toast `已创建收藏夹「xxx」`。
- 重命名收藏夹：空名、与原名一致、同级重名、已不存在、冲突需分别处理。
- 删除收藏夹：
  - 无内容：确认后删除，Undo Toast。
  - 有内容：确认文案需说明“删除收藏夹不会删除内容，内容会回到待整理”。
  - 成功文案包含移回待整理数量。

### R9. 标签 CRUD 边界

- 创建标签：空、空格、过长、非法字符、归一后重复都使用 Inline Error。
- 添加已存在标签到想法时直接使用已有标签，不提示。
- 删除未使用标签：Undo Toast。
- 删除被使用标签：提示引用数量，并提供取消、合并、移除标签。
- 合并标签：必须确认；成功后提供 Undo。

### R10. SavedItem CRUD 边界

- 新增收藏时 URL 已存在不重复创建，定位已有内容。
- URL 无效使用 Inline Error。
- 抓取失败可允许创建成功，状态为 failed，并提示 `已收藏，信息抓取失败` + 重试。
- 修改状态应局部即时变化；若不符合当前筛选，卡片立即从列表移除；成功默认不 Toast。
- 删除内容后：列表立即移除、详情切换下一条或清空、Undo 后恢复列表/详情/计数。

### R11. Thought CRUD 边界

- 空内容且无图片时，记录按钮 disabled。
- 只有标签第一阶段不允许，显示 `请输入想法内容`。
- 创建成功可不 Toast，优先列表插入并轻微高亮；如果提示，使用 `已记录想法`。
- 删除想法：卡片立即移除，Toast `已删除想法` + 撤销，详情编辑器关闭或显示已删除状态。

### R12. 全局 Mutation Pipeline

- 新增 `CrudMutationEvent`：Created / Changed / Deleted / Restored / Merged。
- 新增 `CrudMutationState` 与 `crudMutationProvider`。
- Controller 在成功 mutation 后 emit event。
- List / Detail / Count / Selection 等 provider 或 controller 监听 event 后优先做局部 patch。
- 禁止每次 CRUD 都整页 refresh；`ref.invalidate` 可在过渡期保留，但需要逐步替换。

## Acceptance Criteria

### 全局反馈

- [ ] `AppToast.show()` 支持最多 1 个 action。
- [ ] `AppToast.undo()` 默认 5 秒，文案动作统一为「撤销」。
- [ ] 业务代码中的直接 `SnackBar(` / `showSnackBar` / `ScaffoldMessenger` 使用全部清零；仅允许 `AppToast` 等共享底层组件内部保留。
- [ ] 删除/移除类反馈统一使用右下角浮动 Toast，不再出现底部整条 Snackbar。
- [ ] `AppConfirmDialog` / `AppConflictDialog` 新增并有基础 widget test。

### 统一结果模型

- [ ] `AppFailure`、`CrudResult`、`BatchCrudResult` 新增并有 unit test。
- [ ] `CrudFeedbackCoordinator` 新增并可根据成功、失败、undo、字段错误处理策略选择反馈。
- [ ] 至少 Collections 的一个真实 mutation flow 接入 `CrudResult` 或通过 adapter 接入 coordinator。

### 重名与输入边界

- [ ] 收藏夹创建同级重名时不创建重复项，并返回/显示字段错误。
- [ ] 收藏夹重命名为同级已存在名称时不保存，并返回/显示字段错误。
- [ ] 标签创建非法字符、空格、过长、归一重复时不创建，并返回/显示字段错误。

### 删除边界

- [ ] 删除空收藏夹支持撤销。
- [ ] 删除有内容收藏夹前显示确认，并说明内容回到待整理。
- [ ] 删除被使用标签时不直接删除，提示移除或合并。
- [ ] 永久删除必须二次确认，且不提供 undo。
- [ ] 批量操作部分失败时能表示 partial success。

### Mutation / 软刷新

- [ ] 新建后列表立即插入或局部刷新。
- [ ] 更新后卡片、详情、计数同步变化。
- [ ] 删除后卡片立即消失，详情不显示已删除旧数据。
- [ ] 撤销后卡片与计数恢复。
- [ ] 修改状态后若不符合当前筛选，立即从当前列表移除。

## Definition of Done

- [ ] 任务 PRD 已与用户确认 MVP 边界。
- [ ] `implement.jsonl` / `check.jsonl` 已 curated，不只保留 seed `_example`。
- [ ] 新增或修改的 UI 遵守 Typography 规范。
- [ ] 覆盖新增模型、反馈协调器、关键 CRUD 边界的单元/Widget 测试。
- [ ] `flutter analyze` 0 error / 0 warning。
- [ ] 目标测试通过。
- [ ] 如新增工程约定，更新 `.trellis/spec/` 或相关 `AGENTS.md`。

## Technical Approach

建议采用“先搭骨架、再迁移真实链路、最后扩散”的渐进方案：

1. **PR1：共享反馈与结果模型骨架**
   - 补齐 `AppToast` action API 与测试。
   - 新增 `AppFailure`、`CrudResult`、`BatchCrudResult`、`CrudEntityPolicy`、`NameNormalizer`。
   - 新增 `CrudFeedbackCoordinator` 与 provider。
   - 新增 `AppConfirmDialog` / `AppConflictDialog` 基础实现。

2. **PR2：Collections SavedItem 删除/状态链路接入**
   - 先以 `SavedItemActionResult -> CrudResult` adapter 迁移 UI 反馈，减少大爆炸重构。
   - 清理 `saved_item_card.dart`、`saved_item_detail_panel.dart`、`collection_bulk_action_bar.dart` 的私有 `_showUndoSnackBar` / `_showSnackBar`。
   - 保留现有 controller 能力，逐步将返回类型迁移到通用模型。

3. **PR3：收藏夹与标签边界处理**
   - 收藏夹创建/重命名/删除关联内容边界。
   - 标签创建/删除/合并边界。
   - 与现有 `TagCodec`、共享 tag widgets 对齐。

4. **PR4：Mutation Pipeline**
   - 新增 mutation event/provider。
   - Collections / Thoughts 先接入核心场景。
   - 将散落 `ref.invalidate` 标注并逐步替换为局部 patch。

5. **PR5：批量与存储管理扩展**
   - 批量结果详情。
   - Storage 破坏性操作确认与反馈统一。
   - 补足跨模块验收测试。

## Decision (ADR-lite)

### D1. MVP 范围

**Context**：用户希望本任务作为全局 CRUD 边界条件与反馈系统的一次完整工程改造，而不是只落地基础骨架。

**Decision**：第一轮 MVP 覆盖用户原始 PRD 的五个 Phase：

1. 全局反馈收敛。
2. 统一结果模型。
3. 收藏夹与标签边界处理。
4. Mutation Pipeline。
5. 测试补充。

**Consequences**：

- 优点：一次性建立完整标准，减少后续模块继续沿用旧反馈/刷新方式的窗口期。
- 风险：改动面大，涉及 shared、core storage、Collections、Thoughts、测试与规范文档，必须按小步提交/可回滚实现。
- 约束：即使范围覆盖五阶段，执行仍应按 PR1–PR5 的顺序渐进推进，每个阶段都要保持可分析、可测试、可回退。

### D2. 迁移策略

**Context**：当前已有 `AppToast` 与 Collections `SavedItemActionResult`，但尚无通用 `CrudResult`/`AppFailure`/Mutation Pipeline。

**Decision**：采用“共享模型先行 + 过程中允许 adapter 过渡 + 验收前完全替换删除”的策略。五阶段完成时，Collections 核心 CRUD 不再保留 `SavedItemActionResult`，Controller/UI 对外统一使用 `CrudResult`。

**Consequences**：

- 优点：最终模型干净，避免长期双结果模型带来的认知和测试成本。
- 风险：Collections 改动面更大，必须先补全 `CrudResult` 测试，再迁移 SavedItem 操作链路。
- 执行约束：如中途临时引入 adapter，必须在最终验收前删除 adapter 或仅保留通用、非业务私有的转换工具。

### D3. 标签长度

**Context**：用户 PRD 草案要求标签最多 24 个字符；当前代码中的 `TagCodec` 可能已有 20 字符限制。

**Decision**：统一采用 24 字符作为全局标签最大长度。

**Consequences**：

- 需要更新 `TagCodec`、标签输入文案、Thoughts 标签测试与新增 CRUD 边界测试。
- 标签重复判断仍以 normalize 后结果为准。

### D4. SnackBar 清零边界

**Context**：当前 `SnackBar` / `showSnackBar` 遗留引用不仅存在于 Collections/Thoughts，也存在于 Storage 等页面；如果只清核心模块，用户体验仍不统一。

**Decision**：本任务验收时要求业务层 `SnackBar` / `showSnackBar` / `ScaffoldMessenger` 引用全部清零，仅允许 `AppToast` 等共享底层组件内部使用 Flutter 原生 `SnackBar` 实现。

**Consequences**：

- Storage 等非核心页面也纳入本任务反馈迁移范围。
- `rg "SnackBar\\(|showSnackBar|ScaffoldMessenger" lib` 必须作为验收命令之一；结果应只剩共享底层组件内部或文档中明确允许的示例。

## Open Questions

- 无。当前 PRD 已完成 MVP 范围、标签长度、结果模型迁移与 SnackBar 边界决策。

## Out of Scope

- 不在本任务内实现 Notes / Todos / Calendar 的完整业务 CRUD，仅提供未来接入所需实体策略与通用模型。
- 不在本任务内实现真实多窗口/同步冲突检测的数据层能力；本任务只建立 `conflict` 失败模型与 UI 处理入口，除非现有实体已具备 revision 字段。
- 不在本任务内做大规模数据库 schema 变更，除非收藏夹/标签边界必须依赖唯一索引且经用户确认。
- 不在本任务内引入新的第三方状态管理或反馈库。

## Technical Notes

- 任务目录：`.trellis/tasks/06-07-crud/`
- 已检查文件：
  - `lib/src/shared/widgets/app_toast.dart`
  - `lib/src/AGENTS.md`
  - `lib/src/plugins/collections/AGENTS.md`
  - `lib/src/plugins/thoughts/AGENTS.md`
- 相关规范：
  - `.trellis/workflow.md`
  - `.trellis/spec/frontend/component-guidelines.md`
  - `.trellis/spec/backend/database-guidelines.md`
  - `test/AGENTS.md`
- 当前代码事实：
  - `AppToast` 已存在，PRD 需从“新增 AppToast”调整为“补齐/统一使用 AppToast”。
  - `CrudResult` / `AppFailure` / `CrudMutationEvent` 尚未存在。
  - Collections 已有 `SavedItemActionResult`，可作为迁移桥梁。
  - Thoughts 已有 `TagCodec`，不要重复发明标签校验体系，应先对齐扩展。
