import 'package:flutter/material.dart';
import 'package:uni_hub/src/core/theme/app_theme_tokens.dart';
import 'package:uni_hub/src/core/theme/app_tokens.dart';
import 'package:uni_hub/src/shared/tags/tag_models.dart';
import 'package:uni_hub/src/shared/widgets/app_panel.dart';
import 'package:uni_hub/src/shared/widgets/tags/app_tag_chip.dart';

/// A reusable panel for frequently used tags.
///
/// Keeps tag rendering independent from feature-specific providers so plugins
/// can reuse the same TagKit surface for filtering.
class AppCommonTagsPanel extends StatelessWidget {
  /// Panel title shown next to [icon].
  final String title;

  /// Helper text shown on the right side of the header.
  final String helperText;

  /// Decorative icon shown before [title].
  final IconData icon;

  /// Tag statistics to render.
  final List<AppTagStat> tags;

  /// Tag names currently selected by the host feature.
  final Set<String> selectedTags;

  /// Called when the user toggles a tag chip.
  final ValueChanged<String> onTagToggle;

  /// Maximum number of tags displayed in this panel.
  final int maxVisibleTags;

  /// Text shown when [tags] is empty.
  final String emptyText;

  /// Optional padding forwarded to the outer [AppPanel].
  final EdgeInsetsGeometry? padding;

  const AppCommonTagsPanel({
    required this.tags,
    required this.selectedTags,
    required this.onTagToggle,
    this.title = '常用标签',
    this.helperText = '点击筛选',
    this.icon = Icons.sell_outlined,
    this.maxVisibleTags = 8,
    this.emptyText = '暂无标签',
    this.padding,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final theme = Theme.of(context);
    final visibleTags = maxVisibleTags <= 0
        ? const <AppTagStat>[]
        : tags.take(maxVisibleTags);

    return AppPanel(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              ExcludeSemantics(
                child: Icon(
                  icon,
                  color: appColors.primary,
                  size: AppSpacing.lg,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: appColors.textPrimary,
                    fontWeight: AppFontTokens.extraBold,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  helperText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: appColors.textTertiary,
                    fontWeight: AppFontTokens.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (tags.isEmpty)
            Text(
              emptyText,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: appColors.textTertiary,
              ),
            )
          else
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final tag in visibleTags)
                  AppTagChip(
                    label: tag.name,
                    count: tag.count,
                    selected: selectedTags.contains(tag.name),
                    onTap: () => onTagToggle(tag.name),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
