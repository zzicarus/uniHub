# Collection Pill Visual Polish

## 目标

优化内容收藏页面顶部筛选区（内容类型 chips + 状态 tabs）和底部批量操作条的 typography 与 pill 控件样式。

## 改动文件

| 文件 | 操作 |
|------|------|
| `lib/src/shared/widgets/app_pill_chip.dart` | **新增** — AppPillChip 通用 pill 组件 |
| `lib/src/plugins/collections/ui/widgets/collection_content_type_chips.dart` | **修改** — ChoiceChip/ActionChip → AppPillChip |
| `lib/src/plugins/collections/ui/widgets/collection_status_tabs.dart` | **修改** — ChoiceChip → AppPillChip (compact) |
| `lib/src/plugins/collections/ui/widgets/collection_bulk_action_bar.dart` | **修改** — TextButton.icon → _BulkActionPill |

## 设计要点

- **AppPillChip**: `Material + Ink + InkWell` 模式，本地 Material 宿主确保涟漪安全
- **选中态**: 柔和 `primaryContainer` 半透明背景（不实心），`primary` 文字/边框
- **未选中态**: `surfaceContainerLow` 背景，`onSurfaceVariant` 文字，`outlineVariant` 边框
- **禁用态**: 透明背景，降低透明度文字和边框
- **Typography**: `labelMedium` 基础 + fontSize/high/letterSpacing/fontWeight 微调
- **Bulk action bar**: 改用 `_BulkActionPill` (30px 高, 透明背景, 纯图标+文字)

## 禁止

- 不修改数据库/Repository/Provider/三栏布局
- 不引入新依赖
- 不换全局字体
