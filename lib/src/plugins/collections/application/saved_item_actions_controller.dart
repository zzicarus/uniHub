import 'dart:async';

import 'package:flutter/services.dart';
import 'package:uni_hub/src/plugins/collections/data/collections_repository.dart';
import 'package:uni_hub/src/plugins/collections/domain/consumption_status.dart';
import 'package:uni_hub/src/plugins/collections/services/enrichment_job_service.dart';
import 'package:uni_hub/src/shared/crud/crud.dart';
import 'package:url_launcher/url_launcher.dart';

import 'collections_mutation_event.dart';
import 'collections_refresh_coordinator.dart';
import 'enrichment_queue_controller.dart';
import 'saved_item_undo_snapshot.dart';

/// Unified controller for saved item operations.
///
/// UI components call these methods instead of directly accessing the
/// repository or composing delete/undo/archive flows inline. Every mutation
/// method returns [CrudResult] so the UI can display status messages and offer
/// undo actions without knowing the underlying data layer.
class SavedItemActionsController {
  SavedItemActionsController({
    required CollectionsRepository repository,
    required EnrichmentJobService enrichmentJobService,
    CollectionsRefreshCoordinator? refreshCoordinator,
    EnrichmentQueueController? enrichmentQueueController,
  }) : _repository = repository,
       _enrichmentJobService = enrichmentJobService,
       _refreshCoordinator = refreshCoordinator,
       _enrichmentQueueController = enrichmentQueueController;

  final CollectionsRepository _repository;
  final EnrichmentJobService _enrichmentJobService;
  final CollectionsRefreshCoordinator? _refreshCoordinator;
  final EnrichmentQueueController? _enrichmentQueueController;

  Future<CrudResult<void>> openItem(int itemId) async {
    try {
      final item = await _repository.getSavedItem(itemId);
      if (item == null) {
        return _failure('收藏项不存在', AppFailureCode.notFound);
      }

      final uri = Uri.tryParse(item.originalUrl);
      if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
        return _failure('无效的链接', AppFailureCode.validation);
      }

      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        return _failure('打开链接失败', AppFailureCode.unknown);
      }

