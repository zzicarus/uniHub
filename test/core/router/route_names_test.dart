import 'package:flutter_test/flutter_test.dart';
import 'package:uni_hub/src/core/router/route_names.dart';

void main() {
  group('RouteNames', () {
    test('all constants are non-empty strings', () {
      expect(RouteNames.home, isA<String>());
      expect(RouteNames.home, isNotEmpty);

      expect(RouteNames.thoughts, isA<String>());
      expect(RouteNames.thoughts, isNotEmpty);

      expect(RouteNames.thoughtEditor, isA<String>());
      expect(RouteNames.thoughtEditor, isNotEmpty);

      expect(RouteNames.todos, isA<String>());
      expect(RouteNames.todos, isNotEmpty);

      expect(RouteNames.notes, isA<String>());
      expect(RouteNames.notes, isNotEmpty);

      expect(RouteNames.calendar, isA<String>());
      expect(RouteNames.calendar, isNotEmpty);

      expect(RouteNames.favorites, isA<String>());
      expect(RouteNames.favorites, isNotEmpty);

      expect(RouteNames.search, isA<String>());
      expect(RouteNames.search, isNotEmpty);

      expect(RouteNames.settings, isA<String>());
      expect(RouteNames.settings, isNotEmpty);

      expect(RouteNames.styleGuide, isA<String>());
      expect(RouteNames.styleGuide, isNotEmpty);
    });

    test('expected constants exist with correct values', () {
      expect(RouteNames.home, 'home');
      expect(RouteNames.thoughts, 'thoughts');
      expect(RouteNames.thoughtEditor, 'thought-editor');
      expect(RouteNames.todos, 'todos');
      expect(RouteNames.notes, 'notes');
      expect(RouteNames.calendar, 'calendar');
      expect(RouteNames.favorites, 'favorites');
      expect(RouteNames.search, 'search');
      expect(RouteNames.settings, 'settings');
      expect(RouteNames.styleGuide, 'style-guide');
    });

    test('all constants are unique', () {
      final values = <String>{
        RouteNames.home,
        RouteNames.thoughts,
        RouteNames.thoughtEditor,
        RouteNames.todos,
        RouteNames.notes,
        RouteNames.calendar,
        RouteNames.favorites,
        RouteNames.search,
        RouteNames.settings,
        RouteNames.styleGuide,
      };
      expect(values, hasLength(10));
    });
  });
}
