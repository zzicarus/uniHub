/// Encapsulates the AppFlowy Editor for use in Thought Editor Workspace.
///
/// Provides a clean API that hides [appflowy_editor] internal details.
/// Pages and controllers interact with this widget instead of directly
/// using [AppFlowyEditor], [EditorState], or [Document].
///
/// Input lifecycle:
///   1. [initialJson] → parsed via [Document.fromJson] → [EditorState]
///   2. [initialText] → wrapped into document JSON → [EditorState]
///   3. both null     → [EditorState.blank(withInitialText: true)]
///
/// Output lifecycle:
///   Every content change triggers [onChanged] with the current
///   [AppFlowyThoughtEditorValue].
library;

import 'dart:async';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

import 'appflowy_document_tools.dart';

/// The value emitted by [AppFlowyThoughtEditor] on every content change.
class AppFlowyThoughtEditorValue {
  const AppFlowyThoughtEditorValue({
    required this.documentJson,
    required this.plainText,
  });

  /// The full AppFlowy document JSON map.
  ///
  /// Structure:
  /// ```json
  /// { "document": { "type": "page", "children": [...] } }
  /// ```
  final Map<String, dynamic> documentJson;

  /// The plain text extracted from the document (trimmed).
  final String plainText;
}

/// A thin wrapper around [AppFlowyEditor] that:
///
/// - Creates an [EditorState] from JSON, text, or a blank document.
/// - Listens to document changes and reports them via [onChanged].
/// - Hides [AppFlowyEditor], [EditorState], [Document], [Delta] internals.
///
/// Usage:
/// ```dart
/// AppFlowyThoughtEditor(
///   initialJson: thoughtContentCodec.documentJsonFromStored(...),
///   initialText: 'Type your thoughts...',
///   placeholder: '开始书写你的想法...',
///   onChanged: (value) {
///     print(value.plainText);       // extracted plain text
///     print(value.documentJson);    // full document JSON
///   },
/// )
/// ```
class AppFlowyThoughtEditor extends StatefulWidget {
  const AppFlowyThoughtEditor({
    super.key,
    this.initialJson,
    this.initialText,
    this.placeholder = '开始书写你的想法...',
    this.autofocus = false,
    required this.onChanged,
  });

  /// Initial document JSON in AppFlowy format.
  ///
  /// When provided, takes precedence over [initialText].
  final Map<String, dynamic>? initialJson;

  /// Initial plain text to populate the document.
  ///
  /// Only used when [initialJson] is null.
  final String? initialText;

  /// Placeholder text shown when the document is empty.
  final String placeholder;

  /// Whether to auto-focus the editor on mount.
  final bool autofocus;

  /// Called on every document content change.
  ///
  /// Fires synchronously within the transaction callback, so the parent
  /// always holds the latest [AppFlowyThoughtEditorValue].
  final ValueChanged<AppFlowyThoughtEditorValue> onChanged;

  @override
  State<AppFlowyThoughtEditor> createState() => _AppFlowyThoughtEditorState();
}

class _AppFlowyThoughtEditorState extends State<AppFlowyThoughtEditor> {
  late final EditorState _editorState;
  StreamSubscription<EditorTransactionValue>? _subscription;

  @override
  void initState() {
    super.initState();
    _editorState = _createEditorState();
    // Defer the initial value emission so that the parent widget has
    // finished building before any onChanged → setState chain fires.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _emitCurrentValue();
    });
    _subscription = _editorState.transactionStream.listen(_onTransaction);
  }

  @override
  void didUpdateWidget(AppFlowyThoughtEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Note: changing initialJson/initialText after creation is not
    // supported in the first version. Recreate the widget if the
    // initial content needs to change.
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _editorState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Use the app theme's body style as the base so the editor inherits
    // the project's configured font family (e.g. Inter) instead of
    // falling back to Flutter's default font.
    final editorTextStyle = theme.textTheme.bodyMedium?.copyWith(
      fontSize: 15,
      color: theme.colorScheme.onSurface.withValues(alpha: 0.87),
    ) ?? const TextStyle(fontSize: 15);

    return AppFlowyEditor(
      editorState: _editorState,
      autoFocus: widget.autofocus,
      shrinkWrap: false,
      editorStyle: EditorStyle.desktop(
        cursorColor: theme.colorScheme.primary,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        textStyleConfiguration: TextStyleConfiguration(
          text: editorTextStyle,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Creates an [EditorState] from the provided input.
  EditorState _createEditorState() {
    // Priority: initialJson > initialText > blank.
    if (widget.initialJson != null) {
      // Accept both the full {"document": root} wrapper and the
      // inner {type: 'page', children: [...]} node structure.
      final json = widget.initialJson!.containsKey('document')
          ? widget.initialJson!
          : <String, dynamic>{'document': widget.initialJson!};
      final document = Document.fromJson(json);
      return EditorState(document: document);
    }

    if (widget.initialText != null && widget.initialText!.isNotEmpty) {
      final document = _documentFromPlainText(widget.initialText!);
      return EditorState(document: document);
    }

    return EditorState.blank(withInitialText: true);
  }

  /// Wraps plain text into an AppFlowy document structure.
  Document _documentFromPlainText(String text) {
    final root = Node(
      type: 'page',
      children: [paragraphNode(text: text)],
    );
    return Document(root: root);
  }

  /// Handles transaction events from the editor.
  void _onTransaction(EditorTransactionValue value) {
    final (time, _, _) = value;
    // Only emit after the transaction is applied.
    if (time == TransactionTime.after) {
      _emitCurrentValue();
    }
  }

  /// Builds the current value from the editor state and calls [onChanged].
  void _emitCurrentValue() {
    final docJson = _editorState.document.toJson();
    final plainText =
        AppFlowyDocumentTools.plainTextFromDocumentJson(docJson);
    widget.onChanged(
      AppFlowyThoughtEditorValue(
        documentJson: docJson,
        plainText: plainText.trim(),
      ),
    );
  }
}
