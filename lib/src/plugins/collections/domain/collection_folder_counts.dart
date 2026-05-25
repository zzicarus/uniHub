/// Global navigation counts for the CollectionFolderSidebar.
///
/// These counts are computed in the data layer (DAO → Repository) so they
/// are **not** affected by search queries, platform/media-type filters, or
/// any other UI-level filter applied in [savedItemsListProvider].
class CollectionFolderCounts {
  const CollectionFolderCounts({
    required this.all,
    required this.inbox,
    required this.unread,
    required this.byBoxId,
  });

  /// Total number of saved items (including archived).
  final int all;

  /// Items in the inbox (isInInbox == true, not archived).
  final int inbox;

  /// Items with status == unread.
  final int unread;

  /// Per-collection-box item count.
  final Map<int, int> byBoxId;

  int boxCount(int boxId) => byBoxId[boxId] ?? 0;
}
