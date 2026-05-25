# Backend Development Guidelines

> UniHub 后端（数据层）开发规范（Drift/SQLite + Dart）

---

## Pre-Development Checklist

Before implementing a database/data-layer task:

- [ ] Read `.trellis/spec/backend/database-guidelines.md` — 表定义、DAO/Repository 模式、迁移
- [ ] Read `.trellis/spec/backend/plugin-data-flow.md` — 新增插件数据层端到端流程
- [ ] Read `lib/src/core/database/app_database.dart` — 确认表已在 `@DriftDatabase(tables: [...])` 中注册
- [ ] Read `.trellis/spec/backend/error-handling.md` — 异常处理模式
- [ ] Review `test/AGENTS.md` — 测试隔离模式
- [ ] Check `lib/src/core/plugin/plugin_interface.dart` — 插件表声明规范

---

## Guidelines Index

| Guide | Description | Last Updated |
|-------|-------------|--------------|
| [Directory Structure](./directory-structure.md) | 数据层目录组织、文件命名 | 2026-05-23 |
| [Database Guidelines](./database-guidelines.md) | Drift 表定义、DAO/Repository、迁移、内容存储合同 | 2026-05-25 |
| [Plugin Data Flow](./plugin-data-flow.md) | 插件数据层 Table→Provider→测试端到端流程 | 2026-05-23 |
| [Error Handling](./error-handling.md) | 异常类型、分层处理、禁止模式 | 2026-05-23 |
| [Quality Guidelines](./quality-guidelines.md) | 禁止/必需模式、测试要求、审查清单 | 2026-05-23 |
| [Logging Guidelines](./logging-guidelines.md) | 日志约定（debugPrint） | 2026-05-23 |

---

## Quality Check (Before Committing)

```bash
flutter analyze
flutter test
```

0 errors, 0 warnings required. See `.trellis/spec/backend/quality-guidelines.md` for full checklist.

---

**语言**: 中文（AGENTS.md 的约定）
