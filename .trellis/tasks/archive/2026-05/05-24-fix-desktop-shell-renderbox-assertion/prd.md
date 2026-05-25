# 修复桌面 Shell 渲染断言失败

## Goal

修复桌面端在 `DesktopShell` 的 `Scaffold` paint 阶段触发 `RenderBox was not laid out: RenderPadding ... InkDecoration.paintFeature` 的断言失败，并补充能防止同类错误回归的 widget 测试。

## What I already know

- 用户提供的堆栈定位到 `lib/src/core/app/desktop_shell.dart:14` 的 `Scaffold`，但实际 paint 错误发生在 `_RenderInkFeatures` 处理 `InkDecoration.paintFeature` 时。
- 最近两次相关提交已经处理过部分 `InkWell` 问题：
  - `979ff93`: 侧栏 `_NavItem` / `_UserTile` 改为 `GestureDetector`，`SavedItemCard` 改为 `Ink + InkWell`。
  - `bbaf6d8`: 共享 widget 处理了 `Material(color: Colors.transparent) + InkWell` 和裸 `InkWell`。
- 当前源码仍存在 `return Ink(...)` 但外层没有本地 `Material` 的组件：
  - `lib/src/shared/widgets/app_compact_list_item.dart`
  - `lib/src/shared/widgets/app_section_header.dart`
  - `lib/src/plugins/collections/ui/widgets/saved_item_card.dart`
- `Ink` 需要注册到最近的 `Material` 来绘制 decoration；如果组件自身没有提供本地 `Material`，它仍可能把 `InkDecoration` 注册到 `DesktopShell` / `Scaffold` 的 Material 上。

## Assumptions

- 本次异常不是 Flutter framework 缺陷，而是组件没有为 ink feature 提供稳定的本地 Material 宿主。
- 修复范围应优先收敛在残留的 `Ink` without local `Material` 组件，不扩大到数据库、路由或业务逻辑。

## Requirements

- 所有本次涉及的可点击 `Ink` / `InkWell` 组件必须拥有本地 `Material` 宿主。
- 保持现有视觉样式、圆角、边框和点击回调语义不变。
- 补充测试，明确断言回归点：组件内应包含本地 `Material`，不能只依赖页面/Scaffold 级祖先 Material。

## Acceptance Criteria

- [x] `AppCompactListItem` 拥有本地 `Material`，点击回调正常。
- [x] `AppSectionHeader` 的 trailing action 拥有本地 `Material`，点击回调正常。
- [x] `SavedItemCard` 拥有本地 `Material`，点击回调正常。
- [x] Focused widget tests 通过。
- [x] `flutter analyze` 能运行并无新增代码问题；若本地 Flutter/WSL 环境阻塞，需单独说明阻塞信息。

## Out of Scope

- 不改 `DesktopShell` 路由结构。
- 不改数据库 schema。
- 不重做侧栏动画或页面视觉风格。
- 不处理与本断言无关的现存 lint / 格式问题。

## Technical Notes

- 相关规范：
  - `AGENTS.md`
  - `lib/src/AGENTS.md`
  - `lib/src/core/AGENTS.md`
  - `test/AGENTS.md`
  - `.trellis/spec/frontend/component-guidelines.md`
  - `.trellis/spec/frontend/quality-guidelines.md`
- 错误学习记录：
  - `.trellis/workspace/alan/learnings/errors.md`
- 调研记录：
  - `.trellis/tasks/05-24-fix-desktop-shell-renderbox-assertion/research/ink-material-host.md`
- 验证记录：
  - `flutter test test/shared/widgets/ink_host_regression_test.dart test/plugins/collections/ui/widgets/saved_item_card_test.dart test/shared/widgets/sidebar_test.dart` 通过。
  - `flutter analyze` 通过。
  - `dart fix --dry-run` 无可修复项。
  - `flutter test` 全量仍有 9 个既有 Thoughts 相关失败，集中在 composer/provider/filter/context-menu 测试，与本任务改动无交集。
