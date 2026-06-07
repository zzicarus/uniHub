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
import 'package:uni_hub/src/plugins/collections/domain/saved_items_query.dart';
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

  group('queryItems page result', () {
    test('returns SavedItemsPage with correct items', () async {
      await repository.createSavedItem(
        originalUrl: 'https://example.com/a',
        normalizedUrl: 'https://example.com/a',
        title: 'Item A',
      );

      final page = await repository.queryItems(
        const SavedItemsQuery(view: CollectionView.all),
      );

      expect(page.items, hasLength(1));
      expect(page.items.single.title, 'Item A');
      expect(page.hasMore, isFalse);
    });

    test('hasMore is true when there are more items than limit', () async {
      for (var i = 0; i < 5; i++) {
        await repository.createSavedItem(
          originalUrl: 'https://example.com/item$i',
          normalizedUrl: 'https://example.com/item$i',
          title: 'Item $i',
        );
      }

      final page = await repository.queryItems(
        const SavedItemsQuery(view: CollectionView.all, limit: 3),
      );

      expect(page.items, hasLength(3));
      expect(page.hasMore, isTrue);
    });

    test('hasMore is false when items equal limit', () async {
      for (var i = 0; i < 3; i++) {
        await repository.createSavedItem(
          originalUrl: 'https://example.com/item$i',
          normalizedUrl: 'https://example.com/item$i',
          title: 'Item $i',
        );
      }

      final page = await repository.queryItems(
        const SavedItemsQuery(view: CollectionView.all, limit: 3),
      );

      expect(page.items, hasLength(3));
      // Equal to limit, should be false
      expect(page.hasMore, isFalse);
    });
  });

  group('queryItems boxIdsByItemId', () {
    test('only contains box IDs for current page items', () async {
      final box = await repository.createBox('Test Box');

      final page1Item = await repository.createSavedItem(
        originalUrl: 'https://example.com/page1',
        normalizedUrl: 'https://example.com/page1',
        title: 'Page 1',
      );
      final page2Item = await repository.createSavedItem(
        originalUrl: 'https://example.com/page2',
        normalizedUrl: 'https://example.com/page2',
        title: 'Page 2',
      );

      await repository.setItemBoxes(page1Item.id, {box.id});

      // Query with limit=1, so only page1Item should be returned
      final page = await repository.queryItems(
        const SavedItemsQuery(view: CollectionView.all, limit: 1),
      );

      expect(page.items, hasLength(1));
      expect(page.items.single.id, page1Item.id);
      expect(page.boxIdsByItemId.keys, contains(page1Item.id));
      expect(page.boxIdsByItemId.keys, isNot(contains(page2Item.id)));
      expect(page.boxIdsByItemId[page1Item.id], contains(box.id));
    });

    test('works for items without boxes', () async {
      await repository.createSavedItem(
        originalUrl: 'https://example.com/nobox',
        normalizedUrl: 'https://example.com/nobox',
        title: 'No Box',
      );

      final page = await repository.queryItems(
        const SavedItemsQuery(view: CollectionView.all),
      );

      expect(page.items, hasLength(1));
      // Items without boxes are absent from boxIdsByItemId
      final boxIds = page.boxIdsByItemId[page.items.single.id];
      expect(boxIds, isNull);
    });
  });

  group('queryItems multi-condition filter', () {
    test('status + platform + mediaType combined', () async {
      await repository.createSavedItem(
        originalUrl: 'https://github.com/flutter',
        normalizedUrl: 'https://github.com/flutter',
        title: 'Flutter Repo',
        mediaType: MediaType.repository,
        sourcePlatform: SourcePlatform.github,
      );
      await repository.createSavedItem(
        originalUrl: 'https://example.com/article',
        normalizedUrl: 'https://example.com/article',
        title: 'Web Article',
        mediaType: MediaType.article,
        sourcePlatform: SourcePlatform.web,
      );

      final page = await repository.queryItems(
        const SavedItemsQuery(
          view: CollectionView.all,
          platform: SourcePlatform.github,
          mediaType: MediaType.repository,
        ),
      );

      expect(page.items, hasLength(1));
      expect(page.items.single.title, 'Flutter Repo');
    });

    test('search + box combined', () async {
      final box = await repository.createBox('Flutter Box');

      final matched = await repository.createSavedItem(
        originalUrl: 'https://flutter.dev',
        normalizedUrl: 'https://flutter.dev',
        title: 'Flutter 官方文档',
      );
      await repository.createSavedItem(
        originalUrl: 'https://example.com',
        normalizedUrl: 'https://example.com',
        title: '其他内容',
      );
      await repository.setItemBoxes(matched.id, {box.id});

      // Unboxed item with matching title should not appear
      await repository.createSavedItem(
        originalUrl: 'https://flutter.dev/other',
        normalizedUrl: 'https://flutter.dev/other',
        title: 'Flutter 第三方',
      );

      final page = await repository.queryItems(
        SavedItemsQuery(
          view: CollectionView.all,
          selectedBoxIds: {box.id},
          searchQuery: 'Flutter',
        ),
      );

      expect(page.items, hasLength(1));
      expect(page.items.single.id, matched.id);
    });
  });

  group('queryItems regression - matches old semantics', () {
    test('inbox items match expected semantics', () async {
      // Item in inbox, unread → should match
      await repository.createSavedItem(
        originalUrl: 'https://example.com/inbox',
        normalizedUrl: 'https://example.com/inbox',
        title: 'Inbox Unread',
      );
      // Item in inbox, done → should match
      final inboxDone = await repository.createSavedItem(
        originalUrl: 'https://example.com/inbox-done',
        normalizedUrl: 'https://example.com/inbox-done',
        title: 'Inbox Done',
      );
      await repository.updateStatus(inboxDone.id, ConsumptionStatus.done);

      // Item archived → should NOT match (inbox = isInInbox AND NOT archived)
      final archivedItem = await repository.createSavedItem(
        originalUrl: 'https://example.com/archived',
        normalizedUrl: 'https://example.com/archived',
        title: 'Archived',
      );
      await repository.updateStatus(archivedItem.id, ConsumptionStatus.archived);

      // Item not in inbox → should NOT match
      await repository.createSavedItem(
        originalUrl: 'https://example.com/not-in-inbox',
        normalizedUrl: 'https://example.com/not-in-inbox',
        title: 'Not In Inbox',
        isInInbox: false,
      );

      // Item archived + not in inbox → should NOT match
      await repository.createSavedItem(
        originalUrl: 'https://example.com/archived-out',
        normalizedUrl: 'https://example.com/archived-out',
        title: 'Archived Out',
        isInInbox: false,
      );
      // Mark as archived after creation
      final archivedOut = await repository.findByNormalizedUrl(
        'https://example.com/archived-out',
      );
      if (archivedOut != null) {
        await repository.updateStatus(archivedOut.id, ConsumptionStatus.archived);
      }

      final page = await repository.queryItems(
        const SavedItemsQuery(limit: 100),
      );

      final titles = page.items.map((i) => i.title).toSet();
      expect(titles, contains('Inbox Unread'));
      expect(titles, contains('Inbox Done'));
      expect(titles, isNot(contains('Archived')));
      expect(titles, isNot(contains('Not In Inbox')));
      expect(titles, isNot(contains('Archived Out')));
    });

    test('all view returns everything', () async {
      await repository.createSavedItem(
        originalUrl: 'https://example.com/a',
        normalizedUrl: 'https://example.com/a',
        title: 'A',
      );
      await repository.createSavedItem(
        originalUrl: 'https://example.com/b',
        normalizedUrl: 'https://example.com/b',
        title: 'B',
      );
      await repository.createSavedItem(
        originalUrl: 'https://example.com/c',
        normalizedUrl: 'https://example.com/c',
        title: 'C',
      );

      final page = await repository.queryItems(
        const SavedItemsQuery(view: CollectionView.all, limit: 100),
      );

      expect(page.items, hasLength(3));
    });

    test('archived view correctly excludes non-archived', () async {
      await repository.createSavedItem(
        originalUrl: 'https://example.com/unread',
        normalizedUrl: 'https://example.com/unread',
        title: 'Unread',
      );
      final doneItem = await repository.createSavedItem(
        originalUrl: 'https://example.com/done',
        normalizedUrl: 'https://example.com/done',
        title: 'Done',
      );
      await repository.updateStatus(doneItem.id, ConsumptionStatus.done);
      final archivedItem = await repository.createSavedItem(
        originalUrl: 'https://example.com/archived',
        normalizedUrl: 'https://example.com/archived',
        title: 'Archived',
      );
      await repository.updateStatus(archivedItem.id, ConsumptionStatus.archived);

      final page = await repository.queryItems(
        const SavedItemsQuery(view: CollectionView.archived, limit: 100),
      );

      expect(page.items, hasLength(1));
      expect(page.items.single.title, 'Archived');
    });
  });
}
