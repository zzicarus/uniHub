import 'dart:async';

import 'package:uni_hub/src/core/database/app_database.dart';
import 'package:uni_hub/src/plugins/collections/data/collections_repository.dart';
import 'package:uni_hub/src/shared/crud/crud.dart';

/// Unified controller for collection box (folder) operations.
///
/// Every mutation returns [CrudResult] so the UI can display status messages
/// without catching raw [StateError] or [ArgumentError] from the repository.
class CollectionBoxActionsController {
  CollectionBoxActionsController({
    required CollectionsRepository repository,
  }) : _repository = repository;

  final CollectionsRepository _repository;

  Future<CrudResult<CollectionBoxesTableData>> createBox(String name) async {
    try {
      final box = await _repository.createBox(name);
      return CrudResult<CollectionBoxesTableData>.success(
        data: box,
        message: '已创建收藏夹「${box.name}」',
      );
    } on StateError catch (e) {
      return CrudResult<CollectionBoxesTableData>.failure(
        failure: AppFailure(
          code: AppFailureCode.duplicate,
          message: e.message,
          field: 'name',
        ),
        fieldErrorHandled: true,
      );
    } on ArgumentError catch (e) {
      return CrudResult<CollectionBoxesTableData>.failure(
        failure: AppFailure(
          code: AppFailureCode.validation,
          message: e.message,
          field: 'name',
        ),
        fieldErrorHandled: true,
      );
    } catch (error, stackTrace) {
      return CrudResult<CollectionBoxesTableData>.failure(
        failure: AppFailure(
          code: AppFailureCode.database,
          message: '创建收藏夹失败',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }
}
