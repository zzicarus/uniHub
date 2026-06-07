import 'package:flutter/material.dart';
import 'package:uni_hub/src/core/theme/app_tokens.dart';

/// Shared template widget for empty and error states in the Thoughts plugin.
///
/// Provides a consistent centered layout with icon, title, subtitle, and
/// optional action button. All values use [Theme.of]'s [ColorScheme] for
/// M3 compliance — no hardcoded [AppColors] constants.
///
/// Pre-configured variants are available as named factory constructors
/// (empty states) and static methods (error states).
class ThoughtStateTemplate extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const ThoughtStateTemplate({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 54, color: colorScheme.outline),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              FilledButton.tonalIcon(
                onPressed: onAction,
                icon: const Icon(Icons.add, size: 18),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Empty state factory constructors
  // ---------------------------------------------------------------------------

  /// Empty state: no thoughts recorded yet.
  ///
  /// Title: "还没有想法"
  /// Subtitle: "记录第一个念头..."
  /// Action: "记录想法" (only when [onRecord] is provided)
  factory ThoughtStateTemplate.noThoughts({VoidCallback? onRecord}) {
    return ThoughtStateTemplate(
      icon: Icons.lightbulb_outline,
      title: '还没有想法',
      subtitle: '记录第一个念头...',
      actionLabel: onRecord != null ? '记录想法' : null,
      onAction: onRecord,
    );
  }

  /// Empty state: no results for the given tag filter.
  ///
  /// Title: "没有找到带有 #xxx 的想法"
  /// Subtitle: non-empty hint
  /// Action: "清除筛选" (only when [onClearFilter] is provided)
  factory ThoughtStateTemplate.filterNoResults(
    String tagName, {
    VoidCallback? onClearFilter,
  }) {
    return ThoughtStateTemplate(
      icon: Icons.filter_alt_outlined,
      title: '没有找到带有 #$tagName 的想法',
      subtitle: '试试其他标签或清除筛选条件',
      actionLabel: onClearFilter != null ? '清除筛选' : null,
      onAction: onClearFilter,
    );
  }

  /// Empty state: no search results for the given query.
  ///
  /// Title: "没有找到相关想法"
  /// Subtitle: non-empty hint
  /// Action: "清除搜索" (only when [onClearSearch] is provided)
  factory ThoughtStateTemplate.searchNoResults(
    String query, {
    VoidCallback? onClearSearch,
  }) {
    return ThoughtStateTemplate(
      icon: Icons.search_off_outlined,
      title: '没有找到相关想法',
      subtitle: '试试其他关键词或清除搜索条件',
      actionLabel: onClearSearch != null ? '清除搜索' : null,
      onAction: onClearSearch,
    );
  }

  /// Empty state: archive is empty.
  ///
  /// Title: "暂无归档想法"
  /// Subtitle: "归档后的想法会显示在这里"
  /// No action button.
  factory ThoughtStateTemplate.archiveEmpty() {
    return const ThoughtStateTemplate(
      icon: Icons.archive_outlined,
      title: '暂无归档想法',
      subtitle: '归档后的想法会显示在这里',
    );
  }

  // ---------------------------------------------------------------------------
  // Error state static helpers
  // ---------------------------------------------------------------------------

  /// Save failed: "保存失败，请稍后重试"
  static ThoughtStateTemplate saveError({VoidCallback? onRetry}) {
    return ThoughtStateTemplate(
      icon: Icons.error_outline,
      title: '保存失败',
      subtitle: '请稍后重试',
      actionLabel: onRetry != null ? '重试' : null,
      onAction: onRetry,
    );
  }

  /// Image add failed: "图片添加失败，请检查文件权限"
  static ThoughtStateTemplate imageError({VoidCallback? onRetry}) {
    return ThoughtStateTemplate(
      icon: Icons.image_not_supported_outlined,
      title: '图片添加失败',
      subtitle: '请检查文件权限',
      actionLabel: onRetry != null ? '重试' : null,
      onAction: onRetry,
    );
  }

  /// Delete failed: "删除失败，请稍后重试"
  static ThoughtStateTemplate deleteError({VoidCallback? onRetry}) {
    return ThoughtStateTemplate(
      icon: Icons.delete_outline,
      title: '删除失败',
      subtitle: '请稍后重试',
      actionLabel: onRetry != null ? '重试' : null,
      onAction: onRetry,
    );
  }

  /// Archive failed: "归档失败，请稍后重试"
  static ThoughtStateTemplate archiveError({VoidCallback? onRetry}) {
    return ThoughtStateTemplate(
      icon: Icons.archive_outlined,
      title: '归档失败',
      subtitle: '请稍后重试',
      actionLabel: onRetry != null ? '重试' : null,
      onAction: onRetry,
    );
  }

  /// Restore from archive failed: "恢复失败，请稍后重试"
  static ThoughtStateTemplate restoreError({VoidCallback? onRetry}) {
    return ThoughtStateTemplate(
      icon: Icons.unarchive_outlined,
      title: '恢复失败',
      subtitle: '请稍后重试',
      actionLabel: onRetry != null ? '重试' : null,
      onAction: onRetry,
    );
  }

  /// Filter / data load failed: "加载失败，请重试" with retry button.
  static ThoughtStateTemplate filterError({VoidCallback? onRetry}) {
    return ThoughtStateTemplate(
      icon: Icons.cloud_off_outlined,
      title: '加载失败',
      subtitle: '请重试',
      actionLabel: '重试',
      onAction: onRetry,
    );
  }
}
