import 'package:flutter/foundation.dart';
import 'package:uni_hub/src/core/database/app_database.dart';

import '../data/collections_repository.dart';
import '../data/enrichment_jobs_dao.dart';
import '../domain/enrichment_status.dart';
import 'metadata_provider.dart';

class EnrichmentJobService {
  EnrichmentJobService({
    required CollectionsRepository repository,
    required EnrichmentJobsDao jobsDao,
    required MetadataProvider metadataProvider,
  }) : _repository = repository,
       _jobsDao = jobsDao,
       _metadataProvider = metadataProvider;

  final CollectionsRepository _repository;
  final EnrichmentJobsDao _jobsDao;
  final MetadataProvider _metadataProvider;

  /// 消费 pending job 队列，每轮最多处理 [limit] 个。
  ///
  /// 单个 job 失败不阻断其它 job，异常被捕获并打印日志后继续处理下一个。
  Future<void> runPendingJobs({int limit = 3}) async {
    final jobs = await _jobsDao.getPending(limit: limit);
    for (final job in jobs) {
      try {
        await _processJob(job);
      } catch (error) {
        // 单个 job 的不可恢复错误不阻断队列
        debugPrint('Enrichment job ${job.id} failed: $error');
      }
    }
  }

  Future<void> _processJob(EnrichmentJobsTableData job) async {
    final item = await _repository.getSavedItem(job.itemId);
    if (item == null) {
      await _jobsDao.markFailed(job.id, '收藏项不存在');
      return;
    }

    // 标记 running
    await _jobsDao.markRunning(job.id);
    await _repository.updateMetadata(
      job.itemId,
      enrichmentStatus: EnrichmentStatus.running,
    );

    try {
      final metadata = await _metadataProvider.fetchMetadata(
        item.normalizedUrl,
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
      await _jobsDao.markSuccess(job.id);
    } catch (error) {
      // 失败
      final errorMsg = error.toString();
      final currentAttempts = job.attempts + 1;

      if (currentAttempts >= 3) {
        // 超过最大重试次数，标记永久失败
        await _jobsDao.markFailed(job.id, errorMsg);
        await _repository.updateMetadata(
          job.itemId,
          enrichmentStatus: EnrichmentStatus.failed,
        );
      } else {
        // 重新入队等待下次重试
        await _jobsDao.requeue(job.id, errorMsg);
        await _repository.updateMetadata(
          job.itemId,
          enrichmentStatus: EnrichmentStatus.pending,
        );
      }
    }
  }
}
