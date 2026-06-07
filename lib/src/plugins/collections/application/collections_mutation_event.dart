/// Events emitted by [CollectionsMutationNotifier] to notify downstream
/// controllers that a saved item has changed.
///
/// Each event carries the affected [itemId] and a [reason] describing the
/// type of mutation so handlers can apply precise UI patches instead of
/// full-page reloads.
sealed class CollectionsMutationEvent {
  const CollectionsMutationEvent();
}

/// A saved item was modified in place (status, boxes, metadata, etc.).
class SavedItemChanged extends CollectionsMutationEvent {
  const SavedItemChanged({
    required this.itemId,
    required this.reason,
  });

  final int itemId;
  final SavedItemMutationReason reason;
}

/// A saved item was permanently deleted.
class SavedItemDeleted extends CollectionsMutationEvent {
  const SavedItemDeleted({required this.itemId});

  final int itemId;
}

/// A previously deleted saved item was restored.
class SavedItemRestored extends CollectionsMutationEvent {
  const SavedItemRestored({required this.itemId});

  final int itemId;
}

/// The cached logo for a saved item became available.
class SavedItemLogoChanged extends CollectionsMutationEvent {
  const SavedItemLogoChanged({required this.itemId});

  final int itemId;
}

/// A full list reload is requested (e.g. filter/sort/view changed).
class CollectionsReloadRequested extends CollectionsMutationEvent {
  const CollectionsReloadRequested({required this.reason});

  final String reason;
}

/// Describes what aspect of a saved item mutated, so the coordinator can
/// decide which UI regions to refresh.
enum SavedItemMutationReason {
  /// Consumption status changed (unread → in-progress → archived, etc.).
  status,

  /// Item was opened in an external browser (lastOpenedAt updated).
  opened,

  /// Box (collection folder) assignments changed.
  boxes,

  /// General metadata (title, siteName, mediaType, etc.) changed.
  metadata,

  /// User notes changed.
  notes,

  /// Tags changed.
  tags,

  /// Title changed.
  title,

  /// Item was archived (special case of status).
  archive,

  /// Enrichment (metadata fetch) completed.
  enrichment,
}
