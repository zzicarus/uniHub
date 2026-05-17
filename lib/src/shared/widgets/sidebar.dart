import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/plugin/plugin_registry.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/router/route_names.dart';

class Sidebar extends ConsumerWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registry = ref.watch(pluginRegistryProvider);
    final location = GoRouterState.of(context).uri.toString();
    final theme = Theme.of(context);
    final navEntries = registry.navEntries;

    return SizedBox(
      width: AppDesktopSizes.sidebarWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                Icon(Icons.hub_outlined, color: AppColors.primary, size: 28),
                const SizedBox(width: AppSpacing.sm),
                Text('UniHub', style: theme.textTheme.titleLarge),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.xs),
          _NavItem(
            icon: Icons.home_rounded,
            label: 'Home',
            isSelected: location == '/',
            onTap: () => context.goNamed(RouteNames.home),
          ),
          ...navEntries.map(
            (entry) => _NavItem(
              icon: entry.icon,
              label: entry.label,
              isSelected: location == entry.path,
              onTap: () {
                context.goNamed(
                  entry.routeName,
                  pathParameters: entry.routeParams,
                );
              },
            ),
          ),
          const Spacer(),
          const Divider(),
          _NavItem(
            icon: Icons.settings_outlined,
            label: 'Settings',
            isSelected: location == '/settings',
            onTap: () => context.goNamed(RouteNames.settings),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = isSelected ? AppColors.primary : AppColors.textSecondary;
    final bgColor = isSelected ? AppColors.primarySoft : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          onTap: onTap,
          child: SizedBox(
            height: AppDesktopSizes.navItemHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: [
                  Icon(icon, color: foreground, size: 22),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: foreground,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
