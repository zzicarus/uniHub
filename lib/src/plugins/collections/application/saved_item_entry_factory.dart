import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uni_hub/src/core/database/app_database.dart';
import 'package:uni_hub/src/plugins/collections/providers/collections_providers.dart';
import 'package:uni_hub/src/plugins/collections/services/website_logo_cache_service.dart';

import 'saved_item_list_entry.dart';

/// Factory that builds a [SavedItemListEntry] from a saved item row.
///
/// Centralises the box-resolution + logo-lookup logic so that every consumer
/// (list controller pagination, mutation patch, detail provider) produces
/// identical entries and we never get stale/inconsistent data.
class SavedItemEntryFactory {
  const SavedItemEntryFactory(this.ref);

  final Ref ref;

  /// Build a fully resolved [SavedItemListEntry] for [item].
  ///
  /// If [boxIds] is provided it is used directly (saving an extra query);
  /// otherwise the factory resolves box associations from the repository.
  Future<SavedItemListEntry> buildEntry(
    SavedItemsTableData item, {
    List<int>? boxIds,
    bool selected = false,
  }) async {
    final repository = ref.read(collectionsRepositoryProvider);
    final resolvedBoxIds =
        boxIds ?? await repository.getBoxIdsForItem(item.id);

    final allBoxes = await ref.read(collectionBoxesProvider.future);
    final boxById = {for (final box in allBoxes) box.id: box};

    final lookupUrl = _logoLookupUrlForSavedItem(item);
    final siteKey = WebsiteLogoCacheService.siteKey(lookupUrl);
    final logoDao = ref.read(websiteLogoCacheDaoProvider);
    final row = await logoDao.getBySiteKey(siteKey);

    return SavedItemListEntry(
      item: item,
      boxes: [
        for (final boxId in resolvedBoxIds)
          if (boxById[boxId] != null) boxById[boxId]!,
      ],
      logo: row == null
          ? null
          : WebsiteLogoCacheEntry(
              siteKey: row.siteKey,
              localLogoPath: row.localLogoPath,
              status: row.status,
            ),
      selected: selected,
    );
  }

  /// Determine the URL to use for logo site-key lookups.
  ///
  /// Prefers [item.normalizedUrl] over [item.originalUrl] because the
  /// former may have been normalised to a different host (e.g. redirect
  /// chains collapsed).  Falls back to [item.originalUrl] when the
  /// normalised form is empty.
  String _logoLookupUrlForSavedItem(SavedItemsTableData item) {
    final normalizedUrl = item.normalizedUrl.trim();
    if (normalizedUrl.isNotEmpty) return normalizedUrl;
    return item.originalUrl.trim();
  }
}
