import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uni_hub/src/core/theme/app_theme_tokens.dart';
import 'package:uni_hub/src/shared/tags/tag_models.dart';
import 'package:uni_hub/src/shared/widgets/tags/app_common_tags_panel.dart';

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

/// Helper to pump an [AppCommonTagsPanel] widget in a test environment.
Future<void> pumpPanel(WidgetTester tester, AppCommonTagsPanel panel) {
  return tester.pumpWidget(
    MaterialApp(
      theme: _testTheme(),
      home: Scaffold(body: Center(child: panel)),
    ),
  );
}

void main() {
  group('AppCommonTagsPanel', () {
    testWidgets('displays title 常用标签', (tester) async {
      await pumpPanel(
        tester,
        AppCommonTagsPanel(
          tags: const [],
          selectedTags: const {},
          onTagToggle: (_) {},
        ),
      );

      expect(find.text('常用标签'), findsOneWidget);
    });

    testWidgets('displays helperText 点击筛选', (tester) async {
      await pumpPanel(
        tester,
        AppCommonTagsPanel(
          tags: const [],
          selectedTags: const {},
          onTagToggle: (_) {},
        ),
      );

      expect(find.text('点击筛选'), findsOneWidget);
    });

    testWidgets('shows emptyText when tags is empty', (tester) async {
      await pumpPanel(
        tester,
        AppCommonTagsPanel(
          tags: const [],
          selectedTags: const {},
          onTagToggle: (_) {},
        ),
      );

      expect(find.text('暂无标签'), findsOneWidget);
    });

    testWidgets('renders tag chips when tags is non-empty', (tester) async {
      final tags = [
        const AppTagStat(name: '产品', count: 5),
        const AppTagStat(name: '代码', count: 3),
      ];

      await pumpPanel(
        tester,
        AppCommonTagsPanel(
          tags: tags,
          selectedTags: const {},
          onTagToggle: (_) {},
        ),
      );

      // AppTagChip renders label with # prefix by default
      expect(find.text('#产品'), findsOneWidget);
      expect(find.text('#代码'), findsOneWidget);
    });

    testWidgets('displays count on tag chips', (tester) async {
      final tags = [
        const AppTagStat(name: '产品', count: 8),
      ];

      await pumpPanel(
        tester,
        AppCommonTagsPanel(
          tags: tags,
          selectedTags: const {},
          onTagToggle: (_) {},
        ),
      );

      expect(find.text('#产品'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
    });

    testWidgets('renders selected tags in selected state', (tester) async {
      final tags = [
        const AppTagStat(name: '产品', count: 5),
        const AppTagStat(name: '代码', count: 3),
      ];

      await pumpPanel(
        tester,
        AppCommonTagsPanel(
          tags: tags,
          selectedTags: const {'产品'},
          onTagToggle: (_) {},
        ),
      );

      expect(find.text('#产品'), findsOneWidget);
      expect(find.text('#代码'), findsOneWidget);
      // Both chips should render; the selected one has different styling
      // but the key assertion is no crash and correct text.
    });

    testWidgets('calls onTagToggle when a tag is tapped', (tester) async {
      final tags = [
        const AppTagStat(name: '产品', count: 5),
      ];

      String? toggledTag;
      await pumpPanel(
        tester,
        AppCommonTagsPanel(
          tags: tags,
          selectedTags: const {},
          onTagToggle: (tag) => toggledTag = tag,
        ),
      );

      await tester.tap(find.text('#产品'));
      expect(toggledTag, equals('产品'));
    });

    testWidgets('maxVisibleTags limits displayed tags', (tester) async {
      final tags = [
        const AppTagStat(name: '产品', count: 5),
        const AppTagStat(name: '代码', count: 3),
        const AppTagStat(name: '设计', count: 2),
        const AppTagStat(name: '笔记', count: 1),
      ];

      await pumpPanel(
        tester,
        AppCommonTagsPanel(
          tags: tags,
          selectedTags: const {},
          onTagToggle: (_) {},
          maxVisibleTags: 2,
        ),
      );

      // Only first 2 tags should appear
      expect(find.text('#产品'), findsOneWidget);
      expect(find.text('#代码'), findsOneWidget);
      expect(find.text('#设计'), findsNothing);
      expect(find.text('#笔记'), findsNothing);
    });
  });
}
