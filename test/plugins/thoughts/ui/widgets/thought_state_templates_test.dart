import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uni_hub/src/plugins/thoughts/ui/widgets/thought_state_templates.dart';

/// Helper to pump a [ThoughtStateTemplate] into a test environment with a
/// known [Theme] so color-scheme lookups do not crash.
Future<void> pumpTemplate(
  WidgetTester tester,
  ThoughtStateTemplate template,
) {
  return tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF4F6BFF),
        useMaterial3: true,
      ),
      home: Scaffold(body: Center(child: template)),
    ),
  );
}

void main() {
  group('ThoughtStateTemplate - empty state variants', () {
    testWidgets('noThoughts shows title, subtitle, and action button',
        (tester) async {
      await pumpTemplate(
        tester,
        ThoughtStateTemplate.noThoughts(onRecord: () {}),
      );

      expect(find.text('还没有想法'), findsOneWidget);
      expect(find.text('记录第一个念头...'), findsOneWidget);
      expect(find.text('记录想法'), findsOneWidget);
      expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);
    });

    testWidgets('noThoughts without onRecord hides action button',
        (tester) async {
      await pumpTemplate(tester, ThoughtStateTemplate.noThoughts());

      expect(find.text('还没有想法'), findsOneWidget);
      expect(find.text('记录第一个念头...'), findsOneWidget);
      expect(find.text('记录想法'), findsNothing);
    });

    testWidgets('noThoughts action button triggers callback', (tester) async {
      var tapped = false;
      await pumpTemplate(
        tester,
        ThoughtStateTemplate.noThoughts(onRecord: () => tapped = true),
      );

      await tester.tap(find.text('记录想法'));
      expect(tapped, isTrue);
    });

    testWidgets('filterNoResults shows tag in title and action button',
        (tester) async {
      await pumpTemplate(
        tester,
        ThoughtStateTemplate.filterNoResults('工作', onClearFilter: () {}),
      );

      expect(find.text('没有找到带有 #工作 的想法'), findsOneWidget);
      expect(find.text('试试其他标签或清除筛选条件'), findsOneWidget);
      expect(find.text('清除筛选'), findsOneWidget);
      expect(find.byIcon(Icons.filter_alt_outlined), findsOneWidget);
    });

    testWidgets('filterNoResults without onClearFilter hides action',
        (tester) async {
      await pumpTemplate(
        tester,
        ThoughtStateTemplate.filterNoResults('生活'),
      );

      expect(find.text('没有找到带有 #生活 的想法'), findsOneWidget);
      expect(find.text('清除筛选'), findsNothing);
    });

    testWidgets('filterNoResults action triggers callback', (tester) async {
      var tapped = false;
      await pumpTemplate(
        tester,
        ThoughtStateTemplate.filterNoResults(
          '标签',
          onClearFilter: () => tapped = true,
        ),
      );

      await tester.tap(find.text('清除筛选'));
      expect(tapped, isTrue);
    });

    testWidgets('searchNoResults shows query in subtitle and action button',
        (tester) async {
      await pumpTemplate(
        tester,
        ThoughtStateTemplate.searchNoResults('flutter', onClearSearch: () {}),
      );

      expect(find.text('没有找到相关想法'), findsOneWidget);
      expect(find.text('试试其他关键词或清除搜索条件'), findsOneWidget);
      expect(find.text('清除搜索'), findsOneWidget);
      expect(find.byIcon(Icons.search_off_outlined), findsOneWidget);
    });

    testWidgets('searchNoResults without onClearSearch hides action',
        (tester) async {
      await pumpTemplate(
        tester,
        ThoughtStateTemplate.searchNoResults('测试'),
      );

      expect(find.text('没有找到相关想法'), findsOneWidget);
      expect(find.text('清除搜索'), findsNothing);
    });

    testWidgets('searchNoResults action triggers callback', (tester) async {
      var tapped = false;
      await pumpTemplate(
        tester,
        ThoughtStateTemplate.searchNoResults(
          'dart',
          onClearSearch: () => tapped = true,
        ),
      );

      await tester.tap(find.text('清除搜索'));
      expect(tapped, isTrue);
    });

    testWidgets('archiveEmpty shows expected texts without action',
        (tester) async {
      await pumpTemplate(tester, ThoughtStateTemplate.archiveEmpty());

      expect(find.text('暂无归档想法'), findsOneWidget);
      expect(find.text('归档后的想法会显示在这里'), findsOneWidget);
      expect(find.byIcon(Icons.archive_outlined), findsOneWidget);
      // No action button for archive empty
      expect(
        find.byType(FilledButton),
        findsNothing,
        reason: 'archiveEmpty should not show an action button',
      );
    });
  });

  group('ThoughtStateTemplate - error state variants', () {
    testWidgets('saveError shows correct message', (tester) async {
      await pumpTemplate(tester, ThoughtStateTemplate.saveError());
      expect(find.text('保存失败'), findsOneWidget);
      expect(find.text('请稍后重试'), findsOneWidget);
    });

    testWidgets('saveError with retry shows button and triggers', (tester) async {
      var tapped = false;
      await pumpTemplate(
        tester,
        ThoughtStateTemplate.saveError(onRetry: () => tapped = true),
      );

      expect(find.text('重试'), findsOneWidget);
      await tester.tap(find.text('重试'));
      expect(tapped, isTrue);
    });

    testWidgets('imageError shows correct message', (tester) async {
      await pumpTemplate(tester, ThoughtStateTemplate.imageError());
      expect(find.text('图片添加失败'), findsOneWidget);
      expect(find.text('请检查文件权限'), findsOneWidget);
    });

    testWidgets('imageError with retry shows button', (tester) async {
      await pumpTemplate(
        tester,
        ThoughtStateTemplate.imageError(onRetry: () {}),
      );
      expect(find.text('重试'), findsOneWidget);
    });

    testWidgets('deleteError shows correct message', (tester) async {
      await pumpTemplate(tester, ThoughtStateTemplate.deleteError());
      expect(find.text('删除失败'), findsOneWidget);
      expect(find.text('请稍后重试'), findsOneWidget);
    });

    testWidgets('deleteError with retry shows button', (tester) async {
      await pumpTemplate(
        tester,
        ThoughtStateTemplate.deleteError(onRetry: () {}),
      );
      expect(find.text('重试'), findsOneWidget);
    });

    testWidgets('archiveError shows correct message', (tester) async {
      await pumpTemplate(tester, ThoughtStateTemplate.archiveError());
      expect(find.text('归档失败'), findsOneWidget);
      expect(find.text('请稍后重试'), findsOneWidget);
      expect(find.byIcon(Icons.archive_outlined), findsOneWidget);
    });

    testWidgets('archiveError with retry shows button', (tester) async {
      await pumpTemplate(
        tester,
        ThoughtStateTemplate.archiveError(onRetry: () {}),
      );
      expect(find.text('重试'), findsOneWidget);
    });

    testWidgets('restoreError shows correct message', (tester) async {
      await pumpTemplate(tester, ThoughtStateTemplate.restoreError());
      expect(find.text('恢复失败'), findsOneWidget);
      expect(find.text('请稍后重试'), findsOneWidget);
      expect(find.byIcon(Icons.unarchive_outlined), findsOneWidget);
    });

    testWidgets('restoreError with retry shows button', (tester) async {
      await pumpTemplate(
        tester,
        ThoughtStateTemplate.restoreError(onRetry: () {}),
      );
      expect(find.text('重试'), findsOneWidget);
    });

    testWidgets('filterError shows correct message with retry button',
        (tester) async {
      var tapped = false;
      await pumpTemplate(
        tester,
        ThoughtStateTemplate.filterError(onRetry: () => tapped = true),
      );

      expect(find.text('加载失败'), findsOneWidget);
      expect(find.text('请重试'), findsOneWidget);
      expect(find.text('重试'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);

      await tester.tap(find.text('重试'));
      expect(tapped, isTrue);
    });

    testWidgets('filterError without callback hides retry button',
        (tester) async {
      await pumpTemplate(tester, ThoughtStateTemplate.filterError());
      expect(find.text('加载失败'), findsOneWidget);
      expect(find.text('请重试'), findsOneWidget);
      // No callback = no button (consistent with all other helpers)
      expect(find.text('重试'), findsNothing);
    });
  });
}
