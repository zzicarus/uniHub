import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uni_hub/src/core/theme/app_theme_tokens.dart';
import 'package:uni_hub/src/shared/tags/tag_models.dart';
import 'package:uni_hub/src/shared/widgets/tags/app_tag_filter_bar.dart';

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

/// Helper to pump an [AppTagFilterBar] widget in a test environment.
Future<void> pumpFilterBar(WidgetTester tester, AppTagFilterBar bar) {
  return tester.pumpWidget(
    MaterialApp(
      theme: _testTheme(),
      home: Scaffold(body: Center(child: bar)),
    ),
  );
}

void main() {
  group('AppTagFilterBar', () {
    testWidgets('displays label 按标签筛选：', (tester) async {
      await pumpFilterBar(
        tester,
        AppTagFilterBar(
          tags: const [AppTagStat(name: '产品', count: 5)],
          selectedTags: const {},
          onTagToggle: (_) {},
        ),
      );

      expect(find.text('按标签筛选：'), findsOneWidget);
    });

    testWidgets('shows emptyText when tags is empty', (tester) async {
      await pumpFilterBar(
        tester,
        AppTagFilterBar(
          tags: const [],
          selectedTags: const {},
          onTagToggle: (_) {},
        ),
      );

      expect(find.text('暂无标签'), findsOneWidget);
    });

    testWidgets('renders tag chips when tags is non-empty', (tester) async {
      await pumpFilterBar(
        tester,
        AppTagFilterBar(
          tags: const [
            AppTagStat(name: '产品', count: 5),
            AppTagStat(name: '代码', count: 3),
          ],
          selectedTags: const {},
          onTagToggle: (_) {},
        ),
      );

      // AppTagChip renders label with # prefix by default
      expect(find.text('#产品'), findsOneWidget);
      expect(find.text('#代码'), findsOneWidget);
    });

    testWidgets('shows count when showCounts is true', (tester) async {
      await pumpFilterBar(
        tester,
        AppTagFilterBar(
          tags: const [AppTagStat(name: '产品', count: 8)],
          selectedTags: const {},
          onTagToggle: (_) {},
          showCounts: true,
        ),
      );

      expect(find.text('#产品'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
    });

    testWidgets('hides count when showCounts is false', (tester) async {
      await pumpFilterBar(
        tester,
        AppTagFilterBar(
          tags: const [AppTagStat(name: '产品', count: 8)],
          selectedTags: const {},
          onTagToggle: (_) {},
          showCounts: false,
        ),
      );

      expect(find.text('#产品'), findsOneWidget);
      expect(find.text('8'), findsNothing);
    });

    testWidgets('calls onTagToggle when a tag is tapped', (tester) async {
      String? toggledTag;
      await pumpFilterBar(
        tester,
        AppTagFilterBar(
          tags: const [AppTagStat(name: '产品', count: 5)],
          selectedTags: const {},
          onTagToggle: (tag) => toggledTag = tag,
        ),
      );

      await tester.tap(find.text('#产品'));
      expect(toggledTag, equals('产品'));
    });

    testWidgets('renders selected tags in selected state', (tester) async {
      await pumpFilterBar(
        tester,
        AppTagFilterBar(
          tags: const [
            AppTagStat(name: '产品', count: 5),
            AppTagStat(name: '代码', count: 3),
          ],
          selectedTags: const {'产品'},
          onTagToggle: (_) {},
        ),
      );

      // Both should render; selected chip has different styling but the
      // key assertion is no crash and correct text.
      expect(find.text('#产品'), findsOneWidget);
      expect(find.text('#代码'), findsOneWidget);
    });

    testWidgets('shows 更多标签 button when tags exceed maxVisibleTags', (
      tester,
    ) async {
      await pumpFilterBar(
        tester,
        AppTagFilterBar(
          tags: const [
            AppTagStat(name: '产品', count: 5),
            AppTagStat(name: '代码', count: 3),
            AppTagStat(name: '设计', count: 2),
            AppTagStat(name: '笔记', count: 1),
          ],
          selectedTags: const {},
          onTagToggle: (_) {},
          onMoreTap: () {},
          maxVisibleTags: 2,
        ),
      );

      // 2 visible + "更多标签" button
      expect(find.text('#产品'), findsOneWidget);
      expect(find.text('#代码'), findsOneWidget);
      expect(find.text('更多标签'), findsOneWidget);
      expect(find.text('#设计'), findsNothing);
      expect(find.text('#笔记'), findsNothing);
    });

    testWidgets('calls onMoreTap when 更多标签 button is tapped', (
      tester,
    ) async {
      var moreTapped = false;
      await pumpFilterBar(
        tester,
        AppTagFilterBar(
          tags: const [
            AppTagStat(name: '产品', count: 5),
            AppTagStat(name: '代码', count: 3),
            AppTagStat(name: '设计', count: 2),
          ],
          selectedTags: const {},
          onTagToggle: (_) {},
          onMoreTap: () => moreTapped = true,
          maxVisibleTags: 2,
        ),
      );

      await tester.tap(find.text('更多标签'));
      expect(moreTapped, isTrue);
    });

    testWidgets('renders without error when horizontalScroll is true', (
      tester,
    ) async {
      await pumpFilterBar(
        tester,
        AppTagFilterBar(
          tags: const [
            AppTagStat(name: '产品', count: 5),
            AppTagStat(name: '代码', count: 3),
            AppTagStat(name: '设计', count: 2),
          ],
          selectedTags: const {},
          onTagToggle: (_) {},
          onMoreTap: () {},
          maxVisibleTags: 5,
          horizontalScroll: true,
        ),
      );

      // All tags visible, no "更多标签" since maxVisibleTags ≥ tags.length
      expect(find.text('#产品'), findsOneWidget);
      expect(find.text('#代码'), findsOneWidget);
      expect(find.text('#设计'), findsOneWidget);
      expect(find.text('更多标签'), findsNothing);
    });
  });
}
