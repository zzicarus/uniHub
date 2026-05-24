# Thought Editor: flutter_quill → AppFlowy Editor Migration

> 决策记录日期：2026-05-24
> 决策状态：已批准
> 迁移分支：feature/appflowy-thought-editor

---

## 1. 产品方向

uniHub thoughts 模块重新定位为"想法捕捉 + 轻量知识卡片"系统，拆分两个明确场景：

### Capture Composer（首页快速捕捉）

| 维度 | 描述 |
|------|------|
| 目标 | 轻、快、不打断 |
| 交互 | 用户首页快速记录想法，可顺手加标签、图片、置顶、转待办 |
| 编辑器 | **不**使用完整富文本编辑器或 AppFlowy Editor |
| UI | 轻量输入卡片，高度 120–148px，无富文本 toolbar |
| 保存 | 纯文本输入 → 保存时包装为 `appflowy_json` 格式 |

### Editor Workspace（详情编辑沉淀）

| 维度 | 描述 |
|------|------|
| 目标 | 整理、沉淀、结构化 |
| 入口 | 点击想法卡片 → 打开大尺寸编辑工作台 |
| 编辑器 | AppFlowy Editor（block editor） |
| 布局 | 左侧 MainEditorColumn（标题 + toolbar + 正文）+ 右侧 PropertyRail |
| 体验方向 | Notion-lite / AppFlowy-like，非普通 drawer 表单页 |

---

## 2. 技术方向

### 2.1 编辑器选型

| 维度 | 结论 |
|------|------|
| 详情编辑器 | **AppFlowy Editor** — 块编辑、/命令、标题块、待办块、引用块 |
| 首页 Composer | 轻量 TextField，**不**接完整 AppFlowy Editor |
| 旧编辑器 | 废弃 `flutter_quill`，不做 delta 兼容 |

### 2.2 数据格式

content 字段统一保存为 AppFlowy JSON wrapper：

```json
{
  "format": "unihub.appflowy_json.v1",
  "document": { ... },
  "plainText": "..."
}
```

字段说明：

| 字段 | 用途 | 备注 |
|------|------|------|
| `format` | 格式标识 | 读取时校验格式版本 |
| `document` | AppFlowy 文档 JSON | 编辑器使用 |
| `plainText` | 纯文本 | 列表标题、摘要、搜索、统计 — 避免每次都从 document JSON 深度解析 |

### 2.3 封装策略

AppFlowy Editor 不直接暴露给页面层，通过封装组件隔离：

```
lib/src/shared/editor/appflowy_thought_editor.dart
```

- 输入：`initialJson` / `initialText`
- 输出：`documentJson` / `plainText`
- 页面层不直接依赖 `appflowy_editor` 细节

### 2.4 架构文件

| 文件 | 职责 |
|------|------|
| `lib/src/shared/editor/appflowy_thought_editor.dart` | AppFlowy Editor 封装层 |
| `lib/src/plugins/thoughts/data/thought_content_codec.dart` | appflowy_json 编解码 |
| `lib/src/plugins/thoughts/ui/widgets/thought_editor_workspace.dart` | 编辑工作台 modal |
| `lib/src/plugins/thoughts/ui/widgets/thought_editor_controller.dart` | 编辑器状态管理 |
| `lib/src/plugins/thoughts/ui/layouts/thought_composer.dart` | 首页轻量 composer |
| `lib/src/plugins/thoughts/ui/widgets/thought_composer_controller.dart` | composer 状态管理 |

---

## 3. 数据策略

### 3.1 旧数据处理

- 旧 `unihub.quill_delta.v1` 格式数据可以**清空删除**
- **不做** quill_delta → appflowy_json 格式转换
- **不做** 旧内容迁移
- **不做** 旧编辑器 fallback
- **不做** "转换为新版编辑器" 入口

### 3.2 图片处理（第一阶段）

| 策略 | 说明 |
|------|------|
| 存储 | imagePaths 继续走独立字段，不从 document JSON 提取 |
| AppFlowy image block | 暂不实现，后续单独处理 |

### 3.3 标签处理

- 继续使用已有 TagKit
- 如果已有 AppTagInput 组件，直接接入
- 如无，先新增通用 AppTagInput，不在 composer/editor 中手写标签 TextField

---

## 4. 暂不做（Future scope）

| 项目 | 理由 |
|------|------|
| AppFlowy image block 上传和解析 | 第一阶段图片走独立字段，避免增加复杂度 |
| 数据库结构调整 | content 字段短期继续复用，不立即改 schema |
| notes 模块迁移 | thoughts 后续可能扩展为 notes，但当前不动 |
| 移动端专门适配 | 除非当前代码编译必须，否则专注桌面端 |
| 复杂动画 | 编辑器切换已足够复杂，动画可后续优化 |
| 全文搜索系统 | 搜索功能独立于编辑器迁移 |
| 同步系统 | 无同步需求 |
| 主题系统重构 | 已有主题系统，不要重做 |
| TagKit 重构 | 已有标签系统，不要重做 |
| 路由改造 | 除非打开 workspace modal 的状态管理必须微调 |

---

## 5. 风险与注意事项

| 风险 | 影响 | 缓解措施 |
|------|------|----------|
| AppFlowy Editor API 版本变化 | 可能导致编译失败或行为异常 | 锁定版本，增量升级；先最小可运行接入，不大面积重构 |
| Windows / Android 兼容性 | 某些平台特性可能在桌面端不正常 | 优先保证 Windows，Android 后续验证 |
| AppFlowy Editor License | 商用场景需确认 AGPL 影响 | 当前在开发阶段，商用前需法律审核 |
| flutter_quill 移除后仍有残留引用 | 编译错误或未清理的 dead code | 每步完成后运行 `flutter analyze`；最终检查 Quill 引用是否归零 |
| 产品方向重新聚焦 | 两层编辑体验若未准确传达给团队，可能偏离 | 此文作为决策锚点，后续任务按此执行 |

---

## 6. 已知问题修复

### 6.1 关闭工作台时 GoRouter 崩溃（2026-05-24）

**症状**：在完整富文本编辑工作台中点击关闭/删除想法后，GoRouter 抛出断言错误：
`You have popped the last page off of the stack, there are no pages left to show`

**根因**：`ThoughtEditorWorkspace.show()` 的 `onClose` 回调使用 `Navigator.of(context).pop()`，
该调用直接操作 GoRouter 的页面栈。当编辑器工作台是当前路径下唯一页面时，GoRouter 拒绝弹出最后一页。

**修复**：在 `showDialog` 的 `onClose` 中改用 `Navigator.of(context, rootNavigator: true).pop()`，
限定只弹出对话框的 OverlayRoute，不影响 GoRouter 路由栈。

| 文件 | 修改 |
|------|------|
| `lib/src/plugins/thoughts/ui/widgets/thought_editor_workspace.dart` | `Navigator.of(context).pop()` → `Navigator.of(context, rootNavigator: true).pop()` |

---

## 7. 质量验收标准

1. `flutter analyze` — 0 error, 0 warning
2. 新增测试（如果写了）— 全部通过
3. Quill 引用归零（无残留 import 或依赖）
4. 不保留临时 fallback 代码
5. 每个变更任务输出：修改文件列表 + analyze 结果
