# 收藏删除确认弹窗 UI 改造

## 目标

当前删除弹窗过于简陋（标准 AlertDialog + "确认删除" + 蓝色按钮），需要改成正式产品级 destructive dialog。

## 范围

| 维度 | 内容 |
|------|------|
| 涉及模块 | `lib/src/plugins/collections/`（UI widgets + providers）、`lib/src/shared/`（新建 preferences + delete dialog 组件） |
| 禁止改动 | 数据库 schema、路由、settings_page.dart（后续独立任务） |
| 验收 | `flutter analyze` + `flutter test`（新增 widget test）|

## 功能规格

### 1. 单条删除确认弹窗

- **标题**: "删除这条收藏？"
- **说明**: "删除后，这条内容将从所有收藏夹中移除。此操作暂时不可恢复。"
- **内容预览卡**: 图标 + 标题 + 来源/类型/时间
- **Checkbox**: "以后删除单条收藏时不再提示" + 辅助说明"可在 设置 > 内容收藏 中重新开启"
- **按钮**: 取消（白底描边）+ 删除（红色 destructive）

### 2. 批量删除确认弹窗

- **标题**: "删除 {count} 条收藏？"
- **说明**: "这些内容将从所有收藏夹中移除。此操作暂时不可恢复。"
- **Checkbox**: "以后批量删除收藏时不再提示"
- **按钮**: 取消 + "删除 {count} 项"（红色）

### 3. 多收藏夹场景操作选择弹窗

当 item 属于 2+ 个收藏夹时，优先展示操作选择：
- "仅从当前收藏夹移除"（内容保留在其他收藏夹）
- "删除这条收藏"（从所有收藏夹移除）

### 4. 偏好管理

- `confirmDeleteSingleItem: bool = true`
- `confirmDeleteBatchItems: bool = true`
- 使用 SharedPreferences 持久化

### 5. 删除后撤销

SnackBar 带撤销 action，持续 5 秒：
- 单条: `已删除「{title}」 [撤销]`
- 批量: `已删除 {count} 条收藏 [撤销]`
- 移除: `已从「{folderName}」中移除 [撤销]`

### 6. 视觉规格

| 属性 | 值 |
|------|-----|
| Dialog 宽度 | 440 |
| Dialog 圆角 | 20 |
| Dialog padding | 24 |
| 背景 | #FFFFFF |
| 遮罩 | 黑色 35% |
| 警示图标容器 | 44×44, 圆角 999, 背景 #FEECEC |
| 警示图标 | delete_outline_rounded, 颜色 #E5484D |
| 标题 | titleLarge, w700, #1F2937 |
| 正文 | bodyMedium, #667085, lineHeight 1.45 |
| 预览卡背景 | #F8FAFC, 边框 #E6ECF5, 圆角 14, padding 12 |
| 删除按钮 | 背景 #E5484D, hover #D33C43, 文字白色, 圆角 12 |
| 取消按钮 | 白底, 边框 #E6ECF5, 文字 #344054, 圆角 12 |

## 实现路径

1. 新建 `lib/src/shared/preferences/delete_confirm_prefs.dart` — SharedPreferences 封装
2. 新建 `lib/src/shared/widgets/delete_confirm_dialog.dart` — 弹窗组件
3. 改造 `saved_item_detail_panel.dart` 的 `_deleteItem()`
4. 改造 `saved_item_card.dart` 的 `_CardMoreMenu` 删除入口
5. 改造 `collection_bulk_action_bar.dart` 的删除入口
6. 新增 `CollectionsRepository.removeItemFromBox()` — 仅移除收藏夹关联
7. 所有删除后改为 5 秒可撤销 SnackBar
8. 编写 widget test
