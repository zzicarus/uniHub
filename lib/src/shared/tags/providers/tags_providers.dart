import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uni_hub/src/core/database/database_provider.dart';
import 'package:uni_hub/src/shared/tags/application/tag_actions_controller.dart';
import 'package:uni_hub/src/shared/tags/data/tags_dao.dart';
import 'package:uni_hub/src/shared/tags/tag_models.dart';

// ---------------------------------------------------------------------------
// DAO
// ---------------------------------------------------------------------------

final tagsDaoProvider = Provider<TagsDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return TagsDao(db);
});

// ---------------------------------------------------------------------------
// Controller
// ---------------------------------------------------------------------------

final tagActionsControllerProvider = Provider<TagActionsController>((ref) {
  final controller = TagActionsController(
    tagsDao: ref.watch(tagsDaoProvider),
  );
  ref.onDispose(controller.dispose);
  return controller;
});

// ---------------------------------------------------------------------------
// Queries
// ---------------------------------------------------------------------------

/// All tags, ordered alphabetically.
final allTagsProvider = FutureProvider<List<AppTag>>((ref) {
  final dao = ref.watch(tagsDaoProvider);
  return dao.getAllTags();
});

/// Tags for a given thought.
final tagsForThoughtProvider =
    FutureProvider.family<List<AppTag>, int>((ref, thoughtId) {
  final dao = ref.watch(tagsDaoProvider);
  return dao.getTagsForThought(thoughtId);
});

/// Tags for a given saved item.
final tagsForSavedItemProvider =
    FutureProvider.family<List<AppTag>, int>((ref, savedItemId) {
  final dao = ref.watch(tagsDaoProvider);
  return dao.getTagsForSavedItem(savedItemId);
});