      await _repository.markOpened(itemId);
      _refreshCoordinator?.itemChanged(
        itemId,
        reason: SavedItemMutationReason.opened,
      );
      return const CrudResult<void>.success(
        message: '已打开',
        suppressFeedback: true,
      );
    } catch (error, stackTrace) {
      return _failure(
        '打开链接失败',
        AppFailureCode.unknown,
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<CrudResult<void>> copyUrl(int itemId) async {
    try {
      final item = await _repository.getSavedItem(itemId);
      if (item == null) {
        return _failure('收藏项不存在', AppFailureCode.notFound);
      }

      await Clipboard.setData(ClipboardData(text: item.originalUrl));
      return const CrudResult<void>.success(message: '链接已复制到剪贴板');
    } catch (error, stackTrace) {
      return _failure(
        '复制链接失败',
        AppFailureCode.unknown,
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<CrudResult<void>> updateStatus(
    int itemId,
    ConsumptionStatus status,
  ) async {
    try {
      await _repository.updateStatus(itemId, status);
      _refreshCoordinator?.itemChanged(
        itemId,
        reason: status == ConsumptionStatus.archived
            ? SavedItemMutationReason.archive
            : SavedItemMutationReason.status,
      );
      return CrudResult<void>.success(
        message: '状态已更新为「${status.label}」',
        suppressFeedback: status != ConsumptionStatus.archived,
      );
    } catch (error, stackTrace) {
      return _failure(
        '状态更新失败',
        AppFailureCode.database,
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<CrudResult<void>> archiveItem(int itemId) {
    return updateStatus(itemId, ConsumptionStatus.archived);
  }

  Future<CrudResult<void>> assignBoxes(int itemId, Set<int> boxIds) async {
    try {
      await _repository.setItemBoxes(itemId, boxIds);
      await _repository.updateInboxState(itemId, boxIds.isEmpty);
      _refreshCoordinator?.itemChanged(
        itemId,
        reason: SavedItemMutationReason.boxes,
      );
      return const CrudResult<void>.success(suppressFeedback: true);
    } catch (error, stackTrace) {
      return _failure(
        '收藏夹分配失败',
        AppFailureCode.database,
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<CrudResult<void>> removeFromBox(int itemId, int boxId) async {
    try {
      await _repository.removeItemFromBox(itemId, boxId);
      _refreshCoordinator?.itemChanged(
        itemId,
        reason: SavedItemMutationReason.boxes,
      );
      return const CrudResult<void>.success(suppressFeedback: true);
    } catch (error, stackTrace) {
      return _failure(
        '从收藏夹移除失败',
        AppFailureCode.database,
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<CrudResult<void>> deleteItem(
    int itemId, {
    DeleteMode mode = DeleteMode.fullDelete,
    int? boxId,
    String? boxName,
  }) async {
    try {
      final item = await _repository.getSavedItem(itemId);
      if (item == null) {
        return _failure('收藏项不存在', AppFailureCode.notFound);
      }

      final boxIds = await _repository.getBoxIdsForItem(itemId);
      final snapshot = SavedItemUndoSnapshot(
        item: item,
        boxIds: List<int>.from(boxIds),
      );

      switch (mode) {
        case DeleteMode.fullDelete:
          await _repository.deleteSavedItem(itemId);
          _refreshCoordinator?.itemDeleted(itemId);
          final displayTitle = item.title.isEmpty
              ? item.normalizedUrl
              : item.title;
          return CrudResult<void>.success(
            message: '已删除「$displayTitle」',
            undo: CrudUndoAction(
              execute: () async {
                await restoreDeletedItem(snapshot);
              },
            ),
          );

        case DeleteMode.removeFromBox:
          if (boxId == null) {
            return _failure('请指定要移除的收藏夹', AppFailureCode.validation);
          }
          await _repository.removeItemFromBox(itemId, boxId);
          _refreshCoordinator?.itemChanged(
            itemId,
            reason: SavedItemMutationReason.boxes,
          );
          final currentBoxName = boxName ?? '收藏夹';
          return CrudResult<void>.success(
            message: '已从「$currentBoxName」中移除',
            undo: CrudUndoAction(
              execute: () async {
                final currentIds = await _repository.getBoxIdsForItem(itemId);
                await _repository.setItemBoxes(itemId, {...currentIds, boxId});
                await _repository.updateInboxState(itemId, false);
                _refreshCoordinator?.itemChanged(
                  itemId,
                  reason: SavedItemMutationReason.boxes,
                );
              },
            ),
          );
      }
    } catch (error, stackTrace) {
      return _failure(
        '删除收藏项失败',
        AppFailureCode.database,
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<CrudResult<void>> restoreDeletedItem(
    SavedItemUndoSnapshot snapshot,
  ) async {
    try {
      final restored = await _repository.restoreSavedItem(
        snapshot.item,
        snapshot.boxIds,
      );
      _refreshCoordinator?.itemRestored(restored.id);
      final displayTitle = restored.title.isEmpty
          ? restored.originalUrl
          : restored.title;
      return CrudResult<void>.success(message: '已恢复「$displayTitle」');
    } catch (error, stackTrace) {
      return _failure(
        '恢复收藏项失败',
        AppFailureCode.database,
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<CrudResult<void>> retryEnrichment(int itemId) async {
    final queueController = _enrichmentQueueController;
    if (queueController != null) {
      return queueController.retryItem(itemId);
    }

    try {
      await _repository.enqueueEnrichmentJob(itemId);
      unawaited(_enrichmentJobService.runPendingJobs());
      return const CrudResult<void>.success(message: '已重新加入抓取队列');
    } catch (error, stackTrace) {
      return _failure(
        '重试抓取失败',
        AppFailureCode.database,
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<CrudResult<void>> toggleFavorite(int itemId) async {
    return _failure('星标功能稍后接入', AppFailureCode.cancelled);
  }

  CrudResult<void> _failure(
    String message,
    AppFailureCode code, {
    Object? cause,
    StackTrace? stackTrace,
  }) {
    return CrudResult<void>.failure(
      failure: AppFailure(
        code: code,
        message: message,
        cause: cause,
        stackTrace: stackTrace,
      ),
    );
  }
}
