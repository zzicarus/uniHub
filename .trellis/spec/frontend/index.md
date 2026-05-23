# Frontend Development Guidelines

> UniHub 前端开发规范（Flutter + Riverpod）

---

## Pre-Development Checklist

Before implementing a frontend task:

- [ ] Read `.trellis/spec/frontend/component-guidelines.md` — Widget 规范、设计令牌、配色系统
- [ ] Read `.trellis/spec/frontend/uiux-guidelines.md` — 可访问性、交互状态、空/加载/错误/重试
- [ ] Review `.trellis/spec/frontend/state-management.md` — Provider 模式、AsyncValue 三态
- [ ] Check existing widgets in `lib/src/shared/ui/` for reuse opportunities
- [ ] Verify color/spacing/radius tokens from `lib/src/core/theme/app_tokens.dart`
- [ ] Confirm responsive breakpoints (`AppBreakpoints`) for target screen size

---

## Guidelines Index

| Guide | Description | Last Updated |
|-------|-------------|--------------|
| [Directory Structure](./directory-structure.md) | 前端目录组织、文件命名 | 2026-05-23 |
| [Component Guidelines](./component-guidelines.md) | Widget 类型选择、结构、设计令牌、响应式、配色 | 2026-05-23 |
| [UI/UX Guidelines](./uiux-guidelines.md) | 可访问性、交互状态、桌面/移动体验、表单反馈 | 2026-05-23 |
| [Hook Guidelines](./hook-guidelines.md) | Extension、Mixin、Controller 复用模式 | 2026-05-23 |
| [State Management](./state-management.md) | Riverpod Provider 层级、生命周期 | 2026-05-23 |
| [Quality Guidelines](./quality-guidelines.md) | 禁止/必需模式、测试要求、审查清单 | 2026-05-23 |
| [Type Safety](./type-safety.md) | 类型安全、代码生成、类型定义约定 | 2026-05-23 |

---

## Quality Check (Before Committing)

```bash
flutter analyze
flutter test
```

0 errors, 0 warnings required. See `.trellis/spec/frontend/quality-guidelines.md` for full checklist.

---

**语言**: 中文（AGENTS.md 的约定）
