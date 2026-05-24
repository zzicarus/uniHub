import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uni_hub/src/core/theme/app_tokens.dart';
import 'package:uni_hub/src/plugins/collections/domain/collection_models.dart';
import 'package:uni_hub/src/plugins/collections/domain/consumption_status.dart';
import 'package:uni_hub/src/plugins/collections/domain/media_type.dart';
import 'package:uni_hub/src/plugins/collections/domain/source_platform.dart';
import 'package:uni_hub/src/plugins/collections/providers/collections_providers.dart';

class CollectionFilterBar extends ConsumerWidget {
  const CollectionFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedView = ref.watch(collectionViewProvider);
    final selectedPlatform = ref.watch(collectionPlatformFilterProvider);
    final selectedMediaType = ref.watch(collectionMediaTypeFilterProvider);
    final selectedBoxIds = ref.watch(selectedCollectionBoxIdsProvider);
    final boxesAsync = ref.watch(collectionBoxesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final view in CollectionView.values)
              ChoiceChip(
                label: Text(view.label),
                selected: selectedView == view,
                onSelected: (_) {
                  ref.read(collectionViewProvider.notifier).state = view;
                },
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded),
                  hintText: '搜索标题、描述或 URL',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  ref.read(collectionSearchQueryProvider.notifier).state =
                      value;
                },
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            DropdownButton<SourcePlatform?>(
              value: selectedPlatform,
              hint: const Text('来源'),
              items: [
                const DropdownMenuItem(value: null, child: Text('全部来源')),
                for (final platform in SourcePlatform.values)
                  DropdownMenuItem(
                    value: platform,
                    child: Text(platform.label),
                  ),
              ],
              onChanged: (value) {
                ref.read(collectionPlatformFilterProvider.notifier).state =
                    value;
              },
            ),
            const SizedBox(width: AppSpacing.sm),
            DropdownButton<MediaType?>(
              value: selectedMediaType,
              hint: const Text('媒介'),
              items: [
                const DropdownMenuItem(value: null, child: Text('全部媒介')),
                for (final type in MediaType.values)
                  DropdownMenuItem(value: type, child: Text(type.label)),
              ],
              onChanged: (value) {
                ref.read(collectionMediaTypeFilterProvider.notifier).state =
                    value;
              },
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          children: [
            FilterChip(
              label: const Text('全部状态'),
              selected: ref.watch(collectionStatusFilterProvider) == null,
              onSelected: (_) {
                ref.read(collectionStatusFilterProvider.notifier).state = null;
              },
            ),
            for (final status in ConsumptionStatus.values)
              FilterChip(
                label: Text(status.label),
                selected: ref.watch(collectionStatusFilterProvider) == status,
                onSelected: (_) {
                  ref.read(collectionStatusFilterProvider.notifier).state =
                      status;
                },
              ),
          ],
        ),
        boxesAsync.when(
          data: (boxes) {
            if (boxes.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  FilterChip(
                    label: const Text('全部 Box'),
                    selected: selectedBoxIds.isEmpty,
                    onSelected: (_) {
                      ref
                              .read(selectedCollectionBoxIdsProvider.notifier)
                              .state =
                          const <int>{};
                    },
                  ),
                  for (final box in boxes)
                    FilterChip(
                      label: Text(box.name),
                      selected: selectedBoxIds.contains(box.id),
                      onSelected: (selected) {
                        final next = {...selectedBoxIds};
                        if (selected) {
                          next.add(box.id);
                        } else {
                          next.remove(box.id);
                        }
                        ref
                                .read(selectedCollectionBoxIdsProvider.notifier)
                                .state =
                            next;
                      },
                    ),
                ],
              ),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.only(top: AppSpacing.sm),
            child: LinearProgressIndicator(minHeight: 2),
          ),
          error: (error, stackTrace) => Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              'Box 加载失败：$error',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ),
      ],
    );
  }
}
