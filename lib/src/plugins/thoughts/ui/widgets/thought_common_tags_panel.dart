import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uni_hub/src/core/theme/app_tokens.dart';
import 'package:uni_hub/src/plugins/thoughts/providers/thoughts_providers.dart';
import 'package:uni_hub/src/plugins/thoughts/ui/layouts/thoughts_shared_widgets.dart';

class ThoughtCommonTagsPanel extends ConsumerWidget {
  const ThoughtCommonTagsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commonTags = ref.watch(commonTagsProvider).take(6).toList();
    final selectedTags = ref.watch(selectedTagFiltersProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ThoughtPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: ThoughtPanelHeader(
                  title: '常用标签',
                  icon: Icons.sell_outlined,
                ),
              ),
              Text(
                '点击筛选',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (commonTags.isEmpty)
            const ThoughtSmallMutedText('暂无标签')
          else
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: commonTags.map((entry) {
                final isSelected = selectedTags.contains(entry.key);
                return FilterChip(
                  label: Text('#${entry.key}   ${entry.value}'),
                  selected: isSelected,
                  onSelected: (_) {
                    final current = ref.read(selectedTagFiltersProvider);
                    ref.read(selectedTagFiltersProvider.notifier).state =
                        toggleTagInFilter(current, entry.key);
                  },
                  selectedColor: AppColors.primarySoft,
                  checkmarkColor: AppColors.primary,
                  side: BorderSide(
                    color: isSelected
                        ? AppColors.primary
                        : colorScheme.outlineVariant,
                  ),
                  labelStyle: theme.textTheme.labelMedium?.copyWith(
                    color: isSelected
                        ? AppColors.primary
                        : colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
