import 'package:flutter_test/flutter_test.dart';
import 'package:uni_hub/src/shared/tags/tag_codec.dart';

void main() {
  group('TagCodec.normalize', () {
    test('trims whitespace', () {
      expect(TagCodec.normalize('  Flutter  '), 'Flutter');
    });

    test('strips leading #', () {
      expect(TagCodec.normalize('#产品'), '产品');
    });

    test('strips leading # with whitespace', () {
      expect(TagCodec.normalize('  # Flutter  '), 'Flutter');
    });

    test('returns empty string for blank input', () {
      expect(TagCodec.normalize('   '), '');
    });

    test('preserves already-clean tag', () {
      expect(TagCodec.normalize('Flutter'), 'Flutter');
    });
  });

  group('TagCodec.display', () {
    test('prepends #', () {
      expect(TagCodec.display('产品'), '#产品');
    });
  });

  group('TagCodec.parseCommaSeparated', () {
    test('returns empty list for null', () {
      expect(TagCodec.parseCommaSeparated(null), isEmpty);
    });

    test('returns empty list for empty string', () {
      expect(TagCodec.parseCommaSeparated(''), isEmpty);
    });

    test('returns empty list for blank string', () {
      expect(TagCodec.parseCommaSeparated('   '), isEmpty);
    });

    test(
      'parses comma-separated tags, strips #, trims whitespace, deduplicates',
      () {
        expect(
          TagCodec.parseCommaSeparated('产品, 灵感, #代码'),
          ['产品', '灵感', '代码'],
        );
      },
    );

    test('deduplicates repeated tags', () {
      expect(
        TagCodec.parseCommaSeparated('a, b, a, c, b'),
        ['a', 'b', 'c'],
      );
    });

    test('filters out empty segments', () {
      expect(
        TagCodec.parseCommaSeparated('a, , b,,'),
        ['a', 'b'],
      );
    });
  });

  group('TagCodec.encodeCommaSeparated', () {
    test('returns null for empty input', () {
      expect(TagCodec.encodeCommaSeparated([]), isNull);
    });

    test('normalizes and joins tags', () {
      expect(
        TagCodec.encodeCommaSeparated([' 产品 ', '#灵感', '代码']),
        '产品,灵感,代码',
      );
    });

    test('deduplicates while preserving first occurrence order', () {
      expect(
        TagCodec.encodeCommaSeparated(['a', 'b', 'a', 'c']),
        'a,b,c',
      );
    });

    test('skips empty tags', () {
      expect(
        TagCodec.encodeCommaSeparated(['a', '', '  ', 'b']),
        'a,b',
      );
    });
  });

  group('TagCodec.validate', () {
    test('empty string is invalid', () {
      final result = TagCodec.validate('');
      expect(result.isValid, isFalse);
      expect(result.message, isNotNull);
    });

    test('whitespace-only is invalid', () {
      final result = TagCodec.validate('   ');
      expect(result.isValid, isFalse);
    });

    test('stripped leading # is valid', () {
      final result = TagCodec.validate('#产品');
      expect(result.isValid, isTrue);
    });

    test('tag with 21 characters is invalid', () {
      final result = TagCodec.validate('a' * 21);
      expect(result.isValid, isFalse);
      expect(result.message, contains('20'));
    });

    test('tag with exactly 20 characters is valid', () {
      final result = TagCodec.validate('a' * 20);
      expect(result.isValid, isTrue);
    });

    test('Chinese characters are valid', () {
      expect(TagCodec.validate('产品设计').isValid, isTrue);
      expect(TagCodec.validate('读书笔记').isValid, isTrue);
    });

    test('English letters are valid', () {
      expect(TagCodec.validate('Flutter').isValid, isTrue);
      expect(TagCodec.validate('UIUX').isValid, isTrue);
    });

    test('digits are valid', () {
      expect(TagCodec.validate('2024').isValid, isTrue);
    });

    test('short dashes and underscores are valid', () {
      expect(TagCodec.validate('flutter-dev').isValid, isTrue);
      expect(TagCodec.validate('my_tag').isValid, isTrue);
    });

    test('special characters are invalid', () {
      expect(TagCodec.validate('tag!').isValid, isFalse);
      expect(TagCodec.validate('tag@').isValid, isFalse);
      expect(TagCodec.validate('tag space').isValid, isFalse);
      expect(TagCodec.validate('tag.dot').isValid, isFalse);
    });
  });
}
