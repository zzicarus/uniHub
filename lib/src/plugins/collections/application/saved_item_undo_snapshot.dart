import 'package:uni_hub/src/core/database/app_database.dart';

/// A snapshot captured before a destructive action (e.g. delete), containing
/// enough data to fully restore the item and its box associations.
class SavedItemUndoSnapshot {
  const SavedItemUndoSnapshot({
    required this.item,
    required this.boxIds,
  });

  /// The complete item data captured before deletion.
  final SavedItemsTableData item;

  /// The IDs of collection boxes the item belonged to.
  final List<int> boxIds;

  @override
  String toString() =>
      'SavedItemUndoSnapshot(itemId: ${item.id}, boxes: $boxIds)';
}

/// Mode for item deletion, determining whether to fully delete the item
/// or only remove it from a specific box.
enum DeleteMode {
  /// Completely delete the item from all collections and boxes.
  fullDelete,

  /// Remove the item from a specific box only without deleting it.
  removeFromBox,
}
