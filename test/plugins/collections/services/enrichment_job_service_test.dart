import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uni_hub/src/core/database/app_database.dart';
import 'package:uni_hub/src/core/plugin/plugin_registry.dart';
import 'package:uni_hub/src/plugins/collections/collections_plugin.dart';
import 'package:uni_hub/src/plugins/collections/data/collection_boxes_dao.dart';
import 'package:uni_hub/src/plugins/collections/data/collections_repository.dart';
import 'package:uni_hub/src/plugins/collections/data/enrichment_jobs_dao.dart';
import 'package:uni_hub/src/plugins/collections/data/saved_items_dao.dart';
import 'package:uni_hub/src/plugins/collections/domain/collection_models.dart';
import 'package:uni_hub/src/plugins/collections/domain/enrichment_status.dart';
import 'package:uni_hub/src/plugins/collections/services/enrichment_job_service.dart';
import 'package:uni_hub/src/plugins/collections/services/metadata_provider.dart';

/// 返回固定结果或固定异常的 mock MetadataProvider。
class _MockMetadataProvider implements MetadataProvider {
  _MockMetadataProvider({this.result, this.error});

  final MetadataResult? result;
  final Exception? error;

  @override
  Future<MetadataResult> fetchMetadata(String url) async {
    if (error != null) throw error!;
    return result ?? const MetadataResult(title: 'Mock Title');
  }
}

/// 按调用序列返回结果的 mock（用于单 job 失败不阻断其它 job 的场景）。
class _SequenceMetadataProvider implements MetadataProvider {
  _SequenceMetadataProvider(this._handler);

  final Future<MetadataResult> Function(String url) _handler;

  @override
  Future<MetadataResult> fetchMetadata(String url) => _handler(url);
}

void main() {
  late AppDatabase db;
  late CollectionsRepository repository;
  late EnrichmentJobsDao jobsDao;

  setUp(() {
    final registry = PluginRegistry()..register(CollectionsPlugin());
    db = AppDatabase(NativeDatabase.memory(), registry);
    repository = CollectionsRepository(
      savedItemsDao: SavedItemsDao(db),
      collectionBoxesDao: CollectionBoxesDao(db),
      enrichmentJobsDao: EnrichmentJobsDao(db),
    );
    jobsDao = EnrichmentJobsDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('runPendingJobs', () {
    test('成功抓取 metadata 并更新 item 和 job', () async {
      final service = EnrichmentJobService(
        repository: repository,
        jobsDao: jobsDao,
        metadataProvider: _MockMetadataProvider(
          result: const MetadataResult(
            title: 'Test Title',
            description: 'Test Desc',
            favicon: 'https://example.com/favicon.ico',
          ),
        ),
      );

      final item = await repository.createSavedItem(
        originalUrl: 'https://example.com/article',
        normalizedUrl: 'https://example.com/article',
      );
      await repository.enqueueEnrichmentJob(item.id);

      await service.runPendingJobs(limit: 3);

      // item 的 enrichment 状态和 metadata 已更新
      final updated = await repository.getSavedItem(item.id);
      expect(updated!.enrichmentStatus, EnrichmentStatus.success.value);
      expect(updated.title, 'Test Title');
      expect(updated.description, 'Test Desc');
      expect(updated.favicon, 'https://example.com/favicon.ico');

      // job 状态为 success
      final job = await jobsDao.getById(1);
      expect(job!.status, 'success');
      expect(job.finishedAt, isNotNull);
    });

    test('失败后重试（attempts < 3 时保持 pending）', () async {
      final service = EnrichmentJobService(
        repository: repository,
        jobsDao: jobsDao,
        metadataProvider: _MockMetadataProvider(
          error: Exception('网络错误'),
        ),
      );

      final item = await repository.createSavedItem(
        originalUrl: 'https://example.com/fail',
        normalizedUrl: 'https://example.com/fail',
      );
      await repository.enqueueEnrichmentJob(item.id);

      await service.runPendingJobs(limit: 3);

      // job 状态为 pending，等待下次重试
      final job = await jobsDao.getById(1);
      expect(job!.status, 'pending');
      expect(job.attempts, 1);
      expect(job.errorMessage, isNotNull);

      // item 的 enrichmentStatus 回到 pending
      final savedItem = await repository.getSavedItem(item.id);
      expect(savedItem!.enrichmentStatus, EnrichmentStatus.pending.value);
    });

    test('失败三次后标记永久 failed', () async {
      final service = EnrichmentJobService(
        repository: repository,
        jobsDao: jobsDao,
        metadataProvider: _MockMetadataProvider(
          error: Exception('持久失败'),
        ),
      );

      final item = await repository.createSavedItem(
        originalUrl: 'https://example.com/fail3',
        normalizedUrl: 'https://example.com/fail3',
      );
      await repository.enqueueEnrichmentJob(item.id);

      // 第 1 次：attempts → 1，requeue
      await service.runPendingJobs(limit: 3);
      // 第 2 次：attempts → 2，requeue
      await service.runPendingJobs(limit: 3);
      // 第 3 次：attempts → 3，failed
      await service.runPendingJobs(limit: 3);

      final job = await jobsDao.getById(1);
      expect(job!.status, 'failed');
      expect(job.attempts, 3);
      expect(job.finishedAt, isNotNull);

      // item 标记为永久失败
      final savedItem = await repository.getSavedItem(item.id);
      expect(savedItem!.enrichmentStatus, EnrichmentStatus.failed.value);
    });

    test('单个 job 失败不阻断其它 job', () async {
      final item1 = await repository.createSavedItem(
        originalUrl: 'https://example.com/fail1',
        normalizedUrl: 'https://example.com/fail1',
      );
      final item2 = await repository.createSavedItem(
        originalUrl: 'https://example.com/ok2',
        normalizedUrl: 'https://example.com/ok2',
      );

      await repository.enqueueEnrichmentJob(item1.id);
      await repository.enqueueEnrichmentJob(item2.id);

      int callCount = 0;
      final service = EnrichmentJobService(
        repository: repository,
        jobsDao: jobsDao,
        metadataProvider: _SequenceMetadataProvider((url) async {
          callCount++;
          if (callCount == 1) throw Exception('job1 失败');
          return const MetadataResult(title: 'Job2 Success');
        }),
      );

      await service.runPendingJobs(limit: 2);

      // job1 失败 → requeued
      final job1 = await jobsDao.getById(1);
      expect(job1!.status, 'pending');
      expect(job1.attempts, 1);

      // job2 成功
      final job2 = await jobsDao.getById(2);
      expect(job2!.status, 'success');

      final item2Updated = await repository.getSavedItem(item2.id);
      expect(item2Updated!.enrichmentStatus, EnrichmentStatus.success.value);
    });
  });
}
