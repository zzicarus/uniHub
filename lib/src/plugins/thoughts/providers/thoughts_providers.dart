import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../data/thoughts_dao.dart';
import '../data/thoughts_repository.dart';

final thoughtsDaoProvider = Provider<ThoughtsDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return ThoughtsDao(db);
});

final thoughtsRepositoryProvider = Provider<ThoughtsRepository>((ref) {
  final dao = ref.watch(thoughtsDaoProvider);
  return ThoughtsRepository(dao);
});

final tagFilterProvider = StateProvider<String?>((ref) => null);

/// All thoughts without tag filter, used for tag stats
final allThoughtsProvider = FutureProvider<List<ThoughtsTableData>>((
  ref,
) async {
  final repo = ref.watch(thoughtsRepositoryProvider);
  final archived = ref.watch(archiveFilterProvider);
  return repo.getThoughts(archived: archived);
});

final tagStatsProvider = Provider<Map<String, int>>((ref) {
  final thoughtsAsync = ref.watch(allThoughtsProvider);
  final thoughts = thoughtsAsync.valueOrNull ?? const <ThoughtsTableData>[];
  final stats = <String, int>{};
  for (final t in thoughts) {
    final tags = (t.tags ?? '')
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty);
    for (final tag in tags) {
      stats[tag] = (stats[tag] ?? 0) + 1;
    }
  }
  return stats;
});

final archiveFilterProvider = StateProvider<bool>((ref) => false);

final thoughtsListProvider = FutureProvider<List<ThoughtsTableData>>((
  ref,
) async {
  final repo = ref.watch(thoughtsRepositoryProvider);
  final tagFilter = ref.watch(tagFilterProvider);
  final archived = ref.watch(archiveFilterProvider);

  final thoughts = await repo.getThoughts(archived: archived);

  if (tagFilter != null && tagFilter.isNotEmpty) {
    return thoughts.where((t) {
      final tagList =
          t.tags
              ?.split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList() ??
          [];
      return tagList.contains(tagFilter);
    }).toList();
  }
  return thoughts;
});

final thoughtProvider = FutureProvider.family<ThoughtsTableData?, int>((
  ref,
  id,
) async {
  final repo = ref.watch(thoughtsRepositoryProvider);
  return repo.getThought(id);
});
