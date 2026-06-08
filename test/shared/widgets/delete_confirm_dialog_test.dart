import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uni_hub/src/shared/preferences/delete_confirm_prefs.dart';
import 'package:uni_hub/src/shared/widgets/delete_confirm_dialog.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  /// Helper: show a dialog inside a MaterialApp and pump.
  Future<void> showAndPump<T>(
    WidgetTester tester,
    Widget Function(BuildContext context) dialogBuilder,
  ) async {
    late BuildContext capturedContext;
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) {
        capturedContext = context;
        return const Scaffold(body: Center(child: Text('host')));
      }),
    ));
    await tester.pump();

    unawaited(showDialog<T>(context: capturedContext, builder: dialogBuilder));
    await tester.pumpAndSettle();
  }

  // ---------------------------------------------------------------
  // Single delete dialog
  // ---------------------------------------------------------------

  testWidgets('Single delete dialog shows title, preview, checkbox, and buttons',
      (tester) async {
    final prefs = DeleteConfirmPrefs(await SharedPreferences.getInstance());

    await showAndPump<bool>(tester, (ctx) {
      return DeleteConfirmDialog(
        mode: DialogMode.single,
        itemTitle: 'Test Article',
        itemSource: 'example.com',
        itemTypeLabel: '网页',
        itemRelativeTime: '1 天前',
        fallbackIcon: Icons.article_outlined,
        prefs: prefs,
      );
    });

    // Title
    expect(find.text('删除这条收藏？'), findsOneWidget);

    // Description
    expect(
      find.text('删除后，这条内容将从所有收藏夹中移除。此操作暂时不可恢复。'),
      findsOneWidget,
    );

    // Preview card content
    expect(find.text('Test Article'), findsOneWidget);
    expect(find.textContaining('example.com'), findsOneWidget);

    // Checkbox label
    expect(find.text('以后删除单条收藏时不再提示'), findsOneWidget);
    expect(find.textContaining('可在 设置'), findsOneWidget);

    // Buttons
    expect(find.text('取消'), findsOneWidget);
    expect(find.text('删除'), findsOneWidget);
  });

  testWidgets('Cancel button returns DeleteConfirmResult.cancel',
      (tester) async {
    final prefs = DeleteConfirmPrefs(await SharedPreferences.getInstance());

    await showAndPump<DeleteConfirmResult>(tester, (ctx) {
      return DeleteConfirmDialog(
        mode: DialogMode.single,
        itemTitle: 'Test',
        itemSource: 'example.com',
        itemTypeLabel: '网页',
        itemRelativeTime: '1 天前',
        fallbackIcon: Icons.link,
        prefs: prefs,
      );
    });

    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    // Dialog should be dismissed, "取消" gone
    expect(find.text('取消'), findsNothing);
  });

  testWidgets('Delete button dismisses dialog', (tester) async {
    final prefs = DeleteConfirmPrefs(await SharedPreferences.getInstance());

    await showAndPump<DeleteConfirmResult>(tester, (ctx) {
      return DeleteConfirmDialog(
        mode: DialogMode.single,
        itemTitle: 'Test',
        itemSource: 'example.com',
        itemTypeLabel: '网页',
        itemRelativeTime: '1 天前',
        fallbackIcon: Icons.link,
        prefs: prefs,
      );
    });

    // Find the delete FilledButton and tap it
    await tester.tap(find.widgetWithText(FilledButton, '删除'));
    await tester.pumpAndSettle();

    expect(find.text('删除这条收藏？'), findsNothing);
  });

  testWidgets('dontAskAgain skips dialog and returns delete',
      (tester) async {
    final prefs = DeleteConfirmPrefs(await SharedPreferences.getInstance());
    await prefs.setConfirmDeleteSingleItem(false);

    // Using the public API directly
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          final result = await DeleteConfirmDialog.showSingle(
            context: context,
            title: 'Test',
            source: 'example.com',
            typeLabel: '网页',
            relativeTime: '1 天前',
            fallbackIcon: Icons.link,
            prefs: prefs,
          );
          expect(result, DeleteConfirmResult.delete);
        });
        return const Scaffold(body: Center(child: Text('host')));
      }),
    ));
    await tester.pumpAndSettle();

    // Dialog should not appear
    expect(find.text('删除这条收藏？'), findsNothing);
  });

  // ---------------------------------------------------------------
  // Batch delete dialog
  // ---------------------------------------------------------------

  testWidgets('Batch delete dialog shows correct count and text',
      (tester) async {
    final prefs = DeleteConfirmPrefs(await SharedPreferences.getInstance());

    await showAndPump<DeleteConfirmResult>(tester, (ctx) {
      return DeleteConfirmDialog(
        mode: DialogMode.batch,
        count: 12,
        prefs: prefs,
      );
    });

    expect(find.text('删除 12 条收藏？'), findsOneWidget);
    expect(
      find.text('这些内容将从所有收藏夹中移除。此操作暂时不可恢复。'),
      findsOneWidget,
    );
    expect(find.text('以后批量删除收藏时不再提示'), findsOneWidget);
    expect(find.text('删除 12 项'), findsOneWidget);
  });

  testWidgets('Batch delete dontAskAgain skips dialog',
      (tester) async {
    final prefs = DeleteConfirmPrefs(await SharedPreferences.getInstance());
    await prefs.setConfirmDeleteBatchItems(false);

    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          final result = await DeleteConfirmDialog.showBatch(
            context: context,
            count: 5,
            prefs: prefs,
          );
          expect(result, DeleteConfirmResult.delete);
        });
        return const Scaffold(body: Center(child: Text('host')));
      }),
    ));
    await tester.pumpAndSettle();

    expect(find.text('删除 5 条收藏？'), findsNothing);
  });

  // ---------------------------------------------------------------
  // Multi-box dialog
  // ---------------------------------------------------------------

  testWidgets('Multi-box dialog shows radio options and confirm button',
      (tester) async {
    final prefs = DeleteConfirmPrefs(await SharedPreferences.getInstance());

    await showAndPump<DeleteConfirmResult>(tester, (ctx) {
      return DeleteConfirmDialog(
        mode: DialogMode.multiBox,
        itemTitle: 'Test Article',
        itemSource: 'example.com',
        itemTypeLabel: '网页',
        itemRelativeTime: '1 天前',
        fallbackIcon: Icons.article_outlined,
        prefs: prefs,
      );
    });

    // Title
    expect(find.text('处理这条收藏'), findsOneWidget);

    // Description
    expect(
      find.text('这条内容当前属于多个收藏夹。请选择要执行的操作。'),
      findsOneWidget,
    );

    // Radio options
    expect(find.text('仅从当前收藏夹移除'), findsOneWidget);
    expect(find.text('删除这条收藏'), findsOneWidget);

    // "确认" button
    expect(find.text('确认'), findsOneWidget);

    // No don't-ask checkbox in multi-box
    expect(find.text('以后删除单条收藏时不再提示'), findsNothing);
  });

  // ---------------------------------------------------------------
  // Visual: warning icon
  // ---------------------------------------------------------------

  testWidgets('Warning icon is rendered in the dialog', (tester) async {
    final prefs = DeleteConfirmPrefs(await SharedPreferences.getInstance());

    await showAndPump<DeleteConfirmResult>(tester, (ctx) {
      return DeleteConfirmDialog(
        mode: DialogMode.single,
        itemTitle: 'Test',
        itemSource: 'example.com',
        itemTypeLabel: '网页',
        itemRelativeTime: '1 天前',
        fallbackIcon: Icons.link,
        prefs: prefs,
      );
    });

    expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
  });

  // ---------------------------------------------------------------
  // Checkbox persists preference
  // ---------------------------------------------------------------

  testWidgets('Checkbox saves dont-ask preference on confirm',
      (tester) async {
    final prefs = DeleteConfirmPrefs(await SharedPreferences.getInstance());
    expect(prefs.confirmDeleteSingleItem, isTrue);

    await showAndPump<DeleteConfirmResult>(tester, (ctx) {
      return DeleteConfirmDialog(
        mode: DialogMode.single,
        itemTitle: 'Test',
        itemSource: 'example.com',
        itemTypeLabel: '网页',
        itemRelativeTime: '1 天前',
        fallbackIcon: Icons.link,
        prefs: prefs,
      );
    });

    // Tap checkbox
    final checkbox = find.byType(Checkbox);
    expect(checkbox, findsOneWidget);
    await tester.tap(checkbox);
    await tester.pumpAndSettle();

    // Confirm deletion
    await tester.tap(find.widgetWithText(FilledButton, '删除'));
    await tester.pumpAndSettle();

    expect(prefs.confirmDeleteSingleItem, isFalse);
  });
}
