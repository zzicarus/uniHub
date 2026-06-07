import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/plugin/plugin_interface.dart';
import '../../core/plugin/plugin_registry.dart';
import '../../core/router/route_names.dart';
import '../../core/theme/app_theme_tokens.dart';
import '../../core/theme/app_tokens.dart';

class Sidebar extends ConsumerWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registry = ref.watch(pluginRegistryProvider);
    final location = GoRouterState.of(context).uri.toString();
    final theme = Theme.of(context);
    final appColors = context.appColors;

    return Container(
      width: AppDesktopSizes.sidebarWidth,
      decoration: BoxDecoration(
        color: appColors.sidebarBackground,
        border: Border(
          right: BorderSide(color: appColors.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.xxl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Row(
              children: [
                const _LogoMark(),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'uniHub',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: AppFontTokens.extraBold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _NavItem(
                  icon: Icons.home_rounded,
                  label: '首页',
                  isSelected: location == '/',
                  onTap: () => context.goNamed(RouteNames.home),
                ),
                ...registry.navEntries.map(
                  (entry) =>
                      entry.children != null && entry.children!.isNotEmpty
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
                          isSelected:
                              location == entry.path ||
                              location.startsWith('${entry.path}/'),
                          onTap: () {
                            context.goNamed(
                              entry.routeName,
                              pathParameters: entry.routeParams,
                            );
                          },
                        ),
                ),
                _NavItem(
                  icon: Icons.check_box_outlined,
                  label: '待办',
                  isSelected: location == '/todos',
                  onTap: () => context.goNamed(RouteNames.todos),
                ),
                _NavItem(
                  icon: Icons.description_outlined,
                  label: '笔记',
                  isSelected: location == '/notes',
                  onTap: () => context.goNamed(RouteNames.notes),
                ),
                _NavItem(
                  icon: Icons.calendar_month_outlined,
                  label: '日历',
                  isSelected: location == '/calendar',
                  onTap: () => context.goNamed(RouteNames.calendar),
                ),
                const SizedBox(height: AppSpacing.lg),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: Divider(),
                ),
                _NavItem(
                  icon: Icons.settings_outlined,
                  label: '设置',
                  isSelected: location == '/settings',
                  onTap: () => context.goNamed(RouteNames.settings),
                ),
                const SizedBox(height: AppSpacing.xxs),
                _NavItem(
                  icon: Icons.palette_outlined,
                  label: '组件目录',
                  isSelected: location == '/style-guide',
                  onTap: () => context.goNamed(RouteNames.styleGuide),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            child: _UserTile(),
          ),
        ],
      ),
    );
  }
}

class _LogoMark extends StatelessWidget {
  const _LogoMark();

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: appColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: appColors.primary.withValues(alpha: 0.18),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Center(
        child: Text(
          'U',
          style: TextStyle(
            color: Colors.white,
            fontSize: AppFontTokens.brand,
            height: 1,
            fontWeight: AppFontTokens.black,
          ),
        ),
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = context.appColors;

    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: appColors.panelBackground,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: appColors.border),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: appColors.primarySoft,
              child: Text(
                'U',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: appColors.primary,
                  fontSize: AppFontTokens.titleLg,
                  fontWeight: AppFontTokens.extraBold,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TODO(profile): Replace neutral copy with profileProvider.
                  Text('uniHub', style: theme.textTheme.titleSmall),
                  Text(
                    '本地优先的个人信息工具箱',
                    style: theme.textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.more_horiz_rounded,
              size: 18,
              color: appColors.textTertiary,
            ),
          ],
        ),
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
  ConsumerState<_ExpandableNavItem> createState() => _ExpandableNavItemState();
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
          isSelected:
              isAnyChildSelected ||
              widget.currentLocation == widget.path ||
              widget.currentLocation.startsWith('${widget.path}/'),
          trailing: AnimatedRotation(
            turns: _expanded ? 0.25 : 0.0,
            duration: const Duration(milliseconds: 180),
            child: const Icon(Icons.chevron_right_rounded, size: 18),
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
          duration: const Duration(milliseconds: 180),
        ),
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool compact;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    this.onTap,
    this.trailing,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = context.appColors;
    final isEnabled = onTap != null;
    final foreground = isSelected
        ? appColors.primary
        : isEnabled
        ? appColors.textSecondary
        : appColors.textTertiary;
    final bgColor = isSelected ? appColors.navSelectedBackground : Colors.transparent;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.lg : AppSpacing.xl,
        vertical: AppSpacing.xxs / 2,
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          height: compact
              ? AppDesktopSizes.compactButtonHeight
              : AppDesktopSizes.navItemHeight,
          child: Row(
            children: [
              Icon(icon, color: foreground, size: compact ? 19 : 22),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: foreground,
                    fontSize: compact ? AppFontTokens.titleMd : AppFontTokens.subtitle,
                    fontWeight: isSelected
                        ? AppFontTokens.extraBold
                        : AppFontTokens.medium,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}
