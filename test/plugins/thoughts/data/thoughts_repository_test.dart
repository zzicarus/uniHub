import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:uni_hub/src/core/database/app_database.dart';
import 'package:uni_hub/src/plugins/thoughts/data/thoughts_dao.dart';
import 'package:uni_hub/src/plugins/thoughts/data/thoughts_repository.dart';

void main() {
  late AppDatabase db;
  late ThoughtsDao dao;
  late ThoughtsRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = ThoughtsDao(db);
    repo = ThoughtsRepository(dao);
  });

  tearDown(() async {
    await db.close();
  });

  group('ThoughtsRepository', () {
    group('createThought', () {
      test('creates a thought and returns it', () async {
        final thought = await repo.createThought(content: 'Hello world');

        expect(thought.content, 'Hello world');
        expect(thought.id, greaterThan(0));
        expect(thought.isPinned, false);
        expect(thought.archivedAt, isNull);
      });

      test('creates a thought with tags', () async {
        final thought = await repo.createThought(
          content: 'Tagged',
          tags: 'flutter,dart,riverpod',
        );

        expect(thought.tags, 'flutter,dart,riverpod');
      });

      test('creates a pinned thought', () async {
        // createThought doesn't accept isPinned,
        // so create then pin
        final thought = await repo.createThought(content: 'Pinned later');
        expect(thought.isPinned, false);

        await repo.togglePin(thought.id, true);
        final updated = await repo.getThought(thought.id);
        expect(updated!.isPinned, true);
      });
    });

    group('getThoughts', () {
      test('returns empty list when no thoughts', () async {
        final thoughts = await repo.getThoughts();
        expect(thoughts, isEmpty);
      });

      test('returns active thoughts only by default', () async {
        final t1 = await repo.createThought(content: 'Active 1');
        final t2 = await repo.createThought(content: 'Active 2');
        await repo.createThought(content: 'Should be archived');
        await repo.archiveThought(t2.id); // archive t2

        final active = await repo.getThoughts(archived: false);
        expect(active, hasLength(2));
        expect(active.any((t) => t.id == t1.id), true);
      });

      test('returns archived thoughts when archived=true', () async {
        final t1 = await repo.createThought(content: 'Archived');
        await repo.archiveThought(t1.id);

        final archived = await repo.getThoughts(archived: true);
        expect(archived, hasLength(1));
        expect(archived[0].content, 'Archived');
      });
    });

    group('updateThought', () {
      test('updates content', () async {
        final thought = await repo.createThought(content: 'Original');
        await repo.updateThought(thought.id, content: 'Updated');
        final updated = await repo.getThought(thought.id);
        expect(updated!.content, 'Updated');
      });

      test('updates tags', () async {
        final thought = await repo.createThought(content: 'Taggable');
        await repo.updateThought(thought.id, tags: 'new,tag');
        final updated = await repo.getThought(thought.id);
        expect(updated!.tags, 'new,tag');
      });
    });

    group('deleteThought', () {
      test('hard deletes a thought', () async {
        final thought = await repo.createThought(content: 'Delete me');
        await repo.deleteThought(thought.id);
        final result = await repo.getThought(thought.id);
        expect(result, isNull);
      });
    });

    group('archiveThought and restoreThought', () {
      test('archive sets archivedAt, restore clears it', () async {
        final thought = await repo.createThought(content: 'Archive test');
        expect(thought.archivedAt, isNull);

        await repo.archiveThought(thought.id);
        final archived = await repo.getThought(thought.id);
        expect(archived!.archivedAt, isNotNull);

        await repo.restoreThought(thought.id);
        final restored = await repo.getThought(thought.id);
        expect(restored!.archivedAt, isNull);
      });
    });

    group('togglePin', () {
      test('toggles pin state', () async {
        final thought = await repo.createThought(content: 'Pin test');
        expect(thought.isPinned, false);

        await repo.togglePin(thought.id, true);
        final pinned = await repo.getThought(thought.id);
        expect(pinned!.isPinned, true);

        await repo.togglePin(thought.id, false);
        final unpinned = await repo.getThought(thought.id);
        expect(unpinned!.isPinned, false);
      });
    });
  });
}
