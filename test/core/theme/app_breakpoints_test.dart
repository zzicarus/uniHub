import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:uni_hub/src/core/theme/app_breakpoints.dart';

void main() {
  group('AppBreakpoints', () {
    group('isCompact', () {
      testWidgets('returns true for width < 900', (tester) async {
        tester.view.physicalSize = const Size(600, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pump();

        await tester.pumpWidget(
          Builder(
            builder: (context) {
              expect(AppBreakpoints.isCompact(context), isTrue);
              return const SizedBox();
            },
          ),
        );
      });

      testWidgets('returns false for width >= 900', (tester) async {
        tester.view.physicalSize = const Size(900, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        await tester.pump();

        await tester.pumpWidget(
          Builder(
            builder: (context) {
              expect(AppBreakpoints.isCompact(context), isFalse);
              return const SizedBox();
            },
          ),
        );
      });
    });

    group('isMedium', () {
      testWidgets('returns true for width between 900 and 1279', (tester) async {
        tester.view.physicalSize = const Size(1000, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        await tester.pump();

        await tester.pumpWidget(
          Builder(
            builder: (context) {
              expect(AppBreakpoints.isMedium(context), isTrue);
              return const SizedBox();
            },
          ),
        );
      });

      testWidgets('returns false for width < 900', (tester) async {
        tester.view.physicalSize = const Size(600, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        await tester.pump();

        await tester.pumpWidget(
          Builder(
            builder: (context) {
              expect(AppBreakpoints.isMedium(context), isFalse);
              return const SizedBox();
            },
          ),
        );
      });

      testWidgets('returns false for width >= 1280', (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        await tester.pump();

        await tester.pumpWidget(
          Builder(
            builder: (context) {
              expect(AppBreakpoints.isMedium(context), isFalse);
              return const SizedBox();
            },
          ),
        );
      });
    });

    group('isExpanded', () {
      testWidgets('returns true for width >= 1280', (tester) async {
        tester.view.physicalSize = const Size(1300, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        await tester.pump();

        await tester.pumpWidget(
          Builder(
            builder: (context) {
              expect(AppBreakpoints.isExpanded(context), isTrue);
              return const SizedBox();
            },
          ),
        );
      });

      testWidgets('returns false for width < 1280', (tester) async {
        tester.view.physicalSize = const Size(1000, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        await tester.pump();

        await tester.pumpWidget(
          Builder(
            builder: (context) {
              expect(AppBreakpoints.isExpanded(context), isFalse);
              return const SizedBox();
            },
          ),
        );
      });
    });

    group('WindowSize.of', () {
      testWidgets('returns compact for width < 900', (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        await tester.pump();

        await tester.pumpWidget(
          Builder(
            builder: (context) {
              expect(AppBreakpoints.of(context), WindowSize.compact);
              return const SizedBox();
            },
          ),
        );
      });

      testWidgets('returns medium for width 900-1279', (tester) async {
        tester.view.physicalSize = const Size(1000, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        await tester.pump();

        await tester.pumpWidget(
          Builder(
            builder: (context) {
              expect(AppBreakpoints.of(context), WindowSize.medium);
              return const SizedBox();
            },
          ),
        );
      });

      testWidgets('returns expanded for width >= 1280', (tester) async {
        tester.view.physicalSize = const Size(1400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        await tester.pump();

        await tester.pumpWidget(
          Builder(
            builder: (context) {
              expect(AppBreakpoints.of(context), WindowSize.expanded);
              return const SizedBox();
            },
          ),
        );
      });
    });

    group('WindowSize enum', () {
      test('compact is not medium or expanded', () {
        expect(WindowSize.compact, isNot(equals(WindowSize.medium)));
        expect(WindowSize.compact, isNot(equals(WindowSize.expanded)));
      });

      test('medium is not compact or expanded', () {
        expect(WindowSize.medium, isNot(equals(WindowSize.compact)));
        expect(WindowSize.medium, isNot(equals(WindowSize.expanded)));
      });

      test('expanded is not compact or medium', () {
        expect(WindowSize.expanded, isNot(equals(WindowSize.compact)));
        expect(WindowSize.expanded, isNot(equals(WindowSize.medium)));
      });
    });
  });
}
