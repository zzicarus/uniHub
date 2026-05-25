import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uni_hub/src/core/database/app_database.dart';
import 'package:uni_hub/src/core/database/database_provider.dart';
import 'package:uni_hub/src/core/database/tables/thoughts_table.dart';
import 'package:uni_hub/src/core/plugin/plugin_interface.dart';
import 'package:uni_hub/src/core/plugin/plugin_registry.dart';
import 'package:uni_hub/src/plugins/thoughts/data/thought_content_codec.dart';
import 'package:uni_hub/src/plugins/thoughts/providers/thought_status_filter.dart';
import 'package:uni_hub/src/plugins/thoughts/providers/thoughts_providers.dart';
import 'package:uni_hub/src/shared/editor/appflowy_document_tools.dart';

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
  group('Thoughts provider chain', () {
    late AppDatabase db;
    late ProviderContainer container;
    late _SeededThoughts seeded;

    setUp(() async {
      final registry = PluginRegistry()..register(_ThoughtsTablePlugin());
      db = AppDatabase(NativeDatabase.memory(), registry);
      seeded = await _seedThoughts(db);
      container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          pluginRegistryProvider.overrideWithValue(registry),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    test(
      'composes archive, status, tag, then debounced search filters',
      () async {
        container.read(archiveFilterProvider.notifier).state = false;
        container.read(thoughtStatusFilterProvider.notifier).state =
            ThoughtStatusFilter.pinned;
        container.read(selectedTagFiltersProvider.notifier).state = {'work'};
        container.read(thoughtSearchQueryProvider.notifier).state = 'ALPHA';

        final thoughts = await container.read(thoughtsListProvider.future);

        expect(thoughts.map((thought) => thought.id), [seeded.alphaPinnedWork]);
        expect(container.read(thoughtsCountProvider), 1);
      },
    );

    test('multi-tag filter uses intersection semantics', () async {
      final id = await _insertThought(
        db,
        content: 'Focused work note',
        tags: 'work,focus',
        createdAt: DateTime.now(),
      );
      container.invalidate(allThoughtsProvider);
      container.read(selectedTagFiltersProvider.notifier).state = {
        'work',
        'focus',
      };

      final thoughts = await container.read(thoughtsListProvider.future);

      expect(thoughts.map((thought) => thought.id), [id]);
    });

    test('repository can rename and delete tags globally', () async {
      final repo = container.read(thoughtsRepositoryProvider);
      container.read(selectedTagFiltersProvider.notifier).state = {'personal'};

      final renamed = await repo.renameTag('personal', 'life');
      container
          .read(selectedTagFiltersProvider.notifier)
          .state = renameTagInFilter(
        container.read(selectedTagFiltersProvider),
        'personal',
        'life',
      );
      container.invalidate(allThoughtsProvider);
      await container.read(allThoughtsProvider.future);

      expect(renamed, 2);
      expect(container.read(selectedTagFiltersProvider), {'life'});
      expect(
        container.read(commonTagsProvider).map((entry) => entry.key),
        contains('life'),
      );
      expect(
        container.read(commonTagsProvider).map((entry) => entry.key),
        isNot(contains('personal')),
      );

      final deleted = await repo.deleteTagEverywhere('image');
      container.invalidate(allThoughtsProvider);
      await container.read(allThoughtsProvider.future);

      expect(deleted, 1);
      final personalImage = await repo.getThought(seeded.personalImage);
      expect(personalImage?.tags, 'life');
    });

    test('archived status filter selects the archive bucket', () async {
      container.read(archiveFilterProvider.notifier).state = false;
      container.read(thoughtStatusFilterProvider.notifier).state =
          ThoughtStatusFilter.archived;

      final thoughts = await container.read(thoughtsListProvider.future);
      await Future<void>.delayed(Duration.zero);

      expect(thoughts.map((thought) => thought.id), [seeded.archivedWork]);
      expect(container.read(archiveFilterProvider), isTrue);
    });

    test(
      'search matches plain text content and tags case-insensitively',
      () async {
        container.read(thoughtSearchQueryProvider.notifier).state = 'PERSONAL';

        final byTag = await container.read(thoughtsListProvider.future);
        // Search matches both tags and content case-insensitively.
        // 'Pinned personal note' (content) and 'personal,image' (tag) both match.
        expect(byTag.map((thought) => thought.id), [
          seeded.pinnedPersonal,
          seeded.personalImage,
        ]);

        container.read(thoughtSearchQueryProvider.notifier).state = 'beta';
        container.invalidate(thoughtsListProvider);

        final byContent = await container.read(thoughtsListProvider.future);
        expect(byContent.map((thought) => thought.id), [
          seeded.betaUntaggedOld,
        ]);
      },
    );

    test(
      'withImages status uses image metadata without changing schema',
      () async {
        container.read(thoughtStatusFilterProvider.notifier).state =
            ThoughtStatusFilter.withImages;

        final thoughts = await container.read(thoughtsListProvider.future);

        expect(thoughts.map((thought) => thought.id), [seeded.personalImage]);
      },
    );

    test('multi-tag filter uses all semantics (intersection) by default', () async {
      // Verifies that tags must ALL match — the shared TagFilterLogic default.
      final id = await _insertThought(
        db,
        content: 'Work + focus note',
        tags: 'work,focus',
        createdAt: DateTime.now(),
      );
      container.invalidate(allThoughtsProvider);

      // Both 'work' and 'focus' → should match
      container.read(selectedTagFiltersProvider.notifier).state = {
        'work',
        'focus',
      };
      var thoughts = await container.read(thoughtsListProvider.future);
      expect(thoughts.map((thought) => thought.id), contains(id));

      // Only 'work' and a non-existent tag → should NOT match
      container.read(selectedTagFiltersProvider.notifier).state = {
        'work',
        'nonexistent',
      };
      container.invalidate(thoughtsListProvider);
      thoughts = await container.read(thoughtsListProvider.future);
      expect(thoughts.map((thought) => thought.id), isNot(contains(id)));
    });

    test('commonTagsProvider sorts by count descending', () async {
      // Ensure allThoughtsProvider resolves before reading commonTagsProvider.
      await container.read(allThoughtsProvider.future);

      // Seed: personal=2, work=1, image=1 (archived excluded)
      // Expected order by count desc, then name asc: personal > image > work
      var tags = container.read(commonTagsProvider);
      expect(tags.length, greaterThanOrEqualTo(3));
      expect(tags[0].key, 'personal');
      expect(tags[0].value, 2);
      expect(tags[1].key, 'image');
      expect(tags[1].value, 1);
      expect(tags[2].key, 'work');
      expect(tags[2].value, 1);

      // Add three thoughts with the same tag → often count becomes 3
      for (var i = 0; i < 3; i++) {
        await _insertThought(
          db,
          content: 'Often tagged note $i',
          tags: 'often',
          createdAt: DateTime.now(),
        );
      }
      container.invalidate(allThoughtsProvider);
      await container.read(allThoughtsProvider.future);
      tags = container.read(commonTagsProvider);
      expect(tags[0].key, 'often');
      expect(tags[0].value, 3);
    });

    test('selectedTagFiltersProvider filters thoughtsListProvider', () async {
      // Ensure async providers are resolved.
      await container.read(allThoughtsProvider.future);

      // Initially no filter → all unarchived thoughts visible.
      var thoughts = await container.read(thoughtsListProvider.future);
      expect(thoughts.length, greaterThanOrEqualTo(5));

      // Apply a tag filter → only matching thoughts remain.
      container.read(selectedTagFiltersProvider.notifier).state = {'image'};
      container.invalidate(thoughtsListProvider);
      thoughts = await container.read(thoughtsListProvider.future);
      expect(thoughts.length, 1);
      expect(thoughts.first.id, seeded.personalImage);

      // Clear filter → all thoughts visible again.
      container.read(selectedTagFiltersProvider.notifier).state =
          const <String>{};
      container.invalidate(thoughtsListProvider);
      thoughts = await container.read(thoughtsListProvider.future);
      expect(thoughts.length, greaterThanOrEqualTo(5));
    });

    test('right rail providers ignore tag and search filters', () async {
      container.read(selectedTagFiltersProvider.notifier).state = {'personal'};
      container.read(thoughtSearchQueryProvider.notifier).state = 'no-match';

      final pinned = await container.read(pinnedThoughtsProvider.future);
      final pending = await container.read(pendingReviewProvider.future);
      final commonTags = container.read(commonTagsProvider);
      final randomReview = await container.read(randomReviewProvider.future);

      expect(pinned.map((thought) => thought.id), [
        seeded.pinnedPersonal,
        seeded.pinnedNoTag,
        seeded.alphaPinnedWork,
      ]);
      expect(pending.map((thought) => thought.id), [
        seeded.pinnedNoTag,
        seeded.betaUntaggedOld,
      ]);
      expect(commonTags.map((entry) => entry.key), [
        'personal',
        'image',
        'work',
      ]);
      expect(randomReview?.id, seeded.betaUntaggedOld);
    });
  });
}

Future<_SeededThoughts> _seedThoughts(AppDatabase db) async {
  final now = DateTime.now();
  final alphaPinnedWork = await _insertThought(
    db,
    content: 'Alpha launch plan',
    tags: 'work',
    isPinned: true,
    createdAt: now.subtract(const Duration(days: 1)),
  );
  final personalImage = await _insertThought(
    db,
    content: 'Gallery notes',
    tags: 'personal,image',
    imagePaths: '["/tmp/image.png"]',
    createdAt: now.subtract(const Duration(days: 2)),
  );
  final betaUntaggedOld = await _insertThought(
    db,
    content: 'Beta review candidate',
    createdAt: now.subtract(const Duration(days: 8)),
  );
  final archivedWork = await _insertThought(
    db,
    content: 'Archived alpha work',
    tags: 'work',
    createdAt: now.subtract(const Duration(days: 3)),
    archivedAt: now.subtract(const Duration(days: 1)),
  );
  final pinnedNoTag = await _insertThought(
    db,
    content: 'Pinned without tags',
    isPinned: true,
    createdAt: now.subtract(const Duration(hours: 12)),
  );
  final pinnedPersonal = await _insertThought(
    db,
    content: 'Pinned personal note',
    tags: 'personal',
    isPinned: true,
    createdAt: now.subtract(const Duration(hours: 6)),
  );

  return _SeededThoughts(
    alphaPinnedWork: alphaPinnedWork,
    personalImage: personalImage,
    betaUntaggedOld: betaUntaggedOld,
    archivedWork: archivedWork,
    pinnedNoTag: pinnedNoTag,
    pinnedPersonal: pinnedPersonal,
  );
}

String _appFlowyContent(String plainText) {
  return ThoughtContentCodec.encodeAppFlowy(
    document: AppFlowyDocumentTools.documentJsonFromPlainText(plainText),
    plainText: plainText,
  );
}

Future<int> _insertThought(
  AppDatabase db, {
  required String content,
  String? tags,
  bool isPinned = false,
  String? imagePaths,
  DateTime? createdAt,
  DateTime? archivedAt,
}) {
  final timestamp = createdAt ?? DateTime.now();
  return db
      .into(db.thoughtsTable)
      .insert(
        ThoughtsTableCompanion(
          content: Value(_appFlowyContent(content)),
          tags: Value(tags),
          isPinned: Value(isPinned),
          imagePaths: Value(imagePaths),
          createdAt: Value(timestamp),
          updatedAt: Value(timestamp),
          archivedAt: Value(archivedAt),
        ),
      );
}

class _SeededThoughts {
  final int alphaPinnedWork;
  final int personalImage;
  final int betaUntaggedOld;
  final int archivedWork;
  final int pinnedNoTag;
  final int pinnedPersonal;

  const _SeededThoughts({
    required this.alphaPinnedWork,
    required this.personalImage,
    required this.betaUntaggedOld,
    required this.archivedWork,
    required this.pinnedNoTag,
    required this.pinnedPersonal,
  });
}
