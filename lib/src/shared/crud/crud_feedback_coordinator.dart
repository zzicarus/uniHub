import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uni_hub/src/shared/widgets/app_toast.dart';

import 'app_failure.dart';
import 'crud_result.dart';

final crudFeedbackCoordinatorProvider = Provider<CrudFeedbackCoordinator>((
  ref,
) {
  return const CrudFeedbackCoordinator();
});

class CrudFeedbackCoordinator {
  const CrudFeedbackCoordinator();

  void handle<T>(
    BuildContext context,
    CrudResult<T> result, {
    bool fieldErrorHandled = false,
  }) {
    if (result.suppressFeedback) return;

    if (result.success) {
      final undo = result.undo;
      final message = result.message;
      if (undo != null && message != null && message.isNotEmpty) {
        AppToast.undo(
          context,
          message: message,
          actionLabel: undo.label,
          onUndo: undo.execute,
        );
        return;
      }
      if (message != null && message.isNotEmpty) {
        AppToast.show(context, message: message, type: AppToastType.success);
      }
      return;
    }

    final failure = result.failure;
    final message = result.userMessage;
    if (message == null || message.isEmpty) return;

    final handledByForm = fieldErrorHandled || result.fieldErrorHandled;
    if (handledByForm &&
        (failure?.code == AppFailureCode.validation ||
            failure?.code == AppFailureCode.duplicate)) {
      return;
    }

    AppToast.show(
      context,
      message: message,
      type: _toastTypeFor(failure?.code),
    );
  }

  AppToastType _toastTypeFor(AppFailureCode? code) {
    return switch (code) {
      AppFailureCode.validation ||
      AppFailureCode.duplicate => AppToastType.info,
      AppFailureCode.conflict ||
      AppFailureCode.referenced => AppToastType.warning,
      AppFailureCode.cancelled => AppToastType.info,
      AppFailureCode.permissionDenied ||
      AppFailureCode.network ||
      AppFailureCode.fileSystem ||
      AppFailureCode.database ||
      AppFailureCode.notFound ||
      AppFailureCode.unknown ||
      null => AppToastType.error,
    };
  }
}
