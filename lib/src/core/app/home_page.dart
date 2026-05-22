import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_breakpoints.dart';
import '../theme/app_tokens.dart';
import 'dashboard_providers.dart';
import '../plugin/plugin_interface.dart';

part 'home/header.dart';
part 'home/focus_section.dart';
part 'home/recent_section.dart';
part 'home/right_rail.dart';
part 'home/mobile_home.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primaryContainer.withValues(alpha: 0.18),
              colorScheme.surfaceContainerLowest,
              colorScheme.tertiaryContainer.withValues(alpha: 0.10),
            ],
            stops: const [0.0, 0.48, 1.0],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < AppBreakpoints.tabletMin) {
                return const _MobileHomeView();
              }
              final isWide = constraints.maxWidth >= AppBreakpoints.wideMin;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xxl,
                        AppSpacing.xxl,
                        AppSpacing.xxl,
                        AppSpacing.section,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1080),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _HomeHeader(),
                            const SizedBox(height: AppSpacing.xxl),
                            const _FocusGrid(),
                            const SizedBox(height: AppSpacing.lg),
                            _QuickAccessPanel(
                              onThoughtsTap: () => context.go('/thoughts'),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            _RecentThoughtsPanel(
                              onOpen: () => context.go('/thoughts'),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            const _HomeWorkGrid(),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (isWide) const _HomeRightRail(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─── Reusable Section / Panel Widgets ───────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData? icon;
  final String? trailing;
  final VoidCallback? onTap;

  const _SectionTitle({
    required this.title,
    this.icon,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: AppSpacing.xs),
        ],
        Expanded(child: Text(title, style: theme.textTheme.titleLarge)),
        if (trailing != null)
          InkWell(
            borderRadius: BorderRadius.circular(AppRadius.xs),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: AppSpacing.xxs,
              ),
              child: Text(
                '$trailing  →',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _Panel({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      elevation: 0,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: const [AppShadows.cardSoft],
        ),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class _IconBubble extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color background;

  const _IconBubble({
    required this.icon,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Icon(icon, color: color, size: 26),
    );
  }
}

class _PillButton extends StatelessWidget {
  final IconData icon;
  final String label;

  const _PillButton({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      height: AppDesktopSizes.compactButtonHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.xs),
          Text(label, style: theme.textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String note;
  final Color color;
  final Color background;
  final IconData icon;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.note,
    required this.color,
    required this.background,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      elevation: 0,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: const [AppShadows.cardSoft],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(title, style: theme.textTheme.labelLarge),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                value,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(note, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThoughtPreviewCard extends StatelessWidget {
  final DashboardItem item;
  final VoidCallback onTap;

  const _ThoughtPreviewCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final title = _firstLine(item.content);
    final body = _restLines(item.content);
    final tag = item.tags.isNotEmpty ? item.tags.first : '';
    final time = _formatTimestamp(item.createdAt);
    final color = _itemColor(item, colorScheme);
    final background = _itemBackground(color, colorScheme);

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      elevation: 0,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: const [AppShadows.cardSoft],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (tag.isNotEmpty) ...[
                      const SizedBox(width: AppSpacing.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                          vertical: AppSpacing.xxs,
                        ),
                        decoration: BoxDecoration(
                          color: background.withValues(alpha: 0.62),
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text(
                          tag,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    Icon(
                      item.isPinned
                          ? Icons.push_pin_rounded
                          : Icons.star_border_rounded,
                      color: item.isPinned
                          ? colorScheme.primary
                          : colorScheme.outline,
                      size: 18,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Expanded(
                  child: Text(
                    body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Text(time, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShortcutCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color background;
  final VoidCallback? onTap;

  const _ShortcutCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.background,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      elevation: 0,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: const [AppShadows.cardSoft],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _PanelHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
      ],
    );
  }
}

class _CompactListItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color background;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _CompactListItem({
    required this.icon,
    required this.color,
    required this.background,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Row(
          children: [
            _SmallIconBubble(icon: icon, color: color, background: background),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.more_vert_rounded,
                color: Theme.of(context).colorScheme.outline,
              ),
          ],
        ),
      ),
    );
  }
}

class _SmallIconBubble extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color background;

  const _SmallIconBubble({
    required this.icon,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

class _ActivityLine extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String time;

  const _ActivityLine({
    required this.icon,
    required this.color,
    required this.title,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(time, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _DataLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String change;
  final Color color;
  final Color background;

  const _DataLine({
    required this.icon,
    required this.label,
    required this.value,
    required this.change,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          _SmallIconBubble(icon: icon, color: color, background: background),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodySmall),
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Text(
            change,
            style: theme.textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Formatting Helpers ─────────────────────────────────────────────

String _firstLine(String text) {
  final trimmed = text.trim();
  final firstLine = trimmed.split(RegExp(r'\s*\n\s*')).first;
  if (firstLine.length <= 20) return firstLine;
  return '${firstLine.substring(0, 20)}...';
}

String _restLines(String text) {
  final trimmed = text.trim();
  final lines = trimmed.split(RegExp(r'\s*\n\s*'));
  if (lines.length <= 1) return trimmed;
  return lines.skip(1).join('\n').trim();
}

String _formatTimestamp(DateTime dt) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final date = DateTime(dt.year, dt.month, dt.day);

  if (date == today) {
    return '今天 ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  } else if (date == yesterday) {
    return '昨天 ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  } else if (dt.year == now.year) {
    return '${dt.month}月${dt.day}日 ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
  return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}

Color _itemColor(DashboardItem item, ColorScheme colorScheme) {
  if (item.colorHex != null && item.colorHex!.isNotEmpty) {
    final cleaned = item.colorHex!.replaceFirst('#', '');
    final normalized = cleaned.length == 6 ? 'FF$cleaned' : cleaned;
    final intVal = int.tryParse(normalized, radix: 16);
    if (intVal != null) return Color(intVal);
  }
  final accentPalette = [
    colorScheme.tertiary,
    colorScheme.secondary,
    colorScheme.primary,
    colorScheme.error,
  ];
  final idx = item.itemId.hashCode.abs();
  return accentPalette[idx % accentPalette.length];
}

Color _itemBackground(Color color, ColorScheme colorScheme) {
  return Color.alphaBlend(
    color.withValues(alpha: 0.12),
    colorScheme.surfaceContainerLow,
  );
}
