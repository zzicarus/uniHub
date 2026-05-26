import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uni_hub/src/core/database/app_database.dart';
import 'package:uni_hub/src/core/database/database_provider.dart';
import 'package:uni_hub/src/core/storage/providers/storage_providers.dart';
import '../data/file_image_storage.dart';
import '../data/image_picker_service.dart';
import '../data/image_storage.dart';
import '../data/platform_image_picker.dart';
import '../data/thought_content_codec.dart';
import '../data/thought_deletion_service.dart';
import '../data/thought_image_service.dart';
import '../data/thoughts_dao.dart';
import '../data/thoughts_repository.dart';
import 'package:uni_hub/src/shared/tags/tag_codec.dart';
import 'package:uni_hub/src/shared/tags/tag_filter_logic.dart';
import 'package:uni_hub/src/shared/tags/tag_models.dart';
import 'thought_status_filter.dart';

final thoughtsDaoProvider = Provider<ThoughtsDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return ThoughtsDao(db);
});

final thoughtsRepositoryProvider = Provider<ThoughtsRepository>((ref) {
  final dao = ref.watch(thoughtsDaoProvider);
  return ThoughtsRepository(dao);
});

final imagePickerServiceProvider = Provider<ImagePickerService>((ref) {
  return PlatformImagePicker();
});

final imageStorageProvider = FutureProvider<ImageStorage>((ref) async {
  final storagePaths = await ref.watch(appStoragePathsProvider.future);
  return FileImageStorage(imagesDir: storagePaths.thoughtImagesDir);
});

final thoughtImageServiceProvider = FutureProvider<ThoughtImageService>((ref) async {
  final storage = await ref.watch(imageStorageProvider.future);
  return ThoughtImageService(
    picker: ref.watch(imagePickerServiceProvider),
    storage: storage,
  );
});

/// 安全删除想法及其附件的协调服务。
///
/// 返回 null 当 [thoughtImageServiceProvider] 尚未完成初始化时。
final thoughtDeletionServiceProvider = Provider<ThoughtDeletionService?>((ref) {
  final imageService = ref.watch(thoughtImageServiceProvider).valueOrNull;
  if (imageService == null) return null;

  final repository = ref.watch(thoughtsRepositoryProvider);
  return ThoughtDeletionService(
    repository: repository,
    imageService: imageService,
  );
});

/// 启动时迁移：若 [AppStoragePaths] 在构造期重命名了旧的
/// `thought_images` 目录，则将 DB 中所有 imagePaths 的前缀
/// 从旧路径替换为新路径。
///
/// 无迁移需求时不执行任何操作。
final thoughtImageMigrationProvider = FutureProvider<void>((ref) async {
  final paths = await ref.watch(appStoragePathsProvider.future);
  final migrations = paths.thoughtImageMigrations;
  if (migrations.isEmpty) return;

  final repo = ref.read(thoughtsRepositoryProvider);
  final active = await repo.getThoughts();
  final archived = await repo.getThoughts(archived: true);
  final allThoughts = [...active, ...archived];

  for (final thought in allThoughts) {
    final oldPaths = thought.imagePaths;
    if (oldPaths == null || oldPaths.isEmpty) continue;

    var updated = oldPaths;
    var changed = false;
    for (final entry in migrations.entries) {
      if (updated.contains(entry.key)) {
        updated = updated.replaceAll(entry.key, entry.value);
        changed = true;
      }
    }

    if (changed) {
      await repo.updateThought(thought.id, imagePaths: updated);
    }
  }
});

/// Active tag filters for the thoughts page.
///
/// Tags are multi-select. Keep the set immutable when writing:
/// `ref.read(selectedTagFiltersProvider.notifier).state = {...current, tag}`.
final selectedTagFiltersProvider = StateProvider<Set<String>>(
  (ref) => const <String>{},
);

@Deprecated('Use selectedTagFiltersProvider for multi-select tag filters.')
final tagFilterProvider = StateProvider<String?>((ref) => null);

