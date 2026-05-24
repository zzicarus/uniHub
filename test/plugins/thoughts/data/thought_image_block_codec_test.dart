import 'package:flutter_test/flutter_test.dart';

import 'package:uni_hub/src/plugins/thoughts/data/thought_image_block_codec.dart';

/// Helper: creates an image node map in the legacy JSON format
/// (without AppFlowy's `imageNode` factory — used for extraction tests).
///
/// This is the JSON representation that ends up in the document after
/// round-tripping through [Document.toJson] / JSON serialization.
Map<String, dynamic> _imageNodeJson({
  required String id,
  required String url,
}) {
  return {
    'type': 'image',
    'attributes': {
      'url': url,
      'image_id': id,
      'align': 'center',
    },
  };
}

/// Helper: creates a minimal page document with the given children.
Map<String, dynamic> _pageDoc(List<Map<String, dynamic>> children) {
  return {
    'type': 'page',
    'children': children,
  };
}

/// Helper: wraps a page node in the outer `{'document': ...}` envelope
/// produced by [Document.toJson].
Map<String, dynamic> _envelope(Map<String, dynamic> root) {
  return {'document': root};
}

/// Helper: creates a minimal paragraph node.
Map<String, dynamic> _paragraph(String text) {
  return {
    'type': 'paragraph',
    'data': {
      'delta': [
        {'insert': text},
      ],
    },
  };
}

