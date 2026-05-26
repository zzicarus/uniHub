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

  Future<void> markFailed(int id, String error, {Duration retryDelay = const Duration(minutes: 10)}) async {
    final now = DateTime.now();
    await (_db.update(_db.websiteLogoCacheTable)
      ..where((t) => t.id.equals(id))).write(
      WebsiteLogoCacheTableCompanion(
        status: const Value('failed'),
        lastError: Value(error),
        localLogoPath: const Value(null),
        mimeType: const Value(null),
        expiresAt: Value(now.add(retryDelay)),
        updatedAt: Value(now),
      ),
    );
  }

  /// 批量查询多个 siteKey 的缓存记录。
  ///
  /// 返回 siteKey → row 的映射，未找到的 key 对应 null。
  Future<Map<String, WebsiteLogoCacheTableData?>> getLogosBySiteKeys(
    Iterable<String> siteKeys,
  ) async {
    final keys = siteKeys.toSet();
    if (keys.isEmpty) return const {};
    final results = await (_db.select(_db.websiteLogoCacheTable)
      ..where((t) => t.siteKey.isIn(keys.toList())))
      .get();
    final map = <String, WebsiteLogoCacheTableData?>{};
    for (final key in keys) {
      map[key] = results.where((r) => r.siteKey == key).firstOrNull;
    }
    return map;
  }

  /// 清空所有缓存记录，返回删除行数。
  Future<int> clearAll() {
    return (_db.delete(_db.websiteLogoCacheTable)).go();
  }

  /// 查询所有缓存记录。
  Future<List<WebsiteLogoCacheTableData>> getAll() {
    return _db.select(_db.websiteLogoCacheTable).get();
  }

  /// 统计缓存记录数。
  Future<int> count() async {
    final result = await (_db.selectOnly(_db.websiteLogoCacheTable)
      ..addColumns([_db.websiteLogoCacheTable.id.count()]))
      .getSingle();
    return result.read(_db.websiteLogoCacheTable.id.count()) ?? 0;
  }
}
