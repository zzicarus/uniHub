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

    return Scaffold(
      backgroundColor: AppColors.background,
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
    final moreSelected =
        location == '/calendar' ||
        location == '/favorites' ||
        location == '/settings';
    final searchSelected = location == '/search';
    final selectedIndex = switch (location) {
      '/' => 0,
      '/thoughts' => 1,
      '/todos' => 2,
      '/notes' => 3,
      _ when searchSelected || moreSelected => 4,
      _ => 0,
    };

    return NavigationBar(
      height: AppMobileSizes.bottomNavHeight,
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: AppColors.primarySoft,
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
        NavigationDestination(
          icon: Icon(
            searchSelected ? Icons.search_rounded : Icons.grid_view_rounded,
          ),
          selectedIcon: Icon(
            searchSelected ? Icons.search_rounded : Icons.grid_view_rounded,
          ),
          label: searchSelected ? '搜索' : '更多',
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
            context.goNamed(
              searchSelected ? RouteNames.search : RouteNames.calendar,
            );
        }
      },
    );
  }
}