void main() {
  // ---------------------------------------------------------------------------
  // ThoughtImageRef
  // ---------------------------------------------------------------------------

  group('ThoughtImageRef', () {
    test('equality', () {
      expect(
        const ThoughtImageRef(id: 'a', path: '/p1.png'),
        const ThoughtImageRef(id: 'a', path: '/p1.png'),
      );
    });

    test('inequality — different id', () {
      expect(
        const ThoughtImageRef(id: 'a', path: '/p1.png'),
        isNot(const ThoughtImageRef(id: 'b', path: '/p1.png')),
      );
    });

    test('inequality — different path', () {
      expect(
        const ThoughtImageRef(id: 'a', path: '/p1.png'),
        isNot(const ThoughtImageRef(id: 'a', path: '/p2.png')),
      );
    });

    test('toString contains id and path', () {
      final ref = const ThoughtImageRef(id: 'x', path: '/y.png');
      expect(ref.toString(), contains('x'));
      expect(ref.toString(), contains('/y.png'));
    });
  });

  // ---------------------------------------------------------------------------
  // createImageNode
  // ---------------------------------------------------------------------------

  group('createImageNode', () {
    test('creates node with correct type', () {
      final node = ThoughtImageBlockCodec.createImageNode(
        id: 'img_1',
        path: '/tmp/test.png',
      );
      expect(node.type, 'image');
    });

    test('creates node with url attribute', () {
      final node = ThoughtImageBlockCodec.createImageNode(
        id: 'img_1',
        path: '/tmp/test.png',
      );
      expect(node.attributes['url'], '/tmp/test.png');
    });

    test('creates node with custom image_id attribute', () {
      final node = ThoughtImageBlockCodec.createImageNode(
        id: 'img_1',
        path: '/tmp/test.png',
      );
      expect(node.attributes['image_id'], 'img_1');
    });
  });

  // ---------------------------------------------------------------------------
  // generateImageId
  // ---------------------------------------------------------------------------

  group('generateImageId', () {
    test('generates id with img_ prefix', () {
      final id = ThoughtImageBlockCodec.generateImageId();
      expect(id, startsWith('img_'));
    });

    test('generates unique ids', () {
      final ids = <String>{};
      for (int i = 0; i < 100; i++) {
        ids.add(ThoughtImageBlockCodec.generateImageId());
      }
      expect(ids.length, 100);
    });
  });

  // ---------------------------------------------------------------------------
  // extractImageRefs
  // ---------------------------------------------------------------------------

  group('extractImageRefs', () {
    test('returns empty list for empty document', () {
      final doc = _envelope(_pageDoc([]));
      expect(ThoughtImageBlockCodec.extractImageRefs(doc), isEmpty);
    });

    test('returns empty list for document with no images', () {
      final doc = _envelope(_pageDoc([
        _paragraph('Hello'),
        _paragraph('World'),
      ]));
      expect(ThoughtImageBlockCodec.extractImageRefs(doc), isEmpty);
    });

    test('extracts single image', () {
      final doc = _envelope(_pageDoc([
        _imageNodeJson(id: 'img_1', url: '/p1.png'),
      ]));
      final refs = ThoughtImageBlockCodec.extractImageRefs(doc);
      expect(refs.length, 1);
      expect(refs[0].id, 'img_1');
      expect(refs[0].path, '/p1.png');
    });

    test('extracts multiple images', () {
      final doc = _envelope(_pageDoc([
        _imageNodeJson(id: 'img_1', url: '/p1.png'),
        _paragraph('text'),
        _imageNodeJson(id: 'img_2', url: '/p2.png'),
      ]));
      final refs = ThoughtImageBlockCodec.extractImageRefs(doc);
      expect(refs.length, 2);
      expect(refs[0].id, 'img_1');
      expect(refs[1].id, 'img_2');
    });

    test('extracts images from nested children', () {
      // Simulate a column block containing an image.
      final doc = _envelope(_pageDoc([
        _paragraph('text'),
        {
          'type': 'column',
          'children': [
            _imageNodeJson(id: 'img_nested', url: '/nested.png'),
          ],
        },
      ]));
      final refs = ThoughtImageBlockCodec.extractImageRefs(doc);
      expect(refs.length, 1);
      expect(refs[0].id, 'img_nested');
      expect(refs[0].path, '/nested.png');
    });

    test('ignores image node with empty url', () {
      final doc = _envelope(_pageDoc([
        _imageNodeJson(id: 'img_1', url: ''),
      ]));
      final refs = ThoughtImageBlockCodec.extractImageRefs(doc);
      expect(refs, isEmpty);
    });

    test('handles document without envelope wrapper', () {
      final doc = _pageDoc([
        _imageNodeJson(id: 'img_1', url: '/p1.png'),
      ]);
      final refs = ThoughtImageBlockCodec.extractImageRefs(doc);
      expect(refs.length, 1);
    });

    test('returns empty list for malformed document', () {
      expect(
        ThoughtImageBlockCodec.extractImageRefs({'not': 'a_document'}),
        isEmpty,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // removeImageNode
  // ---------------------------------------------------------------------------

  group('removeImageNode', () {
    test('removes image with matching id', () {
      final doc = _envelope(_pageDoc([
        _imageNodeJson(id: 'img_1', url: '/p1.png'),
        _paragraph('text'),
        _imageNodeJson(id: 'img_2', url: '/p2.png'),
      ]));
      final result = ThoughtImageBlockCodec.removeImageNode(
        document: doc,
        imageId: 'img_1',
      );
      final refs = ThoughtImageBlockCodec.extractImageRefs(result);
      expect(refs.length, 1);
      expect(refs[0].id, 'img_2');
    });

    test('removes only the specified image', () {
      final doc = _envelope(_pageDoc([
        _imageNodeJson(id: 'img_1', url: '/p1.png'),
        _imageNodeJson(id: 'img_2', url: '/p2.png'),
      ]));
      final result = ThoughtImageBlockCodec.removeImageNode(
        document: doc,
        imageId: 'img_1',
      );
      final refs = ThoughtImageBlockCodec.extractImageRefs(result);
      expect(refs.length, 1);
      expect(refs[0].id, 'img_2');
    });

    test('returns unchanged document when no matching id', () {
      final doc = _envelope(_pageDoc([
        _imageNodeJson(id: 'img_1', url: '/p1.png'),
      ]));
      final result = ThoughtImageBlockCodec.removeImageNode(
        document: doc,
        imageId: 'nonexistent',
      );
      final refs = ThoughtImageBlockCodec.extractImageRefs(result);
      expect(refs.length, 1);
      expect(refs[0].id, 'img_1');
    });

    test('removes image from nested children', () {
      final doc = _envelope(_pageDoc([
        {
          'type': 'column',
          'children': [
            _imageNodeJson(id: 'img_nested', url: '/nested.png'),
          ],
        },
      ]));
      final result = ThoughtImageBlockCodec.removeImageNode(
        document: doc,
        imageId: 'img_nested',
      );
      final refs = ThoughtImageBlockCodec.extractImageRefs(result);
      expect(refs, isEmpty);
    });

    test('does not mutate the original document', () {
      final doc = _envelope(_pageDoc([
        _imageNodeJson(id: 'img_1', url: '/p1.png'),
      ]));
      ThoughtImageBlockCodec.removeImageNode(
        document: doc,
        imageId: 'img_1',
      );
      // Original should still have the image.
      final refs = ThoughtImageBlockCodec.extractImageRefs(doc);
      expect(refs.length, 1);
    });
  });

  // ---------------------------------------------------------------------------
  // containsPath
  // ---------------------------------------------------------------------------

  group('containsPath', () {
    test('returns true when path exists', () {
      final doc = _envelope(_pageDoc([
        _imageNodeJson(id: 'img_1', url: '/p1.png'),
      ]));
      expect(
        ThoughtImageBlockCodec.containsPath(doc, '/p1.png'),
        isTrue,
      );
    });

    test('returns false when path does not exist', () {
      final doc = _envelope(_pageDoc([
        _imageNodeJson(id: 'img_1', url: '/p1.png'),
      ]));
      expect(
        ThoughtImageBlockCodec.containsPath(doc, '/other.png'),
        isFalse,
      );
    });

    test('returns false for empty document', () {
      final doc = _envelope(_pageDoc([]));
      expect(
        ThoughtImageBlockCodec.containsPath(doc, '/p1.png'),
        isFalse,
      );
    });
  });
}
