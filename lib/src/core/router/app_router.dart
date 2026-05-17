import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../app/home_page.dart';
import '../app/settings_page.dart';
import '../plugin/plugin_registry.dart';
import '../../shared/layouts/app_layout.dart';
import 'route_names.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final registry = ref.watch(pluginRegistryProvider);
  return GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppLayout(child: child),
        routes: [
          GoRoute(
            path: '/',
            name: RouteNames.home,
            builder: (context, state) => const HomePage(),
          ),
          ...registry.mergedRoutes,
          GoRoute(
            path: '/settings',
            name: RouteNames.settings,
            builder: (context, state) => const SettingsPage(),
          ),
        ],
      ),
    ],
  );
});
