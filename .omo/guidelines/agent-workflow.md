# 代理任务分类与委派指南

> UniHub 的 AI 代理任务分类标准。定义不同任务类型对应的 OMO 分类、技能加载和委派策略。

---

## 总则

所有代理在接到 UniHub 相关任务时，应按以下流程决策：

1. 确认任务类型（架构/数据/UI/测试/文档/验证）
2. 查阅本文件确定分类、技能和委派策略
3. 对于复杂任务，先阅读涉模块的 `AGENTS.md` 和相关 `.omo/guidelines/` 文件
4. 执行任务前使用 `todowrite` 拆分步骤（2 步以上必须写 todo）

### 三条黄金原则

| 原则 | 说明 |
|------|------|
| 依赖方向不可逆 | `plugins/` 可以依赖 `shared/` 和 `core/`，反之禁止 |
| 跨层引用用 package 路径 | `package:uni_hub/src/core/...`，禁止 `../../../` |
| 新增代码禁止类型抑制 | 不写 `as any`、空 catch 块、行级屏蔽不加原因注释 |

---

## OMO 分类速览

| 分类 | 使用场景 | 典型工作量 |
|------|----------|-----------|
| `visual-engineering` | UI 组件、布局、样式、动画 | 1-3 个 widget 文件 |
| `ultrabrain` | 架构决策、复杂逻辑、跨层重构 | 多模块、需方案对比 |
| `deep` | 端到端多步骤实现，含调研+编码+测试 | 完整功能（含测试） |
| `quick` | 1-2 个文件的简单修改 | 单行到十行改动 |
| `unspecified-high` | 不属于上述分类的中等任务 | 迁移脚本、测试框架搭建 |
| `writing` | 文档、PRD、指南 | 纯文字输出 |

### 不能委派的场景

| 场景 | 原因 | 正确做法 |
|------|------|----------|
| 架构方向决策（如"要不要换状态管理库"） | 需要人类判断项目方向 | 准备 2-3 个方案，列出优劣供用户决策 |
| 数据库 schema 设计（如"要不要加新表"） | 影响全应用的数据一致性 | 按 `database.md` 的模式先写 PRD |
| 用户在讨论中明确要求"我来决定"的事项 | 用户保留决策权 | 提供信息，等待用户指令 |
| 冲突合并、rebase 处理 | 需要理解人类意图的语义冲突 | 汇报冲突内容，请用户处理 |

---

## 六类任务的分委派指南

### 1. 架构决策 (Architecture)

**分类**: `ultrabrain`

**典型场景**:
- 新增插件时如何遵循现有插件系统约定（`lib/src/core/plugin/`）
- 跨层重构（如将重复代码提取到 `shared/`）
- 路由结构调整（GoRouter ShellRoute 新增分支）
- Provider 层级设计（Provider 作用域、生命周期管理）

**加载技能**: `flutter-apply-architecture-best-practices`, `flutter-dev`

**前置阅读**:
- `lib/src/core/AGENTS.md` — 基础设施全景
- `lib/src/core/plugin/AGENTS.md` — 插件系统约定
- `.omo/guidelines/workflow.md` — 分层依赖顺序

**示例**:
```dart
// 架构任务：评估新增插件的最佳位置
task(
  category: "ultrabrain",
  load_skills: ["flutter-apply-architecture-best-practices", "flutter-dev"],
  run_in_background: true,
  prompt: "分析 lib/src/core/plugin/ 的插件注册机制，确定在 shared/ 还是 plugins/ 下新增一个 Markdown 渲染模块更合适。阅读相关 AGENTS.md 后给出方案。",
);
```

---

### 2. 数据层 (Data Layer / Drift/SQLite)

**分类**: `unspecified-high`（新增 DAO/Repository 或表变更）
**分类**: `quick`（单条查询修改或字段增减）

**典型场景**:
- 新增 drift Table 定义
- 编写 DAO 查询方法
- 编写 Repository 业务方法
- 修改 `@DriftDatabase(tables: [...])` 声明
- schemaVersion 变更 + migration 逻辑
- 数据模型 Provider 的创建或修改

**加载技能**: `flutter-dev`, `dart-add-unit-test`

**前置阅读**:
- `.omo/guidelines/database.md` — Table 定义、DAO/Repository 模式、迁移策略
- `test/AGENTS.md` — 数据库测试隔离模式（`NativeDatabase.memory()`）

**关键约束**:
- DAO 只做数据访问，业务逻辑在 Repository
- 时间戳命名 `createdAt` / `updatedAt`，软删除用 `archivedAt`
- 测试必须用 `setUp`/`tearDown` 创建和销毁 `AppDatabase`

**示例**:
```dart
// 数据层任务：新增查询方法
task(
  category: "unspecified-high",
  load_skills: ["flutter-dev", "dart-add-unit-test"],
  run_in_background: true,
  prompt: "在 ThoughtsDao 中新增一个 searchByTag(String tag) 方法，使用 drift WHERE 子句过滤 tags 列。对应补充单元测试，使用 NativeDatabase.memory() 隔离模式。",
);
```

