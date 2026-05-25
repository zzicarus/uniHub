import 'package:drift/drift.dart';
import 'package:uni_hub/src/core/database/app_database.dart';

class WebsiteLogoCacheDao {
  WebsiteLogoCacheDao(this._db);

  final AppDatabase _db;

  Future<WebsiteLogoCacheTableData?> getBySiteKey(String siteKey) {
    return (_db.select(_db.websiteLogoCacheTable)
      ..where((t) => t.siteKey.equals(siteKey))).getSingleOrNull();
  }

  Future<WebsiteLogoCacheTableData?> getByHost(String host) {
    return (_db.select(_db.websiteLogoCacheTable)
      ..where((t) => t.host.equals(host))).getSingleOrNull();
  }

  Future<void> upsert(WebsiteLogoCacheTableCompanion entry) async {
    await _db.into(_db.websiteLogoCacheTable).insert(
      entry,
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<void> markSuccess(
    int id, {
    required String localLogoPath,
    required String? mimeType,
    required String? remoteLogoUrl,
    Duration ttl = const Duration(days: 30),
  }) async {
    final now = DateTime.now();
    await (_db.update(_db.websiteLogoCacheTable)
      ..where((t) => t.id.equals(id))).write(
      WebsiteLogoCacheTableCompanion(
        status: const Value('success'),
        localLogoPath: Value(localLogoPath),
        mimeType: Value(mimeType),
        remoteLogoUrl: remoteLogoUrl != null ? Value(remoteLogoUrl) : const Value.absent(),
        lastError: const Value(null),
        fetchedAt: Value(now),
        expiresAt: Value(now.add(ttl)),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> markFailed(int id, String error, {Duration retryDelay = const Duration(hours: 24)}) async {
    final now = DateTime.now();
    await (_db.update(_db.websiteLogoCacheTable)
      ..where((t) => t.id.equals(id))).write(
      WebsiteLogoCacheTableCompanion(
        status: const Value('failed'),
        lastError: Value(error),
        expiresAt: Value(now.add(retryDelay)),
        updatedAt: Value(now),
      ),
    );
  }
}
