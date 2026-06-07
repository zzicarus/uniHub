import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uni_hub/src/shared/widgets/app_confirm_dialog.dart';
import 'package:uni_hub/src/shared/widgets/app_conflict_dialog.dart';

void main() {
  testWidgets('AppConfirmDialog returns true on confirm', (tester) async {
    bool? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await AppConfirmDialog.show(
                  context: context,
                  title: '删除项目',
                  message: '确定删除吗？',
                  confirmLabel: '删除',
                  destructive: true,
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('删除项目'), findsOneWidget);

    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });

  testWidgets('AppConflictDialog returns selected action', (tester) async {
    String? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await AppConflictDialog.show<String>(
                  context: context,
                  title: '名称冲突',
                  message: '已存在同名项目。',
                  actions: const [
                    AppConflictAction(value: 'merge', label: '合并'),
                    AppConflictAction(value: 'overwrite', label: '覆盖'),
                  ],
                );
              },
              child: const Text('conflict'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('conflict'));
    await tester.pumpAndSettle();
    expect(find.text('名称冲突'), findsOneWidget);

    await tester.tap(find.text('合并'));
    await tester.pumpAndSettle();
    expect(result, 'merge');
  });
}
