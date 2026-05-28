import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../router/route_names.dart';
import '../theme/app_tokens.dart';

class MobileShell extends ConsumerWidget {
  final Widget child;

  const MobileShell({required this.child, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;

    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: child,
      bottomNavigationBar: _MobileNavigationBar(location: location),
    );
  }
}

class _MobileNavigationBar extends StatelessWidget {
  final String location;

  const _MobileNavigationBar({required this.location});

  @override
  Widget build(BuildContext context) {
    final selectedIndex = switch (location) {
      '/' => 0,
      '/thoughts' => 1,
      '/todos' => 2,
      '/notes' => 3,
      '/collections' => 4,
      _ => 0,
    };

    final colorScheme = Theme.of(context).colorScheme;
    return NavigationBar(
      height: AppMobileSizes.bottomNavHeight,
      backgroundColor: colorScheme.surface,
      indicatorColor: colorScheme.primaryContainer,
      selectedIndex: selectedIndex,
      destinations: [
        const NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: '首页',
        ),
        const NavigationDestination(
          icon: Icon(Icons.lightbulb_outline),
          selectedIcon: Icon(Icons.lightbulb),
          label: '想法',
        ),
        const NavigationDestination(
          icon: Icon(Icons.check_box_outlined),
          selectedIcon: Icon(Icons.check_box_rounded),
          label: '待办',
        ),
        const NavigationDestination(
          icon: Icon(Icons.article_outlined),
          selectedIcon: Icon(Icons.article_rounded),
          label: '笔记',
        ),
        const NavigationDestination(
          icon: Icon(Icons.bookmark_border_rounded),
          selectedIcon: Icon(Icons.bookmark_rounded),
          label: '收藏库',
        ),
      ],
      onDestinationSelected: (index) {
        switch (index) {
          case 0:
            context.goNamed(RouteNames.home);
          case 1:
            context.goNamed(RouteNames.thoughts);
          case 2:
            context.goNamed(RouteNames.todos);
          case 3:
            context.goNamed(RouteNames.notes);
          case 4:
            context.goNamed(RouteNames.collections);
        }
      },
    );
  }
}
