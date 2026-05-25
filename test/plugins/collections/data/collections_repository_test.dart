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
import 'package:uni_hub/src/plugins/collections/domain/consumption_status.dart';
import 'package:uni_hub/src/plugins/collections/domain/media_type.dart';
import 'package:uni_hub/src/plugins/collections/domain/source_platform.dart';

void main() {
  late AppDatabase db;
  late CollectionsRepository repository;

  setUp(() {
    final registry = PluginRegistry()..register(CollectionsPlugin());
    db = AppDatabase(NativeDatabase.memory(), registry);
    repository = CollectionsRepository(
      savedItemsDao: SavedItemsDao(db),
      collectionBoxesDao: CollectionBoxesDao(db),
      enrichmentJobsDao: EnrichmentJobsDao(db),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('CollectionsRepository', () {
    test('creates a saved item and deduplicates normalized URL', () async {
      final first = await repository.createSavedItem(
        originalUrl: 'https://example.com/read',
        normalizedUrl: 'https://example.com/read',
        mediaType: MediaType.article,
        sourcePlatform: SourcePlatform.web,
      );
      final second = await repository.createSavedItem(
        originalUrl: 'https://example.com/read#section',
        normalizedUrl: 'https://example.com/read',
      );

      expect(second.id, first.id);
      expect(second.normalizedUrl, 'https://example.com/read');
    });

    test('filters by view, status, platform, media type and query', () async {
      final article = await repository.createSavedItem(
        originalUrl: 'https://example.com/article',
        normalizedUrl: 'https://example.com/article',
        title: 'Flutter article',
        mediaType: MediaType.article,
        sourcePlatform: SourcePlatform.web,
      );
      await repository.createSavedItem(
        originalUrl: 'https://github.com/flutter/flutter',
        normalizedUrl: 'https://github.com/flutter/flutter',
        title: 'Flutter repository',
        mediaType: MediaType.repository,
        sourcePlatform: SourcePlatform.github,
      );
      await repository.updateStatus(article.id, ConsumptionStatus.done);

      final result = await repository.queryItems(
        view: CollectionView.done,
        platform: SourcePlatform.web,
        mediaType: MediaType.article,
        query: 'article',
      );

      expect(result, hasLength(1));
      expect(result.single.id, article.id);
    });

    test('filters by assigned Box ids', () async {
      final box = await repository.createBox('待读');
      final matched = await repository.createSavedItem(
        originalUrl: 'https://example.com/boxed',
        normalizedUrl: 'https://example.com/boxed',
        title: 'Boxed item',
      );
      await repository.createSavedItem(
        originalUrl: 'https://example.com/unboxed',
        normalizedUrl: 'https://example.com/unboxed',
        title: 'Unboxed item',
      );
      await repository.setItemBoxes(matched.id, {box.id});

      final result = await repository.queryItems(
        view: CollectionView.all,
        boxIds: {box.id},
      );

      expect(result.map((item) => item.id), [matched.id]);
    });

    test('marks opened and updates status timestamps', () async {
      final item = await repository.createSavedItem(
        originalUrl: 'https://example.com/video',
        normalizedUrl: 'https://example.com/video',
      );

      await repository.markOpened(item.id);
      await repository.updateStatus(item.id, ConsumptionStatus.archived);

      final updated = await repository.getSavedItem(item.id);
      expect(updated!.lastOpenedAt, isNotNull);
      expect(updated.archivedAt, isNotNull);
      expect(updated.status, ConsumptionStatus.archived.value);
    });

    test('updateStatus does not modify isInInbox', () async {
      final item = await repository.createSavedItem(
        originalUrl: 'https://example.com/test-inbox',
        normalizedUrl: 'https://example.com/test-inbox',
      );

      await repository.updateInboxState(item.id, false);
      await repository.updateStatus(item.id, ConsumptionStatus.done);

      final updated = await repository.getSavedItem(item.id);
      expect(updated!.isInInbox, false);
      expect(updated.status, ConsumptionStatus.done.value);
      expect(updated.completedAt, isNotNull);
    });

    test('filters by Box ids using OR semantics', () async {
      final box1 = await repository.createBox('Box OR 1');
      final box2 = await repository.createBox('Box OR 2');

      final itemA = await repository.createSavedItem(
        originalUrl: 'https://example.com/a',
        normalizedUrl: 'https://example.com/a',
      );
      final itemB = await repository.createSavedItem(
        originalUrl: 'https://example.com/b',
        normalizedUrl: 'https://example.com/b',
      );
      final itemC = await repository.createSavedItem(
        originalUrl: 'https://example.com/c',
        normalizedUrl: 'https://example.com/c',
      );

      await repository.setItemBoxes(itemA.id, {box1.id});
      await repository.setItemBoxes(itemB.id, {box2.id});

      final result = await repository.queryItems(
        view: CollectionView.all,
        boxIds: {box1.id, box2.id},
      );

      expect(result.any((e) => e.id == itemA.id), isTrue);
      expect(result.any((e) => e.id == itemB.id), isTrue);
      expect(result.any((e) => e.id == itemC.id), isFalse);
    });

    test('deletes saved item and related data', () async {
      final box = await repository.createBox('Test Box');
      final item = await repository.createSavedItem(
        originalUrl: 'https://example.com/delete-all',
        normalizedUrl: 'https://example.com/delete-all',
        title: 'To be deleted',
      );
      await repository.setItemBoxes(item.id, {box.id});
      await repository.enqueueEnrichmentJob(item.id);

      // Confirm item exists
      expect(await repository.getSavedItem(item.id), isNotNull);
      expect(await repository.getBoxIdsForItem(item.id), isNotEmpty);

      await repository.deleteSavedItem(item.id);

      // Item should be gone
      expect(await repository.getSavedItem(item.id), isNull);
      // Box assignments should be cleaned up
      expect(await repository.getBoxIdsForItem(item.id), isEmpty);
    });
  });
}
