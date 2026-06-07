import 'package:flutter_test/flutter_test.dart';
import 'package:uni_hub/src/shared/crud/crud.dart';

void main() {
  group('AppFailure', () {
    test('stores structured failure data', () {
      const failure = AppFailure(
        code: AppFailureCode.duplicate,
        message: '名称已存在',
        field: 'name',
      );

      expect(failure.code, AppFailureCode.duplicate);
      expect(failure.isFieldFailure, isTrue);
      expect(failure.message, '名称已存在');
    });
  });

  group('CrudResult', () {
    test('success result carries message and undo', () async {
      var undone = false;
      final result = CrudResult<int>.success(
        data: 1,
        message: '已删除',
        undo: CrudUndoAction(execute: () => undone = true),
      );

      expect(result.success, isTrue);
      expect(result.data, 1);
      expect(result.hasUndo, isTrue);
      await result.undo!.execute();
      expect(undone, isTrue);
    });

    test('failure result exposes userMessage from failure', () {
      const result = CrudResult<void>.failure(
        failure: AppFailure(
          code: AppFailureCode.validation,
          message: '不能为空',
          field: 'name',
        ),
        fieldErrorHandled: true,
      );

      expect(result.success, isFalse);
      expect(result.userMessage, '不能为空');
      expect(result.fieldErrorHandled, isTrue);
    });

    test('carries side effects and supports safe casting', () {
      const result = CrudResult<int>.success(
        data: 42,
        message: '已创建',
        sideEffects: [
          SelectEntityEffect(CrudEntityType.savedItem, 42),
          RefreshListEffect(CrudEntityType.savedItem),
        ],
      );

      final cast = result.cast<num>();

      expect(cast.success, isTrue);
      expect(cast.data, 42);
      expect(
        cast.sideEffects,
        contains(const SelectEntityEffect(CrudEntityType.savedItem, 42)),
      );
      expect(
        cast.sideEffects,
        contains(const RefreshListEffect(CrudEntityType.savedItem)),
      );
    });
  });

  group('CrudEntityPolicy', () {
    test('provides default policies for MVP entities', () {
      expect(
        CrudEntityPolicy.defaultsFor(CrudEntityType.savedItem).supportsUndo,
        isTrue,
      );
      expect(
        CrudEntityPolicy.defaultsFor(
          CrudEntityType.collectionBox,
        ).nameUniqueScope,
        NameUniqueScope.parent,
      );
      expect(
        CrudEntityPolicy.defaultsFor(CrudEntityType.tag).supportsMerge,
        isTrue,
      );
      expect(
        CrudEntityPolicy.defaultsFor(CrudEntityType.thought).supportsSoftDelete,
        isTrue,
      );
    });
  });

  group('BatchCrudResult', () {
    test('detects all success and all failure states', () {
      const success = BatchCrudResult<void>(
        results: [CrudResult<void>.success(), CrudResult<void>.success()],
      );
      const failure = BatchCrudResult<void>(
        results: [
          CrudResult<void>.failure(
            failure: AppFailure(
              code: AppFailureCode.database,
              message: 'failed',
            ),
          ),
        ],
      );

      expect(success.status, BatchCrudStatus.allSucceeded);
      expect(success.summaryMessage, '已完成 2 项操作');
      expect(failure.status, BatchCrudStatus.allFailed);
      expect(failure.summaryMessage, '全部 1 项操作失败');
    });

    test('detects partial success', () {
      const batch = BatchCrudResult<void>(
        results: [
          CrudResult<void>.success(message: 'ok'),
          CrudResult<void>.failure(
            failure: AppFailure(
              code: AppFailureCode.database,
              message: 'failed',
            ),
          ),
        ],
      );

      expect(batch.status, BatchCrudStatus.partialSucceeded);
      expect(batch.successCount, 1);
      expect(batch.failureCount, 1);
      expect(batch.summaryMessage, contains('1 项失败'));
    });
  });
}
