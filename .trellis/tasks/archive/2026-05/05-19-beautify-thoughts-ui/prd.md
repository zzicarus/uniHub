# Beautify Thoughts and Home UI design

## Goal

对应用整体页面进行美化，当前核心目标是“美化想法部分的 UI 设计”，并同步修改“主页”风格，保持整体风格统一。

## What I already know

* 项目是一个单仓 Flutter 应用，使用 Material 3。
* 包含了首页 (`lib/src/core/app/home_page.dart`) 和想法部分 (`Thoughts` 插件)。
* 之前的任务中已经基于 `figure/安卓预期效果` 做了安卓端的基础 UI 搭建。
* 现有组件如 `ThoughtCard` 存在边框等干扰视觉纯净度的元素。

## Assumptions (temporary)

* 现有的功能逻辑（发布、浏览、标签过滤、归档等）保持不变。
* 重点是改善排版、颜色、卡片间距、字体层级等整体美感。

## Open Questions

* 无（准备实施）。

## Requirements (evolving)

* 美化“想法”部分的 UI 设计，同步美化主页 (`HomePage`)。
* 整体视觉风格：**Material 3 进阶（Google 风格）**，重点使用 **Tonal 色阶填充**形态，通过柔和的背景色区分层级。
* 去除卡片不必要的边框线，强化纯粹的色块感。
* 交互反馈：采用**色彩加深反馈（标准 M3）**，悬停/点击时仅改变 Tonal 背景色的透明度或深浅，保持扁平克制，不添加额外阴影或缩放变化。
* 主页的概览卡片、快速记录入口等也应采用同样的 Tonal 风格，保持圆角大小、颜色逻辑的统一。

## Acceptance Criteria (evolving)

* [ ] 想法页面的 UI 符合新的美感要求（去除边框，纯净 Tonal）。
* [ ] 主页的 UI 风格与想法页面统一（统一的 Tonal 卡片与间距）。
* [ ] 采用 Material 3 进阶风格，使用 Tonal 色阶填充卡片。
* [ ] 卡片交互使用色彩加深反馈，无需增加阴影或缩放。

## Definition of Done (team quality bar)

* 保证新 UI 在 Android/Desktop 端都具有良好的响应式表现
* Lint / typecheck 测试通过

## Out of Scope (explicit)

* 暂不涉及其他业务模块（笔记、待办等）的核心数据逻辑重构。

## Technical Notes

* 现有的相关文件包括：
  * `lib/src/plugins/thoughts/ui/widgets/thought_card.dart`
  * `lib/src/plugins/thoughts/ui/thoughts_list_page.dart`
  * `lib/src/core/app/home_page.dart`
  * `lib/src/core/app/mobile_shell.dart` 等。