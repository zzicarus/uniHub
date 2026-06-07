import 'package:flutter/material.dart';

import '../../../core/theme/app_theme_tokens.dart';
import '../../../core/theme/app_tokens.dart';
import '../../tags/tag_models.dart';
import 'app_tag_chip.dart';

/// A reusable horizontal tag filter bar.
///
/// Renders a label, a row of [AppTagChip]s, and an optional [AppMoreTagsButton].
/// Designed to be plugged into any module — no provider dependency.
///
/// ```dart
/// AppTagFilterBar(
///   tags: tagStats,
///   selectedTags: selectedTags,
///   onTagToggle: (tag) { /* toggle */ },
///   onMoreTap: () => _showMorePopover(context),
/// )
/// ```
class AppTagFilterBar extends StatelessWidget {
  /// All available tag statistics to display.
  final List<AppTagStat> tags;

  /// The set of currently selected tag names.
  final Set<String> selectedTags;

  /// Called when a tag chip is tapped with its [name].
  final ValueChanged<String> onTagToggle;

  /// Called when the "more" button is tapped.
  final VoidCallback? onMoreTap;

  /// Label text shown before the chips. Defaults to `'按标签筛选：'`.
  final String label;

  /// Maximum number of tags to show before the "more" button appears.
  final int maxVisibleTags;

  /// Whether to display the occurrence count on each chip.
  final bool showCounts;

  /// When `true` renders chips in a horizontally scrollable row instead of
  /// a multi-line [Wrap].
  final bool horizontalScroll;

  /// Text shown when [tags] is empty.
  final String emptyText;

  const AppTagFilterBar({
    required this.tags,
    required this.selectedTags,
    required this.onTagToggle,
    this.onMoreTap,
    this.label = '按标签筛选：',
    this.maxVisibleTags = 5,
    this.showCounts = true,
    this.horizontalScroll = false,
    this.emptyText = '暂无标签',
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appColors;

    final visibleTags = tags.take(maxVisibleTags).toList();
    final hasMore = tags.length > maxVisibleTags;
    final isEmpty = tags.isEmpty;

    return Row(
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: AppFontTokens.bold,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: isEmpty
              ? Text(
                  emptyText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.textTertiary,
                  ),
                )
              : horizontalScroll
                  ? _horizontalLayout(context, visibleTags, hasMore)
                  : _wrapLayout(context, visibleTags, hasMore),
        ),
      ],
    );
  }

  Widget _horizontalLayout(
    BuildContext context,
    List<AppTagStat> visibleTags,
    bool hasMore,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...visibleTags.map(_buildChip),
          if (hasMore && onMoreTap != null) ...[
            const SizedBox(width: AppSpacing.sm),
            AppMoreTagsButton(onTap: onMoreTap!),
          ],
        ],
      ),
    );
  }

  Widget _wrapLayout(
    BuildContext context,
    List<AppTagStat> visibleTags,
    bool hasMore,
  ) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: [
        ...visibleTags.map(_buildChip),
        if (hasMore && onMoreTap != null)
          AppMoreTagsButton(onTap: onMoreTap!),
      ],
    );
  }

  Widget _buildChip(AppTagStat tag) {
    return AppTagChip(
      label: tag.name,
      count: showCounts ? tag.count : null,
      selected: selectedTags.contains(tag.name),
      onTap: () => onTagToggle(tag.name),
    );
  }
}
