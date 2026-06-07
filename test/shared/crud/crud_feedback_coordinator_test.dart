import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uni_hub/src/shared/crud/crud.dart';

void main() {
  Future<void> pumpHost(
    WidgetTester tester,
    void Function(BuildContext context) onPressed,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => onPressed(context),
              child: const Text('run'),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('shows success message and undo action with default label', (
    tester,
  ) async {
    await pumpHost(tester, (context) {
      const CrudFeedbackCoordinator().handle(
        context,
        const CrudResult<void>.success(
          message: '已删除项目',
          undo: CrudUndoAction(execute: _noop),
        ),
      );
    });

    await tester.tap(find.text('run'));
    await tester.pump();

    expect(find.text('已删除项目'), findsOneWidget);
    expect(find.text('撤销'), findsOneWidget);
  });

  testWidgets('passes CrudUndoAction.label as actionLabel', (tester) async {
    await pumpHost(tester, (context) {
      const CrudFeedbackCoordinator().handle(
        context,
        const CrudResult<void>.success(
          message: 'URL 已存在',
          undo: CrudUndoAction(label: '查看', execute: _noop),
        ),
      );
    });

    await tester.tap(find.text('run'));
    await tester.pump();

    expect(find.text('URL 已存在'), findsOneWidget);
    expect(find.text('查看'), findsOneWidget);
  });

  testWidgets('suppresses handled validation field errors', (tester) async {
    await pumpHost(tester, (context) {
      const CrudFeedbackCoordinator().handle(
        context,
        const CrudResult<void>.failure(
          failure: AppFailure(
            code: AppFailureCode.validation,
            message: '名称不能为空',
            field: 'name',
          ),
          fieldErrorHandled: true,
        ),
      );
    });

    await tester.tap(find.text('run'));
    await tester.pump();

    expect(find.text('名称不能为空'), findsNothing);
  });

  testWidgets('shows conflict and technical failures with mapped icons', (
    tester,
  ) async {
    await pumpHost(tester, (context) {
      const CrudFeedbackCoordinator().handle(
        context,
        const CrudResult<void>.failure(
          failure: AppFailure(
            code: AppFailureCode.referenced,
            message: '仍有关联数据',
          ),
        ),
      );
    });

    await tester.tap(find.text('run'));
    await tester.pump();

    expect(find.text('仍有关联数据'), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);

    await tester.tap(find.text('run'));
    await tester.pump();

    expect(find.text('仍有关联数据'), findsOneWidget);
  });

  testWidgets('shows database failure as an error toast', (tester) async {
    await pumpHost(tester, (context) {
      const CrudFeedbackCoordinator().handle(
        context,
        const CrudResult<void>.failure(
          failure: AppFailure(
            code: AppFailureCode.database,
            message: '操作失败，请稍后重试',
          ),
        ),
      );
    });

    await tester.tap(find.text('run'));
    await tester.pump();

    expect(find.text('操作失败，请稍后重试'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
  });
}

Future<void> _noop() async {}
