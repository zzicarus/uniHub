import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../tags/tag_models.dart';

/// A reusable tag chip for filtering / displaying tags.
///
/// Two constructors:
/// - [AppTagChip] — plain label (no provider dependency)
/// - [AppTagChip.fromTag] — backed by [AppTag] with stable colour
///
/// ```dart
/// AppTagChip(label: 'flutter', selected: true, onTap: () {})
/// AppTagChip.fromTag(tag: myTag, onTap: () {})
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

  /// When provided, the chip uses these colours instead of the default.
  final Color? chipColor;

  final Color? chipBackgroundColor;

  const AppTagChip({
    required this.label,
    this.count,
    this.selected = false,
    this.onTap,
    this.compact = false,
    this.showHash = true,
    this.leadingIcon,
    this.chipColor,
    this.chipBackgroundColor,
    super.key,
  });

  /// Create a chip backed by [AppTag] with stable colour tokens.
  ///
  /// The chip foreground is resolved from [AppTag.colorToken] using the
  /// current [ColorScheme], making it consistent across every page.
  factory AppTagChip.fromTag({
    required AppTag tag,
    int? count,
    bool selected = false,
    VoidCallback? onTap,
    bool compact = false,
    bool showHash = true,
    Key? key,
  }) {
    return AppTagChip(
      key: key,
      label: tag.name,
      count: count,
      selected: selected,
      onTap: onTap,
      compact: compact,
      showHash: showHash,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    final Color backgroundColor;
    final Color foregroundColor;
    final Color borderColor;

    if (selected) {
      backgroundColor = chipColor ?? colorScheme.primary;
      foregroundColor = colorScheme.onPrimary;
      borderColor = chipColor ?? colorScheme.primary;
    } else {
      backgroundColor = chipBackgroundColor ?? colorScheme.surfaceContainerLow;
      foregroundColor = chipColor ?? colorScheme.onSurfaceVariant;
      borderColor = colorScheme.outlineVariant;
    }

    final chipHeight = compact ? 24.0 : 32.0;
    final horizontalPadding = compact ? AppSpacing.sm : AppSpacing.md;
    final fontSize = compact ? 12.0 : 13.0;

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
                    fontSize: fontSize,
                  ),
                ),
                if (count != null) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    count.toString(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: selected
                          ? foregroundColor.withValues(alpha: 0.78)
                          : foregroundColor.withValues(alpha: 0.7),
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
/// AppSelectedTagChip(label: 'flutter', onDeleted: () {})
/// ```
class AppSelectedTagChip extends StatelessWidget {
  final String label;
  final VoidCallback? onDeleted;

  const AppSelectedTagChip({
    required this.label,
    this.onDeleted,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return InputChip(
      label: Text('#$label'),
      onDeleted: onDeleted,
      deleteIcon: const Icon(Icons.close_rounded, size: 16),
      backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.4),
      side: BorderSide(
        color: colorScheme.primary.withValues(alpha: 0.15),
      ),
      labelStyle: theme.textTheme.labelMedium?.copyWith(
        color: colorScheme.primary,
        fontWeight: AppFontTokens.extraBold,
      ),
    );
  }
}

/// A pill-shaped button used to reveal additional tags.
///
/// ```dart
/// AppMoreTagsButton(onTap: () => showMoreTagsPopover(context))
/// ```
class AppMoreTagsButton extends StatelessWidget {
  final VoidCallback onTap;
  final String label;

  const AppMoreTagsButton({
    required this.onTap,
    this.label = '更多标签',
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            border: Border.all(color: colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, size: 16, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: AppSpacing.xxs),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
