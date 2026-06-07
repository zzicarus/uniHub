import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:uni_hub/src/shared/widgets/tags/app_selected_tags_bar.dart';
import '../../providers/thoughts_providers.dart';

/// Selected-tags bar for the thoughts list page.
///
/// Acts as an adapter between thoughts-specific providers and the shared
/// [AppSelectedTagsBar]. Exposed public name is preserved for callers.
class ThoughtSelectedTagsBar extends ConsumerWidget {
  const ThoughtSelectedTagsBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTags = ref.watch(selectedTagFiltersProvider);

    return AppSelectedTagsBar(
      selectedTags: selectedTags,
      onRemove: (tag) {
        final current = ref.read(selectedTagFiltersProvider);
        ref.read(selectedTagFiltersProvider.notifier).state =
            removeTagFromFilter(current, tag);
      },
      onClear: () {
        ref.read(selectedTagFiltersProvider.notifier).state =
            const <String>{};
      },
    );
  }
}
