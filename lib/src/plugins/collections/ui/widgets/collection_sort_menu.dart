import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uni_hub/src/core/theme/app_tokens.dart';
import 'package:uni_hub/src/plugins/collections/domain/saved_items_query.dart';
import 'package:uni_hub/src/plugins/collections/providers/collections_providers.dart';

/// Sort dropdown menu for the Collection Command Bar.
///
/// Displays the current sort label as a chip. Opens a [PopupMenuButton]
/// with checkmarks for each sort option.
class CollectionSortMenu extends ConsumerWidget {
  const CollectionSortMenu({super.key});

  static const _sortLabels = <SavedItemsSort, String>{
    SavedItemsSort.createdDesc: '最新收藏',
    SavedItemsSort.updatedDesc: '最近更新',
    SavedItemsSort.lastOpenedDesc: '最近打开',
    SavedItemsSort.titleAsc: '标题 A-Z',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSort = ref.watch(collectionSortProvider);
    final label = _sortLabels[currentSort] ?? '最新收藏';
    final colorScheme = Theme.of(context).colorScheme;

    return PopupMenuButton<SavedItemsSort>(
      onSelected: (sort) {
        ref.read(collectionSortProvider.notifier).state = sort;
      },
      initialValue: currentSort,
      itemBuilder: (context) => [
        for (final entry in _sortLabels.entries)
          PopupMenuItem<SavedItemsSort>(
            value: entry.key,
            child: Row(
              children: [
                Icon(
                  Icons.check_rounded,
                  size: 18,
                  color: entry.key == currentSort
                      ? colorScheme.primary
                      : Colors.transparent,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(entry.value),
              ],
            ),
          ),
      ],
      child: _SortChip(label: label, colorScheme: colorScheme),
    );
  }
}

class _SortChip extends StatelessWidget {
  const _SortChip({required this.label, required this.colorScheme});

  final String label;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.75)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '排序：$label',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              letterSpacing: 0,
              fontWeight: AppFontTokens.medium,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: AppSpacing.xxs),
          Icon(
            Icons.expand_more_rounded,
            size: 16,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
        ],
      ),
    );
  }
}
