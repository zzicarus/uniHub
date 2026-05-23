import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:uni_hub/src/shared/tags/tag_models.dart';
import 'package:uni_hub/src/shared/widgets/tags/app_more_tags_popover.dart';
import 'package:uni_hub/src/shared/widgets/tags/app_tag_filter_bar.dart';
import '../../providers/thoughts_providers.dart';

/// Tag filter section for the thoughts list page.
///
/// Acts as an adapter between thoughts-specific providers and the shared
/// tag widget system. Exposed public name is preserved for callers.
class ThoughtTagFilterBar extends ConsumerWidget {
  const ThoughtTagFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commonTags = ref.watch(commonTagsProvider);
    final selectedTags = ref.watch(selectedTagFiltersProvider);

    final tagStats = commonTags
        .map((e) => AppTagStat(name: e.key, count: e.value))
        .toList();

    return AppTagFilterBar(
      tags: tagStats,
      selectedTags: selectedTags,
      onTagToggle: (tag) {
        final current = ref.read(selectedTagFiltersProvider);
        ref.read(selectedTagFiltersProvider.notifier).state =
            toggleTagInFilter(current, tag);
      },
      onMoreTap: () => _showMoreTagsPopover(context, ref, tagStats, selectedTags),
    );
  }

  Future<void> _showMoreTagsPopover(
    BuildContext context,
    WidgetRef ref,
    List<AppTagStat> tagStats,
    Set<String> selectedTags,
  ) {
    return showAppMoreTagsPopover(
      context: context,
      tags: tagStats,
      selectedTags: selectedTags,
      onTagToggle: (tag) {
        final current = ref.read(selectedTagFiltersProvider);
        ref.read(selectedTagFiltersProvider.notifier).state =
            toggleTagInFilter(current, tag);
      },
      onClear: () {
        ref.read(selectedTagFiltersProvider.notifier).state =
            const <String>{};
      },
    );
  }
}
