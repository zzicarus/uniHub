import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uni_hub/src/plugins/collections/providers/collections_providers.dart';
import 'package:uni_hub/src/shared/crud/crud.dart';

import 'collections_mutation_event.dart';

/// Coordinates UI refresh after saved-item mutations.
///
/// Every write operation (status change, delete, restore, box assignment,
/// logo cache completion, enrichment) goes through this coordinator so
/// downstream controllers can apply precise patches instead of full-page
/// reloads.
///
/// Responsibilities:
/// 1. Emit a [CollectionsMutationEvent] so list/detail controllers react.
/// 2. Invalidate [collectionFolderCountsProvider] when counts may change.
/// 3. Invalidate the detail provider for the affected item.
/// 4. Increment [websiteLogoRefreshProvider] when a logo changes.
///
/// The [CollectionsListController] listens to the mutation stream and
/// performs local patch/remove/insert on its accumulated entry list.
class CollectionsRefreshCoordinator {
  const CollectionsRefreshCoordinator(this.ref);

  final Ref ref;

  /// A saved item's mutable properties changed (status, boxes, metadata, etc.).
  void itemChanged(int itemId, {required SavedItemMutationReason reason}) {
    ref
        .read(collectionsMutationProvider.notifier)
        .emit(SavedItemChanged(itemId: itemId, reason: reason));
    ref
        .read(crudMutationProvider.notifier)
        .emit(
          CrudMutationEvent(
            type: CrudMutationType.changed,
            entityType: CrudEntityType.savedItem,
            entityId: itemId,
            reason: reason.name,
          ),
        );
    ref.invalidate(selectedSavedItemDetailProvider(itemId));
    ref.invalidate(collectionFolderCountsProvider);
  }

  /// A saved item was permanently deleted.
  void itemDeleted(int itemId) {
    ref
        .read(collectionsMutationProvider.notifier)
        .emit(SavedItemDeleted(itemId: itemId));
    ref
        .read(crudMutationProvider.notifier)
        .emit(
          CrudMutationEvent(
            type: CrudMutationType.deleted,
            entityType: CrudEntityType.savedItem,
            entityId: itemId,
          ),
        );
    ref.invalidate(selectedSavedItemDetailProvider(itemId));
    ref.invalidate(collectionFolderCountsProvider);
  }

  /// A previously deleted saved item was restored.
  void itemRestored(int itemId) {
    ref
        .read(collectionsMutationProvider.notifier)
        .emit(SavedItemRestored(itemId: itemId));
    ref
        .read(crudMutationProvider.notifier)
        .emit(
          CrudMutationEvent(
            type: CrudMutationType.restored,
            entityType: CrudEntityType.savedItem,
            entityId: itemId,
          ),
        );
    ref.invalidate(collectionFolderCountsProvider);
  }

  /// The cached logo for a saved item became available.
  ///
  /// Increments [websiteLogoRefreshProvider] so all logo lookups re-read
  /// from the database, and emits a logo-only mutation event so the list
  /// controller can patch just the logo field instead of rebuilding the
  /// entire entry.
  void logoChanged(int itemId) {
    ref
        .read(collectionsMutationProvider.notifier)
        .emit(SavedItemLogoChanged(itemId: itemId));
    ref.read(websiteLogoRefreshProvider.notifier).state++;
  }

  /// Full list reload — e.g. after filter/sort/view changes.
  void hardReload(String reason) {
    ref
        .read(collectionsMutationProvider.notifier)
        .emit(CollectionsReloadRequested(reason: reason));
    ref.invalidate(collectionFolderCountsProvider);
  }
}
