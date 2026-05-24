import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:uni_hub/src/core/plugin/plugin_interface.dart';
import 'package:uni_hub/src/core/plugin/plugin_registry.dart';
import 'package:uni_hub/src/core/router/route_names.dart';
import 'package:uni_hub/src/shared/widgets/sidebar.dart';
import 'package:uni_hub/src/core/theme/app_theme_tokens.dart';

void main() {
  PluginRegistry registryWithPluginNav() {
    final registry = PluginRegistry();
    registry.register(_SidebarTestPlugin());
    return registry;
  }

  GoRouter router({String initialLocation = '/'}) {
    return GoRouter(
      initialLocation: initialLocation,
      routes: [
        ShellRoute(
          builder: (context, state, child) => Row(
            textDirection: TextDirection.ltr,
            children: [
              const Sidebar(),
              Expanded(child: child),
            ],
          ),
          routes: [
            GoRoute(
              path: '/',
              name: RouteNames.home,
              builder: (_, _) => const Text('首页内容'),
            ),
            GoRoute(
              path: '/library',
              name: 'library',
              builder: (_, _) => const Text('资料库内容'),
            ),
            GoRoute(
              path: '/todos',
              name: RouteNames.todos,
              builder: (_, _) => const Text('待办内容'),
            ),
            GoRoute(
              path: '/notes',
              name: RouteNames.notes,
              builder: (_, _) => const Text('笔记内容'),
            ),
            GoRoute(
              path: '/calendar',
              name: RouteNames.calendar,
              builder: (_, _) => const Text('日历内容'),
            ),
            GoRoute(
              path: '/favorites',
              name: RouteNames.favorites,
              builder: (_, _) => const Text('收藏内容'),
            ),
            GoRoute(
              path: '/settings',
              name: RouteNames.settings,
              builder: (_, _) => const Text('设置内容'),
            ),
            GoRoute(
              path: '/style-guide',
              name: RouteNames.styleGuide,
              builder: (_, _) => const Text('组件目录内容'),
            ),
          ],
        ),
      ],
    );
  }

  ThemeData testTheme() {
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

  Future<void> pumpSidebar(
    WidgetTester tester, {
    String initialLocation = '/',
  }) async {
    tester.view.physicalSize = const ui.Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pluginRegistryProvider.overrideWithValue(registryWithPluginNav()),
        ],
        child: MaterialApp.router(
          theme: testTheme(),
          routerConfig: router(initialLocation: initialLocation),
        ),
      ),
    );
  }

  testWidgets('renders built-in and plugin navigation items', (tester) async {
    await pumpSidebar(tester);

    expect(find.text('uniHub'), findsOneWidget);
    expect(find.text('首页'), findsOneWidget);
    expect(find.text('资料库'), findsOneWidget);
    expect(find.text('待办'), findsOneWidget);
    expect(find.text('组件目录'), findsOneWidget);
  });

  testWidgets('tapping an item navigates to its destination', (tester) async {
    await pumpSidebar(tester);

    await tester.tap(find.text('待办'));
    await tester.pumpAndSettle();

    expect(find.text('待办内容'), findsOneWidget);
  });

  testWidgets('active item uses selected highlight color', (tester) async {
    await pumpSidebar(tester, initialLocation: '/library');

    final theme = testTheme();
    final selectedColor = theme
        .extension<UniHubThemeColors>()!
        .navSelectedBackground;

    // _NavItem uses a Container decoration for selected state.
    final containers = tester.widgetList<Container>(
      find.ancestor(of: find.text('资料库'), matching: find.byType(Container)),
    );

    expect(
      containers.any((container) {
        final decoration = container.decoration;
        return decoration is BoxDecoration && decoration.color == selectedColor;
      }),
      isTrue,
    );
  });
}

class _SidebarTestPlugin extends UniHubPlugin {
  @override
  String get id => 'sidebar-test';

  @override
  String get name => 'Sidebar Test';

  @override
  List<NavEntry> get navEntries => const [
    NavEntry(
      label: '资料库',
      icon: Icons.folder_outlined,
      routeName: 'library',
      path: '/library',
    ),
  ];
}
