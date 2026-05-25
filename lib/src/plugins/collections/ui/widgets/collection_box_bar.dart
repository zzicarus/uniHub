import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uni_hub/src/core/theme/app_tokens.dart';
import 'package:uni_hub/src/plugins/collections/providers/collections_providers.dart';

/// A box filter bar with label "Box", multi-select [FilterChip]s for each
/// available collection box, and an ActionChip to create a new box.
///
/// When no boxes exist, shows a compact single-line empty-state hint.
/// The "+ 新建 Box" action is always visible.
class CollectionBoxBar extends ConsumerWidget {
  const CollectionBoxBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boxesAsync = ref.watch(collectionBoxesProvider);
    final selectedBoxIds = ref.watch(selectedCollectionBoxIdsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return boxesAsync.when(
      data: (boxes) {
        if (boxes.isEmpty) {
          return Row(
            children: [
              Icon(Icons.folder_outlined, size: 16, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: AppSpacing.xxs),
              Text(
                '收藏夹：暂无收藏夹，点击新建开始整理收藏。',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _showCreateBoxDialog(context, ref),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('新建收藏夹'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: colorScheme.primary,
                ),
              ),
            ],
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
              label: const Text('+ 新建收藏夹'),
              onPressed: () => _showCreateBoxDialog(context, ref),
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
        title: const Text('新建收藏夹'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '收藏夹名称'),
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
    // Defer invalidation to next frame so the dialog's elements
    // (e.g. InputDecorator with active tickers) are fully deactivated.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(collectionBoxesProvider);
    });
  }
}
