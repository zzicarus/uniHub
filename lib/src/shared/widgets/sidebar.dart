import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/plugin/plugin_interface.dart';
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
            (entry) => entry.children != null && entry.children!.isNotEmpty
                ? _ExpandableNavItem(
                    label: entry.label,
                    icon: entry.icon,
                    path: entry.path,
                    children: entry.children!,
                    currentLocation: location,
                  )
                : _NavItem(
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

class _ExpandableNavItem extends ConsumerStatefulWidget {
  final String label;
  final IconData icon;
  final String path;
  final List<NavEntry> children;
  final String currentLocation;

  const _ExpandableNavItem({
    required this.label,
    required this.icon,
    required this.path,
    required this.children,
    required this.currentLocation,
  });

  @override
  ConsumerState<_ExpandableNavItem> createState() =>
      _ExpandableNavItemState();
}

class _ExpandableNavItemState extends ConsumerState<_ExpandableNavItem> {
  late bool _expanded;

  String _childUri(NavEntry child) {
    if (child.queryParams.isNotEmpty) {
      return Uri(
        path: child.path,
        queryParameters: child.queryParams,
      ).toString();
    }
    return child.path;
  }

  bool _isChildSelected(NavEntry child) {
    return widget.currentLocation == _childUri(child);
  }

  @override
  void initState() {
    super.initState();
    _expanded = _shouldBeExpanded();
  }

  @override
  void didUpdateWidget(covariant _ExpandableNavItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentLocation != oldWidget.currentLocation) {
      _expanded = _shouldBeExpanded();
    }
  }

  bool _shouldBeExpanded() {
    return widget.children.any(_isChildSelected) ||
        widget.currentLocation == widget.path ||
        widget.currentLocation.startsWith('${widget.path}/');
  }

  void _toggle() {
    setState(() {
      _expanded = !_expanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAnyChildSelected = widget.children.any(_isChildSelected);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _NavItem(
          icon: widget.icon,
          label: widget.label,
          isSelected: isAnyChildSelected ||
              widget.currentLocation == widget.path,
          trailing: AnimatedRotation(
            turns: _expanded ? 0.25 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: const Icon(Icons.chevron_right, size: 18),
          ),
          onTap: _toggle,
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(left: AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: widget.children.map((child) {
                final isSelected = _isChildSelected(child);
                return _NavItem(
                  icon: child.icon,
                  label: child.label,
                  isSelected: isSelected,
                  compact: true,
                  onTap: () {
                    if (child.queryParams.isNotEmpty) {
                      context.goNamed(
                        child.routeName,
                        pathParameters: child.routeParams,
                        queryParameters: child.queryParams,
                      );
                    } else {
                      context.goNamed(
                        child.routeName,
                        pathParameters: child.routeParams,
                      );
                    }
                  },
                );
              }).toList(),
            ),
          ),
          crossFadeState: _expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool compact;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.trailing,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = isSelected ? AppColors.primary : AppColors.textSecondary;
    final bgColor = isSelected ? AppColors.primarySoft : Colors.transparent;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.xs : AppSpacing.sm,
        vertical: 2,
      ),
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          onTap: onTap,
          child: SizedBox(
            height: compact
                ? AppDesktopSizes.compactButtonHeight
                : AppDesktopSizes.navItemHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: [
                  Icon(icon, color: foreground, size: compact ? 20 : 22),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: foreground,
                        fontSize: compact ? 13 : null,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  ?trailing,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
