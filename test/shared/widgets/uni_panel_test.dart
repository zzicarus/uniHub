import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uni_hub/src/shared/widgets/uni_panel.dart';

void main() {
  Future<void> pumpPanel(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: Center(child: child)),
      ),
    );
  }

  testWidgets('renders child content inside panel', (tester) async {
    await pumpPanel(tester, const UniPanel(child: Text('面板内容')));

    expect(find.text('面板内容'), findsOneWidget);
    expect(find.byType(DecoratedBox), findsOneWidget);
  });

  testWidgets('uses provided padding around child', (tester) async {
    const padding = EdgeInsets.all(24);

    await pumpPanel(
      tester,
      const UniPanel(padding: padding, child: Text('自定义边距')),
    );

    final paddingWidget = tester.widget<Padding>(
      find
          .ancestor(of: find.text('自定义边距'), matching: find.byType(Padding))
          .first,
    );

    expect(paddingWidget.padding, padding);
  });
}
