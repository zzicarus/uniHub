import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uni_hub/src/shared/widgets/app_compact_list_item.dart';
import 'package:uni_hub/src/shared/widgets/app_section_header.dart';

void main() {
  Future<void> pumpInScaffold(WidgetTester tester, Widget child) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: Center(child: child)),
      ),
    );
  }

  bool hasLocalMaterialAncestor({
    required WidgetTester tester,
    required Finder component,
    required Finder target,
  }) {
    final componentElement = tester.element(component);
    final targetElement = tester.element(target);
    var found = false;

    targetElement.visitAncestorElements((ancestor) {
      if (ancestor == componentElement) return false;
      if (ancestor.widget is Material) {
        found = true;
        return false;
      }
      return true;
    });

    return found;
  }

  group('Shared clickable ink hosts', () {
    testWidgets('AppCompactListItem owns a local Material host', (
      tester,
    ) async {
      var tapped = false;

      await pumpInScaffold(
        tester,
        AppCompactListItem(
          icon: Icons.today_outlined,
          color: Colors.blue,
          background: Colors.blue.shade50,
          title: '考试安排',
          subtitle: '明天 09:00',
          onTap: () => tapped = true,
        ),
      );

      expect(
        hasLocalMaterialAncestor(
          tester: tester,
          component: find.byType(AppCompactListItem),
          target: find.descendant(
            of: find.byType(AppCompactListItem),
            matching: find.byType(Ink),
          ),
        ),
        isTrue,
      );

      await tester.tap(find.text('考试安排'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('AppSectionHeader trailing action owns a local Material host', (
      tester,
    ) async {
      var tapped = false;

      await pumpInScaffold(
        tester,
        AppSectionHeader(
          title: '最近活动',
          trailingText: '查看全部',
          onTrailingTap: () => tapped = true,
        ),
      );

      expect(
        hasLocalMaterialAncestor(
          tester: tester,
          component: find.byType(AppSectionHeader),
          target: find.descendant(
            of: find.byType(AppSectionHeader),
            matching: find.byType(Ink),
          ),
        ),
        isTrue,
      );

      await tester.tap(find.textContaining('查看全部'));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });
}
