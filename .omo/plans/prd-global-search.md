# PRD: 全局搜索

## 背景与动机

当前 `/search` 路由是一个空占位页面（`SearchPage` in `mobile_placeholder_pages.dart`），用户无法在应用内搜索已有的想法内容。随着笔记量增长，用户需要跨插件统一搜索的能力。`UniHubPlugin` 接口已预留 `search(String query)` 方法，但尚无消费方。

## 范围

### In Scope
- [ ] 实现 `ThoughtsDao.searchThoughts(String query)` — 按标题/正文/tags 模糊匹配
- [ ] 在 `ThoughtsPlugin.search()` 中调用并返回 `SearchResult` 列表
- [ ] 创建 `SearchProvider`（`lib/src/core/search/search_provider.dart`）协调所有插件的搜索结果
- [ ] 将 `/search` 占位页替换为真实页面，包含搜索框 + 聚合结果列表
- [ ] 首页搜索框（`_SearchBox` in `home_page.dart`）的行为从 SnackBar 改为跳转 `/search`

### Out of Scope
- 搜索历史缓存 / 搜索建议
- 富文本内高亮匹配关键词
- 文件附件内容索引

## 技术方案

- **搜索基础设施**：`lib/src/core/search/search_provider.dart`
  - `SearchProvider` 为 `FutureProvider.family<List<SearchResult>, String>`，接收 query 参数
  - 遍历 `PluginRegistry` 中所有插件，聚合 `plugin.search(query)` 结果
  - 按 `score` 降序排列，顶部取 20 条
- **Thoughts 搜索实现**：`lib/src/plugins/thoughts/data/thoughts_dao.dart`
  - 新增 `searchThoughts(String query)`，使用 SQL `LIKE '%query%'` 匹配 `content` 和 `tags` 字段
  - `ThoughtContentCodec.plainTextFromStored()` 提取可搜索纯文本
- **路由**：现有 `/search` 路由不变，替换 `SearchPage` 实现
- **UI**：`lib/src/core/ui/search_page.dart`（新增）
  - 桌面端（≥720px）：左侧搜索栏（360px）+ 右侧结果面板
  - 移动端：全屏搜索框 + 结果列表
  - 使用 `AdaptiveLayout` 实现响应式切换，遵循 `widget.md` 中桌面/移动断点约定

## 数据模型

- 无新增表。`SearchResult` 已有定义（`search_result.dart`）
- `ThoughtsDao` 新增方法，无 schemaVersion 变更

## UI 变更

- 新增 `lib/src/core/ui/search_page.dart` — 替换 `mobile_placeholder_pages.dart` 中的 `SearchPage`
  - 搜索框（`TextField` + debounce 300ms）
  - 空状态提示（"输入关键词开始搜索"）
  - 无结果提示（"未找到相关内容"）
  - 结果卡片列表（复用 `_ThoughtPreviewCard` 模式，但使用 `SearchResult` 数据）
- 移动端 `<720px`：`_MobileSearchView` 使用全屏布局
- 首页 `_SearchBox.onTap` 改为 `context.go('/search')`

## 测试计划

- [ ] 单元测试：`ThoughtsDao.searchThoughts` — 匹配 title、匹配 tags、无匹配
- [ ] 单元测试：`SearchProvider` — 空 query 返回空列表、多插件结果聚合排序
- [ ] Widget 测试：搜索页 — 输入关键词、显示结果、空结果状态
- [ ] 集成测试：从首页搜索框进入搜索页 → 输入 → 点击结果跳转

## 验收标准

- [ ] `flutter analyze` 通过
- [ ] `flutter test` 通过
- [ ] 首页搜索框点击后跳转 `/search`，不再是 SnackBar
- [ ] 输入关键词后显示来自 Thoughts 的匹配结果（标题/tags/正文片段）
- [ ] UI 在桌面端（≥720px）和移动端均正常
- [ ] 与现有功能不冲突
