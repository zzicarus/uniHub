import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uni_hub/src/core/theme/app_theme_tokens.dart';
import 'package:uni_hub/src/shared/widgets/tags/app_selected_tags_bar.dart';

/// Create a test [ThemeData] with the [UniHubThemeColors] extension registered.
/// Reuses the same color tokens as [app_tag_chip_test.dart].
ThemeData _testTheme() {
  return ThemeData(
    useMaterial3: true,
    extensions: const <ThemeExtension<dynamic>>[
      UniHubThemeColors(
        background: Color(0xFFFAFBFE),
        surface: Color(0xFFFFFFFF),
        surfaceMuted: Color(0xFFF6F8FC),
        border: Color(0xFFE8ECF4),
        borderStrong: Color(0xFFD1D5DB),
        primary: Color(0xFF4F6BFF),
        primaryHover: Color(0xFF3B55E0),
        primarySoft: Color(0xFFEFF3FF),
        success: Color(0xFF22C55E),
        successSoft: Color(0xFFEFFAF3),
        warning: Color(0xFFF59E0B),
        warningSoft: Color(0xFFFFF7E8),
        purple: Color(0xFF8B5CF6),
        purpleSoft: Color(0xFFF4F0FF),
        danger: Color(0xFFF43F5E),
        dangerSoft: Color(0xFFFFF0F4),
        textPrimary: Color(0xFF111827),
        textSecondary: Color(0xFF667085),
        textTertiary: Color(0xFF98A2B3),
        sidebarBackground: Color(0xFFF6F8FC),
        navSelectedBackground: Color(0xFFEFF3FF),
        panelBackground: Color(0xFFFFFFFF),
      ),
    ],
  );
}

/// Helper to pump an [AppSelectedTagsBar] widget in a test environment.
Future<void> pumpBar(WidgetTester tester, AppSelectedTagsBar bar) {
  return tester.pumpWidget(
    MaterialApp(
      theme: _testTheme(),
      home: Scaffold(body: Center(child: bar)),
    ),
  );
}

void main() {
  group('AppSelectedTagsBar', () {
    testWidgets('shows nothing when selectedTags is empty', (tester) async {
      await pumpBar(
        tester,
        AppSelectedTagsBar(
          selectedTags: const {},
          onRemove: (_) {},
          onClear: () {},
        ),
      );

      // Widget returns SizedBox.shrink() — no label or chips visible
      expect(find.text('已选标签：'), findsNothing);
      expect(find.text('清除标签'), findsNothing);
      // The widget itself is an empty SizedBox
      expect(find.byType(SizedBox), findsOneWidget);
    });

    testWidgets('displays label 已选标签： when tags are present', (
      tester,
    ) async {
      await pumpBar(
        tester,
        AppSelectedTagsBar(
          selectedTags: const {'产品'},
          onRemove: (_) {},
          onClear: () {},
        ),
      );

      expect(find.text('已选标签：'), findsOneWidget);
    });

    testWidgets('renders tag chips with # prefix', (tester) async {
      await pumpBar(
        tester,
        AppSelectedTagsBar(
          selectedTags: const {'产品', '灵感'},
          onRemove: (_) {},
          onClear: () {},
        ),
      );

      // AppSelectedTagChip renders label as '#$label'
      expect(find.text('#产品'), findsOneWidget);
      expect(find.text('#灵感'), findsOneWidget);
    });

    testWidgets('calls onRemove when close icon on a chip is tapped', (
      tester,
    ) async {
      final removed = <String>[];
      await pumpBar(
        tester,
        AppSelectedTagsBar(
          selectedTags: const {'产品', '灵感'},
          onRemove: removed.add,
          onClear: () {},
        ),
      );

      // Tap the close icon on the first chip (InputChip's delete icon).
      // There are 3 close icons: one per chip (2) + the clear TextButton.
      // We target the first InputChip and tap its descendant close icon.
      final firstChip = find.byType(InputChip).first;
      await tester.tap(
        find.descendant(of: firstChip, matching: find.byIcon(Icons.close_rounded)),
      );

      expect(removed, hasLength(1));
      // The first of the sorted tags ('产品' < '灵感') should be removed
      expect(removed.first, '产品');
    });

    testWidgets('calls onClear when 清除标签 button is tapped', (
      tester,
    ) async {
      var cleared = false;
      await pumpBar(
        tester,
        AppSelectedTagsBar(
          selectedTags: const {'产品', '灵感'},
          onRemove: (_) {},
          onClear: () => cleared = true,
        ),
      );

      await tester.tap(find.text('清除标签'));
      expect(cleared, isTrue);
    });

    testWidgets('shows +N overflow indicator when tags exceed maxVisibleTags', (
      tester,
    ) async {
      await pumpBar(
        tester,
        AppSelectedTagsBar(
          selectedTags: const {'产品', '代码', '设计', '笔记'},
          onRemove: (_) {},
          onClear: () {},
          maxVisibleTags: 2,
        ),
      );

      // Only first 2 sorted tags visible, rest show as +2
      expect(find.text('#产品'), findsOneWidget);
      expect(find.text('#代码'), findsOneWidget);
      expect(find.text('#设计'), findsNothing);
      expect(find.text('#笔记'), findsNothing);
      expect(find.text('+2'), findsOneWidget);
    });

    testWidgets('clearLabel can be customized', (tester) async {
      await pumpBar(
        tester,
        AppSelectedTagsBar(
          selectedTags: const {'产品'},
          onRemove: (_) {},
          onClear: () {},
          clearLabel: '清除全部',
        ),
      );

      expect(find.text('清除全部'), findsOneWidget);
      expect(find.text('清除标签'), findsNothing);
    });
  });
}