Set<String> toggleTagInFilter(Set<String> current, String tag) {
  return TagFilterLogic.toggle(current, tag);
}

Set<String> renameTagInFilter(
  Set<String> current,
  String oldTag,
  String newTag,
) {
  return TagFilterLogic.rename(current, oldTag, newTag);
}

Set<String> removeTagFromFilter(Set<String> current, String tag) {
  return TagFilterLogic.remove(current, tag);
}

final archiveFilterProvider = StateProvider<bool>((ref) => false);

final thoughtSearchQueryProvider = StateProvider<String>((ref) => '');

final thoughtSearchDebouncedProvider = FutureProvider.autoDispose<String>((
  ref,
) async {
  final query = ref.watch(thoughtSearchQueryProvider);
  final completer = Completer<void>();
  final timer = Timer(const Duration(milliseconds: 300), completer.complete);
  ref.onDispose(timer.cancel);
  await completer.future;
  return query.trim();
});

final thoughtStatusFilterProvider = StateProvider<ThoughtStatusFilter>(
  (ref) => ThoughtStatusFilter.all,
);

/// All thoughts without UI filters. Filtering is composed in [thoughtsListProvider].
///
/// Depends on [thoughtImageMigrationProvider] to ensure path migration
/// completes before any thought data is loaded.
final allThoughtsProvider = FutureProvider<List<ThoughtsTableData>>((
  ref,
) async {
  // Ensure path migration completes before loading data.
  await ref.watch(thoughtImageMigrationProvider.future);

  final repo = ref.watch(thoughtsRepositoryProvider);
  final active = await repo.getThoughts(archived: false);
  final archived = await repo.getThoughts(archived: true);
  return [...active, ...archived];
});

final tagStatsProvider = Provider<Map<String, int>>((ref) {
  final thoughtsAsync = ref.watch(allThoughtsProvider);
  final showArchived = ref.watch(archiveFilterProvider);
  final thoughts = thoughtsAsync.valueOrNull ?? const <ThoughtsTableData>[];
  return _tagCounts(_filterByArchive(thoughts, showArchived));
});

final thoughtsListProvider = FutureProvider<List<ThoughtsTableData>>((
  ref,
) async {
  final thoughts = await ref.watch(allThoughtsProvider.future);
  final statusFilter = ref.watch(thoughtStatusFilterProvider);
  final selectedTags = ref.watch(selectedTagFiltersProvider);
  final searchQuery = await ref.watch(thoughtSearchDebouncedProvider.future);

  final archived = statusFilter == ThoughtStatusFilter.archived
      ? true
      : ref.watch(archiveFilterProvider);
  if (statusFilter == ThoughtStatusFilter.archived &&
      !ref.read(archiveFilterProvider)) {
    scheduleMicrotask(() {
      ref.read(archiveFilterProvider.notifier).state = true;
    });
  }

  final archiveFiltered = _filterByArchive(thoughts, archived);
  final statusFiltered = _filterByStatus(archiveFiltered, statusFilter);
  final tagFiltered = _filterByTags(statusFiltered, selectedTags);
  return _filterBySearch(tagFiltered, searchQuery);
});

final thoughtsCountProvider = Provider<int>((ref) {
  final thoughtsAsync = ref.watch(thoughtsListProvider);
  return thoughtsAsync.valueOrNull?.length ?? 0;
});

final pinnedThoughtsProvider = FutureProvider<List<ThoughtsTableData>>((
  ref,
) async {
  final thoughts = await ref.watch(allThoughtsProvider.future);
  return _filterByArchive(
    thoughts,
    false,
  ).where((thought) => thought.isPinned).take(3).toList();
});

final pendingReviewProvider = FutureProvider<List<ThoughtsTableData>>((
  ref,
) async {
  final thoughts = await ref.watch(allThoughtsProvider.future);
  return _filterByArchive(
    thoughts,
    false,
  ).where((thought) => _parseTags(thought.tags).isEmpty).toList();
});

