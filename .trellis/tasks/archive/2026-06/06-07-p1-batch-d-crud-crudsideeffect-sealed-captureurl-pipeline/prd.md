# P1-Batch-D: CRUD 流统一、CrudSideEffect sealed、CaptureUrl pipeline

## 背景

Batch D 处理 **P1 架构收敛 + 业务一致性** 问题，不涉及 P0 紧急修复。

## 改动项

| # | 项 | 改动 | 文件 |
|---|----|------|------|
| #6 | 收藏夹创建统一走 CrudResult | 新增 `CollectionBoxActionsController`，UI 不再 catch StateError | 新建 + 3 file |
| #7 | CrudSideEffect 改为 sealed class | 携带 entityId/entityType payload | `crud_result.dart` |
| #9 | 导出确认/冲突对话框 | AppConfirmDialog/AppConflictDialog 已在但未归档 | `crud.dart` |
| #10 | captureUrl 返回 CrudResult | 返回 CrudResult<CaptureResult> 带 sideEffect | `collection_capture_service.dart` |
| #11 | Enrichment 回调传 itemId | onLogoCached 改为 `void Function(int itemId)?` | `enrichment_job_service.dart` |

## 执行顺序

依赖关系： #7 → #6 → #10, #11 独立, #9 随时

建议执行顺序：
1. #7: CrudSideEffect sealed class（先改基础设施）
2. #9: 导出对话框（最小改动）
3. #6: CollectionBoxActionsController（依赖新 CrudSideEffect）
4. #10: captureUrl → CrudResult
5. #11: Enrichment callback 传 itemId
