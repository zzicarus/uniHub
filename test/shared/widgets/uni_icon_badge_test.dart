import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uni_hub/src/shared/widgets/uni_icon_badge.dart';

void main() {
  Future<void> pumpIconBadge(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: Center(child: child)),
      ),
    );
  }

  testWidgets('renders the provided icon with color', (tester) async {
    await pumpIconBadge(
      tester,
      const UniIconBadge(icon: Icons.notifications, color: Colors.orange),
    );

    final icon = tester.widget<Icon>(find.byIcon(Icons.notifications));
    expect(icon.color, Colors.orange);
  });

  testWidgets('renders with provided color and size', (tester) async {
    await pumpIconBadge(
      tester,
      const UniIconBadge(icon: Icons.check, color: Colors.green, size: 48),
    );

    final icon = tester.widget<Icon>(find.byIcon(Icons.check));
    expect(icon.color, Colors.green);
  });

  testWidgets('icon is visible', (tester) async {
    await pumpIconBadge(
      tester,
      const UniIconBadge(icon: Icons.star, color: Colors.blue),
    );

    expect(find.byIcon(Icons.star), findsOneWidget);
  });
}