final commonTagsProvider = Provider<List<MapEntry<String, int>>>((ref) {
  final thoughtsAsync = ref.watch(allThoughtsProvider);
  final thoughts = thoughtsAsync.valueOrNull ?? const <ThoughtsTableData>[];
  final counts = _tagCounts(_filterByArchive(thoughts, false));
  final stats = TagFilterLogic.sortStats(counts);
  return stats
      .map((s) => MapEntry(s.name, s.count))
      .take(8)
      .toList();
});

final _randomReviewSeenIdsProvider = StateProvider<Set<int>>((ref) => <int>{});

final randomReviewProvider = FutureProvider<ThoughtsTableData?>((ref) async {
  final thoughts = await ref.watch(allThoughtsProvider.future);
  final cutoff = DateTime.now().subtract(const Duration(days: 7));
  final candidates = _filterByArchive(
    thoughts,
    false,
  ).where((thought) => thought.createdAt.isBefore(cutoff)).toList();
  if (candidates.isEmpty) return null;

  final seenIds = ref.read(_randomReviewSeenIdsProvider);
  var available = candidates
      .where((thought) => !seenIds.contains(thought.id))
      .toList();
  if (available.isEmpty) {
    ref.read(_randomReviewSeenIdsProvider.notifier).state = <int>{};
    available = candidates;
  }

  final selected = available[Random().nextInt(available.length)];
  ref.read(_randomReviewSeenIdsProvider.notifier).state = {
    ...ref.read(_randomReviewSeenIdsProvider),
    selected.id,
  };
  return selected;
});

final thoughtProvider = FutureProvider.family<ThoughtsTableData?, int>((
  ref,
  id,
) async {
  final repo = ref.watch(thoughtsRepositoryProvider);
  return repo.getThought(id);
});

List<ThoughtsTableData> _filterByArchive(
  List<ThoughtsTableData> thoughts,
  bool archived,
) {
  return thoughts.where((thought) {
    return archived ? thought.archivedAt != null : thought.archivedAt == null;
  }).toList();
}

List<ThoughtsTableData> _filterByStatus(
  List<ThoughtsTableData> thoughts,
  ThoughtStatusFilter filter,
) {
  return switch (filter) {
    ThoughtStatusFilter.all || ThoughtStatusFilter.archived => thoughts,
    ThoughtStatusFilter.unorganized =>
      thoughts.where((thought) => _parseTags(thought.tags).isEmpty).toList(),
    ThoughtStatusFilter.pinned =>
      thoughts.where((thought) => thought.isPinned).toList(),
    ThoughtStatusFilter.withImages =>
      thoughts
          .where(
            (thought) =>
                (thought.imagePaths?.trim().isNotEmpty ?? false) ||
                ThoughtContentCodec.imagePathsFromStored(
                  thought.content,
                ).isNotEmpty,
          )
          .toList(),
  };
}

List<ThoughtsTableData> _filterByTags(
  List<ThoughtsTableData> thoughts,
  Set<String> selectedTags,
) {
  if (selectedTags.isEmpty) return thoughts;
  return thoughts.where((thought) {
    return TagFilterLogic.matches(
      itemTags: TagCodec.parseCommaSeparated(thought.tags),
      selectedTags: selectedTags,
      mode: TagMatchMode.all,
    );
  }).toList();
}

List<ThoughtsTableData> _filterBySearch(
  List<ThoughtsTableData> thoughts,
  String query,
) {
  if (query.isEmpty) return thoughts;
  final normalizedQuery = query.toLowerCase();
  return thoughts.where((thought) {
    final content = ThoughtContentCodec.plainTextFromStored(
      thought.content,
    ).toLowerCase();
    final tags = _parseTags(thought.tags).join(' ').toLowerCase();
    return content.contains(normalizedQuery) || tags.contains(normalizedQuery);
  }).toList();
}

Map<String, int> _tagCounts(List<ThoughtsTableData> thoughts) {
  return TagFilterLogic.countTags(
    thoughts.map((t) => TagCodec.parseCommaSeparated(t.tags)),
  );
}

List<String> _parseTags(String? tags) {
  return TagCodec.parseCommaSeparated(tags);
}
