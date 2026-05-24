import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uni_hub/src/core/database/app_database.dart';
import 'package:uni_hub/src/core/theme/app_tokens.dart';
import 'package:uni_hub/src/plugins/collections/providers/collections_providers.dart';

import '../widgets/collection_box_bar.dart';
import '../widgets/collection_bulk_action_bar.dart';
import '../widgets/collection_capture_bar.dart';
import '../widgets/collection_search_filter_bar.dart';
import '../widgets/collection_view_chips.dart';
import '../widgets/saved_item_card.dart';
import '../widgets/saved_item_detail_panel.dart';

class CollectionsDesktopLayout extends ConsumerStatefulWidget {
  const CollectionsDesktopLayout({super.key});

  @override
  ConsumerState<CollectionsDesktopLayout> createState() =>
      _CollectionsDesktopLayoutState();
}

class _CollectionsDesktopLayoutState
    extends ConsumerState<CollectionsDesktopLayout> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoSelectFirstItem();
    });
  }

  void _autoSelectFirstItem() {
    final itemsAsync = ref.read(savedItemsListProvider);
    final currentSelectedId = ref.read(selectedSavedItemIdProvider);

    if (currentSelectedId != null) return;

    itemsAsync.whenData((items) {
      if (items.isNotEmpty && mounted) {
        ref.read(selectedSavedItemIdProvider.notifier).state = items.first.id;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(savedItemsListProvider);
    final selectedId = ref.watch(selectedSavedItemIdProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Compute display item from async data synchronously
    final items = itemsAsync.asData?.value ?? <SavedItemsTableData>[];
    SavedItemsTableData? displayItem;
    if (selectedId != null) {
      displayItem = items.where(
        (item) => item.id == selectedId,
      ).firstOrNull;
    }
    displayItem ??= items.isNotEmpty ? items.first : null;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('收藏', style: theme.textTheme.headlineMedium),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '保存链接、稍后阅读，并按状态与来源快速筛选。',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(savedItemsListProvider),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('刷新'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            // Capture bar
            const CollectionCaptureBar(),
            const SizedBox(height: AppSpacing.sm),
            // View chips
            const CollectionViewChips(),
            const SizedBox(height: AppSpacing.xs),
            // Box bar
            const CollectionBoxBar(),
            const SizedBox(height: AppSpacing.xs),
            // Search / filter bar
            const CollectionSearchFilterBar(),
            const SizedBox(height: AppSpacing.sm),
            // Split pane: list + detail
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left panel - item list + bulk action bar
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: itemsAsync.when(
                            data: (items) {
                              if (items.isEmpty) {
                                return const _EmptyState();
                              }
                              return ListView.separated(
                                itemCount: items.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: AppSpacing.sm),
                                itemBuilder: (context, index) {
                                  final item = items[index];
                                  final isSelected = item.id == selectedId;
                                  return SavedItemCard(
                                    item: item,
                                    selected: isSelected,
                                    onTap: () {
                                      ref
                                          .read(
                                            selectedSavedItemIdProvider
                                                .notifier,
                                          )
                                          .state = item.id;
                                    },
                                  );
                                },
                              );
                            },
                            loading: () => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            error: (error, stackTrace) => _ErrorState(
                              error: error,
                              onRetry: () =>
                                  ref.invalidate(savedItemsListProvider),
                            ),
                          ),
                        ),
                        const CollectionBulkActionBar(),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  // Right panel - detail
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final detailWidth = (constraints.maxWidth * 0.36)
                          .clamp(420.0, 540.0);
                      return SizedBox(
                        width: detailWidth,
                        child: SavedItemDetailPanel(item: displayItem),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bookmark_add_outlined,
              size: 56,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text('还没有收藏', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '在上方输入 URL，创建第一条稍后阅读内容。',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, color: theme.colorScheme.error),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '暂时无法加载收藏',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '$error',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('重试'),
          ),
        ],
      ),
    );
  }
}
