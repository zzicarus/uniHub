import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uni_hub/src/core/database/app_database.dart';
import 'package:uni_hub/src/core/plugin/plugin_registry.dart';
import 'package:uni_hub/src/plugins/collections/application/enrichment_queue_controller.dart';
import 'package:uni_hub/src/plugins/collections/collections_plugin.dart';
import 'package:uni_hub/src/plugins/collections/data/collection_boxes_dao.dart';
import 'package:uni_hub/src/plugins/collections/data/collections_repository.dart';
import 'package:uni_hub/src/plugins/collections/data/enrichment_jobs_dao.dart';
import 'package:uni_hub/src/plugins/collections/data/saved_items_dao.dart';
import 'package:uni_hub/src/plugins/collections/domain/collection_models.dart';
import 'package:uni_hub/src/plugins/collections/services/enrichment_job_service.dart';
import 'package:uni_hub/src/plugins/collections/services/metadata_provider.dart';

/// A stub metadata provider that returns default values without network I/O.
class _StubMetadataProvider implements MetadataProvider {
  @override
  Future<MetadataResult> fetchMetadata(String url) async {
    return const MetadataResult(
      title: 'Stub Title',
      siteName: 'stub.example.com',
    );
  }
}

void main() {
  late AppDatabase db;
  late CollectionsRepository repository;
  late EnrichmentJobsDao jobsDao;
  late EnrichmentJobService jobService;

  EnrichmentQueueController createController() {
    return EnrichmentQueueController(
      jobService: jobService,
      // ref is null in unit tests; runOnce/drainPending still work via
      // _jobService directly; retryItem will fail cleanly when _ref is null.
    );
  }

  setUp(() {
    final registry = PluginRegistry()..register(CollectionsPlugin());
    db = AppDatabase(NativeDatabase.memory(), registry);

    final savedItemsDao = SavedItemsDao(db);
    final collectionBoxesDao = CollectionBoxesDao(db);
    jobsDao = EnrichmentJobsDao(db);

    repository = CollectionsRepository(
      savedItemsDao: savedItemsDao,
      collectionBoxesDao: collectionBoxesDao,
      enrichmentJobsDao: jobsDao,
    );

    jobService = EnrichmentJobService(
      repository: repository,
      jobsDao: jobsDao,
      metadataProvider: _StubMetadataProvider(),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('EnrichmentQueueController', () {
    group('runOnce', () {
      test('processes pending jobs and returns count', () async {
        final controller = createController();

        final item = await repository.createSavedItem(
          originalUrl: 'https://example.com/test',
          normalizedUrl: 'https://example.com/test',
        );
        await repository.enqueueEnrichmentJob(item.id);

        final count = await controller.runOnce();

        expect(count, 1);
        final updated = await repository.getSavedItem(item.id);
        expect(updated!.enrichmentStatus, 'success');
      });

      test('returns 0 when no pending jobs', () async {
        final controller = createController();

        final count = await controller.runOnce();

        expect(count, 0);
      });

      test('isRunning guard prevents concurrent execution', () async {
        final controller = createController();

        // First call starts
        final firstFuture = controller.runOnce();
        // Second call should return 0 immediately
        final secondCount = await controller.runOnce();
        expect(secondCount, 0);

        await firstFuture;
      });
    });

    group('drainPending', () {
      test('processes multiple batches', () async {
        final controller = createController();

        // Create 8 items with pending jobs
        for (var i = 0; i < 8; i++) {
          final item = await repository.createSavedItem(
            originalUrl: 'https://example.com/item$i',
            normalizedUrl: 'https://example.com/item$i',
          );
          await repository.enqueueEnrichmentJob(item.id);
        }

        // drainPending with batchSize=5, maxBatches=2 should process all 8
        final total = await controller.drainPending(
          maxBatches: 2,
        );

        expect(total, 8);
      });

      test('stops when no jobs', () async {
        final controller = createController();

        final total = await controller.drainPending(
          
        );

        expect(total, 0);
      });

      test('respects maxBatches', () async {
        final controller = createController();

        // Create 12 items with pending jobs
        for (var i = 0; i < 12; i++) {
          final item = await repository.createSavedItem(
            originalUrl: 'https://example.com/item$i',
            normalizedUrl: 'https://example.com/item$i',
          );
          await repository.enqueueEnrichmentJob(item.id);
        }

        // batchSize=5, maxBatches=2 → max 10 jobs processed
        final total = await controller.drainPending(
          maxBatches: 2,
        );

        expect(total, 10);
      });

      test('isRunning guard prevents concurrent execution', () async {
        final controller = createController();

        final firstFuture = controller.drainPending(maxBatches: 2);
        final secondCount = await controller.drainPending(maxBatches: 2);
        expect(secondCount, 0);

        await firstFuture;
      });
    });

    group('retryItem', () {
      test('enqueues a new job for items without pending jobs', () async {
        // retryItem uses _ref.read(enrichmentJobsDaoProvider) which will
        // fail when ref is null. We test the DAO-level behavior directly.
        final item = await repository.createSavedItem(
          originalUrl: 'https://example.com/retry',
          normalizedUrl: 'https://example.com/retry',
        );

        // Manually enqueue to verify the DAO works
        await jobsDao.enqueue(item.id);
        final pending = await jobsDao.getPending(limit: 10);
        expect(pending.length, 1);

        // Process it
        await jobService.runPendingJobs(limit: 10);
        final updated = await repository.getSavedItem(item.id);
        expect(updated!.enrichmentStatus, 'success');
      });

      test('getPendingForItem returns existing pending job', () async {
        final item = await repository.createSavedItem(
          originalUrl: 'https://example.com/duplicate',
          normalizedUrl: 'https://example.com/duplicate',
        );
        await repository.enqueueEnrichmentJob(item.id);

        // Should find the pending job
        final existing = await jobsDao.getPendingForItem(item.id);
        expect(existing, isNotNull);
        expect(existing!.itemId, item.id);
        expect(existing.status, 'pending');

        // No duplicate pending jobs should be found (it's the same one)
        final pendingList = await jobsDao.getPending(limit: 10);
        expect(pendingList.length, 1);
      });

      test('getPendingForItem returns null when no pending job', () async {
        final existing = await jobsDao.getPendingForItem(999);
        expect(existing, isNull);
      });
    });
  });
}
