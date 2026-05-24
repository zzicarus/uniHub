import 'package:drift/drift.dart';
import 'package:uni_hub/src/core/database/app_database.dart';

class EnrichmentJobsDao {
  EnrichmentJobsDao(this._db);

  final AppDatabase _db;

  Future<int> enqueue(int itemId) {
    final now = DateTime.now();
    return _db
        .into(_db.enrichmentJobsTable)
        .insert(
          EnrichmentJobsTableCompanion(
            itemId: Value(itemId),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
  }

  Future<EnrichmentJobsTableData?> nextPending() {
    final query = _db.select(_db.enrichmentJobsTable)
      ..where((t) => t.status.equals('pending'))
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
      ..limit(1);
    return query.getSingleOrNull();
  }

  Future<int> updateStatus(
    int id, {
    required String status,
    String? errorMessage,
    DateTime? startedAt,
    DateTime? finishedAt,
  }) {
    final now = DateTime.now();
    return (_db.update(
      _db.enrichmentJobsTable,
    )..where((t) => t.id.equals(id))).write(
      EnrichmentJobsTableCompanion(
        status: Value(status),
        errorMessage: Value(errorMessage),
        updatedAt: Value(now),
        startedAt: startedAt != null ? Value(startedAt) : const Value.absent(),
        finishedAt: finishedAt != null
            ? Value(finishedAt)
            : const Value.absent(),
      ),
    );
  }
}
