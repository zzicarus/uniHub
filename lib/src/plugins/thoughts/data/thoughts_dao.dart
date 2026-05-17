import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';

class ThoughtsDao {
  final AppDatabase _db;

  ThoughtsDao(this._db);

  Future<List<ThoughtsTableData>> getAll({bool archived = false}) {
    final query = _db.select(_db.thoughtsTable);
    if (archived) {
      query.where((t) => t.archivedAt.isNotNull());
    } else {
      query.where((t) => t.archivedAt.isNull());
    }
    query.orderBy([
      (t) => OrderingTerm.desc(t.isPinned),
      (t) => OrderingTerm.desc(t.createdAt),
    ]);
    return query.get();
  }

  Future<ThoughtsTableData?> getById(int id) {
    return (_db.select(
      _db.thoughtsTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<int> insert(ThoughtsTableCompanion entry) {
    return _db.into(_db.thoughtsTable).insert(entry);
  }

  Future<int> updateById(int id, ThoughtsTableCompanion entry) {
    return (_db.update(
      _db.thoughtsTable,
    )..where((t) => t.id.equals(id))).write(entry);
  }

  Future<int> delete(int id) {
    return (_db.delete(_db.thoughtsTable)..where((t) => t.id.equals(id))).go();
  }

  Future<int> archive(int id) {
    final now = DateTime.now();
    return (_db.update(_db.thoughtsTable)..where((t) => t.id.equals(id))).write(
      ThoughtsTableCompanion(archivedAt: Value(now), updatedAt: Value(now)),
    );
  }

  Future<int> restore(int id) {
    return (_db.update(_db.thoughtsTable)..where((t) => t.id.equals(id))).write(
      ThoughtsTableCompanion(
        archivedAt: const Value(null),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> togglePin(int id, bool pinned) {
    return (_db.update(_db.thoughtsTable)..where((t) => t.id.equals(id))).write(
      ThoughtsTableCompanion(
        isPinned: Value(pinned),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}
