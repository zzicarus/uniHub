import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uni_hub/src/core/theme/app_tokens.dart';

import '../../providers/thoughts_providers.dart';
import '../layouts/thoughts_shared_widgets.dart';

class ThoughtStatsPanel extends ConsumerWidget {
  const ThoughtStatsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allThoughts = ref.watch(allThoughtsProvider).valueOrNull ?? const [];
    final visibleCount = ref.watch(thoughtsCountProvider);
    final active = allThoughts
        .where((thought) => thought.archivedAt == null)
        .toList();
    final pinned = active.where((thought) => thought.isPinned).length;

    return ThoughtPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ThoughtPanelHeader(
            title: '想法统计',
            icon: Icons.bar_chart_rounded,
          ),
          const SizedBox(height: AppSpacing.md),
          ThoughtStatRow(
            icon: Icons.lightbulb_outline,
            label: '总想法',
            value: active.length.toString(),
            color: AppColors.primary,
            background: AppColors.primarySoft,
          ),
          ThoughtStatRow(
            icon: Icons.add_circle_outline_rounded,
            label: '本页展示',
            value: visibleCount.toString(),
            color: AppColors.secondary,
            background: AppColors.greenSoft,
          ),
          ThoughtStatRow(
            icon: Icons.star_border_rounded,
            label: '置顶数量',
            value: pinned.toString(),
            color: AppColors.purple,
            background: AppColors.purpleSoft,
          ),
        ],
      ),
    );
  }
}

class ThoughtHotTagsPanel extends ConsumerWidget {
  const ThoughtHotTagsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tags = ref.watch(commonTagsProvider);
    final top = tags.isEmpty ? null : tags.first;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ThoughtPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ThoughtPanelHeader(title: '热门标签', icon: Icons.sell_outlined),
          const SizedBox(height: AppSpacing.md),
          if (top == null)
            const ThoughtSmallMutedText('暂无热门标签')
          else ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    '#${top.key} 在本页最活跃',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  '${top.value} 条',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.full),
              child: LinearProgressIndicator(
                value: 1,
                minHeight: 7,
                backgroundColor: colorScheme.surfaceContainerHigh,
                color: AppColors.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
