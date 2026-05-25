import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uni_hub/src/core/database/app_database.dart';
import 'package:uni_hub/src/core/plugin/plugin_registry.dart';
import 'package:uni_hub/src/plugins/collections/collections_plugin.dart';
import 'package:uni_hub/src/plugins/collections/data/saved_items_dao.dart';

void main() {
  late AppDatabase db;
  late SavedItemsDao dao;

  setUp(() {
    final registry = PluginRegistry()..register(CollectionsPlugin());
    db = AppDatabase(NativeDatabase.memory(), registry);
    dao = SavedItemsDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('insert and retrieve by id', () async {
    final now = DateTime.now();
    final id = await dao.insert(
      SavedItemsTableCompanion(
        originalUrl: Value('https://example.com/test'),
        normalizedUrl: Value('https://example.com/test'),
        title: const Value('Test Item'),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );

    final item = await dao.getById(id);
    expect(item, isNotNull);
    expect(item!.title, 'Test Item');
    expect(item.originalUrl, 'https://example.com/test');
  });

  test('findByNormalizedUrl returns null for non-existent', () async {
    final item = await dao.findByNormalizedUrl('https://example.com/missing');
    expect(item, isNull);
  });

  test('findByNormalizedUrl returns matching item', () async {
    final now = DateTime.now();
    await dao.insert(
      SavedItemsTableCompanion(
        originalUrl: Value('https://example.com/unique'),
        normalizedUrl: Value('https://example.com/unique'),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );

    final item = await dao.findByNormalizedUrl('https://example.com/unique');
    expect(item, isNotNull);
    expect(item!.normalizedUrl, 'https://example.com/unique');
  });

  test('getAll returns items ordered by updatedAt desc', () async {
    final now = DateTime.now();
    final id1 = await dao.insert(
      SavedItemsTableCompanion(
        originalUrl: Value('https://example.com/old'),
        normalizedUrl: Value('https://example.com/old'),
        createdAt: Value(now),
        updatedAt: Value(now.subtract(const Duration(hours: 2))),
      ),
    );
    final id2 = await dao.insert(
      SavedItemsTableCompanion(
        originalUrl: Value('https://example.com/new'),
        normalizedUrl: Value('https://example.com/new'),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );

    final items = await dao.getAll();
    expect(items.length, greaterThanOrEqualTo(2));
    // newest first
    expect(items.first.id, id2);
    expect(items[1].id, id1);
  });

  test('updateById modifies fields', () async {
    final now = DateTime.now();
    final id = await dao.insert(
      SavedItemsTableCompanion(
        originalUrl: Value('https://example.com/update'),
        normalizedUrl: Value('https://example.com/update'),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );

    await dao.updateById(
      id,
      SavedItemsTableCompanion(
        title: const Value('Updated Title'),
        updatedAt: Value(DateTime.now()),
      ),
    );

    final item = await dao.getById(id);
    expect(item!.title, 'Updated Title');
  });

  test('updateLastOpenedAt sets lastOpenedAt', () async {
    final now = DateTime.now();
    final id = await dao.insert(
      SavedItemsTableCompanion(
        originalUrl: Value('https://example.com/opened'),
        normalizedUrl: Value('https://example.com/opened'),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );

    final openedAt = DateTime.now().add(const Duration(hours: 1));
    await dao.updateLastOpenedAt(id, openedAt);

    final item = await dao.getById(id);
    expect(item!.lastOpenedAt, isNotNull);
    // drift stores with microsecond precision; compare by ignoring sub-second
    expect(item.lastOpenedAt!.difference(openedAt).inSeconds, 0);
  });

  test('deleteById removes the item', () async {
    final now = DateTime.now();
    final id = await dao.insert(
      SavedItemsTableCompanion(
        originalUrl: Value('https://example.com/delete-me'),
        normalizedUrl: Value('https://example.com/delete-me'),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );

    await dao.deleteById(id);

    final item = await dao.getById(id);
    expect(item, isNull);
  });
}
