import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uni_hub/src/core/database/app_database.dart';
import 'package:uni_hub/src/plugins/collections/application/saved_item_list_entry.dart';
import 'package:uni_hub/src/plugins/collections/domain/collection_models.dart';
import 'package:uni_hub/src/plugins/collections/domain/consumption_status.dart';
import 'package:uni_hub/src/plugins/collections/domain/saved_items_query.dart';
import 'package:uni_hub/src/plugins/collections/providers/collections_providers.dart';
import 'package:uni_hub/src/plugins/collections/services/website_logo_cache_service.dart';

import 'collections_mutation_event.dart';
import 'collections_mutation_notifier.dart';

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
/// - Mutation events from [collectionsMutationProvider] trigger local
///   patching (patch/remove/insert) instead of full page reloads.
class CollectionsListController
    extends AutoDisposeAsyncNotifier<CollectionsListState> {
  @override
  Future<CollectionsListState> build() async {
    // Listen to mutation events for local patching.
    ref.listen<CollectionsMutationState>(
      collectionsMutationProvider,
      (_, next) {
        final event = next.event;
        if (event == null) return;
        _handleMutation(event);
      },
    );

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
      offset: offset,
    );
  }

  /// Load a single page at [offset] from the repository.
  Future<CollectionsListState> _loadPage(int offset) async {
    ref.read(collectionPageOffsetProvider.notifier).state = offset;

    final repository = ref.read(collectionsRepositoryProvider);
    final query = _buildQuery(offset);
    final page = await repository.queryItems(query);

    // ── Box lookup ──────────────────────────────────────────────────────────
    final boxes = await ref.read(collectionBoxesProvider.future);
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

  // ------------------------------------------------------------------
  // Mutation handling
  // ------------------------------------------------------------------

  void _handleMutation(CollectionsMutationEvent event) {
    // Only react when state is already loaded (ignore mutations during init).
    final current = state.valueOrNull;
    if (current == null) return;

    switch (event) {
      case SavedItemChanged(:final itemId):
        unawaited(_patchChangedItem(itemId));

      case SavedItemDeleted(:final itemId):
        _removeDeletedItem(itemId);

      case SavedItemRestored(:final itemId):
        unawaited(_maybeInsertRestoredItem(itemId));

      case SavedItemLogoChanged(:final itemId):
        unawaited(_patchLogoOnly(itemId));

      case CollectionsReloadRequested():
        unawaited(refresh());
    }
  }

  /// Patch the entry for [itemId] in-place by re-fetching from the repository.
  ///
  /// If the item no longer matches the current query, it is removed.
  Future<void> _patchChangedItem(int itemId) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final repository = ref.read(collectionsRepositoryProvider);
    final item = await repository.getSavedItem(itemId);

    if (item == null) {
      _removeDeletedItem(itemId);
      return;
    }

    final boxIds = await repository.getBoxIdsForItem(itemId);
    final boxIdSet = boxIds.toSet();
    final shouldRemainVisible = _matchesCurrentQuery(item, boxIdSet);

    if (!shouldRemainVisible) {
      _removeDeletedItem(itemId);
      return;
    }

    final entryFactory = ref.read(savedItemEntryFactoryProvider);
    final updatedEntry = await entryFactory.buildEntry(
      item,
      boxIds: boxIds,
      selected: current.selectedId == itemId,
    );

    final index = current.entries.indexWhere((e) => e.item.id == itemId);

    if (index == -1) {
      // Item not in current list — insert at the top (simple strategy;
      // a production implementation could sort by the current sort order).
      state = AsyncData(
        current.copyWith(entries: [updatedEntry, ...current.entries]),
      );
      return;
    }

    final nextEntries = [...current.entries];
    nextEntries[index] = updatedEntry;

    state = AsyncData(current.copyWith(entries: nextEntries));
  }

  /// Remove a deleted item from the list and advance selection.
  void _removeDeletedItem(int itemId) {
    final current = state.valueOrNull;
    if (current == null) return;

    final oldIndex = current.entries.indexWhere((e) => e.item.id == itemId);
    final nextEntries = [
      for (final entry in current.entries)
        if (entry.item.id != itemId) entry,
    ];

    int? nextSelectedId = current.selectedId;
    if (current.selectedId == itemId) {
      if (nextEntries.isEmpty) {
        nextSelectedId = null;
      } else {
        final fallbackIndex = oldIndex.clamp(0, nextEntries.length - 1);
        nextSelectedId = nextEntries[fallbackIndex].item.id;
      }

      ref.read(selectedSavedItemIdProvider.notifier).state = nextSelectedId;
    }

    state = AsyncData(
      current.copyWith(
        entries: nextEntries,
        selectedId: nextSelectedId,
      ),
    );
  }

  /// Insert a restored item if it matches the current query.
  Future<void> _maybeInsertRestoredItem(int itemId) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final repository = ref.read(collectionsRepositoryProvider);
    final item = await repository.getSavedItem(itemId);
    if (item == null) return;

    final boxIds = await repository.getBoxIdsForItem(itemId);
    final boxIdSet = boxIds.toSet();

    if (!_matchesCurrentQuery(item, boxIdSet)) return;

    final entryFactory = ref.read(savedItemEntryFactoryProvider);
    final entry = await entryFactory.buildEntry(
      item,
      boxIds: boxIds,
    );

    state = AsyncData(
      current.copyWith(entries: [entry, ...current.entries]),
    );
  }

  /// Patch only the logo field of an entry (cheap, no DB re-fetch).
  Future<void> _patchLogoOnly(int itemId) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final index = current.entries.indexWhere((e) => e.item.id == itemId);
    if (index == -1) return;

    final oldEntry = current.entries[index];
    final logoDao = ref.read(websiteLogoCacheDaoProvider);
    final lookupUrl = _logoLookupUrlForSavedItem(oldEntry.item);
    final siteKey = WebsiteLogoCacheService.siteKey(lookupUrl);
    final row = await logoDao.getBySiteKey(siteKey);

    final updatedEntry = oldEntry.copyWith(
      logo: row == null
          ? null
          : WebsiteLogoCacheEntry(
              siteKey: row.siteKey,
              localLogoPath: row.localLogoPath,
              status: row.status,
            ),
    );

    final nextEntries = [...current.entries];
    nextEntries[index] = updatedEntry;

    state = AsyncData(current.copyWith(entries: nextEntries));
  }

  // ------------------------------------------------------------------
  // Query matching (in-memory replica of DAO filters)
  // ------------------------------------------------------------------

  /// Returns true if [item] (with its [boxIds]) should remain visible
  /// given the current view, status, platform, media-type, box, and
  /// search filters.
  bool _matchesCurrentQuery(
    SavedItemsTableData item,
    Set<int> boxIds,
  ) {
    final view = ref.read(collectionViewProvider);
    final status = ref.read(collectionStatusFilterProvider);
    final platform = ref.read(collectionPlatformFilterProvider);
    final mediaType = ref.read(collectionMediaTypeFilterProvider);
    final selectedBoxIds = ref.read(selectedCollectionBoxIdsProvider);
    final searchQuery =
        ref.read(collectionDebouncedSearchQueryProvider).valueOrNull ?? '';

    if (!_matchesView(item, view)) return false;

    if (status != null && item.status != status.value) return false;
    if (platform != null && item.sourcePlatform != platform.value) return false;
    if (mediaType != null && item.mediaType != mediaType.value) return false;

    if (selectedBoxIds.isNotEmpty &&
        !selectedBoxIds.any((id) => boxIds.contains(id))) {
      return false;
    }

    if (searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      final haystack = [
        item.title,
        item.originalUrl,
        item.normalizedUrl,
        item.siteName ?? '',
        item.description ?? '',
      ].join(' ').toLowerCase();

      if (!haystack.contains(q)) return false;
    }

    return true;
  }

  /// Returns true if [item] matches the current [CollectionView].
  bool _matchesView(SavedItemsTableData item, CollectionView view) {
    return switch (view) {
      CollectionView.all => true,
      CollectionView.inbox =>
        item.isInInbox && item.status != ConsumptionStatus.archived.value,
      CollectionView.archived =>
        item.status == ConsumptionStatus.archived.value,
      CollectionView.unread => item.status == ConsumptionStatus.unread.value,
      CollectionView.inProgress =>
        item.status == ConsumptionStatus.inProgress.value,
      CollectionView.done => item.status == ConsumptionStatus.done.value,
    };
  }

  String _logoLookupUrlForSavedItem(SavedItemsTableData item) {
    final normalizedUrl = item.normalizedUrl.trim();
    if (normalizedUrl.isNotEmpty) return normalizedUrl;
    return item.originalUrl.trim();
  }
}
