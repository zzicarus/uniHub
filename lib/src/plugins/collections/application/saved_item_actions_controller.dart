import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uni_hub/src/plugins/collections/data/collections_repository.dart';
import 'package:uni_hub/src/plugins/collections/domain/consumption_status.dart';
import 'package:uni_hub/src/plugins/collections/providers/collections_providers.dart';
import 'package:uni_hub/src/plugins/collections/services/enrichment_job_service.dart';
import 'package:url_launcher/url_launcher.dart';

import 'saved_item_action_result.dart';
import 'saved_item_undo_snapshot.dart';

/// Unified controller for saved item operations.
///
/// UI components call these methods instead of directly accessing the
/// repository or composing delete/undo/archive flows inline. Every
/// mutation method returns [SavedItemActionResult] so the UI can display
/// status messages and offer undo actions without knowing the underlying
/// data layer.
class SavedItemActionsController {
  SavedItemActionsController({
    required CollectionsRepository repository,
    required EnrichmentJobService enrichmentJobService,
    Ref? ref,
  }) : _repository = repository,
       _enrichmentJobService = enrichmentJobService,
       _ref = ref;

  final CollectionsRepository _repository;
  final EnrichmentJobService _enrichmentJobService;
  final Ref? _ref;

  // ------------------------------------------------------------------
  // Invalidation helpers
  //
  // These are overridable in subclasses (e.g. for tests) to replace
  // Riverpod invalidation with test-friendly callbacks.
  // ------------------------------------------------------------------

  @protected
  void invalidateLists() {
    _ref?.invalidate(savedItemsPageProvider);
  }

  @protected
  void invalidateCounts() {
    _ref?.invalidate(collectionFolderCountsProvider);
  }

  @protected
  void invalidateAll() {
    invalidateLists();
    invalidateCounts();
  }

  // ------------------------------------------------------------------
  // Actions
  // ------------------------------------------------------------------

