import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uni_hub/src/shared/widgets/uni_pill.dart';

void main() {
  Future<void> pumpPill(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: Center(child: child)),
      ),
    );
  }

  testWidgets('renders label text', (tester) async {
    await pumpPill(
      tester,
      const UniPill(label: '课程', color: Colors.blue, tint: Colors.white),
    );

    expect(find.text('课程'), findsOneWidget);
  });

  testWidgets('applies provided foreground and tint colors', (tester) async {
    const foreground = Colors.deepPurple;
    const tint = Colors.amber;

    await pumpPill(
      tester,
      const UniPill(label: '重要', color: foreground, tint: tint),
    );

    final text = tester.widget<Text>(find.text('重要'));
    final decoratedBox = tester.widget<DecoratedBox>(find.byType(DecoratedBox));
    final decoration = decoratedBox.decoration as BoxDecoration;

    expect(text.style?.color, foreground);
    expect(decoration.color, tint);
  });
}
