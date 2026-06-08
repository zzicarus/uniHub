import 'package:drift/drift.dart';
import 'package:uni_hub/src/core/database/app_database.dart';
import 'package:uni_hub/src/shared/tags/domain/tag_color_token.dart';
import 'package:uni_hub/src/shared/tags/tag_models.dart';

/// Database access for [TagsTable] and related relation tables.
class TagsDao {
  final AppDatabase _db;

  TagsDao(this._db);

  // ---------------------------------------------------------------------------
  // Tags
  // ---------------------------------------------------------------------------

  Future<List<AppTag>> getAllTags() async {
    final rows = await _db.select(_db.tagsTable).get();
    return rows.map(_toAppTag).toList();
  }

  Future<AppTag?> getTagById(int id) async {
    final row = await (_db.select(_db.tagsTable)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row != null ? _toAppTag(row) : null;
  }

  Future<AppTag?> getTagByNormalizedName(String name) async {
    final normalized = name.toLowerCase().trim();
    final row = await (_db.select(_db.tagsTable)
          ..where((t) => t.normalizedName.equals(normalized)))
        .getSingleOrNull();
    return row != null ? _toAppTag(row) : null;
  }

  Future<AppTag> createTag(String name) async {
    final now = DateTime.now();
    final normalized = name.toLowerCase().trim();
    final id = await _db.into(_db.tagsTable).insert(
      TagsTableCompanion(
        name: Value(name.trim()),
        normalizedName: Value(normalized),
        colorToken: Value(TagColorToken.assign(name).value),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );
    final row = await (_db.select(_db.tagsTable)
          ..where((t) => t.id.equals(id)))
        .getSingle();
    return _toAppTag(row);
  }

  Future<AppTag> getOrCreateTag(String name) async {
    final existing = await getTagByNormalizedName(name);
    if (existing != null) return existing;
    return createTag(name);
  }

  Future<void> renameTag(int tagId, String newName) async {
    await (_db.update(_db.tagsTable)..where((t) => t.id.equals(tagId))).write(
      TagsTableCompanion(
        name: Value(newName.trim()),
        normalizedName: Value(newName.toLowerCase().trim()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteTag(int tagId) async {
    await (_db.delete(_db.tagsTable)..where((t) => t.id.equals(tagId))).go();
  }

  // ---------------------------------------------------------------------------
  // Relations: Thought ↔ Tag
  // ---------------------------------------------------------------------------

  Future<List<AppTag>> getTagsForThought(int thoughtId) async {
    final query = _db.select(_db.tagsTable).join([
      innerJoin(
        _db.thoughtTagsTable,
        _db.tagsTable.id.equalsExp(_db.thoughtTagsTable.tagId),
      ),
    ]);
    query.where(_db.thoughtTagsTable.thoughtId.equals(thoughtId));
    final rows = await query.get();
    return rows.map((r) => _toAppTag(r.readTable(_db.tagsTable))).toList();
  }

  Future<void> addTagToThought(int thoughtId, int tagId) async {
    await _db.into(_db.thoughtTagsTable).insert(
      ThoughtTagsTableCompanion(
        thoughtId: Value(thoughtId),
        tagId: Value(tagId),
        createdAt: Value(DateTime.now()),
      ),
      mode: InsertMode.insertOrIgnore,
    );
  }

  Future<void> removeTagFromThought(int thoughtId, int tagId) async {
    await (_db.delete(_db.thoughtTagsTable)
          ..where((t) =>
              t.thoughtId.equals(thoughtId) & t.tagId.equals(tagId)))
        .go();
  }

  // ---------------------------------------------------------------------------
  // Relations: SavedItem ↔ Tag
  // ---------------------------------------------------------------------------

  Future<List<AppTag>> getTagsForSavedItem(int savedItemId) async {
    final query = _db.select(_db.tagsTable).join([
      innerJoin(
        _db.savedItemTagsTable,
        _db.tagsTable.id.equalsExp(_db.savedItemTagsTable.tagId),
      ),
    ]);
    query.where(_db.savedItemTagsTable.savedItemId.equals(savedItemId));
    final rows = await query.get();
    return rows.map((r) => _toAppTag(r.readTable(_db.tagsTable))).toList();
  }

  Future<void> addTagToSavedItem(int savedItemId, int tagId) async {
    await _db.into(_db.savedItemTagsTable).insert(
      SavedItemTagsTableCompanion(
        savedItemId: Value(savedItemId),
        tagId: Value(tagId),
        createdAt: Value(DateTime.now()),
      ),
      mode: InsertMode.insertOrIgnore,
    );
  }

  Future<void> removeTagFromSavedItem(int savedItemId, int tagId) async {
    await (_db.delete(_db.savedItemTagsTable)
          ..where((t) =>
              t.savedItemId.equals(savedItemId) & t.tagId.equals(tagId)))
        .go();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  AppTag _toAppTag(TagsTableData row) {
    final tokens = TagColorToken.values;
    return AppTag(
      id: row.id,
      name: row.name,
      normalizedName: row.normalizedName,
      colorToken: tokens[row.colorToken % tokens.length],
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}
