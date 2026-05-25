# 修复 Thoughts 测试失败

## Goal

修复当前 `flutter test` 中既有 Thoughts provider/UI 测试失败，使全量测试恢复通过。

## What I already know

- 在 Collections MVP 验证阶段，focused Collections/Core 测试通过，但 full `flutter test` 失败集中在 Thoughts 测试。
- 失败涉及搜索/筛选/card 期望，示例文件：
  - `test/plugins/thoughts/providers/thoughts_providers_test.dart`
  - `test/plugins/thoughts/ui/thoughts_integration_test.dart`
  - `test/plugins/thoughts/ui/thoughts_qa_test.dart`
- Collections MVP 未修改 `lib/src/plugins/thoughts/**` 或 `test/plugins/thoughts/**`，因此本问题从 Collections 任务中拆出处理。

## Requirements

- 复现并定位 Thoughts provider/UI 测试失败根因。
- 修复实现或测试期望，避免破坏 Thoughts 现有功能。
- 全量 `flutter test` 通过。

## Acceptance Criteria

- [ ] `flutter test test/plugins/thoughts` 通过。
- [ ] `flutter test` 通过。
- [ ] `flutter analyze` 通过。

## Out of Scope

- 不修改 Collections MVP 行为，除非证明失败与 Collections 改动直接相关。

## Technical Notes

- 从 `.trellis/tasks/05-24-collections-mvp/` 验证阶段拆出。
