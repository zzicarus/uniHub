import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uni_hub/src/shared/widgets/uni_icon_badge.dart';
import 'package:uni_hub/src/shared/widgets/uni_status_panel.dart';

void main() {
  Future<void> pumpStatusPanel(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: Center(child: child)),
      ),
    );
  }

  testWidgets('renders status icon, title, message and filled action', (
    tester,
  ) async {
    var tapped = false;

    await pumpStatusPanel(
      tester,
      UniStatusPanel(
        icon: Icons.inbox_outlined,
        iconColor: Colors.teal,
        title: '没有内容',
        message: '添加内容后会显示在这里。',
        actionLabel: '立即添加',
        onAction: () => tapped = true,
      ),
    );

    expect(find.byType(UniIconBadge), findsOneWidget);
    expect(find.text('没有内容'), findsOneWidget);
    expect(find.text('添加内容后会显示在这里。'), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);

    await tester.tap(find.text('立即添加'));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('renders outlined action when requested', (tester) async {
    await pumpStatusPanel(
      tester,
      const UniStatusPanel(
        icon: Icons.error_outline,
        iconColor: Colors.red,
        title: '加载失败',
        message: '请稍后重试。',
        actionLabel: '重试',
        isOutlinedAction: true,
      ),
    );

    expect(find.text('加载失败'), findsOneWidget);
    expect(find.text('请稍后重试。'), findsOneWidget);
    expect(find.byType(OutlinedButton), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
  });
}
