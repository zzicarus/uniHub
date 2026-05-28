import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uni_hub/src/core/theme/app_tokens.dart';
import 'package:uni_hub/src/plugins/collections/application/saved_item_list_entry.dart';
import 'package:uni_hub/src/plugins/collections/domain/collection_models.dart';
import 'package:uni_hub/src/plugins/collections/domain/consumption_status.dart';
import 'package:uni_hub/src/plugins/collections/domain/media_type.dart';
import 'package:uni_hub/src/plugins/collections/domain/saved_items_query.dart';
import 'package:uni_hub/src/plugins/collections/domain/source_platform.dart';
import 'package:uni_hub/src/plugins/collections/providers/collections_providers.dart';
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
  final List<SavedItemListEntry> _accumulatedEntries = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _drainPendingEnrichment();
    });
    // #3: 持续监听列表数据就绪，自动选中第一条（替代 post-frame 一次性读取）
    ref.listenManual<AsyncValue<List<SavedItemListEntry>>>(
      savedItemListEntriesProvider,
      (prev, next) {
        final entries = next.valueOrNull;
        if (entries == null) return;

        final offset = ref.read(collectionPageOffsetProvider);

        // 先维护列表数据，不受 selected 影响
        if (offset == 0) {
          _accumulatedEntries
            ..clear()
            ..addAll(entries);
        } else {
          final existingIds = _accumulatedEntries.map((e) => e.item.id).toSet();
          for (final entry in entries) {
            if (!existingIds.contains(entry.item.id)) {
              _accumulatedEntries.add(entry);
            }
          }
        }

        // 再做自动选中
        final selected = ref.read(selectedSavedItemIdProvider);
        if (selected == null && entries.isNotEmpty && mounted) {
          ref.read(selectedSavedItemIdProvider.notifier).state =
              entries.first.item.id;
        }

        if (mounted) {
          setState(() {});
        }
      },
    );
    // #4: 筛选条件变化时重置分页
    ref.listenManual<CollectionView>(
      collectionViewProvider,
      (_, _) => _resetPagination(),
    );
    ref.listenManual<ConsumptionStatus?>(
      collectionStatusFilterProvider,
      (_, _) => _resetPagination(),
    );
    ref.listenManual<SourcePlatform?>(
      collectionPlatformFilterProvider,
      (_, _) => _resetPagination(),
    );
    ref.listenManual<MediaType?>(
      collectionMediaTypeFilterProvider,
      (_, _) => _resetPagination(),
    );
    ref.listenManual<Set<int>>(
      selectedCollectionBoxIdsProvider,
      (_, _) => _resetPagination(),
    );
    ref.listenManual<SavedItemsSort>(
      collectionSortProvider,
      (_, _) => _resetPagination(),
    );
  }

  void _resetPagination() {
    ref.read(collectionPageOffsetProvider.notifier).state = 0;
  }

  void _refreshList() {
    setState(() {
      _accumulatedEntries.clear();
    });
    ref.read(collectionPageOffsetProvider.notifier).state = 0;
    ref.invalidate(savedItemsPageProvider);
    ref.invalidate(savedItemListEntriesProvider);
  }

  void _drainPendingEnrichment() {
    // 收藏页进入时主动扫描并消费 pending enrichment jobs
    final controller = ref.read(enrichmentQueueControllerProvider);
    controller.drainPending(
      batchSize: 5,
      maxBatches: 3,
    );
  }

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(savedItemListEntriesProvider);
    final hasMore = ref.watch(collectionHasMoreProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Responsive header — uses outer LayoutBuilder to determine
            // narrow mode so that import/refresh buttons can be icon-only.
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 760;
                return ResponsivePageHeader(
                  title: '内容收藏',
                  subtitle: '收集网页、视频、公众号、文章与其他值得保存的内容。',
                  search: null,
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
                  final showDetail = constraints.maxWidth >= 960;
                  final detailWidth = showDetail
                      ? (constraints.maxWidth * 0.30).clamp(380.0, 440.0)
                      : 0.0;

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(
                        width: 220,
                        child: CollectionFolderSidebar(),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: entriesAsync.when(
                                data: (_) {
                                  if (_accumulatedEntries.isEmpty) {
                                    return const _EmptyState();
                                  }
                                  return ListView.separated(
                                    itemCount: _accumulatedEntries.length +
                                        (hasMore ? 1 : 0),
                                    separatorBuilder: (context, index) =>
                                        const SizedBox(height: AppSpacing.sm),
                                    itemBuilder: (context, index) {
                                      // #4: 加载更多按钮（列表末尾）
                                      if (hasMore &&
                                          index ==
                                              _accumulatedEntries.length) {
                                        return Center(
                                          child: TextButton.icon(
                                            onPressed: () {
                                              ref
                                                  .read(
                                                    collectionPageOffsetProvider
                                                        .notifier,
                                                  )
                                                  .update((o) => o + 50);
                                            },
                                            icon: const Icon(
                                              Icons.expand_more_rounded,
                                              size: 18,
                                            ),
                                            label: const Text('加载更多'),
                                          ),
                                        );
                                      }
                                      final entry =
                                          _accumulatedEntries[index];
                                      return SavedItemCard(
                                        key: ValueKey(entry.item.id),
                                        entry: entry,
                                        onTap: () {
                                          ref
                                              .read(
                                                selectedSavedItemIdProvider
                                                    .notifier,
                                              )
                                              .state = entry.item.id;
                                        },
                                      );
                                    },
                                  );
                                },
                                loading: () {
                                  if (_accumulatedEntries.isNotEmpty) {
                                    return ListView.separated(
                                      itemCount: _accumulatedEntries.length,
                                      separatorBuilder: (context, index) =>
                                          const SizedBox(
                                        height: AppSpacing.sm,
                                      ),
                                      itemBuilder: (context, index) {
                                        final entry =
                                            _accumulatedEntries[index];
                                        return SavedItemCard(
                                          key: ValueKey(entry.item.id),
                                          entry: entry,
                                          onTap: () {
                                            ref
                                                .read(
                                                  selectedSavedItemIdProvider
                                                      .notifier,
                                                )
                                                .state = entry.item.id;
                                          },
                                        );
                                      },
                                    );
                                  }
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                },
                                error: (error, stackTrace) {
                                  if (_accumulatedEntries.isNotEmpty) {
                                    return ListView.separated(
                                      itemCount: _accumulatedEntries.length,
                                      separatorBuilder: (context, index) =>
                                          const SizedBox(
                                        height: AppSpacing.sm,
                                      ),
                                      itemBuilder: (context, index) {
                                        final entry =
                                            _accumulatedEntries[index];
                                        return SavedItemCard(
                                          key: ValueKey(entry.item.id),
                                          entry: entry,
                                          onTap: () {
                                            ref
                                                .read(
                                                  selectedSavedItemIdProvider
                                                      .notifier,
                                                )
                                                .state = entry.item.id;
                                          },
                                        );
                                      },
                                    );
                                  }
                                  return _ErrorState(
                                    error: error,
                                    onRetry: () =>
                                        ref.invalidate(savedItemsPageProvider),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (showDetail) ...[
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('导入功能稍后接入')),
    );
  }
}

/// 详情面板容器：内部 watch [selectedSavedItemEntryProvider]，
/// 选中变化时只有本 widget 重建，布局父级不受影响。
class _DetailPanel extends ConsumerWidget {
  const _DetailPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entry = ref.watch(selectedSavedItemEntryProvider);
    if (entry == null) {
      return Center(
        child: Text(
          '选择一条收藏查看详情',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    return SavedItemDetailPanel(item: entry.item);
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
