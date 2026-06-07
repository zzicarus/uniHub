import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/ui/style_guide_screen.dart';
import '../app/adaptive_shell.dart';
import '../app/home_page.dart';
import '../app/mobile_placeholder_pages.dart';
import '../app/settings_page.dart';
import '../plugin/plugin_registry.dart';
import '../storage/ui/storage_management_page.dart';
import 'route_names.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final registry = ref.watch(pluginRegistryProvider);
  return GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) => AdaptiveShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            name: RouteNames.home,
            builder: (context, state) => const HomePage(),
          ),
          ...registry.mergedRoutes,
          GoRoute(
            path: '/todos',
            name: RouteNames.todos,
            builder: (context, state) => const TodosPage(),
          ),
          GoRoute(
            path: '/notes',
            name: RouteNames.notes,
            builder: (context, state) => const NotesPage(),
          ),
          GoRoute(
            path: '/calendar',
            name: RouteNames.calendar,
            builder: (context, state) => const CalendarPage(),
          ),
          GoRoute(
            path: '/favorites',
            name: RouteNames.favorites,
            redirect: (_, _) => '/collections',
          ),
          GoRoute(
            path: '/search',
            name: RouteNames.search,
            builder: (context, state) => const SearchPage(),
          ),
          GoRoute(
            path: '/settings',
            name: RouteNames.settings,
            builder: (context, state) => const SettingsPage(),
          ),
          GoRoute(
            path: '/style-guide',
            name: RouteNames.styleGuide,
            builder: (context, state) => const StyleGuideScreen(),
          ),
          GoRoute(
            path: '/settings/storage',
            name: RouteNames.storageManagement,
            builder: (context, state) => const StorageManagementPage(),
          ),
        ],
      ),
    ],
  );
});
