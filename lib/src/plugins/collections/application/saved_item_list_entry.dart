import 'package:uni_hub/src/core/database/app_database.dart';
import 'package:uni_hub/src/plugins/collections/domain/enrichment_status.dart';
import 'package:uni_hub/src/plugins/collections/services/website_logo_cache_service.dart';

/// ViewModel for a single item in the saved-items list.
///
/// Aggregates the item data, its box assignments, the cached logo entry,
/// and the selection state — eliminating the need for UI widgets to
/// perform N+1 queries when rendering a card.
class SavedItemListEntry {
  const SavedItemListEntry({
    required this.item,
    required this.boxes,
    this.logo,
    required this.selected,
  });

  /// The underlying saved item.
  final SavedItemsTableData item;

  /// The collection boxes this item belongs to.
  final List<CollectionBoxesTableData> boxes;

  /// The cached website logo, if available.
  final WebsiteLogoCacheEntry? logo;

  /// Whether this item is currently selected in the list.
  final bool selected;

  /// Display title: falls back to the normalized URL when empty.
  String get displayTitle =>
      item.title.trim().isEmpty ? item.normalizedUrl : item.title;

  /// Whether this item has at least one box assignment.
  bool get hasBoxes => boxes.isNotEmpty;

  /// Whether enrichment has permanently failed for this item.
  bool get enrichmentFailed =>
      item.enrichmentStatus == EnrichmentStatus.failed.value;
}
