# 收藏页面删除功能

## 目标

为收藏页面增加删除功能，支持从三个入口删除收藏项。

## 范围

- 数据层：DAO + Repository 级联删除
- UI 层：卡片更多菜单、详情面板快速操作、批量操作栏
- 测试：DAO 单测 + Repository 级联删除测试

## 禁止

- 不改动数据库 schema
- 不修改路由、布局

## 入口点

1. 卡片右侧更多菜单 → 「删除」（红色，含确认弹窗）
2. 详情面板快速操作区 → 「删除」（destructive 样式，含确认弹窗）
3. 批量操作栏 → 「删除」（destructive 红色按钮，含确认弹窗）

## 级联清理

删除时同步清理：
- `saved_item_boxes` 中的关联记录
- `enrichment_jobs` 中的关联记录
- `saved_items` 中的主记录

删除当前选中项时，自动清除 `selectedSavedItemIdProvider` 状态。

## 验收

- `flutter analyze` 0 issues
- `flutter test test/plugins/collections/` 全部通过
- DAO deleteById 测试通过
- Repository 级联删除测试通过
