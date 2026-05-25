import 'package:drift/drift.dart';
import 'package:uni_hub/src/core/database/app_database.dart';

class CollectionBoxesDao {
  CollectionBoxesDao(this._db);

  final AppDatabase _db;

  Future<List<CollectionBoxesTableData>> getAll() {
    final query = _db.select(_db.collectionBoxesTable)
      ..orderBy([
        (t) => OrderingTerm.asc(t.sortOrder),
        (t) => OrderingTerm.asc(t.name),
      ]);
    return query.get();
  }

  Future<CollectionBoxesTableData?> getById(int id) {
    return (_db.select(
      _db.collectionBoxesTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<int> insert(CollectionBoxesTableCompanion entry) {
    return _db.into(_db.collectionBoxesTable).insert(entry);
  }

  Future<List<int>> getBoxIdsForItem(int itemId) async {
    final rows = await (_db.select(
      _db.savedItemBoxesTable,
    )..where((t) => t.itemId.equals(itemId))).get();
    return rows.map((row) => row.boxId).toList();
  }

  Future<Map<int, List<int>>> getBoxIdsForItems(Iterable<int> itemIds) async {
    final ids = itemIds.toSet();
    if (ids.isEmpty) return const {};
    final rows = await (_db.select(
      _db.savedItemBoxesTable,
    )..where((t) => t.itemId.isIn(ids))).get();
    final result = <int, List<int>>{};
    for (final row in rows) {
      result.putIfAbsent(row.itemId, () => []).add(row.boxId);
    }
    return result;
  }

  /// Remove a single box assignment for an item.
  Future<int> deleteItemBox(int itemId, int boxId) {
    return (_db.delete(_db.savedItemBoxesTable)
      ..where((t) => t.itemId.equals(itemId) & t.boxId.equals(boxId))).go();
  }

  Future<void> setItemBoxes(int itemId, Set<int> boxIds) async {
    await _db.transaction(() async {
      await (_db.delete(
        _db.savedItemBoxesTable,
      )..where((t) => t.itemId.equals(itemId))).go();
      final now = DateTime.now();
      for (final boxId in boxIds) {
        await _db
            .into(_db.savedItemBoxesTable)
            .insert(
              SavedItemBoxesTableCompanion(
                itemId: Value(itemId),
                boxId: Value(boxId),
                createdAt: Value(now),
              ),
            );
      }
    });
  }

  // ---------------------------------------------------------
  // Counts
  // ---------------------------------------------------------

  Future<int> deleteAllItemBoxes(int itemId) {
    return (_db.delete(_db.savedItemBoxesTable)
      ..where((t) => t.itemId.equals(itemId))).go();
  }

  /// Number of items per collection box.
  Future<Map<int, int>> countItemsByBox() async {
    final boxId = _db.savedItemBoxesTable.boxId;
    final countExp = boxId.count();

    final query = _db.selectOnly(_db.savedItemBoxesTable)
      ..addColumns([boxId, countExp])
      ..groupBy([boxId]);

    final rows = await query.get();

    return {
      for (final row in rows)
        row.read(boxId)!: row.read(countExp)!,
    };
  }
}
