# Ink 与 Material 宿主调研

## 结论

`Ink` 不是本地 ink 宿主。它会通过 `Material.of(context)` 找到最近的 `MaterialInkController`，并把 `InkDecoration` 注册到那个 `Material` 上。

因此，仅把裸 `InkWell` 改成 `Ink(child: InkWell(...))` 不足以阻断跨组件树 paint 问题；如果外层没有本地 `Material`，`InkDecoration` 仍会挂到 `DesktopShell` / `Scaffold` 级 Material。

## 本地源码证据

来源：`/home/zzicarus/develop/flutter/packages/flutter/lib/src/material/ink_decoration.dart`

- `Ink._build` 创建 `InkDecoration`
- `controller: Material.of(context)`
- `referenceBox: _boxKey.currentContext!.findRenderObject()! as RenderBox`
- `InkDecoration` 构造函数中调用 `controller.addInkFeature(this)`

用户堆栈里的 `InkDecoration.paintFeature` 与该链路吻合：当 referenceBox 处于 `NEEDS-LAYOUT` 时，`paintFeature` 读取 `referenceBox.size` 会触发 `RenderBox was not laid out`。

## 对本任务的修复原则

- 任何使用 `Ink` / `InkWell` 的组件都应在组件本地提供 `Material`。
- 对只有透明点击区域的组件，使用 `Material(type: MaterialType.transparency, child: Ink(...))`。
- 对有 decoration 的组件，使用 `Material(shape/clipBehavior, child: Ink(decoration: ..., child: InkWell(...)))`。
- 测试应断言组件内部存在本地 `Material`，防止只依赖 `Scaffold` 祖先 Material 的回归。
