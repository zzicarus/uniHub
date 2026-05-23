import 'dart:convert';
import 'dart:io';

import 'package:flutter_quill/flutter_quill.dart' show BlockEmbed, Document;
import 'package:flutter_quill/quill_delta.dart' show Delta;

import '../../../../src/shared/editor/appflowy_document_tools.dart';

class ThoughtContentCodec {
  /// Current format identifier for AppFlowy JSON content.
  static const String format = 'unihub.appflowy_json.v1';

  @Deprecated('Use [format] instead')
  static const String _format = 'unihub.quill_delta.v1';

  const ThoughtContentCodec._();

  // ---------------------------------------------------------------------------
  // AppFlowy JSON (new format)
  // ---------------------------------------------------------------------------

  /// Encodes a document into the `unihub.appflowy_json.v1` format string.
  static String encodeAppFlowy({
    required Map<String, dynamic> document,
    required String plainText,
  }) {
    return jsonEncode({
      'format': format,
      'document': document,
      'plainText': plainText,
    });
  }

  /// Extracts the AppFlowy document JSON from a stored content string.
  ///
  /// Returns `null` if the stored data is not in the new format.
  static Map<String, dynamic>? documentJsonFromStored(String stored) {
    try {
      final decoded = jsonDecode(stored.trim());
      if (decoded is Map<String, dynamic> && decoded['format'] == format) {
        final doc = decoded['document'];
        if (doc is Map<String, dynamic>) return doc;
      }
    } catch (_) {
      // Not valid JSON — return null.
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Plain text & title (AppFlowy-aware)
  // ---------------------------------------------------------------------------

  /// Extracts plain text from a stored content string.
  ///
  /// Priority:
  /// 1. Direct `plainText` field from `unihub.appflowy_json.v1` wrapper.
  /// 2. Extract from `document` JSON via [AppFlowyDocumentTools].
  /// 3. Fallback: empty string (old format data is discarded).
  static String plainTextFromStored(String stored) {
    final trimmed = stored.trim();
    if (trimmed.isEmpty) return '';

    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map<String, dynamic> && decoded['format'] == format) {
        // Prefer the stored plainText field.
        final plainText = decoded['plainText'];
        if (plainText is String && plainText.isNotEmpty) {
          return plainText.trim();
        }
        // Fall back to extracting from the document JSON.
        final doc = decoded['document'];
        if (doc is Map<String, dynamic>) {
          return AppFlowyDocumentTools.plainTextFromDocumentJson(doc);
        }
      }
    } catch (_) {
      // Not valid JSON.
    }

    // Old format data or unparseable content — discard.
    return '';
  }

  /// Generates a title from the stored content string.
  ///
  /// Takes the first non-empty line of the plain text.
  /// Returns `'无标题想法'` when empty. Truncates at [maxLength].
  static String titleFromStored(String stored, {int maxLength = 20}) {
    final text = plainTextFromStored(stored);
    final firstLine = text
        .split(RegExp(r'\s*\n\s*'))
        .where((line) => line.trim().isNotEmpty)
        .join(' ')
        .trim();
    if (firstLine.isEmpty) return '无标题想法';
    if (firstLine.length <= maxLength) return firstLine;
    return '${firstLine.substring(0, maxLength)}...';
  }

  /// Returns image paths extracted from stored content.
  ///
  /// Phase 1: Returns an empty list, because images are stored in an
  /// independent [imagePaths] field and AppFlowy image block is not yet
  /// implemented.
  static List<String> imagePathsFromStored(String stored) {
    return const [];
  }

  // ---------------------------------------------------------------------------
  // Deprecated stubs (Quill-specific)
  // ---------------------------------------------------------------------------
  // These methods are kept to allow callers to compile while they are
  // migrated to the new AppFlowy-based API. They will be removed in a
  // later phase once all callers are updated.
  //

  @Deprecated('Use documentJsonFromStored or the AppFlowy editor instead')
  static Document documentFromStored(String stored) {
    return Document();
  }

  @Deprecated('Use encodeAppFlowy instead')
  static String encodeDocument(Document document) {
    return jsonEncode({
      'format': _format,
      'delta': document.toDelta().toJson(),
    });
  }

  @Deprecated('Images are now managed separately via the imagePaths field')
  static String imageSourceForPath(String path) {
    return path;
  }

  @Deprecated('Images are now managed separately via the imagePaths field')
  static String? imagePathFromSource(String source) {
    if (source.isEmpty) return null;
    final uri = Uri.tryParse(source);
    if (uri != null && uri.scheme == 'file') {
      return uri.toFilePath();
    }
    if (source.startsWith('file://file:///')) {
      final fixed = source.replaceFirst('file://', '');
      return Uri.tryParse(fixed)?.toFilePath();
    }
    if (source.startsWith('http://') ||
        source.startsWith('https://') ||
        source.startsWith('data:')) {
      return null;
    }
    return source;
  }

  @Deprecated('Images are now managed separately via the imagePaths field')
  static Document removeImage(Document document, String path) {
    final delta = Delta();
    for (final op in document.toDelta().toList()) {
      final data = op.data;
      if (data is Map && data[BlockEmbed.imageType] is String) {
        final imagePath = imagePathFromSource(
          data[BlockEmbed.imageType] as String,
        );
        if (imagePath == path) continue;
      }
      delta.push(op);
    }
    return Document.fromDelta(delta);
  }

  @Deprecated('Images are now managed separately via the imagePaths field')
  static List<String> mergeImagePaths(
    String? storedImages,
    String content, {
    bool Function(String)? existsChecker,
  }) {
    final paths = <String>{
      ..._decodeImagePaths(storedImages),
    };
    final checker = existsChecker ?? (path) => File(path).existsSync();
    return paths.where(checker).toList();
  }

  @Deprecated('No longer needed')
  static List<String> _decodeImagePaths(String? json) {
    if (json == null || json.isEmpty) return const [];
    try {
      final list = jsonDecode(json) as List;
      return list.cast<String>();
    } catch (_) {
      return const [];
    }
  }
}
