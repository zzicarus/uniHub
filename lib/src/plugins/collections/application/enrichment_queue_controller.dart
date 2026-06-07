import 'dart:async';

import 'package:uni_hub/src/plugins/collections/data/enrichment_jobs_dao.dart';
import 'package:uni_hub/src/plugins/collections/services/enrichment_job_service.dart';

import 'package:uni_hub/src/shared/crud/crud.dart';

import 'collections_mutation_event.dart';
import 'collections_refresh_coordinator.dart';

/// 增强 Enrichment 队列恢复能力控制器。
///
/// 提供 runOnce / drainPending / retryItem 三种启动方式：
/// - [runOnce]：单批次消费
/// - [drainPending]：批量多批次消费直至队列清空或达到 [maxBatches]
/// - [retryItem]：为指定项重新入队并触发消费
///
/// 使用 [_isRunning] 防止并发执行。
class EnrichmentQueueController {
  EnrichmentQueueController({
    required EnrichmentJobService jobService,
    required EnrichmentJobsDao jobsDao,
    CollectionsRefreshCoordinator? refreshCoordinator,
  }) : _jobService = jobService,
       _jobsDao = jobsDao,
       _refreshCoordinator = refreshCoordinator;

  final EnrichmentJobService _jobService;
  final EnrichmentJobsDao _jobsDao;
  final CollectionsRefreshCoordinator? _refreshCoordinator;
  bool _isRunning = false;

  /// Run one batch of pending jobs.
  ///
  /// Returns the number of jobs processed.
  Future<int> runOnce({int limit = 5}) async {
    if (_isRunning) return 0;
    _isRunning = true;
    try {
      return await _jobService.runPendingJobs(limit: limit);
    } finally {
      _isRunning = false;
    }
  }

  /// Keep draining pending jobs in batches until the queue is empty
  /// or [maxBatches] is reached.
  ///
  /// Returns the total number of jobs processed across all batches.
  Future<int> drainPending({int batchSize = 5, int maxBatches = 5}) async {
    if (_isRunning) return 0;
    _isRunning = true;
    var totalProcessed = 0;
    try {
      for (var i = 0; i < maxBatches; i++) {
        final processed = await _jobService.runPendingJobs(limit: batchSize);
        totalProcessed += processed;
        if (processed == 0) break;
      }
      return totalProcessed;
    } finally {
      _isRunning = false;
      _refreshCoordinator?.hardReload('enrichment drain completed');
    }
  }

  /// Retry enrichment for a specific item by creating or resetting its job.
  ///
  /// If the item already has a pending or running job, returns immediately
  /// with a message. Otherwise, enqueues a new job and triggers immediate
  /// consumption.
  Future<CrudResult<void>> retryItem(int itemId) async {
    try {
      final existing = await _jobsDao.getPendingForItem(itemId);
      if (existing != null) {
        return const CrudResult<void>.success(message: '该收藏已在抓取队列中');
      }
      await _jobsDao.enqueue(itemId);
      // Process this immediately in the background
      unawaited(_drainAfterRetry(itemId));
      return const CrudResult<void>.success(message: '已重新加入抓取队列');
    } catch (e) {
      return CrudResult<void>.failure(
        failure: AppFailure(
          code: AppFailureCode.database,
          message: '重试失败',
          cause: e,
        ),
      );
    }
  }

  /// Drain pending jobs and then patch the enriched item.
  ///
  /// After enrichment completes we emit a [SavedItemChanged] event so the
  /// list controller can soft-patch the enriched metadata (title, site,
  /// mediaType, etc.).
  Future<void> _drainAfterRetry(int itemId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    await drainPending(maxBatches: 3);
    // After drain, emit an enrichment mutation so the list controller
    // soft-patches this item's metadata and logo.
    _refreshCoordinator?.itemChanged(
      itemId,
      reason: SavedItemMutationReason.enrichment,
    );
  }
}
