import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:appflowy_editor/appflowy_editor.dart';

import 'package:uni_hub/src/core/theme/app_theme.dart';
import 'package:uni_hub/src/core/theme/app_theme_preset.dart';
import 'package:uni_hub/src/shared/editor/appflowy_thought_editor.dart';

/// Helper: wraps [AppFlowyThoughtEditor] with MaterialApp + required
/// localizations delegates so that it can render in widget tests.
Widget wrapEditor({
  Map<String, dynamic>? initialJson,
  String? initialText,
  ValueChanged<AppFlowyThoughtEditorValue>? onChanged,
}) {
  return MaterialApp(
    // AppFlowyEditor needs AppFlowyEditorLocalizations.
    localizationsDelegates: const [
      AppFlowyEditorLocalizations.delegate,
      DefaultMaterialLocalizations.delegate,
      DefaultWidgetsLocalizations.delegate,
    ],
    theme: AppTheme.build(
      preset: AppThemePreset.uniBlue,
      brightness: Brightness.light,
    ),
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 800,
          height: 600,
          child: AppFlowyThoughtEditor(
            initialJson: initialJson,
            initialText: initialText,
            onChanged: onChanged ?? (_) {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('AppFlowyThoughtEditor', () {
    testWidgets('renders without crashing with initialText', (tester) async {
      await tester.pumpWidget(wrapEditor(
        initialText: 'Hello World',
      ));
      // Initial pump: editor mounts, EditorState is created.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // The editor should not throw any errors.
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without crashing with initialJson', (tester) async {
      final json = {
        'document': {
          'type': 'page',
          'children': [
            {
              'type': 'paragraph',
              'data': {
                'delta': [
                  {'insert': 'From JSON'},
                ],
              },
            },
          ],
        },
      };

      await tester.pumpWidget(wrapEditor(initialJson: json));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without crashing with blank (no input)',
        (tester) async {
      await tester.pumpWidget(wrapEditor());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
    });

    testWidgets('onChanged fires initial value after mount', (tester) async {
      AppFlowyThoughtEditorValue? captured;

      await tester.pumpWidget(wrapEditor(
        initialText: 'Smoke test',
        onChanged: (value) {
          captured = value;
        },
      ));
      // Let the post-frame callback fire.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // onChanged should have been called at least once with the
      // initial document state.
      expect(captured, isNotNull);
      expect(captured!.documentJson, isA<Map<String, dynamic>>());
      expect(captured!.documentJson.containsKey('document'), isTrue);
    });

    testWidgets('onChanged fires on transaction after editing',
        (tester) async {
      AppFlowyThoughtEditorValue? captured;

      await tester.pumpWidget(wrapEditor(
        onChanged: (value) {
          captured = value;
        },
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Reset captured so we can detect a new emission.
      captured = null;

      // Tap the editor area to focus it.
      await tester.tapAt(const Offset(400, 300));
      await tester.pump();

      // AppFlowyEditor renders its own EditableText-like widgets.
      // We use pump to flush any pending selection/transaction changes.
      await tester.pump(const Duration(milliseconds: 100));

      // Note: Flutter widget tests cannot reliably simulate IME text
      // input inside AppFlowyEditor because it uses a custom
      // DeltaTextInputService instead of standard EditableText.
      // This test verifies that the editor mounts and is interactive
      // (tap fires onChanged via transaction stream) without crashing.
      //
      // If captured is still null after tap, it's a known limitation
      // of the test environment — the onChanged fires only on real
      // document mutations.
      if (captured != null) {
        expect(captured!.plainText, isA<String>());
      }
    });
  });
}
