import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uni_hub/src/core/theme/app_tokens.dart';
import 'package:uni_hub/src/plugins/collections/domain/collection_models.dart';
import 'package:uni_hub/src/plugins/collections/providers/collections_providers.dart';

/// A horizontal row of [ChoiceChip] widgets for selecting the current
/// [CollectionView] (Inbox, 全部, 未看, 进行中, 已看, 归档).
///
/// Reads from [collectionViewProvider] and writes back to the same provider
/// on selection. Does NOT touch [collectionStatusFilterProvider].
class CollectionViewChips extends ConsumerWidget {
  const CollectionViewChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedView = ref.watch(collectionViewProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: CollectionView.values.map((view) {
          final isSelected = selectedView == view;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: ChoiceChip(
              label: Text(view.label),
              selected: isSelected,
              onSelected: (_) {
                ref.read(collectionViewProvider.notifier).state = view;
              },
              selectedColor: colorScheme.primary,
              backgroundColor: colorScheme.surfaceContainerLow,
              labelStyle: TextStyle(
                color: isSelected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurface,
              ),
              visualDensity: VisualDensity.compact,
            ),
          );
        }).toList(),
      ),
    );
  }
}
