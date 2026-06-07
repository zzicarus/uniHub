import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uni_hub/src/plugins/collections/domain/saved_items_query.dart';
import 'package:uni_hub/src/plugins/collections/providers/collections_providers.dart';
import 'package:uni_hub/src/plugins/collections/application/saved_item_list_entry.dart';
import 'package:uni_hub/src/plugins/collections/services/website_logo_cache_service.dart';

/// Immutable state for the collections list view.
///
/// Holds the accumulated list entries, pagination info, and selection
/// state in a single value so the widget only has to watch one provider.
class CollectionsListState {
  const CollectionsListState({
    this.entries = const [],
    this.offset = 0,
    this.hasMore = false,
    this.selectedId,
    this.loadingMore = false,
  });

  /// Accumulated list entries across all loaded pages.
  final List<SavedItemListEntry> entries;

  /// Current page offset (number of items already loaded).
  final int offset;

  /// Whether the server/repository reported more pages available.
  final bool hasMore;

  /// Currently selected item ID, if any.
  final int? selectedId;

  /// Whether a load-more operation is in flight.
  final bool loadingMore;

  CollectionsListState copyWith({
    List<SavedItemListEntry>? entries,
    int? offset,
    bool? hasMore,
    int? selectedId,
    bool? loadingMore,
  }) {
    return CollectionsListState(
      entries: entries ?? this.entries,
      offset: offset ?? this.offset,
      hasMore: hasMore ?? this.hasMore,
      selectedId: selectedId ?? this.selectedId,
      loadingMore: loadingMore ?? this.loadingMore,
    );
  }
}

/// Manages pagination, selection, and refresh for the collections list.
///
/// Design decisions:
/// - `build()` is a one-shot initialization (no reactive Riverpod
///   dependencies).  Filter changes must call [refresh] explicitly
///   from the widget via `ref.listen`.
/// - Each page is fetched directly through the repository to avoid
///   depending on Riverpod's [FutureProvider] async resolution inside
///   controller methods.  The corresponding providers stay in sync
///   via [collectionPageOffsetProvider] updates and invalidation.
/// - `loadMore` merges new entries into the accumulated list,
///   deduplicating by item ID.
class CollectionsListController
    extends AutoDisposeAsyncNotifier<CollectionsListState> {
  @override
  Future<CollectionsListState> build() async {
    return _loadPage(0);
  }

  /// Build a [SavedItemsQuery] from the current filter providers.
  SavedItemsQuery _buildQuery(int offset) {
    return SavedItemsQuery(
      view: ref.read(collectionViewProvider),
      status: ref.read(collectionStatusFilterProvider),
      platform: ref.read(collectionPlatformFilterProvider),
      mediaType: ref.read(collectionMediaTypeFilterProvider),
      selectedBoxIds: ref.read(selectedCollectionBoxIdsProvider),
      searchQuery:
          ref.read(collectionDebouncedSearchQueryProvider).valueOrNull ?? '',
      sort: ref.read(collectionSortProvider),
      limit: 50,
      offset: offset,
    );
  }

  /// Load a single page at [offset] from the repository.
  ///
  /// Replicates the enrichment logic of [savedItemListEntriesProvider]
  /// (box resolution + logo lookups) so the controller is self-contained
  /// for pagination.
  Future<CollectionsListState> _loadPage(int offset) async {
    ref.read(collectionPageOffsetProvider.notifier).state = offset;

    final repository = ref.read(collectionsRepositoryProvider);
    final query = _buildQuery(offset);
    final page = await repository.queryItems(query);

    // ── Box lookup ──────────────────────────────────────────────────────────
    final boxes = await ref.read(collectionBoxesProvider.future);
    // .future on a FutureProvider returns Future<List<CollectionBoxesTableData>>
    // when passed to ref.read (the .future getter on FutureProvider exists in
    // riverpod 2.x and returns a ProviderListenable<Future<T>>).
    final boxById = {for (final box in boxes) box.id: box};

    // ── Logo lookup ─────────────────────────────────────────────────────────
    final logoDao = ref.read(websiteLogoCacheDaoProvider);
    final siteKeys = page.items
        .map((item) => WebsiteLogoCacheService.siteKey(item.originalUrl));
    final logoRows = await logoDao.getLogosBySiteKeys(siteKeys);
    final logos = <String, WebsiteLogoCacheEntry?>{};
    for (final entry in logoRows.entries) {
      final row = entry.value;
      logos[entry.key] = row != null
          ? WebsiteLogoCacheEntry(
              siteKey: row.siteKey,
              localLogoPath: row.localLogoPath,
              status: row.status,
            )
          : null;
    }

    // ── Build entries ───────────────────────────────────────────────────────
    final entries = [
      for (final item in page.items)
        SavedItemListEntry(
          item: item,
          boxes: [
            for (final boxId in page.boxIdsByItemId[item.id] ?? const <int>[])
              if (boxById[boxId] != null) boxById[boxId]!,
          ],
          logo: logos[WebsiteLogoCacheService.siteKey(item.originalUrl)],
          selected: false,
        ),
    ];

    return CollectionsListState(
      entries: entries,
      offset: offset,
      hasMore: page.hasMore,
      selectedId: entries.isNotEmpty ? entries.first.item.id : null,
    );
  }

  /// Reload the first page from scratch.
  ///
  /// Used when filter / view / sort / search changes — resets offset to 0
  /// and discards all accumulated entries.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _loadPage(0));
  }

  /// Append the next page of entries to the accumulated list.
  ///
  /// No-op if already loading more or if [hasMore] is false.
  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || current.loadingMore || !current.hasMore) return;

    state = AsyncData(current.copyWith(loadingMore: true));

    try {
      final nextOffset = current.offset + 50;
      final newState = await _loadPage(nextOffset);

      // Dedup by item ID so we never show duplicates
      final existingIds = current.entries.map((e) => e.item.id).toSet();
      final merged = [
        ...current.entries,
        for (final entry in newState.entries)
          if (!existingIds.contains(entry.item.id)) entry,
      ];

      state = AsyncData(
        current.copyWith(
          entries: merged,
          offset: nextOffset,
          hasMore: newState.hasMore,
          loadingMore: false,
        ),
      );
    } catch (_) {
      state = AsyncData(current.copyWith(loadingMore: false));
    }
  }

  /// Select an item by ID.
  ///
  /// Updates both the local state [selectedId] and the global
  /// [selectedSavedItemIdProvider] so the detail panel can react.
  void selectItem(int id) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(selectedId: id));
    ref.read(selectedSavedItemIdProvider.notifier).state = id;
  }
}
