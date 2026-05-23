# PRD: Thoughts 完整标签系统接入

## 目标

完成 Thoughts 页面的标签系统全线接入，确保共享标签 Widget 在桌面端和移动端一致使用，同时增强标签输入体验（校验 + 自动补全），清理已废弃的旧代码。

## 范围（4 个子项）

### 1. 清理遗留废代码

**内容**：删除 `thought_more_tags_popover.dart` 中不再被引用的 `ThoughtMoreTagsPopover`。

**验证**：`grep -rn "ThoughtMoreTagsPopover" lib/ test/` 只能返回定义文件自身，且 `flutter analyze` 通过。

### 2. 移动端标签 Widget 接入共享体系

**方案**：轻量替换，保留当前移动端布局结构，只将内部 Widget 替换为共享组件。

| 位置 | 旧 Widget | 新 Widget |
|------|-----------|-----------|
| `_TagChip`（`_MobileFilterChips` 内） | `ThoughtFilterChip` | `AppTagChip` |
| `_MoreTagsButton` | `ThoughtFilterChip` | `AppMoreTagsButton` |
| `_SelectedTagBanner` | 原始 `Chip` | `AppSelectedTagsBar`（或 inline 用 `AppSelectedTagChip`） |
| 底部弹出层（`_showTagsBottomSheet`） | `ThoughtFilterChip` | `AppTagChip`（并考虑整合 `AppMoreTagsPopoverContent`） |

### 3. 前端标签校验接入

**内容**：在 `ThoughtComposerController.handleTagInput()` 和 `ThoughtEditorController.handleTagInput()` 中调用 `TagCodec.validate()`，对无效标签给出提示。

**需要改动**：
- `ThoughtComposerController` — validate 后过滤无效标签，对无效标签不添加
- `ThoughtEditorController` — 同上
- 若需要 UI 反馈，在对应 Widget 中显示验证错误（可选，优先级低于核心校验逻辑）

### 4. 标签输入自动补全

**内容**：在创作者 QuickComposer 和编辑器 Editor 的标签输入框下方，输入时显示已有标签候选列表。

**需要改动**：
- 读取 `commonTagsProvider` 或 `tagStatsProvider` 获得已有标签列表
- 在 `ThoughtComposerController` + `ThoughtEditorController` 中提供搜索匹配逻辑
- UI 侧：在 `ThoughtsEditorPage` 和 `ThoughtComposer` 的标签输入框下方加一个候选列表 overlay

## 依赖

- 共享标签系统已提取完成（`shared/tags/` + `shared/widgets/tags/`）
- Thoughts providers 已使用 `TagCodec` / `TagFilterLogic`

## 约束

- 不改数据库 schema
- 不改 DAO / Repository
- 不改 desktop filter panel（已使用共享 Widget）
- 不改 `ThoughtFilterChip` 类（仍在 status chip 中使用）
