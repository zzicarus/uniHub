import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uni_hub/src/shared/widgets/app_compact_list_item.dart';
import 'package:uni_hub/src/shared/widgets/app_icon_bubble.dart';
import 'package:uni_hub/src/shared/widgets/app_panel.dart';
import 'package:uni_hub/src/shared/widgets/app_search_box.dart';
import 'package:uni_hub/src/shared/widgets/app_section_header.dart';

import '../plugin/plugin_interface.dart';
import '../theme/app_breakpoints.dart';
import '../theme/app_tokens.dart';
import 'dashboard_providers.dart';

part 'home/header.dart';
part 'home/focus_section.dart';
part 'home/recent_section.dart';
part 'home/right_rail.dart';
part 'home/mobile_home.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
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
                    padding: const EdgeInsets.fromLTRB(32, 28, 32, 40),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: AppDesktopSizes.desktopContentMaxWidth,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _HomeHeader(),
                            const SizedBox(height: AppSpacing.xl),
                            const _FocusGrid(),
                            const SizedBox(height: AppSpacing.lg),
                            _QuickAccessPanel(
                              onThoughtsTap: () => context.go('/thoughts'),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            _RecentThoughtsPanel(
                              onOpen: () => context.go('/thoughts'),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            const _HomeWorkGrid(),
                          ],
                        ),
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
    );
  }
}

// ─── Shared wrappers kept for the mobile part file ──────────────────

class _Panel extends StatelessWidget {
  final Widget child;

  const _Panel({required this.child});

  @override
  Widget build(BuildContext context) {
    return AppPanel(child: child);
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
    return AppIconBubble(
      icon: icon,
      color: color,
      background: background,
      size: 58,
      iconSize: 28,
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
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
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
    final colorScheme = theme.colorScheme;

    return AppPanel(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: 16,
      ),
      child: Row(
        children: [
          AppIconBubble(
            icon: icon,
            color: color,
            background: background,
            size: 58,
            iconSize: 28,
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  note,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
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

    return AppPanel(
      onTap: onTap,
      compact: true,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Icon(
                item.isPinned
                    ? Icons.push_pin_rounded
                    : Icons.star_border_rounded,
                color: item.isPinned
                    ? colorScheme.primary
                    : colorScheme.outline,
                size: 17,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Expanded(
            child: Text(
              body.isEmpty ? title : body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.25,
              ),
            ),
          ),
          Row(
            children: [
              if (tag.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    tag,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              const Spacer(),
              Text(
                time,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.outline,
                ),
              ),
            ],
          ),
        ],
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

    return AppPanel(
      onTap: onTap,
      compact: true,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppIconBubble(
            icon: icon,
            color: color,
            background: background,
            size: 42,
            iconSize: 22,
            shape: BoxShape.rectangle,
            radius: AppRadius.lg,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
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
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          AppIconBubble(
            icon: icon,
            color: color,
            background: color.withValues(alpha: 0.10),
            size: 34,
            iconSize: 17,
            shape: BoxShape.rectangle,
            radius: AppRadius.sm,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            time,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.outline,
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
  if (trimmed.isEmpty) return '未命名想法';
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
