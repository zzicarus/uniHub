import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uni_hub/src/core/theme/app_tokens.dart';
import 'package:uni_hub/src/plugins/collections/application/saved_item_list_entry.dart';
import 'package:uni_hub/src/plugins/collections/providers/collections_providers.dart';
import 'package:uni_hub/src/shared/widgets/app_toast.dart';
import 'package:uni_hub/src/shared/widgets/responsive_page_header.dart';

import '../widgets/collection_command_bar.dart';
import '../widgets/collection_folder_sidebar.dart';
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
      _drainPendingEnrichment();
    });
  }

  void _refreshList() {
    ref.read(collectionsListControllerProvider.notifier).refresh();
    ref.invalidate(collectionFolderCountsProvider);
  }

  void _drainPendingEnrichment() {
    // 收藏页进入时主动扫描并消费 pending enrichment jobs
    final controller = ref.read(enrichmentQueueControllerProvider);
    controller.drainPending(
      maxBatches: 3,
    );
  }

  @override
  Widget build(BuildContext context) {
    // ── Filter listeners ──────────────────────────────────────────────────
    // Every time a filter / view / sort / search changes, reload from page 0.
    ref.listen(collectionViewProvider, (_, _) {
      ref.read(collectionsListControllerProvider.notifier).refresh();
    });
    ref.listen(collectionStatusFilterProvider, (_, _) {
      ref.read(collectionsListControllerProvider.notifier).refresh();
    });
    ref.listen(collectionPlatformFilterProvider, (_, _) {
      ref.read(collectionsListControllerProvider.notifier).refresh();
    });
    ref.listen(collectionMediaTypeFilterProvider, (_, _) {
      ref.read(collectionsListControllerProvider.notifier).refresh();
    });
    ref.listen(selectedCollectionBoxIdsProvider, (_, _) {
      ref.read(collectionsListControllerProvider.notifier).refresh();
    });
    ref.listen(collectionSortProvider, (_, _) {
      ref.read(collectionsListControllerProvider.notifier).refresh();
    });


    // ── Controller state ──────────────────────────────────────────────────
    final listStateAsync = ref.watch(collectionsListControllerProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 760;
                return ResponsivePageHeader(
                  title: '内容库',
                  subtitle: '收集网页、视频、公众号、文章与其他值得保存的内容。',
                  actions: [
                    if (isNarrow)
                      IconButton(
                        icon: const Icon(Icons.file_download_outlined),
                        tooltip: '导入',
                        onPressed: () => _showImportSoon(context),
                      )
                    else
                      OutlinedButton.icon(
                        onPressed: () => _showImportSoon(context),
                        icon: const Icon(Icons.file_download_outlined),
                        label: const Text('导入'),
                      ),
                    if (isNarrow)
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded),
                        tooltip: '刷新',
                        onPressed: _refreshList,
                      )
                    else
                      OutlinedButton.icon(
                        onPressed: _refreshList,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('刷新'),
                      ),
                  ],
                );
              },
            ),
            const CollectionCommandBar(),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final showFixedDetail = width >= 1200;
                  final showNarrowDetail = width >= 960 && width < 1200;
                  final showSidebar = width >= 760;

                  // PRD 2.2 响应式规则：
                  // >= 1200px: Box 侧栏 + 列表 + 固定详情 (420px)
                  // 960-1199px: 列表 + 窄详情 (340px)，侧栏可保留
                  // < 960px: 无详情面板，点击卡片打开底部抽屉
                  final detailWidth = showFixedDetail
                      ? 420.0
                      : showNarrowDetail
                          ? 340.0
                          : 0.0;

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (showSidebar)
                        const SizedBox(
                          width: 220,
                          child: CollectionFolderSidebar(),
                        ),
                      if (showSidebar) const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: listStateAsync.when(
                                data: (listState) {
                                  if (listState.entries.isEmpty) {
                                    return const _EmptyState();
                                  }
                                  return _buildEntryList(
                                    context,
                                    listState.entries,
                                    listState.hasMore,
                                    listState.loadingMore,
                                    ref,
                                  );
                                },
                                loading: () {
                                  final existing = listStateAsync.valueOrNull;
                                  if (existing != null &&
                                      existing.entries.isNotEmpty) {
                                    return _buildEntryList(
                                      context,
                                      existing.entries,
                                      existing.hasMore,
                                      existing.loadingMore,
                                      ref,
                                    );
                                  }
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                },
                                error: (error, _) {
                                  final existing = listStateAsync.valueOrNull;
                                  if (existing != null &&
                                      existing.entries.isNotEmpty) {
                                    return _buildEntryList(
                                      context,
                                      existing.entries,
                                      existing.hasMore,
                                      existing.loadingMore,
                                      ref,
                                    );
                                  }
                                  return _ErrorState(
                                    error: error,
                                    onRetry: () => ref
                                        .read(
                                          collectionsListControllerProvider
                                              .notifier,
                                        )
                                        .refresh(),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (showFixedDetail || showNarrowDetail) ...[
                        const SizedBox(width: AppSpacing.md),
                        SizedBox(
                          width: detailWidth,
                          child: const _DetailPanel(),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImportSoon(BuildContext context) {
    AppToast.show(
      context,
      message: '导入功能稍后接入',
    );
  }
}

/// Reusable list builder — used by all [listStateAsync.when] branches so
/// the entry card rendering logic is written once.
Widget _buildEntryList(
  BuildContext context,
  List<SavedItemListEntry> entries,
  bool hasMore,
  bool loadingMore,
  WidgetRef ref,
) {
  final screenWidth = MediaQuery.of(context).size.width;
  final useBottomSheet = screenWidth < 960;

  return ListView.separated(
    itemCount: entries.length + (hasMore ? 1 : 0),
    separatorBuilder: (context, index) =>
        const SizedBox(height: AppSpacing.sm),
    itemBuilder: (context, index) {
      // 加载更多按钮（列表末尾）
      if (hasMore && index == entries.length) {
        return Center(
          child: TextButton.icon(
            onPressed: loadingMore
                ? null
                : () => ref
                    .read(collectionsListControllerProvider.notifier)
                    .loadMore(),
            icon: const Icon(Icons.expand_more_rounded, size: 18),
            label: Text(loadingMore ? '加载中' : '加载更多'),
          ),
        );
      }

      final entry = entries[index];
      return SavedItemCard(
        key: ValueKey(entry.item.id),
        entry: entry,
        onTap: () {
          ref
              .read(collectionsListControllerProvider.notifier)
              .selectItem(entry.item.id);

          // < 960px: 打开底部详情抽屉代替固定侧栏
          if (useBottomSheet) {
            _showDetailBottomSheet(context, entry.item.id);
          }
        },
      );
    },
  );
}

/// 在窄屏下通过底部抽屉展示详情。
void _showDetailBottomSheet(
  BuildContext context,
  int itemId,
) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.86,
        minChildSize: 0.5,
        maxChildSize: 0.96,
        builder: (context, scrollController) {
          return SavedItemDetailPanel(
            itemId: itemId,
          );
        },
      );
    },
  );
}

/// 详情面板容器：按 itemId 从 [selectedSavedItemDetailProvider] 加载详情。
///
/// 不再依赖当前列表的 entry 状态，分页切换后仍可正常加载。
class _DetailPanel extends ConsumerWidget {
  const _DetailPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedId = ref.watch(selectedSavedItemIdProvider);

    if (selectedId == null) {
      return Center(
        child: Text(
          '选择一条收藏查看详情',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return SavedItemDetailPanel(itemId: selectedId);
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
            Text(
              '还没有收藏',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '在上方输入 URL，创建第一条稍后阅读内容。',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '$error',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
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
