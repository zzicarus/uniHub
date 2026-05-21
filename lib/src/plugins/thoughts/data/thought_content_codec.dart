import 'dart:convert';
import 'dart:io';

import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:markdown/markdown.dart' as markdown;
import 'package:markdown_quill/markdown_quill.dart';

class ThoughtContentCodec {
  static const String _format = 'unihub.quill_delta.v1';

  const ThoughtContentCodec._();

  static Document documentFromStored(String stored) {
    final trimmed = stored.trim();
    if (trimmed.isEmpty) return Document();

    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map<String, dynamic> &&
          decoded['format'] == _format &&
          decoded['delta'] is List) {
        return Document.fromJson(decoded['delta'] as List<dynamic>);
      }
      if (decoded is List) {
        return Document.fromJson(decoded);
      }
    } catch (_) {
      // Fall through to legacy Markdown conversion.
    }

    final mdDocument = markdown.Document(encodeHtml: false);
    final delta = MarkdownToDelta(markdownDocument: mdDocument).convert(stored);
    return Document.fromDelta(_normalizeImageUris(delta));
  }

  static String encodeDocument(Document document) {
    return jsonEncode({
      'format': _format,
      'delta': document.toDelta().toJson(),
    });
  }

  static String plainTextFromStored(String stored) {
    return documentFromStored(stored).toPlainText().trim();
  }

  static String titleFromStored(String stored, {int maxLength = 20}) {
    final text = plainTextFromStored(stored)
        .split(RegExp(r'\s*\n\s*'))
        .where((line) => line.trim().isNotEmpty)
        .join(' ')
        .trim();
    if (text.isEmpty) return '无标题想法';
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  static List<String> imagePathsFromStored(String stored) {
    final paths = <String>{};
    paths.addAll(_extractMarkdownImagePaths(stored));
    for (final op in documentFromStored(stored).toDelta().toList()) {
      final data = op.data;
      if (data is Map && data[BlockEmbed.imageType] is String) {
        final path = imagePathFromSource(data[BlockEmbed.imageType] as String);
        if (path != null) paths.add(path);
      }
    }
    return paths.toList();
  }

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

  static String imageSourceForPath(String path) {
    return path;
  }

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

  static List<String> mergeImagePaths(
    String? storedImages,
    String content, {
    bool Function(String)? existsChecker,
  }) {
    final paths = <String>{
      ..._decodeImagePaths(storedImages),
      ...imagePathsFromStored(content),
    };
    final checker = existsChecker ?? (path) => File(path).existsSync();
    return paths.where(checker).toList();
  }

  static Delta _normalizeImageUris(Delta delta) {
    final normalized = Delta();
    for (final op in delta.toList()) {
      final data = op.data;
      if (data is Map && data[BlockEmbed.imageType] is String) {
        final path = imagePathFromSource(data[BlockEmbed.imageType] as String);
        if (path != null) {
          normalized.insert(BlockEmbed.image(path), op.attributes);
          continue;
        }
      }
      normalized.push(op);
    }
    return normalized;
  }

  static List<String> _decodeImagePaths(String? json) {
    if (json == null || json.isEmpty) return const [];
    try {
      final list = jsonDecode(json) as List;
      return list.cast<String>();
    } catch (_) {
      return const [];
    }
  }

  static List<String> _extractMarkdownImagePaths(String text) {
    final paths = <String>[];
    final imagePattern = RegExp(r'!\[[^\]]*\]\(([^)]+)\)');
    for (final match in imagePattern.allMatches(text)) {
      final source = match.group(1);
      if (source == null) continue;
      final path = imagePathFromSource(source.trim());
      if (path != null) paths.add(path);
    }
    return paths;
  }
}
