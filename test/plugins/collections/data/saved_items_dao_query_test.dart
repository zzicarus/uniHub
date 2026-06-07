import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uni_hub/src/core/database/app_database.dart';
import 'package:uni_hub/src/core/plugin/plugin_registry.dart';
import 'package:uni_hub/src/plugins/collections/collections_plugin.dart';
import 'package:uni_hub/src/plugins/collections/data/collection_boxes_dao.dart';
import 'package:uni_hub/src/plugins/collections/data/saved_items_dao.dart';
import 'package:uni_hub/src/plugins/collections/domain/collection_models.dart';
import 'package:uni_hub/src/plugins/collections/domain/consumption_status.dart';
import 'package:uni_hub/src/plugins/collections/domain/media_type.dart';
import 'package:uni_hub/src/plugins/collections/domain/saved_items_query.dart';
import 'package:uni_hub/src/plugins/collections/domain/source_platform.dart';

void main() {
  late AppDatabase db;
  late SavedItemsDao dao;
  late CollectionBoxesDao boxesDao;

  int itemCounter = 0;

  /// Helper to insert a saved item with minimal required fields.
  ///
  /// Each call generates a unique [normalizedUrl] by appending a counter to
  /// the default value to avoid UNIQUE constraint violations.
  Future<int> insertItem({
    String title = '',
    String? description,
    String? author,
    String? siteName,
    String originalUrl = 'https://example.com/item',
    String? normalizedUrl,
    String status = 'unread',
    String mediaType = 'unknown',
    String sourcePlatform = 'unknown',
    bool isInInbox = true,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastOpenedAt,
  }) async {
    itemCounter++;
    final uniqueUrl = normalizedUrl ?? 'https://example.com/item$itemCounter';
    final now = DateTime.now();
    return dao.insert(
      SavedItemsTableCompanion(
        originalUrl: Value(originalUrl),
        normalizedUrl: Value(uniqueUrl),
        title: Value(title),
        description: description != null
            ? Value(description)
            : const Value.absent(),
        author: author != null ? Value(author) : const Value.absent(),
        siteName: siteName != null ? Value(siteName) : const Value.absent(),
        mediaType: Value(mediaType),
        sourcePlatform: Value(sourcePlatform),
        status: Value(status),
        isInInbox: Value(isInInbox),
        createdAt: Value(createdAt ?? now),
        updatedAt: Value(updatedAt ?? now),
        lastOpenedAt: lastOpenedAt != null
            ? Value(lastOpenedAt)
            : const Value.absent(),
      ),
    );
  }

  setUp(() {
    final registry = PluginRegistry()..register(CollectionsPlugin());
    db = AppDatabase(NativeDatabase.memory(), registry);
    dao = SavedItemsDao(db);
    boxesDao = CollectionBoxesDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('queryItemsPage - view filter', () {
    test('returns inbox items (isInInbox && not archived)', () async {
      await insertItem(title: 'Inbox item');
      await insertItem(title: 'Archived', isInInbox: false, status: 'archived');
      await insertItem(
        title: 'Not in inbox',
        isInInbox: false,
      );

      final result = await dao.queryItemsPage(
        const SavedItemsQuery(limit: 100),
      );

      expect(result.map((i) => i.title), contains('Inbox item'));
      expect(result.map((i) => i.title), isNot(contains('Archived')));
      expect(result.map((i) => i.title), isNot(contains('Not in inbox')));
    });

    test('returns all items for all view', () async {
      await insertItem(title: 'A');
      await insertItem(title: 'B', status: 'done');

      final result = await dao.queryItemsPage(
        const SavedItemsQuery(view: CollectionView.all, limit: 100),
      );

      expect(result.length, 2);
    });

    test('returns unread items', () async {
      await insertItem(title: 'Unread');
      await insertItem(title: 'Done', status: 'done');

      final result = await dao.queryItemsPage(
        const SavedItemsQuery(view: CollectionView.unread, limit: 100),
      );

      expect(result.map((i) => i.title), ['Unread']);
    });

    test('returns in-progress items', () async {
      await insertItem(title: 'In Progress 1', status: 'in_progress');
      await insertItem(title: 'In Progress 2', status: 'in_progress');
      await insertItem(title: 'Done', status: 'done');

      final result = await dao.queryItemsPage(
        const SavedItemsQuery(view: CollectionView.inProgress, limit: 100),
      );

      expect(result.map((i) => i.title), ['In Progress 1', 'In Progress 2']);
    });

    test('returns done items', () async {
      await insertItem(title: 'Done', status: 'done');
      await insertItem(title: 'Unread');

      final result = await dao.queryItemsPage(
        const SavedItemsQuery(view: CollectionView.done, limit: 100),
      );

      expect(result.map((i) => i.title), ['Done']);
    });

    test('returns archived items', () async {
      await insertItem(title: 'Archived', status: 'archived');
      await insertItem(title: 'Unread');

      final result = await dao.queryItemsPage(
        const SavedItemsQuery(view: CollectionView.archived, limit: 100),
      );

      expect(result.map((i) => i.title), ['Archived']);
    });
  });

  group('queryItemsPage - status filter', () {
    test('filters by unread status', () async {
      await insertItem(title: 'Unread');
      await insertItem(title: 'Done', status: 'done');

      final result = await dao.queryItemsPage(
        const SavedItemsQuery(
          view: CollectionView.all,
          status: ConsumptionStatus.unread,
          limit: 100,
        ),
      );

      expect(result.map((i) => i.title), ['Unread']);
    });

    test('null status returns all', () async {
      await insertItem(title: 'A');
      await insertItem(title: 'B', status: 'done');
      await insertItem(title: 'C', status: 'archived');

      final result = await dao.queryItemsPage(
        const SavedItemsQuery(view: CollectionView.all, limit: 100),
      );

      expect(result.length, 3);
    });
  });

  group('queryItemsPage - platform filter', () {
    test('filters by platform', () async {
      await insertItem(
        title: 'GitHub',
        sourcePlatform: SourcePlatform.github.value,
      );
      await insertItem(title: 'Web', sourcePlatform: SourcePlatform.web.value);

      final result = await dao.queryItemsPage(
        const SavedItemsQuery(
          view: CollectionView.all,
          platform: SourcePlatform.github,
          limit: 100,
        ),
      );

      expect(result.map((i) => i.title), ['GitHub']);
    });
  });

  group('queryItemsPage - media type filter', () {
    test('filters by media type', () async {
      await insertItem(title: 'Article', mediaType: MediaType.article.value);
      await insertItem(title: 'Video', mediaType: MediaType.video.value);

      final result = await dao.queryItemsPage(
        const SavedItemsQuery(
          view: CollectionView.all,
          mediaType: MediaType.article,
          limit: 100,
        ),
      );

      expect(result.map((i) => i.title), ['Article']);
    });
  });

  group('queryItemsPage - box filter', () {
    test('filters by selected box ids (any-of)', () async {
      final box1Id = await boxesDao.insert(
        CollectionBoxesTableCompanion(
          name: const Value('Box 1'),
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
      );
      final box2Id = await boxesDao.insert(
        CollectionBoxesTableCompanion(
          name: const Value('Box 2'),
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
      );

      final item1Id = await insertItem(title: 'In Box 1');
      final item2Id = await insertItem(title: 'In Box 2');
      await insertItem(title: 'No Box');

      await boxesDao.setItemBoxes(item1Id, {box1Id});
      await boxesDao.setItemBoxes(item2Id, {box2Id});

      final result = await dao.queryItemsPage(
        SavedItemsQuery(
          view: CollectionView.all,
          selectedBoxIds: {box1Id, box2Id},
          limit: 100,
        ),
      );

      expect(result.map((i) => i.title), contains('In Box 1'));
      expect(result.map((i) => i.title), contains('In Box 2'));
      expect(result.map((i) => i.title), isNot(contains('No Box')));
    });
  });

  group('queryItemsPage - search filter', () {
    test('matches title', () async {
      await insertItem(title: 'Flutter 入门教程');
      await insertItem(title: 'Dart 语言指南');

      final result = await dao.queryItemsPage(
        const SavedItemsQuery(
          view: CollectionView.all,
          searchQuery: 'Flutter',
          limit: 100,
        ),
      );

      expect(result.length, 1);
      expect(result.single.title, 'Flutter 入门教程');
    });

    test('matches description', () async {
      await insertItem(title: 'Article', description: '这是一篇关于 Flutter 的文章');
      await insertItem(title: 'Other', description: '无关内容');

      final result = await dao.queryItemsPage(
        const SavedItemsQuery(
          view: CollectionView.all,
          searchQuery: 'Flutter',
          limit: 100,
        ),
      );

      expect(result.length, 1);
      expect(result.single.title, 'Article');
    });

    test('matches original_url', () async {
      await insertItem(
        originalUrl: 'https://flutter.dev/docs',
        normalizedUrl: 'https://flutter.dev/docs',
      );
      await insertItem(
        originalUrl: 'https://example.com',
        normalizedUrl: 'https://example.com',
      );

      final result = await dao.queryItemsPage(
        const SavedItemsQuery(
          view: CollectionView.all,
          searchQuery: 'flutter.dev',
          limit: 100,
        ),
      );

      expect(result.length, 1);
    });

    test('matches site_name', () async {
      await insertItem(title: 'Post', siteName: '掘金');
      await insertItem(title: 'Other', siteName: '知乎');

      final result = await dao.queryItemsPage(
        const SavedItemsQuery(
          view: CollectionView.all,
          searchQuery: '掘金',
          limit: 100,
        ),
      );

      expect(result.length, 1);
      expect(result.single.title, 'Post');
    });

    test('matches author', () async {
      await insertItem(title: 'Book', author: '张三');
      await insertItem(title: 'Another', author: '李四');

      final result = await dao.queryItemsPage(
        const SavedItemsQuery(
          view: CollectionView.all,
          searchQuery: '张三',
          limit: 100,
        ),
      );

      expect(result.length, 1);
      expect(result.single.title, 'Book');
    });

    test('empty search query returns all', () async {
      await insertItem(title: 'A');
      await insertItem(title: 'B');

      final result = await dao.queryItemsPage(
        const SavedItemsQuery(
          view: CollectionView.all,
          limit: 100,
        ),
      );

      expect(result.length, 2);
    });

    test('trims whitespace from search query', () async {
      await insertItem(title: 'Flutter 文章');

      final result = await dao.queryItemsPage(
        const SavedItemsQuery(
          view: CollectionView.all,
          searchQuery: '  Flutter  ',
          limit: 100,
        ),
      );

      expect(result.length, 1);
    });

    test('case-insensitive search', () async {
      await insertItem(title: 'Flutter Framework');

      final result = await dao.queryItemsPage(
        const SavedItemsQuery(
          view: CollectionView.all,
          searchQuery: 'flutter',
          limit: 100,
        ),
      );

      expect(result.length, 1);
    });

    test('treats percent as a literal character', () async {
      await insertItem(title: '100% useful');
      await insertItem(title: '100x useful');

      final result = await dao.queryItemsPage(
        const SavedItemsQuery(
          view: CollectionView.all,
          searchQuery: '%',
          limit: 100,
        ),
      );

      expect(result.map((item) => item.title), ['100% useful']);
    });

    test('treats underscore as a literal character', () async {
      await insertItem(title: 'draft_note');
      await insertItem(title: 'draft-note');

      final result = await dao.queryItemsPage(
        const SavedItemsQuery(
          view: CollectionView.all,
          searchQuery: '_',
          limit: 100,
        ),
      );

      expect(result.map((item) => item.title), ['draft_note']);
    });

    test('treats backslash as a literal character', () async {
      await insertItem(title: r'path\to\note');
      await insertItem(title: 'path/to/note');

      final result = await dao.queryItemsPage(
        const SavedItemsQuery(
          view: CollectionView.all,
          searchQuery: r'\',
          limit: 100,
        ),
      );

      expect(result.map((item) => item.title), [r'path\to\note']);
    });
  });

  group('queryItemsPage - pagination', () {
    test('respects limit', () async {
      for (var i = 0; i < 10; i++) {
        await insertItem(title: 'Item $i');
      }

      final result = await dao.queryItemsPage(
        const SavedItemsQuery(view: CollectionView.all, limit: 3),
      );

      expect(result.length, 3);
    });

    test('respects offset', () async {
      // Insert items with different timestamps for deterministic ordering
      final base = DateTime(2025);
      for (var i = 0; i < 5; i++) {
        await insertItem(
          title: 'Item $i',
          createdAt: base.add(Duration(hours: i)),
          updatedAt: base.add(Duration(hours: i)),
        );
      }

      final page1 = await dao.queryItemsPage(
        const SavedItemsQuery(
          view: CollectionView.all,
          sort: SavedItemsSort.createdAsc,
          limit: 2,
        ),
      );

      final page2 = await dao.queryItemsPage(
        const SavedItemsQuery(
          view: CollectionView.all,
          sort: SavedItemsSort.createdAsc,
          limit: 2,
          offset: 2,
        ),
      );

      expect(page1.length, 2);
      expect(page2.length, 2);
      expect(page1[0].title, 'Item 0');
      expect(page1[1].title, 'Item 1');
      expect(page2[0].title, 'Item 2');
      expect(page2[1].title, 'Item 3');
    });
  });

  group('queryItemsPage - sort', () {
    test('default sort is updatedAt desc, createdAt desc', () async {
      final now = DateTime.now();
      await insertItem(
        title: 'Oldest',
        updatedAt: now.subtract(const Duration(hours: 2)),
      );
      await insertItem(
        title: 'Newest',
        updatedAt: now.subtract(const Duration(hours: 1)),
      );
      await insertItem(
        title: 'Middle',
        updatedAt: now.subtract(const Duration(minutes: 90)),
      );

      final result = await dao.queryItemsPage(
        const SavedItemsQuery(
          view: CollectionView.all,
          limit: 100,
        ),
      );

      expect(result[0].title, 'Newest');
      expect(result[1].title, 'Middle');
      expect(result[2].title, 'Oldest');
    });

    test('titleAsc sort', () async {
      await insertItem(title: 'C Item');
      await insertItem(title: 'A Item');
      await insertItem(title: 'B Item');

      final result = await dao.queryItemsPage(
        const SavedItemsQuery(
          view: CollectionView.all,
          sort: SavedItemsSort.titleAsc,
          limit: 100,
        ),
      );

      expect(result[0].title, 'A Item');
      expect(result[1].title, 'B Item');
      expect(result[2].title, 'C Item');
    });

    test('lastOpenedDesc sort', () async {
      final now = DateTime.now();
      await insertItem(title: 'Just opened', updatedAt: now, lastOpenedAt: now);
      await insertItem(
        title: 'Never opened',
        updatedAt: now.subtract(const Duration(hours: 1)),
      );

      final result = await dao.queryItemsPage(
        const SavedItemsQuery(
          view: CollectionView.all,
          sort: SavedItemsSort.lastOpenedDesc,
          limit: 100,
        ),
      );

      expect(result[0].title, 'Just opened');
    });
  });
}
