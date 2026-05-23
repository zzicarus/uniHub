import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uni_hub/src/plugins/thoughts/ui/widgets/thought_editor_controller.dart';

/// Captures the WidgetRef from a ProviderScope so it can be used
/// to construct a ThoughtEditorController for unit-level tag tests.
WidgetRef? capturedRef;

Widget buildApp() {
  return ProviderScope(
    child: Consumer(
      builder: (context, ref, child) {
        capturedRef = ref;
        return const SizedBox.shrink();
      },
    ),
  );
}

void main() {
  group('ThoughtEditorController tag validation', () {
    late ThoughtEditorController controller;

    setUp(() {
      // Reset between tests
      capturedRef = null;
    });

    tearDown(() {
      controller.dispose();
    });

    Future<void> initController(WidgetTester tester) async {
      await tester.pumpWidget(buildApp());
      controller = ThoughtEditorController(
        ref: capturedRef!,
        thoughtId: 1,
      );
      controller.initialize();
    }

    testWidgets('starts with empty tagChips and no error', (tester) async {
      await initController(tester);

      expect(controller.tagChips, isEmpty);
      expect(controller.tagErrorMessage, isNull);
    });

    testWidgets('rejects tags longer than 20 characters and sets tagErrorMessage', (
      tester,
    ) async {
      await initController(tester);

      controller.handleTagInput('${'a' * 21},');

      expect(controller.tagChips, isEmpty);
      expect(controller.tagErrorMessage, isNotNull);
      expect(controller.tagErrorMessage, contains('20'));
    });

    testWidgets('rejects tags with special characters and sets tagErrorMessage', (
      tester,
    ) async {
      await initController(tester);

      controller.handleTagInput('hello@world,');

      expect(controller.tagChips, isEmpty);
      expect(controller.tagErrorMessage, isNotNull);
      expect(controller.tagErrorMessage, contains('只能包含'));
    });

    testWidgets('accepts valid tags and clears tagErrorMessage', (tester) async {
      await initController(tester);

      controller.handleTagInput('bad@tag,');
      expect(controller.tagErrorMessage, isNotNull);

      controller.handleTagInput('valid-tag,');

      expect(controller.tagChips, contains('valid-tag'));
      expect(controller.tagErrorMessage, isNull);
    });

    testWidgets('clears tagErrorMessage when input is cleared', (tester) async {
      await initController(tester);

      controller.handleTagInput('toolonggggggggggggggggggggg,');
      expect(controller.tagErrorMessage, isNotNull);

      controller.handleTagInput('');

      expect(controller.tagErrorMessage, isNull);
    });

    testWidgets('commits tag chips on comma and avoids duplicates', (
      tester,
    ) async {
      await initController(tester);

      controller.handleTagInput('work,');
      controller.handleTagInput('personal,');

      expect(controller.tagChips, ['work', 'personal']);
    });

    testWidgets('commits a single tag via trailing space', (tester) async {
      await initController(tester);

      controller.handleTagInput('solo ');

      expect(controller.tagChips, ['solo']);
    });

    testWidgets('removes a tag chip via removeChip', (tester) async {
      await initController(tester);

      controller.handleTagInput('work,');
      controller.handleTagInput('personal,');

      controller.removeChip('work');

      expect(controller.tagChips, ['personal']);
    });
  });
}
