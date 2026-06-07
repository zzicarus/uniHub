import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uni_hub/src/plugins/thoughts/providers/thoughts_providers.dart';
import 'package:uni_hub/src/shared/tags/tag_models.dart';
import 'package:uni_hub/src/shared/widgets/tags/app_common_tags_panel.dart';

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
      tags: tagStats,
      selectedTags: selectedTags,
      onTagToggle: (tag) {
        final current = ref.read(selectedTagFiltersProvider);
        ref.read(selectedTagFiltersProvider.notifier).state =
            toggleTagInFilter(current, tag);
      },
    );
  }
}