  /// Launch the item's URL in an external browser and mark it opened only
  /// after the launcher reports success.
  Future<SavedItemActionResult> openItem(int itemId) async {
    final item = await _repository.getSavedItem(itemId);
    if (item == null) {
      return const SavedItemActionResult(success: false, message: '收藏项不存在');
    }

    final uri = Uri.tryParse(item.originalUrl);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      return const SavedItemActionResult(success: false, message: '无效的链接');
    }

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        return const SavedItemActionResult(success: false, message: '打开链接失败');
      }

      await _repository.markOpened(itemId);
      invalidateLists();
      return const SavedItemActionResult(success: true, message: '已打开');
    } catch (e) {
      return SavedItemActionResult(success: false, message: '打开链接失败', error: e);
    }
  }

  /// Copy the item's original URL to the system clipboard.
  Future<SavedItemActionResult> copyUrl(int itemId) async {
    final item = await _repository.getSavedItem(itemId);
    if (item == null) {
      return const SavedItemActionResult(success: false, message: '收藏项不存在');
    }

    await Clipboard.setData(ClipboardData(text: item.originalUrl));
    return const SavedItemActionResult(success: true, message: '链接已复制到剪贴板');
  }

  /// Update the consumption status of a saved item.
  Future<SavedItemActionResult> updateStatus(
    int itemId,
    ConsumptionStatus status,
  ) async {
    try {
      await _repository.updateStatus(itemId, status);
      invalidateAll();
      return SavedItemActionResult(
        success: true,
        message: '状态已更新为「${status.label}」',
      );
    } catch (e) {
      return SavedItemActionResult(success: false, message: '状态更新失败', error: e);
    }
  }

  /// Convenience method to archive an item.
  Future<SavedItemActionResult> archiveItem(int itemId) async {
    return updateStatus(itemId, ConsumptionStatus.archived);
  }

  /// Assign a set of box IDs to an item, replacing any existing assignments.
  ///
  /// Flips [isInInbox] based solely on whether [boxIds] is non-empty,
  /// regardless of prior state — this ensures inbox stays consistent
  /// with box assignments even if the DB was previously out of sync.
  Future<SavedItemActionResult> assignBoxes(int itemId, Set<int> boxIds) async {
    try {
      await _repository.setItemBoxes(itemId, boxIds);
      await _repository.updateInboxState(itemId, boxIds.isEmpty);

      // Defer invalidation to next frame for safe UI rebuild
      if (_ref != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          invalidateAll();
        });
      }

      return const SavedItemActionResult(success: true);
    } catch (e) {
      return SavedItemActionResult(
        success: false,
        message: '收藏夹分配失败',
        error: e,
      );
    }
  }

  /// Remove an item from a single collection box.
  ///
  /// If this was the last box, the item returns to Inbox.
  Future<SavedItemActionResult> removeFromBox(int itemId, int boxId) async {
    try {
      await _repository.removeItemFromBox(itemId, boxId);
      // Defer invalidation to next frame for safe UI rebuild
      if (_ref != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          invalidateAll();
        });
      }
      return const SavedItemActionResult(success: true);
    } catch (e) {
      return SavedItemActionResult(
        success: false,
        message: '从收藏夹移除失败',
        error: e,
      );
    }
  }

  /// Delete a saved item, optionally only removing it from a specific box.
  ///
  /// Returns an undo snapshot so the UI can offer an undo action.
  Future<SavedItemActionResult> deleteItem(
    int itemId, {
    DeleteMode mode = DeleteMode.fullDelete,
    int? boxId,
    String? boxName,
  }) async {
    final item = await _repository.getSavedItem(itemId);
    if (item == null) {
      return const SavedItemActionResult(success: false, message: '收藏项不存在');
    }

    final boxIds = await _repository.getBoxIdsForItem(itemId);
    final snapshot = SavedItemUndoSnapshot(
      item: item,
      boxIds: List<int>.from(boxIds),
    );

    switch (mode) {
      case DeleteMode.fullDelete:
        await _repository.deleteSavedItem(itemId);
        _ref?.read(selectedSavedItemIdProvider.notifier).state = null;
        invalidateAll();

        final displayTitle = item.title.isEmpty
            ? item.normalizedUrl
            : item.title;

        return SavedItemActionResult(
          success: true,
          message: '已删除「$displayTitle」',
          undo: SavedItemUndoAction(
            label: '撤销',
            execute: () => restoreDeletedItem(snapshot),
          ),
        );

      case DeleteMode.removeFromBox:
        if (boxId == null) {
          return const SavedItemActionResult(
            success: false,
            message: '请指定要移除的收藏夹',
          );
        }
        await _repository.removeItemFromBox(itemId, boxId);

        final currentBoxName = boxName ?? '收藏夹';
        invalidateAll();

        return SavedItemActionResult(
          success: true,
          message: '已从「$currentBoxName」中移除',
          undo: SavedItemUndoAction(
            label: '撤销',
            execute: () async {
              final currentIds = await _repository.getBoxIdsForItem(itemId);
              await _repository.setItemBoxes(itemId, {...currentIds, boxId});
              await _repository.updateInboxState(itemId, false);
              invalidateAll();
            },
          ),
        );
    }
  }

  /// Restore a previously deleted item from its snapshot.
  ///
  /// Creates a new saved item with all original fields and restores
  /// its box associations.
  Future<SavedItemActionResult> restoreDeletedItem(
    SavedItemUndoSnapshot snapshot,
  ) async {
    try {
      final restored = await _repository.restoreSavedItem(
        snapshot.item,
        snapshot.boxIds,
      );
      invalidateAll();
      final displayTitle = restored.title.isEmpty
          ? restored.originalUrl
          : restored.title;
      return SavedItemActionResult(
        success: true,
        message: '已恢复「$displayTitle」',
      );
    } catch (e) {
      return SavedItemActionResult(
        success: false,
        message: '恢复收藏项失败',
        error: e,
      );
    }
  }

  /// Retry enrichment for a saved item.
  ///
  /// Delegates to [EnrichmentQueueController.retryItem] when [_ref] is
  /// available (production). Falls back to the direct repository +
  /// enrichment service path in tests where [_ref] may be null.
  Future<SavedItemActionResult> retryEnrichment(int itemId) async {
    if (_ref != null) {
      try {
        final queueController = _ref.read(enrichmentQueueControllerProvider);
        return queueController.retryItem(itemId);
      } catch (e) {
        return SavedItemActionResult(
          success: false,
          message: '重试失败：${e.toString()}',
          error: e,
        );
      }
    }
    // Fallback for tests
    try {
      await _repository.enqueueEnrichmentJob(itemId);
      unawaited(_enrichmentJobService.runPendingJobs());
      return const SavedItemActionResult(success: true, message: '已重新加入抓取队列');
    } catch (e) {
      return SavedItemActionResult(success: false, message: '重试抓取失败', error: e);
    }
  }

  /// Toggle favorite status for an item (not yet supported).
  Future<SavedItemActionResult> toggleFavorite(int itemId) async {
    return const SavedItemActionResult(success: false, message: '星标功能稍后接入');
  }
}
