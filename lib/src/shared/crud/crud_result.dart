import 'dart:async';

import 'app_failure.dart';

class CrudUndoAction {
  const CrudUndoAction({this.label = '撤销', required this.execute});

  final String label;
  final FutureOr<void> Function() execute;

  @override
  String toString() => 'CrudUndoAction(label: $label)';
}

enum CrudSideEffect {
  selectEntity,
  closeDetail,
  clearSelection,
  refreshList,
  retry,
  viewExisting,
}

class CrudResult<T> {
  const CrudResult({
    required this.success,
    this.data,
    this.message,
    this.failure,
    this.undo,
    this.sideEffects = const <CrudSideEffect>[],
    this.suppressFeedback = false,
    this.fieldErrorHandled = false,
  });

  const CrudResult.success({
    T? data,
    String? message,
    CrudUndoAction? undo,
    List<CrudSideEffect> sideEffects = const <CrudSideEffect>[],
    bool suppressFeedback = false,
  }) : this(
         success: true,
         data: data,
         message: message,
         undo: undo,
         sideEffects: sideEffects,
         suppressFeedback: suppressFeedback,
       );

  const CrudResult.failure({
    required AppFailure failure,
    String? message,
    List<CrudSideEffect> sideEffects = const <CrudSideEffect>[],
    bool fieldErrorHandled = false,
  }) : this(
         success: false,
         message: message,
         failure: failure,
         sideEffects: sideEffects,
         fieldErrorHandled: fieldErrorHandled,
       );

  final bool success;
  final T? data;
  final String? message;
  final AppFailure? failure;
  final CrudUndoAction? undo;
  final List<CrudSideEffect> sideEffects;
  final bool suppressFeedback;
  final bool fieldErrorHandled;

  bool get isFailure => !success;
  bool get hasUndo => undo != null;
  String? get userMessage => message ?? failure?.message;

  CrudResult<R> cast<R>() {
    return CrudResult<R>(
      success: success,
      data: data is R ? data as R : null,
      message: message,
      failure: failure,
      undo: undo,
      sideEffects: sideEffects,
      suppressFeedback: suppressFeedback,
      fieldErrorHandled: fieldErrorHandled,
    );
  }

  @override
  String toString() =>
      'CrudResult(success: $success, message: $message, failure: $failure, hasUndo: $hasUndo)';
}

enum BatchCrudStatus { allSucceeded, allFailed, partialSucceeded }

class BatchCrudResult<T> {
  const BatchCrudResult({required this.results, this.message});

  final List<CrudResult<T>> results;
  final String? message;

  int get totalCount => results.length;
  int get successCount => results.where((result) => result.success).length;
  int get failureCount => totalCount - successCount;

  BatchCrudStatus get status {
    if (failureCount == 0) return BatchCrudStatus.allSucceeded;
    if (successCount == 0) return BatchCrudStatus.allFailed;
    return BatchCrudStatus.partialSucceeded;
  }

  bool get isPartialSuccess => status == BatchCrudStatus.partialSucceeded;

  String get summaryMessage {
    if (message != null) return message!;
    return switch (status) {
      BatchCrudStatus.allSucceeded => '已完成 $successCount 项操作',
      BatchCrudStatus.allFailed => '全部 $failureCount 项操作失败',
      BatchCrudStatus.partialSucceeded =>
        '已完成 $successCount 项，$failureCount 项失败',
    };
  }
}
