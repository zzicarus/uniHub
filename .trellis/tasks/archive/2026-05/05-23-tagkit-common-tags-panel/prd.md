# PRD: 新增通用 AppCommonTagsPanel

## 背景与动机

TagKit 需要一个可复用的常用标签面板，供 thoughts 当前能力稳定使用，并为 notes、todos、favorites 后续复用打基础。当前 thoughts 右侧常用标签由 `ThoughtCommonTagsPanel` 自行组织布局，缺少共享组件。本 leaf 仅新增通用组件，不接入 thoughts，避免跨 leaf 扩大改动范围。

## 范围

### In Scope

- [ ] 新增 `lib/src/shared/widgets/tags/app_common_tags_panel.dart`。
- [ ] 定义 `AppCommonTagsPanel extends StatelessWidget`。
- [ ] 使用 `AppPanel` 作为外层容器。
- [ ] 顶部展示 icon + title，右侧展示 helperText。
- [ ] tags 为空时显示 emptyText。
- [ ] tags 非空时使用 Wrap 展示 `tags.take(maxVisibleTags)`。
- [ ] 每个标签使用 `AppTagChip`，支持 count、selected 与 onTagToggle。
- [ ] 使用 shared TagKit 模型，不依赖 thoughts provider 或 thoughts 专用面板组件。
- [ ] 使用 `context.appColors` 或通用组件内部颜色，不使用 `AppColors` 静态色。

### Out of Scope

- 不接入 thoughts。
- 不修改任何 thoughts 文件。
- 不重做 TagCodec / TagFilterLogic。
- 不重做 AppTagChip / AppTagFilterBar / AppSelectedTagsBar。
- 不改数据库、路由、composer、thoughts 卡片布局。
- 不做全局 tags table。
- 不做标签颜色、图标、分组等高级功能。
- 不补本 leaf 以外的 widget test。

## 技术方案

新增共享 Widget：

```dart
class AppCommonTagsPanel extends StatelessWidget
```

参数：

- `String title = '常用标签'`
- `String helperText = '点击筛选'`
- `IconData icon = Icons.sell_outlined`
- `List<AppTagStat> tags`
- `Set<String> selectedTags`
- `ValueChanged<String> onTagToggle`
- `int maxVisibleTags = 8`
- `String emptyText = '暂无标签'`
- `EdgeInsetsGeometry? padding`

依赖：

- `lib/src/shared/tags/tag_models.dart`
- `lib/src/shared/widgets/tags/app_tag_chip.dart`
- `lib/src/shared/widgets/app_panel.dart`
- `lib/src/core/theme/app_tokens.dart`
- `lib/src/core/theme/app_theme_tokens.dart`

实现约束：

- 外层使用 `AppPanel`。
- 面板内部可用 token 控制 padding、间距和圆角。
- 顶部 Row 左侧为 icon + title，右侧为 helperText。
- tags 为空时显示 emptyText；非空时 `Wrap` 渲染 `tags.take(maxVisibleTags)`。
- `AppTagChip(label: tag.name, count: tag.count, selected: selectedTags.contains(tag.name), onTap: () => onTagToggle(tag.name))`。

## 验收标准

- [ ] 新增文件存在：`lib/src/shared/widgets/tags/app_common_tags_panel.dart`。
- [ ] 未修改任何 thoughts 文件。
- [ ] 组件不依赖 thoughts provider / ThoughtPanel / ThoughtPanelHeader / ThoughtSmallMutedText。
- [ ] 组件不使用 `AppColors` 静态色。
- [ ] `flutter analyze` 通过。
