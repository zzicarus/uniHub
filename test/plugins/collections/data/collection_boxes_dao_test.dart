import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uni_hub/src/core/database/app_database.dart';
import 'package:uni_hub/src/core/plugin/plugin_registry.dart';
import 'package:uni_hub/src/plugins/collections/collections_plugin.dart';
import 'package:uni_hub/src/plugins/collections/data/collection_boxes_dao.dart';
import 'package:uni_hub/src/plugins/collections/data/saved_items_dao.dart';

void main() {
  late AppDatabase db;
  late CollectionBoxesDao dao;
  late SavedItemsDao savedItemsDao;

  setUp(() {
    final registry = PluginRegistry()..register(CollectionsPlugin());
    db = AppDatabase(NativeDatabase.memory(), registry);
    dao = CollectionBoxesDao(db);
    savedItemsDao = SavedItemsDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('CollectionBoxesDao', () {
    test('getAll returns boxes sorted by sortOrder then name', () async {
      final now = DateTime.now();
      await dao.insert(
        CollectionBoxesTableCompanion(
          name: const Value('B Box'),
          sortOrder: const Value(2),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      await dao.insert(
        CollectionBoxesTableCompanion(
          name: const Value('A Box'),
          sortOrder: const Value(1),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      await dao.insert(
        CollectionBoxesTableCompanion(
          name: const Value('C Box'),
          sortOrder: const Value(1),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      final boxes = await dao.getAll();
      expect(boxes.length, greaterThanOrEqualTo(3));
      // sortOrder=1 first, then alphabetical within same sortOrder
      expect(boxes[0].name, 'A Box');
      expect(boxes[1].name, 'C Box');
      expect(boxes[2].name, 'B Box');
    });

    test('getById returns null for non-existent id', () async {
      final box = await dao.getById(999);
      expect(box, isNull);
    });

    test('getById returns matching box', () async {
      final now = DateTime.now();
      final id = await dao.insert(
        CollectionBoxesTableCompanion(
          name: const Value('收藏夹'),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      final box = await dao.getById(id);
      expect(box, isNotNull);
      expect(box!.name, '收藏夹');
      expect(box.id, id);
    });

    test('setItemBoxes replaces existing assignments', () async {
      final now = DateTime.now();
      final itemId = await savedItemsDao.insert(
        SavedItemsTableCompanion(
          originalUrl: Value('https://example.com/box-test'),
          normalizedUrl: Value('https://example.com/box-test'),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      final box1 = await dao.insert(
        CollectionBoxesTableCompanion(
          name: const Value('Box 1'),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      final box2 = await dao.insert(
        CollectionBoxesTableCompanion(
          name: const Value('Box 2'),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      // 分配两个 Box
      await dao.setItemBoxes(itemId, {box1, box2});
      var boxIds = await dao.getBoxIdsForItem(itemId);
      expect(boxIds, hasLength(2));
      expect(boxIds, containsAll([box1, box2]));

      // 改为只分配一个 Box（替换）
      await dao.setItemBoxes(itemId, {box1});
      boxIds = await dao.getBoxIdsForItem(itemId);
      expect(boxIds, [box1]);

      // 清空所有 Box
      await dao.setItemBoxes(itemId, {});
      boxIds = await dao.getBoxIdsForItem(itemId);
      expect(boxIds, isEmpty);
    });

    test('getBoxIdsForItems returns multiple items', () async {
      final now = DateTime.now();
      final item1 = await savedItemsDao.insert(
        SavedItemsTableCompanion(
          originalUrl: Value('https://example.com/1'),
          normalizedUrl: Value('https://example.com/1'),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      final item2 = await savedItemsDao.insert(
        SavedItemsTableCompanion(
          originalUrl: Value('https://example.com/2'),
          normalizedUrl: Value('https://example.com/2'),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      final box1 = await dao.insert(
        CollectionBoxesTableCompanion(
          name: const Value('Shared'),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      await dao.setItemBoxes(item1, {box1});
      await dao.setItemBoxes(item2, {box1});

      final result = await dao.getBoxIdsForItems({item1, item2});
      expect(result[item1], [box1]);
      expect(result[item2], [box1]);
    });
  });
}
