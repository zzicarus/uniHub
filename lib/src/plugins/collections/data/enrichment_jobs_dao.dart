import 'package:drift/drift.dart';
import 'package:uni_hub/src/core/database/app_database.dart';

class EnrichmentJobsDao {
  EnrichmentJobsDao(this._db);

  final AppDatabase _db;

  Future<int> enqueue(int itemId) {
    final now = DateTime.now();
    return _db.into(_db.enrichmentJobsTable).insert(
      EnrichmentJobsTableCompanion(
        itemId: Value(itemId),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  Future<List<EnrichmentJobsTableData>> getPending({int limit = 3}) {
    final query = _db.select(_db.enrichmentJobsTable)
      ..where((t) => t.status.equals('pending'))
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
      ..limit(limit);
    return query.get();
  }

  Future<EnrichmentJobsTableData?> getById(int id) {
    return (_db.select(_db.enrichmentJobsTable)
      ..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<void> markRunning(int id) async {
    final now = DateTime.now();
    await (_db.update(_db.enrichmentJobsTable)
      ..where((t) => t.id.equals(id))).write(
      EnrichmentJobsTableCompanion(
        status: const Value('running'),
        startedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> markSuccess(int id) async {
    final now = DateTime.now();
    await (_db.update(_db.enrichmentJobsTable)
      ..where((t) => t.id.equals(id))).write(
      EnrichmentJobsTableCompanion(
        status: const Value('success'),
        finishedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> markFailed(int id, String errorMessage) async {
    final job = await getById(id);
    if (job == null) return;
    final now = DateTime.now();
    await (_db.update(_db.enrichmentJobsTable)
      ..where((t) => t.id.equals(id))).write(
      EnrichmentJobsTableCompanion(
        status: const Value('failed'),
        errorMessage: Value(errorMessage),
        attempts: Value(job.attempts + 1),
        finishedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> requeue(int id, String errorMessage) async {
    final job = await getById(id);
    if (job == null) return;
    final now = DateTime.now();
    await (_db.update(_db.enrichmentJobsTable)
      ..where((t) => t.id.equals(id))).write(
      EnrichmentJobsTableCompanion(
        status: const Value('pending'),
        errorMessage: Value(errorMessage),
        attempts: Value(job.attempts + 1),
        updatedAt: Value(now),
      ),
    );
  }

  Future<int> deleteByItemId(int itemId) {
    return (_db.delete(_db.enrichmentJobsTable)
      ..where((t) => t.itemId.equals(itemId))).go();
  }
}
