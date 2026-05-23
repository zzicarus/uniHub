import 'package:flutter_test/flutter_test.dart';
import 'package:uni_hub/src/shared/tags/tag_filter_logic.dart';
import 'package:uni_hub/src/shared/tags/tag_models.dart';

void main() {
  group('TagFilterLogic.toggle', () {
    test('adds a tag to an empty set', () {
      final result = TagFilterLogic.toggle(<String>{}, 'flutter');
      expect(result, {'flutter'});
    });

    test('removes a tag that is already present', () {
      final result = TagFilterLogic.toggle({'flutter', 'dart'}, 'flutter');
      expect(result, {'dart'});
    });

    test('normalizes the input tag before toggling', () {
      final result = TagFilterLogic.toggle(<String>{}, ' #Flutter ');
      expect(result, {'Flutter'});
    });

    test('returns original set for empty tag', () {
      final result = TagFilterLogic.toggle({'a'}, '');
      expect(result, {'a'});
    });
  });

  group('TagFilterLogic.remove', () {
    test('removes a tag that exists', () {
      final result = TagFilterLogic.remove({'a', 'b', 'c'}, 'b');
      expect(result, {'a', 'c'});
    });

    test('ignores removal of non-existent tag', () {
      final result = TagFilterLogic.remove({'a', 'b'}, 'c');
      expect(result, {'a', 'b'});
    });

    test('normalizes the input before removal', () {
      final result = TagFilterLogic.remove({'Flutter'}, ' #Flutter ');
      expect(result, isEmpty);
    });
  });

  group('TagFilterLogic.rename', () {
    test('replaces oldTag with newTag in the set', () {
      final result = TagFilterLogic.rename(
        {'personal', 'work'},
        'personal',
        'life',
      );
      expect(result, {'life', 'work'});
    });

    test('does nothing when oldTag is not present', () {
      final result = TagFilterLogic.rename({'work'}, 'personal', 'life');
      expect(result, {'work'});
    });

    test('normalizes both old and new tags', () {
      final result = TagFilterLogic.rename(
        {'Personal'},
        ' #Personal ',
        ' Life ',
      );
      expect(result, {'Life'});
    });

    test('returns original set when old or new normalizes to empty', () {
      final result = TagFilterLogic.rename({'a'}, '', 'b');
      expect(result, {'a'});
    });
  });

  group('TagFilterLogic.clear', () {
    test('returns an empty set', () {
      final result = TagFilterLogic.clear();
      expect(result, isEmpty);
    });
  });

  group('TagFilterLogic.matches', () {
    test('returns true when selectedTags is empty (no filter)', () {
      expect(
        TagFilterLogic.matches(
          itemTags: ['a', 'b'],
          selectedTags: <String>{},
        ),
        isTrue,
      );
    });

    group('TagMatchMode.all', () {
      test('returns true when item has all selected tags', () {
        expect(
          TagFilterLogic.matches(
            itemTags: ['a', 'b', 'c'],
            selectedTags: {'a', 'b'},
            mode: TagMatchMode.all,
          ),
          isTrue,
        );
      });

      test('returns false when item misses one selected tag', () {
        expect(
          TagFilterLogic.matches(
            itemTags: ['a', 'b'],
            selectedTags: {'a', 'c'},
            mode: TagMatchMode.all,
          ),
          isFalse,
        );
      });

      test('normalizes item tags before matching', () {
        expect(
          TagFilterLogic.matches(
            itemTags: [' #产品 ', '代码'],
            selectedTags: {'产品', '代码'},
            mode: TagMatchMode.all,
          ),
          isTrue,
        );
      });
    });

    group('TagMatchMode.any', () {
      test('returns true when item has at least one selected tag', () {
        expect(
          TagFilterLogic.matches(
            itemTags: ['a', 'b'],
            selectedTags: {'c', 'a'},
            mode: TagMatchMode.any,
          ),
          isTrue,
        );
      });

      test('returns false when item has none of the selected tags', () {
        expect(
          TagFilterLogic.matches(
            itemTags: ['a', 'b'],
            selectedTags: {'c', 'd'},
            mode: TagMatchMode.any,
          ),
          isFalse,
        );
      });
    });

    test('returns false when item tags are all empty after normalization', () {
      expect(
        TagFilterLogic.matches(
          itemTags: ['', '  '],
          selectedTags: {'a'},
          mode: TagMatchMode.all,
        ),
        isFalse,
      );
    });
  });

  group('TagFilterLogic.countTags', () {
    test('counts occurrences across multiple tag lists', () {
      final result = TagFilterLogic.countTags([
        ['a', 'b'],
        ['a', 'c'],
        ['b', 'd'],
      ]);
      expect(result, {'a': 2, 'b': 2, 'c': 1, 'd': 1});
    });

    test('normalizes tags before counting', () {
      final result = TagFilterLogic.countTags([
        [' #产品 '],
        ['产品'],
      ]);
      expect(result, {'产品': 2});
    });

    test('returns empty map for empty input', () {
      expect(TagFilterLogic.countTags([]), isEmpty);
    });
  });

  group('TagFilterLogic.sortStats', () {
    test('sorts by count descending, then name ascending', () {
      final result = TagFilterLogic.sortStats({
        'a': 5,
        'b': 3,
        'c': 3,
        'd': 1,
      });
      expect(result.length, 4);
      expect(result[0].name, 'a');
      expect(result[0].count, 5);
      expect(result[1].name, 'b');
      expect(result[1].count, 3);
      expect(result[2].name, 'c');
      expect(result[2].count, 3);
      expect(result[3].name, 'd');
      expect(result[3].count, 1);
    });

    test('returns empty list for empty map', () {
      expect(TagFilterLogic.sortStats({}), isEmpty);
    });
  });
}
