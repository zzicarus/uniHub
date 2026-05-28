import 'package:drift/drift.dart';
import 'package:uni_hub/src/core/database/app_database.dart';

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

  /// 活跃（未归档）想法数量，使用数据库侧 COUNT 聚合。
  Future<int> countActive() async {
    final countExp = _db.thoughtsTable.id.count();

    final query = _db.selectOnly(_db.thoughtsTable)
      ..addColumns([countExp])
      ..where(_db.thoughtsTable.archivedAt.isNull());

    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  /// 最近 N 条未归档想法。
  Future<List<ThoughtsTableData>> getRecent({required int limit}) {
    final query = _db.select(_db.thoughtsTable)
      ..where((t) => t.archivedAt.isNull())
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
      ..limit(limit);
    return query.get();
  }

  /// 最近 N 条置顶的未归档想法。
  Future<List<ThoughtsTableData>> getPinned({required int limit}) {
    final query = _db.select(_db.thoughtsTable)
      ..where((t) => t.archivedAt.isNull() & t.isPinned.equals(true))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
      ..limit(limit);
    return query.get();
  }
}
