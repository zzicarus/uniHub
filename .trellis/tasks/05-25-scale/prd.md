# PRD: 内容收藏右侧详情栏 —— 删除底部操作栏，Scale 适配，视觉微调

> 模块：uniHub / 内容收藏  
> 目标文件：`lib/src/plugins/collections/ui/widgets/saved_item_detail_panel.dart`  
> 优先级：P1  
> 目标版本：内容收藏 UI v2.0

## 背景

右侧详情栏已具备完整的身份信息、整理区、内容预览、技术信息，但仍有两个问题：

1. **底部操作栏重复** — 底部固定的「打开内容」「编辑」「更多」与顶部「打开原网页」语义重叠，视觉重心下沉
2. **Scale 适配不完善** — 未考虑 100%/125%/150% 缩放、窗口宽度 380-440px 区间的布局溢出风险

## 改造目标

1. 删除右侧栏底部固定的「打开内容」「编辑」「更多」按钮区域
2. 备注区用 `ConstrainedBox` 代替固定高度，防止文本缩放截断
3. TabBar 改为 `isScrollable: true`，防止 textScale 大时溢出
4. 身份卡图标增加紧凑模式（LayoutBuilder：宽度 <400px 时 60→56）
5. 顶部打开按钮文案在宽度 <360px 时降级为「打开网页」

## 修改范围

| 文件 | 改动 |
|------|------|
| `saved_item_detail_panel.dart` | 删除底部操作栏、备注区 ConstrainedBox、TabBar isScrollable、紧凑模式 LayoutBuilder、修复缩进 |

## 不修改

数据库 schema、Drift migration、Repository、三栏主布局、左侧/中间栏

## 验收标准

- `flutter analyze` 0 error 0 warning
- 右侧底部不再出现「打开内容/编辑/更多」
- 右侧顶部大图标身份卡完整
- 状态/收藏夹/标签使用 Wrap 不溢出
- textScale 1.25/1.5 下不溢出
- 打开原网页、复制链接、状态切换、收藏夹选择仍可用
