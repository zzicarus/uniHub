/// Tools for creating and extracting data from AppFlowy Document JSON.
///
/// These utilities isolate the details of AppFlowy's document JSON structure
/// from UI components, so that pages and controllers never need to write
/// raw JSON directly.
///
/// Document JSON structure (AppFlowy v6):
/// ```json
/// {
///   "document": {
///     "type": "page",
///     "children": [
///       {
///         "type": "paragraph",
///         "data": {
///           "delta": [
///             { "insert": "Some text here" }
///           ]
///         }
///       }
///     ]
///   }
/// }
/// ```
library;

import 'package:appflowy_editor/appflowy_editor.dart';

abstract final class AppFlowyDocumentTools {
  /// Returns a minimal empty document JSON with a single empty paragraph.
  ///
  /// The returned map conforms to the AppFlowy document format and can be
  /// directly passed to [AppFlowyThoughtEditor] or [Document.fromJson].
  static Map<String, dynamic> emptyDocumentJson() {
    return Document.blank(withInitialText: true).toJson();
  }

  /// Creates a document JSON from a plain text string.
  ///
  /// The text is stored as a single paragraph node. If [text] is empty,
  /// the result is equivalent to [emptyDocumentJson].
  ///
  /// The returned map conforms to the AppFlowy document format.
  static Map<String, dynamic> documentJsonFromPlainText(String text) {
    return Document(
      root: Node(
        type: 'page',
        children: [paragraphNode(text: text)],
      ),
    ).toJson();
  }

  /// Extracts plain text from an AppFlowy document JSON structure.
  ///
  /// Recursively walks the document tree to collect text content:
  /// - From `data.delta[].insert` strings (standard paragraph blocks)
  /// - From `data.text` fields (some block types may use this)
  /// - From nested `children` nodes
  ///
  /// Blocks are separated by newlines. The result is trimmed.
  static String plainTextFromDocumentJson(Map<String, dynamic> document) {
    final buffer = StringBuffer();
    // Handle both the outer wrapper {'document': {...}} and the inner
    // node structure {'type': 'page', 'children': [...]}.
    final root = document['document'] is Map<String, dynamic>
        ? document['document'] as Map<String, dynamic>
        : document;
    _extractText(root, buffer);
    return buffer.toString().trim();
  }

  /// Recursively extracts text from a document node map.
  static void _extractText(Map<String, dynamic> node, StringBuffer buffer) {
    final data = node['data'] as Map<String, dynamic>?;

    if (data != null) {
      // 1. Extract from delta operations (standard approach for AppFlowy).
      final delta = data['delta'];
      if (delta is List) {
        for (final operation in delta) {
          if (operation is Map<String, dynamic>) {
            final insert = operation['insert'];
            if (insert is String) {
              buffer.write(insert);
            }
          }
        }
        // Add a newline after each block.
        buffer.writeln();
      }

      // 2. Extract from a direct text field (some block types may use this).
      final text = data['text'];
      if (text is String) {
        buffer.write(text);
        buffer.writeln();
      }
    }

    // 3. Recurse into children.
    final children = node['children'] as List<dynamic>?;
    if (children != null) {
      for (final child in children) {
        if (child is Map<String, dynamic>) {
          _extractText(child, buffer);
        }
      }
    }
  }
}
