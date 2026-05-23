# Trellis Spec — UniHub

> 项目级开发规范。所有文件以中文书写（AGENTS.md 约定）。

---

## Spec 分类

| 分类 | 适用 | 索引 |
|------|------|------|
| [Backend](./backend/index.md) | 数据层（Drift/SQLite）、插件数据流、错误处理、日志 | 6 篇 |
| [Frontend](./frontend/index.md) | Widget 规范、状态管理、UI/UX、类型安全、测试 | 7 篇 |
| [Guides](./guides/index.md) | 跨层思考、代码复用、任务分类、PRD 模板 | 4 篇 |

---

## 补充设计文档

| 文档 | 说明 |
|------|------|
| [`docs/tag-system.md`](../../docs/tag-system.md) | TagKit 标签系统架构、多标签筛选语义、未来规划 |

---

## 质量门禁

提交前必须通过：

```bash
flutter analyze     # 0 error 0 warning
flutter test        # 全部通过
```

---

> 最后核对日期：2026-05-23
