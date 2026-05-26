import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uni_hub/src/core/database/app_database.dart';

import '../data/collections_repository.dart';
import '../data/enrichment_jobs_dao.dart';
import '../domain/enrichment_status.dart';
import 'collection_debug_logger.dart';
import 'metadata_provider.dart';
import 'website_logo_cache_service.dart';

class EnrichmentJobService {
  EnrichmentJobService({
    required CollectionsRepository repository,
    required EnrichmentJobsDao jobsDao,
    required MetadataProvider metadataProvider,
    WebsiteLogoCacheService? logoCacheService,
    this.onLogoCached,
  }) : _repository = repository,
       _jobsDao = jobsDao,
       _metadataProvider = metadataProvider,
       _logoCacheService = logoCacheService;

  final CollectionsRepository _repository;
  final EnrichmentJobsDao _jobsDao;
  final MetadataProvider _metadataProvider;
  final WebsiteLogoCacheService? _logoCacheService;
  static const int _maxAttempts = 3;

  /// Called after every successful logo cache write.
  /// Used to trigger UI refresh of cached logo lookups.
  final VoidCallback? onLogoCached;

  /// 消费 pending job 队列，每轮最多处理 [limit] 个。
  ///
  /// 单个 job 失败不阻断其它 job，异常被捕获并打印日志后继续处理下一个。
  Future<void> runPendingJobs({int limit = 3}) async {
    final jobs = await _jobsDao.getPending(limit: limit);
    CollectionDebugLogger.log(
      'runPendingJobs limit=$limit pendingCount=${jobs.length}',
    );
    for (final job in jobs) {
      try {
        CollectionDebugLogger.log(
          'runPendingJobs start id=${job.id} itemId=${job.itemId} attempts=${job.attempts}',
        );
        await _processJob(job);
      } catch (error) {
        // 单个 job 的不可恢复错误不阻断队列
        CollectionDebugLogger.error(
          'Enrichment job ${job.id} fatal error',
          error,
        );
      }
    }
  }

  Future<void> _processJob(EnrichmentJobsTableData job) async {
    CollectionDebugLogger.log(
      '_processJob start id=${job.id} itemId=${job.itemId} attempts=${job.attempts}',
    );

    final item = await _repository.getSavedItem(job.itemId);
    if (item == null) {
      CollectionDebugLogger.warn(
        '_processJob item not found id=${job.id} itemId=${job.itemId}',
      );
      await _jobsDao.markFailed(job.id, '收藏项不存在');
      return;
    }

    // 标记 running
    CollectionDebugLogger.log('_processJob mark running id=${job.id}');
    await _jobsDao.markRunning(job.id);
    await _repository.updateMetadata(
      job.itemId,
      enrichmentStatus: EnrichmentStatus.running,
    );

    try {
      CollectionDebugLogger.log(
        '_processJob metadata fetch start url=${item.normalizedUrl}',
      );
      final metadata = await _metadataProvider.fetchMetadata(
        item.normalizedUrl,
      );
      CollectionDebugLogger.log(
        '_processJob metadata fetched title=${metadata.title} '
        'hasDescription=${metadata.description != null && metadata.description!.isNotEmpty} '
        'coverImage=${metadata.coverImage} favicon=${metadata.favicon}',
      );

      // 成功
      await _repository.updateMetadata(
        job.itemId,
        title: metadata.title,
        description: metadata.description,
        author: metadata.author,
        siteName: metadata.siteName,
        coverImage: metadata.coverImage,
        favicon: metadata.favicon,
        metadataJson: metadata.metadataJson,
        enrichmentStatus: EnrichmentStatus.success,
      );
      CollectionDebugLogger.log(
        '_processJob updateMetadata success id=${job.id}',
      );

      // Trigger logo caching in the background (non-blocking)
      if (_logoCacheService != null) {
        CollectionDebugLogger.log(
          '_processJob logo cache start itemId=${item.id} pageUrl=${item.normalizedUrl}',
        );
        unawaited(
          _logoCacheService
              .ensureLogoCached(
                pageUrl: item.normalizedUrl,
                remoteFaviconUrl: metadata.favicon,
              )
              .then((entry) {
                CollectionDebugLogger.log(
                  'logo cached itemId=${item.id} siteKey=${entry?.siteKey} path=${entry?.localLogoPath} status=${entry?.status}',
                );
                onLogoCached?.call();
                CollectionDebugLogger.log('websiteLogoRefreshProvider increment');
              })
              .catchError((error, stackTrace) {
                CollectionDebugLogger.error(
                  'logo cache async failed itemId=${item.id}',
                  error,
                  stackTrace,
                );
              }),
        );
      }

      await _jobsDao.markSuccess(job.id);
      CollectionDebugLogger.log('_processJob success id=${job.id}');
    } catch (error) {
      // 失败
      final errorMsg = error.toString();
      final currentAttempts = job.attempts + 1;

      CollectionDebugLogger.error(
        '_processJob failed id=${job.id} attempts=$currentAttempts/$_maxAttempts error=$errorMsg',
        error,
      );

      if (currentAttempts >= _maxAttempts) {
        // 超过最大重试次数，标记永久失败
        CollectionDebugLogger.warn(
          '_processJob permanent fail id=${job.id} (max retries reached)',
        );
        await _jobsDao.markFailed(job.id, errorMsg);
        await _repository.updateMetadata(
          job.itemId,
          enrichmentStatus: EnrichmentStatus.failed,
        );
      } else {
        // 重新入队等待下次重试
        CollectionDebugLogger.log(
          '_processJob requeue id=${job.id} for retry $currentAttempts/$_maxAttempts',
        );
        await _jobsDao.requeue(job.id, errorMsg);
        await _repository.updateMetadata(
          job.itemId,
          enrichmentStatus: EnrichmentStatus.pending,
        );
      }
    }
  }
}
