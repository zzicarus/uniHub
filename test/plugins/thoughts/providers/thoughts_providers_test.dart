import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uni_hub/src/core/database/app_database.dart';
import 'package:uni_hub/src/core/database/database_provider.dart';
import 'package:uni_hub/src/core/database/tables/thoughts_table.dart';
import 'package:uni_hub/src/core/plugin/plugin_interface.dart';
import 'package:uni_hub/src/core/plugin/plugin_registry.dart';
import 'package:uni_hub/src/core/storage/app_storage_paths.dart';
import 'package:uni_hub/src/core/storage/providers/storage_providers.dart';
import 'package:uni_hub/src/plugins/thoughts/data/thought_content_codec.dart';
import 'package:uni_hub/src/plugins/thoughts/providers/thought_status_filter.dart';
import 'package:uni_hub/src/plugins/thoughts/providers/thoughts_providers.dart';
import 'package:uni_hub/src/shared/editor/appflowy_document_tools.dart';
import 'package:uni_hub/src/shared/tags/domain/tag_color_token.dart';
import 'package:uni_hub/src/shared/tags/providers/tags_providers.dart';

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
    late Directory tempDir;

    setUp(() async {
      tempDir = Directory.systemTemp.createTempSync('thoughts_providers_test_');
      final testPaths = AppStoragePaths(
        documentsDir: tempDir,
        cacheDir: tempDir,
      );

      final registry = PluginRegistry()..register(_ThoughtsTablePlugin());
      db = AppDatabase(NativeDatabase.memory(), registry);
      seeded = await _seedThoughts(db);
      container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          pluginRegistryProvider.overrideWithValue(registry),
          appStoragePathsProvider.overrideWith((ref) => Future.value(testPaths)),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
      await db.close();
      try { tempDir.deleteSync(recursive: true); } catch (_) {}
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

    test('tags dao can rename and delete tags globally', () async {
      final tagsDao = container.read(tagsDaoProvider);
      container.read(selectedTagFiltersProvider.notifier).state = {'personal'};

      final personalTag = await tagsDao.getTagByNormalizedName('personal');
      expect(personalTag, isNotNull);

      await tagsDao.renameTag(personalTag!.id, 'life');
      container
          .read(selectedTagFiltersProvider.notifier)
          .state = renameTagInFilter(
        container.read(selectedTagFiltersProvider),
        'personal',
        'life',
      );
      container.invalidate(allThoughtsProvider);
      container.invalidate(tagStatsProvider);
      await container.read(allThoughtsProvider.future);
      await container.read(tagStatsProvider.future);

      expect(container.read(selectedTagFiltersProvider), {'life'});
      expect(
        container.read(commonTagsProvider).map((entry) => entry.key),
        contains('life'),
      );
      expect(
        container.read(commonTagsProvider).map((entry) => entry.key),
        isNot(contains('personal')),
      );

      final imageTag = await tagsDao.getTagByNormalizedName('image');
      expect(imageTag, isNotNull);
      await tagsDao.deleteTag(imageTag!.id);
      container.invalidate(allThoughtsProvider);
      container.invalidate(tagStatsProvider);
      await container.read(allThoughtsProvider.future);
      await container.read(tagStatsProvider.future);

      expect(
        container.read(commonTagsProvider).map((entry) => entry.key),
        isNot(contains('image')),
      );
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
      // Ensure both allThoughtsProvider and tagStatsProvider resolve.
      await container.read(allThoughtsProvider.future);
      await container.read(tagStatsProvider.future);

      // tagStatsProvider counts ALL thought_tags rows (ignores archive status):
      //   personal=2 (pinnedPersonal + personalImage)
      //   work=2 (alphaPinnedWork + archivedWork)
      //   image=1 (personalImage)
      // Order: personal(2) > work(2) > image(1)
      var tags = container.read(commonTagsProvider);
      expect(tags.length, greaterThanOrEqualTo(3));
      expect(tags[0].key, 'personal');
      expect(tags[0].value, 2);
      expect(tags[1].key, 'work');
      expect(tags[1].value, 2);
      expect(tags[2].key, 'image');
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
      container.invalidate(tagStatsProvider);
      await container.read(allThoughtsProvider.future);
      await container.read(tagStatsProvider.future);
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
      await container.read(tagStatsProvider.future);
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
        'work',
        'image',
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
}) async {
  final timestamp = createdAt ?? DateTime.now();
  final id = await db.into(db.thoughtsTable).insert(
    ThoughtsTableCompanion(
      content: Value(_appFlowyContent(content)),
      isPinned: Value(isPinned),
      imagePaths: Value(imagePaths),
      createdAt: Value(timestamp),
      updatedAt: Value(timestamp),
      archivedAt: Value(archivedAt),
    ),
  );

  if (tags != null && tags.trim().isNotEmpty) {
    final now = DateTime.now();
    for (final raw in tags.split(',')) {
      final name = raw.trim();
      if (name.isEmpty) continue;
      final normalized = name.toLowerCase();
      final existing = await (db.select(db.tagsTable)
            ..where((t) => t.normalizedName.equals(normalized)))
          .getSingleOrNull();
      final tagId = existing?.id ??
          await db.into(db.tagsTable).insert(
            TagsTableCompanion(
              name: Value(name),
              normalizedName: Value(normalized),
              colorToken: Value(TagColorToken.assign(name).value),
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );
      await db.into(db.thoughtTagsTable).insert(
        ThoughtTagsTableCompanion(
          thoughtId: Value(id),
          tagId: Value(tagId),
          createdAt: Value(now),
        ),
        mode: InsertMode.insertOrIgnore,
      );
    }
  }

  return id;
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
