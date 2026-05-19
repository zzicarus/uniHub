import 'package:flutter/material.dart';
import '../../../../core/theme/app_tokens.dart';

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
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: const [AppShadows.card],
      ),
      child: child,
    );
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
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Icon(icon, color: color, size: 28),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: AppDesktopSizes.compactButtonHeight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.tertiaryContainer
              : colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: selected ? colorScheme.tertiary : colorScheme.outline,
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
    );
  }
}

class ThoughtSearchBox extends StatelessWidget {
  const ThoughtSearchBox({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      width: 260,
      height: AppSizes.inputHeight,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colorScheme.outline),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: colorScheme.outline),
          const SizedBox(width: AppSpacing.xs),
          Text('Ctrl + K 全局搜索', style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class ThoughtIconSquare extends StatelessWidget {
  final IconData icon;

  const ThoughtIconSquare({required this.icon, super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: AppSizes.inputHeight,
      height: AppSizes.inputHeight,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Icon(icon, color: colorScheme.onSurfaceVariant),
    );
  }
}

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
          height: AppDesktopSizes.compactButtonHeight,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? colorScheme.primary : colorScheme.outline,
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
              Text(
                value,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: selected
                      ? colorScheme.onPrimary.withValues(alpha: 0.7)
                      : colorScheme.outline,
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
        Chip(
          label: Text(count.toString()),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          side: BorderSide.none,
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
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
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurface),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
        if (count != null)
          Chip(
            label: Text(count.toString()),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            side: BorderSide.none,
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
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          ThoughtIconBubble(
            icon: Icons.lightbulb_outline,
            color: Theme.of(context).colorScheme.onTertiaryContainer,
            background: Theme.of(context).colorScheme.tertiaryContainer,
          ),
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
          Icon(
            Icons.star_rounded,
            color: Theme.of(context).colorScheme.tertiary,
            size: 18,
          ),
        ],
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

class ThoughtErrorState extends StatelessWidget {
  final Object error;

  const ThoughtErrorState({required this.error, super.key});

  @override
  Widget build(BuildContext context) {
    return ThoughtPanel(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Text(
          '加载失败: $error',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}

class ThoughtEmptyState extends StatelessWidget {
  final bool isArchived;
  final String? tagFilter;

  const ThoughtEmptyState({
    required this.isArchived,
    required this.tagFilter,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ThoughtPanel(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          children: [
            Icon(
              isArchived ? Icons.archive_outlined : Icons.lightbulb_outline,
              size: 54,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              tagFilter != null
                  ? '没有匹配 "#$tagFilter" 的想法'
                  : isArchived
                  ? '归档里还没有想法'
                  : '还没有想法',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              isArchived ? '归档后的想法会在这里显示。' : '用上方输入框记录第一个想法。',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
