import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uni_hub/src/core/theme/app_tokens.dart';
import 'package:uni_hub/src/shared/tags/tag_models.dart';
import 'package:uni_hub/src/shared/widgets/tags/app_tag_chip.dart';
import 'package:uni_hub/src/plugins/thoughts/providers/thoughts_providers.dart';
import 'package:uni_hub/src/plugins/thoughts/ui/layouts/thoughts_shared_widgets.dart';

class ThoughtCommonTagsPanel extends ConsumerWidget {
  const ThoughtCommonTagsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commonTags = ref.watch(commonTagsProvider).take(8).toList();
    final selectedTags = ref.watch(selectedTagFiltersProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final tagStats = commonTags
        .map((e) => AppTagStat(name: e.key, count: e.value))
        .toList();

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
          if (tagStats.isEmpty)
            const ThoughtSmallMutedText('暂无标签')
          else
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: tagStats.map((tag) {
                return AppTagChip(
                  label: tag.name,
                  count: tag.count,
                  selected: selectedTags.contains(tag.name),
                  onTap: () {
                    final current = ref.read(selectedTagFiltersProvider);
                    ref.read(selectedTagFiltersProvider.notifier).state =
                        toggleTagInFilter(current, tag.name);
                  },
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