---

### 3. UI / 前端 (Visual)

**分类**: `visual-engineering`

**典型场景**:
- 新增页面（如 thoughts 列表页）
- 设计新组件（如卡片、列表项）
- 响应式布局调整
- 暗色模式适配
- 主题 Token 替换（`colorScheme.*` + `AppSpacing`/`AppRadius`）

**加载技能**: `flutter-dev`, `flutter-build-responsive-layout`

**前置阅读**:
- `.omo/guidelines/widget.md` — Widget 类型选择、Token 使用、M3 颜色映射
- `lib/src/core/app/adaptive_shell.dart` — 路由层 ShellRoute 实现参考
- `lib/src/shared/widgets/adaptive_layout.dart` — 插件内响应式布局实现参考

**关键约束**:
- 颜色必须用 `Theme.of(context).colorScheme.*`，禁止硬编码
- 间距圆角必须用 `AppSpacing`/`AppRadius`，禁止直接写数值
- 桌面端断点 `>=720px`
- Widget 使用 `const` 构造器 + `super.key`

**示例**:
```dart
// UI 任务：新卡片组件
task(
  category: "visual-engineering",
  load_skills: ["flutter-dev", "flutter-build-responsive-layout"],
  run_in_background: true,
  prompt: "在 lib/src/plugins/thoughts/ui/widgets/ 下新建一个 ThoughtCard 组件。接收 Thought 对象，展示内容摘要（最多两行）、标签和创建时间。使用 colorScheme 配色和 AppSpacing/AppRadius Token。",
);
```

---

### 4. 测试 (Testing)

#### 单元测试

**分类**: `quick`（单个数据层方法测试）
**分类**: `unspecified-high`（多方法覆盖或首次搭建测试文件）

**典型场景**:
- 为 DAO 新增方法写测试
- 为 Repository 写测试
- 为工具类/helper 函数写测试
- 测试 `ThoughtContentCodec` 的 encode/decode 往返

**加载技能**: `dart-add-unit-test`, `flutter-dev`

**前置阅读**: `test/AGENTS.md` — ProviderScope override 模式

**关键约束**:
- Database 测试：`NativeDatabase.memory()` + `setUp`/`tearDown`
- Provider override：`ProviderScope` 传 `overrides`
- **零 mockito**：手写 stub 替代

#### Widget 测试

**分类**: `unspecified-high`

**典型场景**:
- 为页面组件写 Widget 测试
- 验证组件在不同状态下的渲染（加载/空/错误/数据）
- 测试用户交互（点击、滚动、输入）

**加载技能**: `flutter-add-widget-test`, `flutter-dev`

**关键约束**:
- 使用 `tester.pumpWidget(ProviderScope(...))` 包裹
- 验证关键 UI 元素存在/不存在，不检查像素级细节
- 测试文件放在 `test/` 对应模块目录下

**示例**:
```dart
// 测试任务：完整测试覆盖
task(
  category: "unspecified-high",
  load_skills: ["dart-add-unit-test", "flutter-dev"],
  run_in_background: true,
  prompt: "为 ThoughtsDao 的 getAll()、insert()、searchByTag() 三个方法编写单元测试。使用 NativeDatabase.memory() 隔离，遵循 test/AGENTS.md 的 ProviderScope override 模式。",
);
```

---

### 5. 文档 (Documentation)

**分类**: `writing`

**典型场景**:
- 创建 `AGENTS.md` 或更新现有模块文档
- 写 PRD（`.omo/plans/prd-*.md`）
- 更新 `.omo/guidelines/` 规范
- 写 README、CHANGELOG

**加载技能**: 不需要（如果涉及架构理解可加 `flutter-dev`）

**前置阅读**:
- `.omo/guidelines/planning.md` — PRD 模板
- 被文档覆盖的模块的 `AGENTS.md`

**关键约束**:
- 全部使用中文（根 AGENTS.md 的要求）
- 不使用 emoji
- 引用真实文件路径

**示例**:
```dart
// 文档任务：写 PRD
task(
  category: "writing",
  run_in_background: true,
  prompt: "按照 .omo/guidelines/planning.md 的 PRD 模板，在 .omo/plans/ 下创建 prd-todo-plugin.md。描述一个 Todo 插件的数据模型（title, done, dueDate, priority）和 UI 结构（列表页+编辑页）。",
);
```

---

### 6. 验证 (Verification)

**分类**: `quick`（直接执行验证命令）

**典型场景**:
- 执行 `flutter analyze` 检查代码质量
- 执行 `flutter test` 验证测试通过
- 用 `dart fix --dry-run` 预览自动修复

**加载技能**: `dart-run-static-analysis`

**用法**: 作为最终步骤，不应单独委派给子代理，而是由主流程按顺序执行。

