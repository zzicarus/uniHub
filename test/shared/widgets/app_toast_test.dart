import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uni_hub/src/shared/widgets/app_toast.dart';

void main() {
  testWidgets('show supports one action', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () {
                AppToast.show(
                  context,
                  message: '已完成',
                  actionLabel: '查看',
                  onAction: () => tapped = true,
                );
              },
              child: const Text('show'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('show'));
    await tester.pumpAndSettle();

    expect(find.text('已完成'), findsOneWidget);
    expect(find.text('查看'), findsOneWidget);

    await tester.tap(find.byType(SnackBarAction));
    await tester.pump();
    expect(tapped, isTrue);
  });

  testWidgets('undo uses default label', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () {
                AppToast.undo(context, message: '已删除', onUndo: () {});
              },
              child: const Text('undo'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('undo'));
    await tester.pump();

    expect(find.text('已删除'), findsOneWidget);
    expect(find.text('撤销'), findsOneWidget);
  });

  testWidgets('undo accepts custom actionLabel', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () {
                AppToast.undo(
                  context,
                  message: 'URL 已存在',
                  actionLabel: '查看',
                  onUndo: () {},
                );
              },
              child: const Text('custom'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('custom'));
    await tester.pump();

    expect(find.text('URL 已存在'), findsOneWidget);
    expect(find.text('查看'), findsOneWidget);
  });
}
