import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uni_hub/src/core/theme/app_theme_tokens.dart';
import 'package:uni_hub/src/shared/tags/tag_models.dart';
import 'package:uni_hub/src/shared/widgets/tags/app_more_tags_popover.dart';
import 'package:uni_hub/src/shared/widgets/tags/app_tag_chip.dart';

/// Create a test [ThemeData] with the [UniHubThemeColors] extension registered.
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

const _tags = <AppTagStat>[
  AppTagStat(name: '产品', count: 5),
  AppTagStat(name: '代码', count: 3),
  AppTagStat(name: '产品设计', count: 2),
];

Future<void> _pumpPopoverContent(
  WidgetTester tester, {
  Set<String> selectedTags = const <String>{},
  ValueChanged<String>? onTagToggle,
  VoidCallback? onClear,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: _testTheme(),
      home: Scaffold(
        body: Center(
          child: AppMoreTagsPopoverContent(
            tags: _tags,
            selectedTags: selectedTags,
            onTagToggle: onTagToggle ?? (_) {},
            onClear: onClear,
          ),
        ),
      ),
    ),
  );
}

Finder _selectedChip(String label) {
  return find.byWidgetPredicate(
    (widget) => widget is AppTagChip && widget.label == label && widget.selected,
  );
}

Finder _unselectedChip(String label) {
  return find.byWidgetPredicate(
    (widget) => widget is AppTagChip && widget.label == label && !widget.selected,
  );
}

void main() {
  group('AppMoreTagsPopoverContent', () {
    testWidgets('displays title, search hint, and provided tags', (
      tester,
    ) async {
      await _pumpPopoverContent(tester);

      expect(find.text('更多标签'), findsOneWidget);
      expect(find.text('搜索标签...'), findsOneWidget);
      expect(find.text('#产品'), findsOneWidget);
      expect(find.text('#代码'), findsOneWidget);
    });

    testWidgets('fires onTagToggle and updates local selected state on tap', (
      tester,
    ) async {
      String? toggledTag;
      await _pumpPopoverContent(
        tester,
        onTagToggle: (tag) => toggledTag = tag,
      );

      expect(_unselectedChip('产品'), findsOneWidget);

      await tester.tap(find.text('#产品'));
      await tester.pump();

      expect(toggledTag, '产品');
      expect(_selectedChip('产品'), findsOneWidget);
    });

    testWidgets('filters tags by search query', (tester) async {
      await _pumpPopoverContent(tester);

      await tester.enterText(find.byType(TextField), '产品');
      await tester.pump();

      expect(find.text('#产品'), findsOneWidget);
      expect(find.text('#产品设计'), findsOneWidget);
      expect(find.text('#代码'), findsNothing);
    });

    testWidgets('shows empty message when search has no results', (tester) async {
      await _pumpPopoverContent(tester);

      await tester.enterText(find.byType(TextField), '不存在');
      await tester.pump();

      expect(find.text('没有找到标签'), findsOneWidget);
    });

    testWidgets('shows clear button and clears local selected state', (
      tester,
    ) async {
      var clearCount = 0;
      await _pumpPopoverContent(
        tester,
        selectedTags: const {'产品'},
        onClear: () => clearCount += 1,
      );

      expect(find.text('清空'), findsOneWidget);
      expect(_selectedChip('产品'), findsOneWidget);

      await tester.tap(find.text('清空'));
      await tester.pump();

      expect(clearCount, 1);
      expect(_unselectedChip('产品'), findsOneWidget);
    });

    testWidgets('finish button closes dialog', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: _testTheme(),
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: FilledButton(
                    onPressed: () {
                      showAppMoreTagsPopover(
                        context: context,
                        tags: _tags,
                        selectedTags: const <String>{},
                        onTagToggle: (_) {},
                      );
                    },
                    child: const Text('打开更多标签'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('打开更多标签'));
      await tester.pumpAndSettle();

      expect(find.byType(AppMoreTagsPopoverContent), findsOneWidget);

      await tester.tap(find.text('完成'));
      await tester.pumpAndSettle();

      expect(find.byType(AppMoreTagsPopoverContent), findsNothing);
    });
  });
}
