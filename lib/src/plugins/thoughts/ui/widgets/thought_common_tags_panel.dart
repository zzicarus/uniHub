import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uni_hub/src/core/theme/app_tokens.dart';
import 'package:uni_hub/src/plugins/thoughts/providers/thoughts_providers.dart';
import 'package:uni_hub/src/plugins/thoughts/ui/layouts/thoughts_shared_widgets.dart';

/// Right rail panel showing top 8 tags sorted by frequency from unarchived thoughts.
/// Each tag is tappable to set [tagFilterProvider].
/// Syncs with main tag filter.
/// Data source: [commonTagsProvider] (global).
class ThoughtCommonTagsPanel extends ConsumerWidget {
  const ThoughtCommonTagsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commonTags = ref.watch(commonTagsProvider);
    final currentTagFilter = ref.watch(tagFilterProvider);

    return ThoughtPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ThoughtPanelHeader(
            title: '常用标签',
            icon: Icons.sell_outlined,
          ),
          const SizedBox(height: AppSpacing.md),
          if (commonTags.isEmpty)
            const ThoughtSmallMutedText('暂无标签')
          else
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: commonTags.map((entry) {
                final isSelected = currentTagFilter == entry.key;
                return ThoughtTagChip(
                  label: entry.key,
                  count: entry.value,
                  onTap: () {
                    ref.read(tagFilterProvider.notifier).state =
                        isSelected ? null : entry.key;
                  },
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
