import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uni_hub/src/core/theme/app_theme_tokens.dart';
import 'package:uni_hub/src/shared/widgets/tags/app_tag_chip.dart';

/// Create a test [ThemeData] with the [UniHubThemeColors] extension registered.
ThemeData _testTheme() {
  return ThemeData(
    useMaterial3: true,
    extensions: const <ThemeExtension<dynamic>>[
      UniHubThemeColors(
        background: Color(0xFFFAFBFE),
        surface: Color(0xFFFFFFFF),
        surfaceMuted: Color(0xFFF6F8FC),
        border: Color(0xFFE8ECF4),
        borderStrong: Color(0xFFD1D5DB),
        primary: Color(0xFF4F6BFF),
        primaryHover: Color(0xFF3B55E0),
        primarySoft: Color(0xFFEFF3FF),
        success: Color(0xFF22C55E),
        successSoft: Color(0xFFEFFAF3),
        warning: Color(0xFFF59E0B),
        warningSoft: Color(0xFFFFF7E8),
        purple: Color(0xFF8B5CF6),
        purpleSoft: Color(0xFFF4F0FF),
        danger: Color(0xFFF43F5E),
        dangerSoft: Color(0xFFFFF0F4),
        textPrimary: Color(0xFF111827),
        textSecondary: Color(0xFF667085),
        textTertiary: Color(0xFF98A2B3),
        sidebarBackground: Color(0xFFF6F8FC),
        navSelectedBackground: Color(0xFFEFF3FF),
        panelBackground: Color(0xFFFFFFFF),
      ),
    ],
  );
}

/// Helper to pump an [AppTagChip] widget in a test environment.
Future<void> pumpChip(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(
      theme: _testTheme(),
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  group('AppTagChip', () {
    testWidgets('displays label with # prefix by default', (tester) async {
      await pumpChip(
        tester,
        const AppTagChip(label: '产品', onTap: null),
      );

      // Default showHash = true, so label should show "#产品"
      expect(find.text('#产品'), findsOneWidget);
    });

    testWidgets('displays label without # when showHash is false', (
      tester,
    ) async {
      await pumpChip(
        tester,
        const AppTagChip(label: '产品', showHash: false, onTap: null),
      );

      expect(find.text('产品'), findsOneWidget);
      expect(find.text('#产品'), findsNothing);
    });

    testWidgets('shows count when provided', (tester) async {
      await pumpChip(
        tester,
        const AppTagChip(label: '产品', count: 8, onTap: null),
      );

      expect(find.text('#产品'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
    });

    testWidgets('hides count when null', (tester) async {
      await pumpChip(
        tester,
        const AppTagChip(label: '产品', onTap: null),
      );

      expect(find.text('#产品'), findsOneWidget);
      expect(find.text('8'), findsNothing);
    });

    testWidgets('renders in selected state without error', (tester) async {
      await pumpChip(
        tester,
        const AppTagChip(label: '产品', selected: true, count: 5, onTap: null),
      );

      expect(find.text('#产品'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('fires onTap when tapped', (tester) async {
      var tapped = false;
      await pumpChip(
        tester,
        AppTagChip(label: '产品', onTap: () => tapped = true),
      );

      await tester.tap(find.text('#产品'));
      expect(tapped, isTrue);
    });

    testWidgets('renders leading icon when provided', (tester) async {
      await pumpChip(
        tester,
        const AppTagChip(
          label: '产品',
          leadingIcon: Icons.star,
          onTap: null,
        ),
      );

      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('renders compact variant without error', (tester) async {
      await pumpChip(
        tester,
        const AppTagChip(label: '产品', compact: true, onTap: null),
      );

      expect(find.text('#产品'), findsOneWidget);
    });
  });
}
