import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_theme_tokens.dart';
import 'app_tag_chip.dart';

/// A bar displaying currently selected tags with individual and bulk removal.
///
/// Automatically hides when [selectedTags] is empty.
///
/// ```dart
/// AppSelectedTagsBar(
///   selectedTags: selectedTags,
///   onRemove: (tag) => /* remove one */,
///   onClear: () => /* clear all */,
/// )
/// ```
class AppSelectedTagsBar extends StatelessWidget {
  /// The set of currently selected tag names.
  final Set<String> selectedTags;

  /// Called when the close icon on a single tag chip is tapped.
  final ValueChanged<String> onRemove;

  /// Called when the "clear" button is tapped.
  final VoidCallback onClear;

  /// Label text shown before the chips.
  final String label;

  /// Label for the clear-all button.
  final String clearLabel;

  /// Maximum number of chips to display before showing a `+N` overflow indicator.
  final int maxVisibleTags;

  const AppSelectedTagsBar({
    required this.selectedTags,
    required this.onRemove,
    required this.onClear,
    this.label = '已选标签：',
    this.clearLabel = '清除标签',
    this.maxVisibleTags = 5,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedTags.isEmpty) return const SizedBox.shrink();

    final colors = context.appColors;
    final theme = Theme.of(context);

    final sortedTags = selectedTags.toList()..sort();
    final visibleTags = sortedTags.take(maxVisibleTags).toList();
    final overflowCount = sortedTags.length - maxVisibleTags;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          top: BorderSide(
            color: colors.border.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: colors.textSecondary,
              fontWeight: AppFontTokens.bold,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                ...visibleTags.map((tag) => AppSelectedTagChip(
                  label: tag,
                  onDeleted: () => onRemove(tag),
                )),
                if (overflowCount > 0) _overflowChip(context, overflowCount),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.close_rounded, size: 16),
            label: Text(clearLabel),
          ),
        ],
      ),
    );
  }

  Widget _overflowChip(BuildContext context, int count) {
    final colors = context.appColors;
    final theme = Theme.of(context);

    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: colors.border),
      ),
      child: Center(
        child: Text(
          '+$count',
          style: theme.textTheme.labelMedium?.copyWith(
            color: colors.textSecondary,
            fontWeight: AppFontTokens.bold,
          ),
        ),
      ),
    );
  }
}
