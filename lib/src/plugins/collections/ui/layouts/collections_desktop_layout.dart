import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uni_hub/src/core/database/app_database.dart';
import 'package:uni_hub/src/core/theme/app_tokens.dart';
import 'package:uni_hub/src/plugins/collections/providers/collections_providers.dart';

import '../widgets/collection_capture_bar.dart';
import '../widgets/collection_folder_sidebar.dart';
import '../widgets/collection_list_toolbar.dart';
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
      displayItem = items.where((item) => item.id == selectedId).firstOrNull;
    }
    displayItem ??= items.isNotEmpty ? items.first : null;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('内容收藏', style: theme.textTheme.headlineMedium),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '收集网页、视频、公众号、文章与其他值得保存的内容。',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 320,
                    maxWidth: 460,
                  ),
                  child: const _HeaderSearchField(),
                ),
                const SizedBox(width: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('导入功能稍后接入')));
                  },
                  icon: const Icon(Icons.file_download_outlined),
                  label: const Text('导入'),
                ),
                const SizedBox(width: AppSpacing.xs),
                OutlinedButton.icon(
                  onPressed: () => ref.invalidate(savedItemsListProvider),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('刷新'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            const CollectionCaptureBar(),
            const SizedBox(height: AppSpacing.sm),
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
                            const CollectionListToolbar(),
                            const SizedBox(height: AppSpacing.sm),
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
                                                  .state =
                                              item.id;
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
}

class _HeaderSearchField extends ConsumerWidget {
  const _HeaderSearchField();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(collectionSearchQueryProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              key: ValueKey('collection-header-search-$query'),
              initialValue: query,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded),
                hintText: '搜索收藏内容（标题 / 来源 / 标签 / URL）',
                border: InputBorder.none,
                isDense: true,
              ),
              onChanged: (value) {
                ref.read(collectionSearchQueryProvider.notifier).state = value;
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppRadius.xs),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: AppSpacing.xxs,
                ),
                child: Text(
                  'Ctrl K',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: AppFontTokens.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
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
