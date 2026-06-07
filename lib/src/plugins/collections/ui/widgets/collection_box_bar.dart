import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uni_hub/src/core/theme/app_tokens.dart';
import 'package:uni_hub/src/plugins/collections/providers/collections_providers.dart';
import 'package:uni_hub/src/plugins/collections/ui/widgets/create_collection_folder_dialog.dart';
import 'package:uni_hub/src/shared/crud/crud.dart';

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
              Icon(
                Icons.folder_outlined,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
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
                  ref.read(selectedCollectionBoxIdsProvider.notifier).state =
                      next;
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
        style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.error),
      ),
    );
  }

  Future<void> _showCreateBoxDialog(BuildContext context, WidgetRef ref) async {
    final boxes = ref.read(collectionBoxesProvider).valueOrNull ?? const [];
    final name = await showDialog<String>(
      context: context,
      builder: (_) => CreateCollectionFolderDialog(
        existingNames: boxes.map((box) => box.name),
      ),
    );
    if (name == null || name.isEmpty) return;

    // Wait until the dialog route and all its associated animations (e.g.
    // InputDecorator tickers) are fully torn down before touching providers.
    await WidgetsBinding.instance.endOfFrame;

    try {
      await ref.read(collectionsRepositoryProvider).createBox(name);
      ref.invalidate(collectionBoxesProvider);
      if (!context.mounted) return;
      ref
          .read(crudFeedbackCoordinatorProvider)
          .handle(context, CrudResult<void>.success(message: '已创建收藏夹「$name」'));
    } on ArgumentError catch (error) {
      if (!context.mounted) return;
      ref
          .read(crudFeedbackCoordinatorProvider)
          .handle(
            context,
            CrudResult<void>.failure(
              failure: AppFailure(
                code: AppFailureCode.validation,
                message: error.message.toString(),
                field: 'name',
                cause: error,
              ),
            ),
          );
    } on StateError catch (error) {
      if (!context.mounted) return;
      ref
          .read(crudFeedbackCoordinatorProvider)
          .handle(
            context,
            CrudResult<void>.failure(
              failure: AppFailure(
                code: AppFailureCode.duplicate,
                message: error.message,
                field: 'name',
                cause: error,
              ),
            ),
          );
    }
  }
}