**示例**:
```dart
// 验证任务：代码质量检查（在主流程中执行，不委派）
// 不要将验证作为 background task — 应在主流程中串行执行
```

---

## UniHub 常见任务速查表

| 任务描述 | Category | Skills | 前置文档 |
|----------|----------|--------|----------|
| 新增插件模块注册 | `ultrabrain` | `flutter-apply-architecture-best-practices` | `lib/src/core/plugin/AGENTS.md` |
| 新建 drift Table | `unspecified-high` | `flutter-dev`, `dart-add-unit-test` | `.omo/guidelines/database.md` |
| 新增 DAO 方法 | `unspecified-high` | `flutter-dev`, `dart-add-unit-test` | `.omo/guidelines/database.md` |
| 新增页面/组件 | `visual-engineering` | `flutter-dev`, `flutter-build-responsive-layout` | `.omo/guidelines/widget.md` |
| 响应式布局调整 | `visual-engineering` | `flutter-build-responsive-layout`, `flutter-dev` | `lib/src/shared/widgets/adaptive_layout.dart` |
| Provider 层级调整 | `ultrabrain` | `flutter-apply-architecture-best-practices` | `lib/src/core/AGENTS.md` |
| 数据层单元测试 | `quick` / `unspecified-high` | `dart-add-unit-test` | `test/AGENTS.md` |
| Widget 测试 | `unspecified-high` | `flutter-add-widget-test` | `test/AGENTS.md` |
| 写 PRD | `writing` | 无需加载 | `.omo/guidelines/planning.md` |
| 写模块文档 | `writing` | 无需加载 | 对应模块的代码和 AGENTS.md |
| 代码质量检查 | `quick` | `dart-run-static-analysis` | `.omo/guidelines/workflow.md` |
| 第三方库用法查询 | `quick` | `context7-mcp` | 不适用 |
| 使用 pattern matching 重构 | `quick` | `dart-use-pattern-matching` | `lib/src/` 涉模块 |
| 完整端到端插件开发 | `deep` | `flutter-dev`, `dart-add-unit-test` | 全部相关指南 |
| 重构公共组件到 shared/ | `ultrabrain` | `flutter-apply-architecture-best-practices` | `lib/src/shared/AGENTS.md` |
| Post-implementation 审查 | 不委派（用 `/review-work`） | `review-work` | 所有相关代码 |

---

## 委派策略

### Do delegate

| 场景 | 理由 |
|------|------|
| 明确拆分的子任务（如"实现 DAO + 对应 Repository + 测试"） | 可并行执行 |
| 单一模块内的改动 | 上下文小，独立性强 |
| 独立的 UI 组件 | 不需要理解全貌即可实现 |
| 文档编写（给定明确大纲） | 纯文字输出，不涉及代码 |

### Do NOT delegate

| 场景 | 理由 |
|------|------|
| 架构决策 | 需要全局理解和人类判断 |
| 跨层重构（core 改动影响 plugins） | 影响面难以预估 |
| 合并冲突解决 | 语义冲突需要理解意图 |
| 调研替代方案 | 交给 background agent 会丢失上下文 |

### 背景委派使用模式

```dart
// 并行委派两个独立子任务
task(category: "visual-engineering", ..., run_in_background: true);
task(category: "unspecified-high", ..., run_in_background: true);

// 等待两者完成后，收集结果继续
final result1 = background_output(taskId: "bg_...");
final result2 = background_output(taskId: "bg_...");
```

串行依赖的任务不要并行执行（如先建表再写 DAO）。

---

## 工作流程集成

agent-workflow.md 与 `.omo/guidelines/workflow.md` 的 Plan → Code → Verify → Review → Ship 流程配合：

| 流程阶段 | 本文件的作用 |
|----------|-------------|
| Plan | 根据任务类型确定 category 和 skills，决定是否委派 |
| Code | 委派子任务时加载对应的 skills，传递正确的前置文档引用 |
| Verify | 使用 `dart-run-static-analysis`，在主流程串行执行 |
| Review | 复杂任务完成后触发 `/review-work` |
| Ship | 遵循 workflow.md 的提交格式 |

---

## 相关文件索引

| 文件 | 内容 |
|------|------|
| `AGENTS.md` | 项目概述、已知问题 |
| `.omo/guidelines/database.md` | Drift/SQLite 建表和查询规范 |
| `.omo/guidelines/widget.md` | Widget 编写规范、Token 使用 |
| `.omo/guidelines/workflow.md` | 完整开发流程规范 |
| `.omo/guidelines/planning.md` | PRD 模板和命名约定 |
| `lib/src/AGENTS.md` | 三层架构总览 |
| `test/AGENTS.md` | 测试隔离模式和 ProviderScope override |
| `lib/src/core/plugin/AGENTS.md` | 插件系统关键约定 |

> 最后更新：2026-05-21 | 本文件是代理任务委派的唯一权威参考。如有矛盾以本文件为准。
