import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uni_hub/src/core/theme/app_tokens.dart';
import 'package:uni_hub/src/plugins/collections/application/saved_item_list_entry.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoSelectFirstItem();
      _drainPendingEnrichment();
    });
  }

  void _drainPendingEnrichment() {
    // 收藏页进入时主动扫描并消费 pending enrichment jobs
    final controller = ref.read(enrichmentQueueControllerProvider);
    controller.drainPending(
      batchSize: 5,
      maxBatches: 3,
    );
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
    final entriesAsync = ref.watch(savedItemListEntriesProvider);
    final selectedId = ref.watch(selectedSavedItemIdProvider);

    // Compute display item from entries synchronously
    final entries = entriesAsync.asData?.value ?? <SavedItemListEntry>[];
    SavedItemListEntry? displayEntry;
    if (selectedId != null) {
      displayEntry =
          entries.where((e) => e.item.id == selectedId).firstOrNull;
    }
    displayEntry ??= entries.isNotEmpty ? entries.first : null;
    final displayItem = displayEntry?.item;

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
                        onPressed: () =>
                            ref.invalidate(savedItemsListProvider),
                      )
                    else
                      OutlinedButton.icon(
                        onPressed: () =>
                            ref.invalidate(savedItemsListProvider),
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
                                data: (entries) {
                                  if (entries.isEmpty) {
                                    return const _EmptyState();
                                  }
                                  return ListView.separated(
                                    itemCount: entries.length,
                                    separatorBuilder: (context, index) =>
                                        const SizedBox(height: AppSpacing.sm),
                                    itemBuilder: (context, index) {
                                      final entry = entries[index];
                                      return SavedItemCard(
                                        entry: entry,
                                        onTap: () {
                                          ref
                                                  .read(
                                                    selectedSavedItemIdProvider
                                                        .notifier,
                                                  )
                                                  .state =
                                              entry.item.id;
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
                          ],
                        ),
                      ),
                      if (showDetail) ...[
                        const SizedBox(width: AppSpacing.md),
                        SizedBox(
                          width: detailWidth,
                          child: SavedItemDetailPanel(item: displayItem),
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
