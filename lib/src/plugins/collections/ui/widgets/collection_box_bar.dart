import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uni_hub/src/core/theme/app_tokens.dart';
import 'package:uni_hub/src/plugins/collections/providers/collections_providers.dart';

/// A box filter bar with label "Box", multi-select [FilterChip]s for each
/// available collection box, and an ActionChip to create a new box.
///
/// When no boxes exist, shows an empty-state message. Selection is stored in
/// [selectedCollectionBoxIdsProvider]; empty selection means "show all items".
class CollectionBoxBar extends ConsumerWidget {
  const CollectionBoxBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boxesAsync = ref.watch(collectionBoxesProvider);
    final selectedBoxIds = ref.watch(selectedCollectionBoxIdsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Box',
          style: theme.textTheme.titleSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        boxesAsync.when(
          data: (boxes) {
            if (boxes.isEmpty) {
              return Text(
                '暂无 Box，点击新建开始整理收藏。',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              );
            }
            return Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final box in boxes)
                  FilterChip(
                    label: Text(box.name),
                    selected: selectedBoxIds.contains(box.id),
                    onSelected: (selected) {
                      final next = Set<int>.from(selectedBoxIds);
                      if (selected) {
                        next.add(box.id);
                      } else {
                        next.remove(box.id);
                      }
                      ref
                          .read(selectedCollectionBoxIdsProvider.notifier)
                          .state = next;
                    },
                    visualDensity: VisualDensity.compact,
                  ),
                ActionChip(
                  label: const Text('+ 新建 Box'),
                  onPressed: () =>
                      _showCreateBoxDialog(context, ref),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            );
          },
          loading: () => const LinearProgressIndicator(minHeight: 2),
          error: (e, _) => Text(
            '加载失败：$e',
            style: TextStyle(color: colorScheme.error),
          ),
        ),
      ],
    );
  }

  Future<void> _showCreateBoxDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('新建 Box'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '名称'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx, controller.text.trim());
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    await ref.read(collectionsRepositoryProvider).createBox(name);
    ref.invalidate(collectionBoxesProvider);
  }
}
