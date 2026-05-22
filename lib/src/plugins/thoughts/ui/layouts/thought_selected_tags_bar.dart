import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:uni_hub/src/core/theme/app_tokens.dart';
import '../../providers/thoughts_providers.dart';

class ThoughtSelectedTagsBar extends ConsumerWidget {
  const ThoughtSelectedTagsBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTags = ref.watch(selectedTagFiltersProvider).toList()..sort();
    if (selectedTags.isEmpty) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            '已选标签：',
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: selectedTags.map((tag) {
                return InputChip(
                  label: Text('#$tag'),
                  onDeleted: () {
                    final current = ref.read(selectedTagFiltersProvider);
                    ref.read(selectedTagFiltersProvider.notifier).state =
                        removeTagFromFilter(current, tag);
                  },
                  deleteIcon: const Icon(Icons.close_rounded, size: 16),
                  backgroundColor: AppColors.primarySoft,
                  side: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.15),
                  ),
                  labelStyle: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                );
              }).toList(),
            ),
          ),
          TextButton.icon(
            onPressed: () {
              ref.read(selectedTagFiltersProvider.notifier).state =
                  const <String>{};
            },
            icon: const Icon(Icons.close_rounded, size: 16),
            label: const Text('清除筛选'),
          ),
        ],
      ),
    );
  }
}
