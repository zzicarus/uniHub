import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uni_hub/src/core/database/app_database.dart';
import 'package:uni_hub/src/core/theme/app_tokens.dart';
import 'package:uni_hub/src/plugins/collections/domain/collection_folder_counts.dart';
import 'package:uni_hub/src/plugins/collections/domain/collection_models.dart';
import 'package:uni_hub/src/plugins/collections/providers/collections_providers.dart';
import 'package:uni_hub/src/plugins/collections/ui/widgets/create_collection_folder_dialog.dart';

/// Sidebar listing default views and custom collection folders.
///
/// Fully scrollable (ListView) so it never overflows regardless of
/// window height, text scale, or system zoom.
class CollectionFolderSidebar extends ConsumerWidget {
  const CollectionFolderSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final boxesAsync = ref.watch(collectionBoxesProvider);
    final countsAsync = ref.watch(collectionFolderCountsProvider);
    final counts = countsAsync.asData?.value;
    final selectedBoxIds = ref.watch(selectedCollectionBoxIdsProvider);
    final selectedView = ref.watch(collectionViewProvider);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: const [AppShadows.cardSoft],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.sm),
          children: [
            // ---- Header row ----
            Row(
              children: [
                Expanded(
                  child: Text(
                    '收藏夹',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: AppFontTokens.bold,
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

            // ---- Default views ----
            _FolderRow(
              icon: Icons.bookmark_border_rounded,
              label: '全部收藏',
              count: counts?.all,
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
              count: counts?.inbox,
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
              count: counts?.unread,
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
            Divider(color: colorScheme.outlineVariant, height: 1),
            const SizedBox(height: AppSpacing.xs),

            // ---- Custom folders ----
            ..._buildFolderContent(
              context,
              ref,
              boxesAsync,
              selectedBoxIds,
              colorScheme,
              counts,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFolderContent(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<CollectionBoxesTableData>> boxesAsync,
    Set<int> selectedBoxIds,
    ColorScheme colorScheme,
    CollectionFolderCounts? counts,
  ) {
    return boxesAsync.when(
      data: (boxes) {
        if (boxes.isEmpty) {
          return [
            _EmptyFolders(
              onCreate: () => _showCreateFolderDialog(context, ref),
            ),
          ];
        }
        return [
          for (final box in boxes)
            _FolderRow(
              icon: Icons.folder_outlined,
              label: box.name,
              count: counts?.boxCount(box.id),
              selected:
                  selectedBoxIds.length == 1 && selectedBoxIds.contains(box.id),
              onTap: () {
                ref.read(selectedCollectionBoxIdsProvider.notifier).state = {
                  box.id,
                };
                ref.read(collectionViewProvider.notifier).state =
                    CollectionView.all;
              },
            ),
        ];
      },
      loading: () => [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: LinearProgressIndicator(minHeight: 2),
        ),
      ],
      error: (error, stackTrace) => [
        _FolderError(
          error: error,
          onRetry: () => ref.invalidate(collectionBoxesProvider),
        ),
      ],
    );
  }

  Future<void> _showCreateFolderDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const CreateCollectionFolderDialog(),
    );

    if (name == null || name.isEmpty) return;

    // Wait until the dialog route and all its associated animations (e.g.
    // InputDecorator tickers) are fully torn down before touching providers.
    await WidgetsBinding.instance.endOfFrame;

    try {
      await ref.read(collectionsRepositoryProvider).createBox(name);
      ref.invalidate(collectionBoxesProvider);
      ref.invalidate(collectionFolderCountsProvider);
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
    this.count,
  });

  final IconData icon;
  final String label;
  final int? count;
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
                    fontWeight: selected ? AppFontTokens.bold : AppFontTokens.medium,
                  ),
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '$count',
                  maxLines: 1,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: selected
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.folder_open_rounded,
            size: 32,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '暂无自定义收藏夹',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          TextButton(onPressed: onCreate, child: const Text('创建一个')),
        ],
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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 16, color: colorScheme.error),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  '收藏夹加载失败',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colorScheme.error),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          TextButton(onPressed: onRetry, child: const Text('重试')),
        ],
      ),
    );
  }
}
