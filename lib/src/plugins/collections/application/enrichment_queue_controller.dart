import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uni_hub/src/plugins/collections/providers/collections_providers.dart';
import 'package:uni_hub/src/plugins/collections/services/enrichment_job_service.dart';

import 'saved_item_action_result.dart';

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
    Ref? ref,
  })  : _jobService = jobService,
        _ref = ref;

  final EnrichmentJobService _jobService;
  final Ref? _ref;
  bool _isRunning = false;

  void _invalidateLists() {
    _ref?.invalidate(savedItemsPageProvider);
    _ref?.read(websiteLogoRefreshProvider.notifier).state++;
  }

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
  Future<int> drainPending({
    int batchSize = 5,
    int maxBatches = 5,
  }) async {
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
      _invalidateLists();
    }
  }

  /// Retry enrichment for a specific item by creating or resetting its job.
  ///
  /// If the item already has a pending or running job, returns immediately
  /// with a message. Otherwise, enqueues a new job and triggers immediate
  /// consumption.
  Future<SavedItemActionResult> retryItem(int itemId) async {
    try {
      final jobsDao = _ref?.read(enrichmentJobsDaoProvider);
      if (jobsDao == null) {
        return const SavedItemActionResult(
          success: false,
          message: 'EnrichmentQueueController 未初始化',
        );
      }
      final existing = await jobsDao.getPendingForItem(itemId);
      if (existing != null) {
        return const SavedItemActionResult(
          success: true,
          message: '该收藏已在抓取队列中',
        );
      }
      await jobsDao.enqueue(itemId);
      // Process this immediately in the background
      unawaited(_drainAfterRetry());
      return const SavedItemActionResult(
        success: true,
        message: '已重新加入抓取队列',
      );
    } catch (e) {
      return SavedItemActionResult(
        success: false,
        message: '重试失败：${e.toString()}',
        error: e,
      );
    }
  }

  Future<void> _drainAfterRetry() async {
    // Small delay so the UI can show the updated state
    await Future.delayed(const Duration(milliseconds: 100));
    await drainPending(batchSize: 5, maxBatches: 3);
  }
}
