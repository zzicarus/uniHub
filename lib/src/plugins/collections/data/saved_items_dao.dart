import 'package:drift/drift.dart';
import 'package:uni_hub/src/core/database/app_database.dart';

class SavedItemsDao {
  SavedItemsDao(this._db);

  final AppDatabase _db;

  Future<List<SavedItemsTableData>> getAll() {
    final query = _db.select(_db.savedItemsTable)
      ..orderBy([
        (t) => OrderingTerm.desc(t.updatedAt),
        (t) => OrderingTerm.desc(t.createdAt),
      ]);
    return query.get();
  }

  Future<SavedItemsTableData?> getById(int id) {
    return (_db.select(
      _db.savedItemsTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<SavedItemsTableData?> findByNormalizedUrl(String normalizedUrl) {
    return (_db.select(
      _db.savedItemsTable,
    )..where((t) => t.normalizedUrl.equals(normalizedUrl))).getSingleOrNull();
  }

  Future<int> insert(SavedItemsTableCompanion entry) {
    return _db.into(_db.savedItemsTable).insert(entry);
  }

  Future<int> updateById(int id, SavedItemsTableCompanion entry) {
    return (_db.update(
      _db.savedItemsTable,
    )..where((t) => t.id.equals(id))).write(entry);
  }

  Future<int> updateLastOpenedAt(int id, DateTime openedAt) {
    return updateById(
      id,
      SavedItemsTableCompanion(
        lastOpenedAt: Value(openedAt),
        updatedAt: Value(openedAt),
      ),
    );
  }
}
