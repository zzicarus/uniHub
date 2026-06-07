import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:uni_hub/src/plugins/thoughts/data/thought_content_codec.dart';

/// AppFlowy-style document JSON helpers for test data.
///
/// These mirror the structure produced by [AppFlowyDocumentTools] but
/// are defined inline to avoid a dependency on `appflowy_editor` in tests.
/// Returns the raw document node tree (without the outer `document` wrapper).
Map<String, dynamic> _pageDoc(List<Map<String, dynamic>> children) {
  return {
    'type': 'page',
    'children': children,
  };
}

Map<String, dynamic> _paragraphNode(String text) {
  return {
    'type': 'paragraph',
    'data': {
      'delta': [
        {'insert': text},
      ],
    },
  };
}

String _encodeAppFlowy({
  required Map<String, dynamic> document,
  required String plainText,
}) {
  return jsonEncode({
    'format': 'unihub.appflowy_json.v1',
    'document': document,
    'plainText': plainText,
  });
}

void main() {
  group('ThoughtContentCodec — AppFlowy JSON format', () {
    // -------------------------------------------------------------------------
    // format constant
    // -------------------------------------------------------------------------
    test('format constant is unihub.appflowy_json.v1', () {
      expect(ThoughtContentCodec.format, 'unihub.appflowy_json.v1');
    });

    // -------------------------------------------------------------------------
    // encodeAppFlowy
    // -------------------------------------------------------------------------
    test('encodeAppFlowy produces valid JSON with correct format', () {
      final root = _pageDoc([_paragraphNode('Hello')]);
      final result = ThoughtContentCodec.encodeAppFlowy(
        document: root,
        plainText: 'Hello',
      );

      final decoded = jsonDecode(result) as Map<String, dynamic>;
      expect(decoded['format'], 'unihub.appflowy_json.v1');
      expect(decoded['plainText'], 'Hello');
      expect(decoded['document'], isA<Map<String, dynamic>>());
    });

    test('encodeAppFlowy preserves document structure', () {
      final root = _pageDoc([_paragraphNode('First'), _paragraphNode('Second')]);
      final result = ThoughtContentCodec.encodeAppFlowy(
        document: root,
        plainText: 'First Second',
      );

      final decoded = jsonDecode(result) as Map<String, dynamic>;
      final docField = decoded['document'] as Map<String, dynamic>;
      expect(docField['type'], 'page');
      final children = docField['children'] as List;
      expect(children.length, 2);
    });

    // -------------------------------------------------------------------------
    // documentJsonFromStored
    // -------------------------------------------------------------------------
    test('documentJsonFromStored retrieves document from valid JSON', () {
      final root = _pageDoc([_paragraphNode('text')]);
      final stored = _encodeAppFlowy(document: root, plainText: 'text');

      final doc = ThoughtContentCodec.documentJsonFromStored(stored);
      expect(doc, isNotNull);
      expect(doc!['type'], 'page');
    });

    test('documentJsonFromStored returns null for old format', () {
      const oldFormat = '{"format": "unihub.quill_delta.v1", "delta": []}';
      expect(ThoughtContentCodec.documentJsonFromStored(oldFormat), isNull);
    });

    test('documentJsonFromStored returns null for invalid JSON', () {
      expect(ThoughtContentCodec.documentJsonFromStored('not json'), isNull);
    });

    test('documentJsonFromStored returns null for empty content', () {
      expect(ThoughtContentCodec.documentJsonFromStored(''), isNull);
    });

    // -------------------------------------------------------------------------
    // plainTextFromStored — prefer wrapper.plainText
    // -------------------------------------------------------------------------
    test('plainTextFromStored reads plainText field when present', () {
      final root = _pageDoc([_paragraphNode('ignored doc text')]);
      final stored = _encodeAppFlowy(document: root, plainText: 'Hello World');

      expect(
        ThoughtContentCodec.plainTextFromStored(stored),
        'Hello World',
      );
    });

    test('plainTextFromStored extracts from document when no plainText', () {
      final root = _pageDoc([_paragraphNode('Extracted from document')]);
      // Store without plainText field.
      final stored = jsonEncode({
        'format': 'unihub.appflowy_json.v1',
        'document': root,
      });

      expect(
        ThoughtContentCodec.plainTextFromStored(stored),
        'Extracted from document',
      );
    });

    test('plainTextFromStored extracts from multi-paragraph document', () {
      final root = _pageDoc([
        _paragraphNode('Line one\n'),
        _paragraphNode('Line two\n'),
      ]);
      final stored = jsonEncode({
        'format': 'unihub.appflowy_json.v1',
        'document': root,
      });

      final result = ThoughtContentCodec.plainTextFromStored(stored);
      expect(result, contains('Line one'));
      expect(result, contains('Line two'));
    });

    test('plainTextFromStored returns empty for old format', () {
      const oldFormat = '{"format": "unihub.quill_delta.v1", "delta": []}';
      expect(ThoughtContentCodec.plainTextFromStored(oldFormat), isEmpty);
    });

    test('plainTextFromStored returns empty for empty input', () {
      expect(ThoughtContentCodec.plainTextFromStored(''), isEmpty);
    });

    test('plainTextFromStored returns empty for invalid JSON', () {
      expect(ThoughtContentCodec.plainTextFromStored('not json'), isEmpty);
    });

    test('plainTextFromStored returns empty for non-string plainText', () {
      final stored = jsonEncode({
        'format': 'unihub.appflowy_json.v1',
        'plainText': 123, // not a string
        'document': {'type': 'page', 'children': []},
      });

      // Should not crash and return empty since document has no text.
      expect(ThoughtContentCodec.plainTextFromStored(stored), isEmpty);
    });

    // -------------------------------------------------------------------------
    // titleFromStored
    // -------------------------------------------------------------------------
    test('titleFromStored uses first line as title', () {
      final root = _pageDoc([_paragraphNode('My Title')]);
      final stored = _encodeAppFlowy(document: root, plainText: 'My Title');

      expect(ThoughtContentCodec.titleFromStored(stored), 'My Title');
    });

    test('titleFromStored returns 无标题想法 for empty content', () {
      expect(
        ThoughtContentCodec.titleFromStored(''),
        '无标题想法',
      );
    });

    test('titleFromStored returns 无标题想法 for old format', () {
      const oldFormat = '{"format": "unihub.quill_delta.v1"}';
      expect(
        ThoughtContentCodec.titleFromStored(oldFormat),
        '无标题想法',
      );
    });

    test('titleFromStored respects maxLength', () {
      const longText = 'A very long title that should be truncated';
      final root = _pageDoc([_paragraphNode(longText)]);
      final stored = _encodeAppFlowy(document: root, plainText: longText);

      final title = ThoughtContentCodec.titleFromStored(stored, maxLength: 10);
      expect(title, 'A very lon...');
    });

    test('titleFromStored does not truncate when under maxLength', () {
      final root = _pageDoc([_paragraphNode('Short')]);
      final stored = _encodeAppFlowy(document: root, plainText: 'Short');

      expect(
        ThoughtContentCodec.titleFromStored(stored),
        'Short',
      );
    });

    test('titleFromStored extracts from multi-line plainText', () {
      final root = _pageDoc([
        _paragraphNode('Title line\n'),
        _paragraphNode('Body line\n'),
      ]);
      final stored = _encodeAppFlowy(
        document: root,
        plainText: 'Title line\nBody line',
      );

      expect(
        ThoughtContentCodec.titleFromStored(stored),
        'Title line Body line',
      );
    });

    // -------------------------------------------------------------------------
    // imagePathsFromStored
    // -------------------------------------------------------------------------
    test('imagePathsFromStored returns empty list in phase 1', () {
      expect(
        ThoughtContentCodec.imagePathsFromStored('any content'),
        isEmpty,
      );
    });
  });
}
