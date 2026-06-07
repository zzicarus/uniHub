import 'package:uni_hub/src/core/database/app_database.dart';
import 'package:uni_hub/src/plugins/collections/services/website_logo_cache_service.dart';

/// ViewModel for a single saved item's detail view.
///
/// Fetches the [item], its associated [boxes], and the cached [logo]
/// in one aggregated query so the detail panel does not perform N+1
/// calls. Unlike [SavedItemListEntry], this ViewModel is loaded on-demand
/// by item ID and does not depend on the current list state.
class SavedItemDetailVm {
  const SavedItemDetailVm({
    required this.item,
    required this.boxes,
    this.logo,
  });

  final SavedItemsTableData item;
  final List<CollectionBoxesTableData> boxes;
  final WebsiteLogoCacheEntry? logo;
}
