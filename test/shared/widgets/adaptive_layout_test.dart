import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uni_hub/src/core/theme/app_breakpoints.dart';
import 'package:uni_hub/src/shared/widgets/adaptive_layout.dart';

void main() {
  Future<void> pumpWithWidth(
    WidgetTester tester, {
    required double width,
    required Widget child,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, 600);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(home: child));
  }

  testWidgets('renders mobile builder below tablet breakpoint', (tester) async {
    var mobileBuilds = 0;
    var desktopBuilds = 0;

    await pumpWithWidth(
      tester,
      width: AppBreakpoints.mobileMax,
      child: AdaptiveLayout(
        mobile: (_) {
          mobileBuilds += 1;
          return const Text('mobile layout');
        },
        desktop: (_) {
          desktopBuilds += 1;
          return const Text('desktop layout');
        },
      ),
    );

    expect(find.text('mobile layout'), findsOneWidget);
    expect(find.text('desktop layout'), findsNothing);
    expect(mobileBuilds, 1);
    expect(desktopBuilds, 0);
  });

  testWidgets('renders desktop builder at tablet breakpoint and above', (
    tester,
  ) async {
    var mobileBuilds = 0;
    var desktopBuilds = 0;

    await pumpWithWidth(
      tester,
      width: AppBreakpoints.tabletMin,
      child: AdaptiveLayout(
        mobile: (_) {
          mobileBuilds += 1;
          return const Text('mobile layout');
        },
        desktop: (_) {
          desktopBuilds += 1;
          return const Text('desktop layout');
        },
      ),
    );

    expect(find.text('desktop layout'), findsOneWidget);
    expect(find.text('mobile layout'), findsNothing);
    expect(mobileBuilds, 0);
    expect(desktopBuilds, 1);
  });
}
