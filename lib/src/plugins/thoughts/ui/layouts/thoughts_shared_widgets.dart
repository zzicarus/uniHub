import 'package:flutter/material.dart';
import 'package:uni_hub/src/core/theme/app_tokens.dart';
import 'package:uni_hub/src/shared/widgets/app_compact_list_item.dart';
import 'package:uni_hub/src/shared/widgets/app_icon_bubble.dart';
import 'package:uni_hub/src/shared/widgets/app_panel.dart';
import 'package:uni_hub/src/shared/widgets/app_search_box.dart';

/// Desktop-style white card with thin border and light shadow.
/// Matches `_Panel` in home_page.dart.
class ThoughtPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const ThoughtPanel({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AppPanel(padding: padding, child: child);
  }
}

class ThoughtIconBubble extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color background;

  const ThoughtIconBubble({
    required this.icon,
    required this.color,
    required this.background,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AppIconBubble(
      icon: icon,
      color: color,
      background: background,
      size: 48,
      iconSize: 24,
      shape: BoxShape.rectangle,
      radius: AppRadius.md,
    );
  }
}

class ThoughtPillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool selected;

  const ThoughtPillButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.selected = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Material(
      color: selected ? colorScheme.tertiaryContainer : colorScheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: selected
                  ? colorScheme.tertiary
                  : colorScheme.outlineVariant,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected
                    ? colorScheme.onTertiaryContainer
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: selected ? colorScheme.onTertiaryContainer : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Desktop-style search box with consistent visual.
class ThoughtSearchBox extends StatelessWidget {
  const ThoughtSearchBox({super.key});

  @override
  Widget build(BuildContext context) {
    return AppSearchBox(
      width: 320,
      hintText: 'Ctrl + K 全局搜索',
      onTap: () {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('全局搜索即将上线')));
      },
    );
  }
}

class ThoughtIconSquare extends StatelessWidget {
  final IconData icon;

  const ThoughtIconSquare({required this.icon, super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      elevation: 0,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: colorScheme.outlineVariant),
          boxShadow: const [AppShadows.cardSoft],
        ),
        child: Icon(icon, color: colorScheme.onSurfaceVariant, size: 22),
      ),
    );
  }
}

/// Desktop-style filter chip matching the visual language.
class ThoughtFilterChip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final VoidCallback? onTap;

  const ThoughtFilterChip({
    required this.label,
    required this.value,
    this.selected = false,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Material(
      color: selected ? colorScheme.primary : colorScheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected
                  ? colorScheme.primary
                  : colorScheme.outlineVariant,
            ),
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: selected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxs,
                  vertical: 1,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? colorScheme.onPrimary.withValues(alpha: 0.15)
                      : colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  value,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontSize: 11,
                    color: selected
                        ? colorScheme.onPrimary.withValues(alpha: 0.85)
                        : colorScheme.outline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ThoughtSectionLabel extends StatelessWidget {
  final IconData icon;
  final String title;
  final int count;

  const ThoughtSectionLabel({
    required this.icon,
    required this.title,
    required this.count,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: colorScheme.primary),
        const SizedBox(width: AppSpacing.xs),
        Text(title, style: theme.textTheme.titleMedium),
        const SizedBox(width: AppSpacing.xs),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Text(
            count.toString(),
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class ThoughtPanelHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final int? count;

  const ThoughtPanelHeader({
    required this.title,
    required this.icon,
    this.count,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.onSurface),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
        if (count != null)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Text(
              count.toString(),
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}

class ThoughtCompactItem extends StatelessWidget {
  final String title;
  final String subtitle;

  const ThoughtCompactItem({
    required this.title,
    required this.subtitle,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: AppCompactListItem(
        icon: Icons.lightbulb_outline,
        color: colorScheme.onTertiaryContainer,
        background: colorScheme.tertiaryContainer,
        title: title,
        subtitle: subtitle,
        trailing: Icon(
          Icons.star_rounded,
          color: colorScheme.tertiary,
          size: 18,
        ),
      ),
    );
  }
}

class ThoughtStatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color background;

  const ThoughtStatRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.background,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          ThoughtIconBubble(icon: icon, color: color, background: background),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class ThoughtSmallMutedText extends StatelessWidget {
  final String text;

  const ThoughtSmallMutedText(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.bodySmall);
  }
}

class ThoughtLoadingState extends StatelessWidget {
  const ThoughtLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return const ThoughtPanel(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xxl),
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}

/// Desktop-style tag chip for the right rail tags panel.
class ThoughtTagChip extends StatelessWidget {
  final String label;
  final int count;
  final VoidCallback? onTap;

  const ThoughtTagChip({
    required this.label,
    required this.count,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Material(
      color: colorScheme.primaryContainer.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xxs + 2,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.sell_outlined, size: 12, color: colorScheme.primary),
              const SizedBox(width: AppSpacing.xxs),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: AppSpacing.xxs),
              Text(
                count.toString(),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.outline,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
