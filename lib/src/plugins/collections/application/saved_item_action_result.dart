/// Result of a saved item action performed by [SavedItemActionsController].
///
/// Contains success status, an optional user-facing message, and an optional
/// undo action that the UI can attach to a SnackBar or other undo mechanism.
class SavedItemActionResult {
  const SavedItemActionResult({
    required this.success,
    this.message,
    this.undo,
    this.error,
  });

  /// Whether the operation completed successfully.
  final bool success;

  /// User-facing message describing the result (e.g. "已删除" or an error).
  final String? message;

  /// An optional undo action that can be shown in a SnackBar.
  ///
  /// When present, the UI should offer the user a chance to undo the
  /// operation within a limited time window.
  final SavedItemUndoAction? undo;

  /// The error object when [success] is false, for diagnostic purposes.
  final Object? error;

  @override
  String toString() =>
      'SavedItemActionResult(success: $success, message: $message, '
      'hasUndo: ${undo != null}, error: $error)';
}

/// Represents an undoable action that can be reverted.
///
/// UI components use [label] as the SnackBar action button text and
/// [execute] as the callback triggered when the user taps "撤销".
class SavedItemUndoAction {
  const SavedItemUndoAction({
    required this.label,
    required this.execute,
  });

  /// Short label for the undo button (e.g. "撤销").
  final String label;

  /// The callback to revert the original action.
  final Future<void> Function() execute;

  @override
  String toString() => 'SavedItemUndoAction(label: $label)';
}
