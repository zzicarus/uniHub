import 'package:flutter_test/flutter_test.dart';
import 'package:uni_hub/src/shared/crud/crud.dart';

void main() {
  test('normalizes whitespace and keys', () {
    expect(NameNormalizer.normalize('  A   B  '), 'A B');
    expect(NameNormalizer.normalizeForKey('  Foo  '), 'foo');
  });

  group('tag validation', () {
    test('allows 24 characters and rejects longer names', () {
      expect(NameNormalizer.validateTag('a' * 24), isNull);
      expect(NameNormalizer.validateTag('a' * 25)?.message, contains('24'));
    });

    test('rejects whitespace and invalid characters', () {
      expect(
        NameNormalizer.validateTag('foo bar')?.code,
        AppFailureCode.validation,
      );
      expect(
        NameNormalizer.validateTag('foo!')?.code,
        AppFailureCode.validation,
      );
    });
  });

  group('collection box validation', () {
    test('rejects blank, slash, too long and duplicate names', () {
      expect(
        NameNormalizer.validateCollectionBoxName(' ')?.message,
        '收藏夹名称不能为空',
      );
      expect(
        NameNormalizer.validateCollectionBoxName('a/b')?.message,
        '收藏夹名称不能包含 /',
      );
      expect(
        NameNormalizer.validateCollectionBoxName('a' * 31)?.message,
        contains('30'),
      );
      expect(
        NameNormalizer.validateCollectionBoxName(
          ' Work ',
          siblingNames: ['work'],
        )?.code,
        AppFailureCode.duplicate,
      );
    });
  });
}
