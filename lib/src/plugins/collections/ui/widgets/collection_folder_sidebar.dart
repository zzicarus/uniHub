import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uni_hub/src/core/theme/app_tokens.dart';
import 'package:uni_hub/src/plugins/collections/domain/collection_models.dart';
import 'package:uni_hub/src/plugins/collections/providers/collections_providers.dart';

class CollectionFolderSidebar extends ConsumerWidget {
  const CollectionFolderSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final boxesAsync = ref.watch(collectionBoxesProvider);
    final selectedBoxIds = ref.watch(selectedCollectionBoxIdsProvider);
    final selectedView = ref.watch(collectionViewProvider);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: const [AppShadows.cardSoft],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '收藏夹',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: '新建收藏夹',
                  onPressed: () => _showCreateFolderDialog(context, ref),
                  icon: const Icon(Icons.add_rounded),
                ),
                IconButton(
                  tooltip: '搜索收藏夹',
                  onPressed: () => _showComingSoon(context, '收藏夹搜索稍后接入'),
                  icon: const Icon(Icons.search_rounded),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            _FolderRow(
              icon: Icons.bookmark_border_rounded,
              label: '全部收藏',
              selected:
                  selectedBoxIds.isEmpty && selectedView == CollectionView.all,
              onTap: () {
                ref.read(selectedCollectionBoxIdsProvider.notifier).state =
                    const <int>{};
                ref.read(collectionViewProvider.notifier).state =
                    CollectionView.all;
              },
            ),
            _FolderRow(
              icon: Icons.inbox_outlined,
              label: '待整理',
              selected:
                  selectedBoxIds.isEmpty &&
                  selectedView == CollectionView.inbox,
              onTap: () {
                ref.read(selectedCollectionBoxIdsProvider.notifier).state =
                    const <int>{};
                ref.read(collectionViewProvider.notifier).state =
                    CollectionView.inbox;
              },
            ),
            _FolderRow(
              icon: Icons.schedule_rounded,
              label: '稍后阅读',
              selected:
                  selectedBoxIds.isEmpty &&
                  selectedView == CollectionView.unread,
              onTap: () {
                ref.read(selectedCollectionBoxIdsProvider.notifier).state =
                    const <int>{};
                ref.read(collectionViewProvider.notifier).state =
                    CollectionView.unread;
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            Divider(color: colorScheme.outlineVariant),
            const SizedBox(height: AppSpacing.xs),
            Expanded(
              child: boxesAsync.when(
                data: (boxes) => boxes.isEmpty
                    ? _EmptyFolders(
                        onCreate: () {
                          _showCreateFolderDialog(context, ref);
                        },
                      )
                    : ListView.separated(
                        itemCount: boxes.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: AppSpacing.xxs),
                        itemBuilder: (context, index) {
                          final box = boxes[index];
                          return _FolderRow(
                            icon: Icons.folder_outlined,
                            label: box.name,
                            selected:
                                selectedBoxIds.length == 1 &&
                                selectedBoxIds.contains(box.id),
                            onTap: () {
                              ref
                                  .read(
                                    selectedCollectionBoxIdsProvider.notifier,
                                  )
                                  .state = {
                                box.id,
                              };
                              ref.read(collectionViewProvider.notifier).state =
                                  CollectionView.all;
                            },
                          );
                        },
                      ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => _FolderError(
                  error: error,
                  onRetry: () => ref.invalidate(collectionBoxesProvider),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () => _showCreateFolderDialog(context, ref),
                icon: const Icon(Icons.add_rounded),
                label: const Text('新建收藏夹'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCreateFolderDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('新建收藏夹'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '收藏夹名称'),
          textInputAction: TextInputAction.done,
          onSubmitted: (value) => Navigator.pop(dialogContext, value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext, controller.text.trim());
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (name == null || name.isEmpty) return;

    try {
      await ref.read(collectionsRepositoryProvider).createBox(name);
      ref.invalidate(collectionBoxesProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('已创建收藏夹「$name」')));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('创建收藏夹失败：$error')));
    }
  }

  void _showComingSoon(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _FolderRow extends StatelessWidget {
  const _FolderRow({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final borderRadius = BorderRadius.circular(AppRadius.sm);

    return Material(
      color: selected
          ? colorScheme.primaryContainer.withValues(alpha: 0.45)
          : colorScheme.surface,
      borderRadius: borderRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: selected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: selected
                        ? colorScheme.primary
                        : colorScheme.onSurface,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyFolders extends StatelessWidget {
  const _EmptyFolders({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.folder_open_rounded,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '暂无自定义收藏夹',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            TextButton(onPressed: onCreate, child: const Text('创建一个')),
          ],
        ),
      ),
    );
  }
}

class _FolderError extends StatelessWidget {
  const _FolderError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, color: colorScheme.error),
            const SizedBox(height: AppSpacing.xs),
            Text('收藏夹加载失败', style: TextStyle(color: colorScheme.error)),
            const SizedBox(height: AppSpacing.xs),
            TextButton(onPressed: onRetry, child: const Text('重试')),
          ],
        ),
      ),
    );
  }
}
