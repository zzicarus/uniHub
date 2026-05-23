import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uni_hub/src/shared/tags/tag_models.dart';
import 'package:uni_hub/src/shared/widgets/tags/app_common_tags_panel.dart';
import 'package:uni_hub/src/plugins/thoughts/providers/thoughts_providers.dart';

class ThoughtCommonTagsPanel extends ConsumerWidget {
  const ThoughtCommonTagsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commonTags = ref.watch(commonTagsProvider).take(8).toList();
    final selectedTags = ref.watch(selectedTagFiltersProvider);

    final tagStats = commonTags
        .map((e) => AppTagStat(name: e.key, count: e.value))
        .toList();

    return AppCommonTagsPanel(
      title: '常用标签',
      helperText: '点击筛选',
      icon: Icons.sell_outlined,
      tags: tagStats,
      selectedTags: selectedTags,
      maxVisibleTags: 8,
      emptyText: '暂无标签',
      onTagToggle: (tag) {
        final current = ref.read(selectedTagFiltersProvider);
        ref.read(selectedTagFiltersProvider.notifier).state =
            toggleTagInFilter(current, tag);
      },
    );
  }
}
