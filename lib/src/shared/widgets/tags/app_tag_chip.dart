import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_theme_tokens.dart';

/// A reusable tag chip for filtering / displaying tags.
///
/// Designed to work with any data model — the tag string is provided as a
/// plain [label] parameter. No provider dependency.
///
/// ```dart
/// AppTagChip(
///   label: 'flutter',
///   count: 12,
///   selected: true,
///   onTap: () { /* toggle */ },
/// )
/// ```
class AppTagChip extends StatelessWidget {
  /// The raw tag name (without `#` — added automatically when [showHash] is true).
  final String label;

  /// Optional occurrence count displayed as a badge.
  final int? count;

  /// Whether this chip reflects an active filter.
  final bool selected;

  /// Called when the chip is tapped.
  final VoidCallback? onTap;

  /// When `true` renders a smaller chip suitable for constrained spaces.
  final bool compact;

  /// Whether to prepend `#` to [label] for display.
  final bool showHash;

  /// An optional icon shown before the label.
  final IconData? leadingIcon;

  const AppTagChip({
    required this.label,
    this.count,
    this.selected = false,
    this.onTap,
    this.compact = false,
    this.showHash = true,
    this.leadingIcon,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);

    final backgroundColor = selected ? colors.primary : colors.surfaceMuted;
    final foregroundColor = selected ? Colors.white : colors.textSecondary;
    final borderColor = selected ? colors.primary : colors.border;
    final chipHeight = compact ? 28.0 : 36.0;
    final horizontalPadding = compact ? AppSpacing.sm : AppSpacing.md;

    return Tooltip(
      message: label,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.full),
          child: Container(
            height: chipHeight,
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            decoration: BoxDecoration(
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (leadingIcon != null) ...[
                  Icon(leadingIcon, size: 14, color: foregroundColor),
                  const SizedBox(width: AppSpacing.xxs),
                ],
                Text(
                  showHash ? '#$label' : label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: foregroundColor,
                    fontWeight: AppFontTokens.extraBold,
                  ),
                ),
                if (count != null) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    count.toString(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: selected
                          ? Colors.white.withValues(alpha: 0.78)
                          : colors.textTertiary,
                      fontWeight: AppFontTokens.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A tag chip that represents an already-selected filter, with a delete icon.
///
/// ```dart
/// AppSelectedTagChip(
///   label: 'flutter',
///   onDeleted: () { /* remove filter */ },
/// )
/// ```
class AppSelectedTagChip extends StatelessWidget {
  /// The tag name (without `#` — it is prepended automatically).
  final String label;

  /// Called when the user taps the close icon.
  final VoidCallback? onDeleted;

  const AppSelectedTagChip({
    required this.label,
    this.onDeleted,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);

    return InputChip(
      label: Text('#$label'),
      onDeleted: onDeleted,
      deleteIcon: const Icon(Icons.close_rounded, size: 16),
      backgroundColor: colors.primarySoft,
      side: BorderSide(
        color: colors.primary.withValues(alpha: 0.15),
      ),
      labelStyle: theme.textTheme.labelMedium?.copyWith(
        color: colors.primary,
        fontWeight: AppFontTokens.extraBold,
      ),
    );
  }
}

/// A pill-shaped button used to reveal additional tags (e.g. in a popover).
///
/// ```dart
/// AppMoreTagsButton(
///   onTap: () => showMoreTagsPopover(context),
/// )
/// ```
class AppMoreTagsButton extends StatelessWidget {
  /// Called when the button is tapped.
  final VoidCallback onTap;

  /// The button label. Defaults to `'更多标签'`.
  final String label;

  const AppMoreTagsButton({
    required this.onTap,
    this.label = '更多标签',
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);

    return Material(
      color: colors.surfaceMuted,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            border: Border.all(color: colors.border),
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, size: 16, color: colors.textSecondary),
              const SizedBox(width: AppSpacing.xxs),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
