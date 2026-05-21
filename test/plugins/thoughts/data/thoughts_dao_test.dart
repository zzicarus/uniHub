import 'package:flutter_test/flutter_test.dart';
// hide avoids ambiguity with `package:test` matchers isNull/isNotNull.
// Use `package:drift`'s .isNull extension on Expression types when needed.
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:uni_hub/src/core/database/app_database.dart';
import 'package:uni_hub/src/core/database/tables/thoughts_table.dart';
import 'package:uni_hub/src/core/plugin/plugin_interface.dart';
import 'package:uni_hub/src/core/plugin/plugin_registry.dart';
import 'package:uni_hub/src/plugins/thoughts/data/thoughts_dao.dart';

class _ThoughtsTablePlugin extends UniHubPlugin {
  @override
  String get id => 'thoughts-test';
  @override
  String get name => 'Thoughts Test';
  @override
  List<Type> get tables => [ThoughtsTable];
  @override
  int get schemaVersion => 2;
}

void main() {
  late AppDatabase db;
  late ThoughtsDao dao;

  setUp(() {
    final registry = PluginRegistry();
    registry.register(_ThoughtsTablePlugin());
    db = AppDatabase(NativeDatabase.memory(), registry);
    dao = ThoughtsDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('ThoughtsDao', () {
    group('insert and getById', () {
      test('inserts a thought and retrieves it by id', () async {
        final now = DateTime.now();
        final id = await dao.insert(
          ThoughtsTableCompanion(
            content: const Value('Test thought'),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

        final result = await dao.getById(id);
        expect(result, isNotNull);
        expect(result!.content, 'Test thought');
        expect(result.tags, isNull);
        expect(result.isPinned, false);
        expect(result.archivedAt, isNull);
      });

      test('inserts a thought with tags and color', () async {
        final now = DateTime.now();
        final id = await dao.insert(
          ThoughtsTableCompanion(
            content: const Value('Tagged thought'),
            tags: const Value('flutter,dart'),
            color: const Value('#2563EB'),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

        final result = await dao.getById(id);
        expect(result!.tags, 'flutter,dart');
        expect(result.color, '#2563EB');
      });

      test('getById returns null for non-existent id', () async {
        final result = await dao.getById(999);
        expect(result, isNull);
      });
    });

    group('getAll', () {
      test('returns empty list when no thoughts exist', () async {
        final results = await dao.getAll();
        expect(results, isEmpty);
      });

      test(
        'returns thoughts ordered by isPinned desc, createdAt desc',
        () async {
          final now = DateTime.now();
          await dao.insert(
            ThoughtsTableCompanion(
              content: const Value('First'),
              createdAt: Value(now.subtract(const Duration(minutes: 10))),
              updatedAt: Value(now.subtract(const Duration(minutes: 10))),
            ),
          );
          await dao.insert(
            ThoughtsTableCompanion(
              content: const Value('Second'),
              createdAt: Value(now.subtract(const Duration(minutes: 5))),
              updatedAt: Value(now.subtract(const Duration(minutes: 5))),
            ),
          );

          final results = await dao.getAll();
          expect(results, hasLength(2));
          expect(results[0].content, 'Second');
          expect(results[1].content, 'First');
        },
      );

      test('pinned items come first', () async {
        final now = DateTime.now();
        await dao.insert(
          ThoughtsTableCompanion(
            content: const Value('Normal'),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

        await dao.insert(
          ThoughtsTableCompanion(
            content: const Value('Pinned'),
            isPinned: const Value(true),
            createdAt: Value(now.subtract(const Duration(hours: 1))),
            updatedAt: Value(now.subtract(const Duration(hours: 1))),
          ),
        );

        final results = await dao.getAll();
        expect(results, hasLength(2));
        expect(results[0].content, 'Pinned');
        expect(results[1].content, 'Normal');
      });

      test('getAll with archived=true returns only archived', () async {
        final now = DateTime.now();
        await dao.insert(
          ThoughtsTableCompanion(
            content: const Value('Active'),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

        await dao.insert(
          ThoughtsTableCompanion(
            content: const Value('Archived'),
            createdAt: Value(now.subtract(const Duration(hours: 1))),
            updatedAt: Value(now.subtract(const Duration(hours: 1))),
            archivedAt: Value(now.subtract(const Duration(minutes: 30))),
          ),
        );

        final activeResults = await dao.getAll(archived: false);
        expect(activeResults, hasLength(1));
        expect(activeResults[0].content, 'Active');

        final archivedResults = await dao.getAll(archived: true);
        expect(archivedResults, hasLength(1));
        expect(archivedResults[0].content, 'Archived');
      });
    });

    group('updateById', () {
      test('updates thought content', () async {
        final now = DateTime.now();
        final id = await dao.insert(
          ThoughtsTableCompanion(
            content: const Value('Original'),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

        await dao.updateById(
          id,
          ThoughtsTableCompanion(
            content: const Value('Updated'),
            updatedAt: Value(DateTime.now()),
          ),
        );

        final result = await dao.getById(id);
        expect(result!.content, 'Updated');
      });

      test('updates multiple fields', () async {
        final now = DateTime.now();
        final id = await dao.insert(
          ThoughtsTableCompanion(
            content: const Value('Original'),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

        await dao.updateById(
          id,
          ThoughtsTableCompanion(
            content: const Value('Updated'),
            tags: const Value('new,tags'),
            updatedAt: Value(DateTime.now()),
          ),
        );

        final result = await dao.getById(id);
        expect(result!.content, 'Updated');
        expect(result.tags, 'new,tags');
      });
    });

    group('delete', () {
      test('deletes a thought', () async {
        final now = DateTime.now();
        final id = await dao.insert(
          ThoughtsTableCompanion(
            content: const Value('To delete'),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

        await dao.delete(id);
        final result = await dao.getById(id);
        expect(result, isNull);
      });
    });

    group('archive and restore', () {
      test('archive sets archivedAt', () async {
        final now = DateTime.now();
        final id = await dao.insert(
          ThoughtsTableCompanion(
            content: const Value('To archive'),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

        await dao.archive(id);
        final result = await dao.getById(id);
        expect(result!.archivedAt, isNotNull);
      });

      test('restore clears archivedAt', () async {
        final now = DateTime.now();
        final id = await dao.insert(
          ThoughtsTableCompanion(
            content: const Value('To archive and restore'),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

        await dao.archive(id);
        final archived = await dao.getById(id);
        expect(archived!.archivedAt, isNotNull);

        await dao.restore(id);
        final restored = await dao.getById(id);
        expect(restored!.archivedAt, isNull);
      });
    });

    group('togglePin', () {
      test('pins and unpins a thought', () async {
        final now = DateTime.now();
        final id = await dao.insert(
          ThoughtsTableCompanion(
            content: const Value('Toggle pin'),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

        await dao.togglePin(id, true);
        var result = await dao.getById(id);
        expect(result!.isPinned, true);

        await dao.togglePin(id, false);
        result = await dao.getById(id);
        expect(result!.isPinned, false);
      });
    });
  });
}
