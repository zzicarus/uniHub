import 'package:drift/drift.dart';
import 'package:uni_hub/src/core/database/app_database.dart';
import '../domain/collection_models.dart';
import '../domain/consumption_status.dart';
import '../domain/saved_items_query.dart';

class SavedItemsDao {
  SavedItemsDao(this._db);

  static const _likeEscapeChar = r'\';

  final AppDatabase _db;

  Future<List<SavedItemsTableData>> getAll() {
    final query = _db.select(_db.savedItemsTable)
      ..orderBy([
        (t) => OrderingTerm.desc(t.updatedAt),
        (t) => OrderingTerm.desc(t.createdAt),
      ]);
    return query.get();
  }

  // ---------------------------------------------------------
  // Global counts (unaffected by UI filters)
  // ---------------------------------------------------------

  /// Total saved items count (all statuses, including archived).
  Future<int> countAllItems() async {
    final query = _db.selectOnly(_db.savedItemsTable)
      ..addColumns([_db.savedItemsTable.id.count()]);
    final row = await query.getSingle();
    return row.read(_db.savedItemsTable.id.count()) ?? 0;
  }

  /// Inbox count: isInInbox == true, status != 'archived'.
  Future<int> countInboxItems() async {
    final query = _db.selectOnly(_db.savedItemsTable)
      ..addColumns([_db.savedItemsTable.id.count()])
      ..where(_db.savedItemsTable.isInInbox.equals(true))
      ..where(_db.savedItemsTable.status.equals('archived').not());
    final row = await query.getSingle();
    return row.read(_db.savedItemsTable.id.count()) ?? 0;
  }

  /// Unread count: status == 'unread'.
  Future<int> countUnreadItems() async {
    final query = _db.selectOnly(_db.savedItemsTable)
      ..addColumns([_db.savedItemsTable.id.count()])
      ..where(_db.savedItemsTable.status.equals('unread'));
    final row = await query.getSingle();
    return row.read(_db.savedItemsTable.id.count()) ?? 0;
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

  Future<int> deleteById(int id) {
    return (_db.delete(
      _db.savedItemsTable,
    )..where((t) => t.id.equals(id))).go();
  }

  // ---------------------------------------------------------
  // SQL 化分页查询
  // ---------------------------------------------------------

  /// 根据 [query] 参数从数据库查询一页收藏项。
  ///
  /// 所有筛选条件在数据库侧完成，不做内存过滤。
  /// 返回条数为 [query.limit]（或更少，如果没有足够数据）。
  Future<List<SavedItemsTableData>> queryItemsPage(
    SavedItemsQuery query,
  ) async {
    final tbl = _db.savedItemsTable;
    final q = _db.select(tbl);

    // view filter
    switch (query.view) {
      case CollectionView.inbox:
        q.where(
          (t) =>
              t.isInInbox.equals(true) &
              t.status.equals(ConsumptionStatus.archived.value).not(),
        );
        break;
      case CollectionView.archived:
        q.where((t) => t.status.equals(ConsumptionStatus.archived.value));
        break;
      case CollectionView.unread:
        q.where((t) => t.status.equals(ConsumptionStatus.unread.value));
        break;
      case CollectionView.inProgress:
        q.where((t) => t.status.equals(ConsumptionStatus.inProgress.value));
        break;
      case CollectionView.done:
        q.where((t) => t.status.equals(ConsumptionStatus.done.value));
        break;
      case CollectionView.all:
        // no filter needed
        break;
    }

    // status filter
    if (query.status != null) {
      q.where((t) => t.status.equals(query.status!.value));
    }

    // platform filter
    if (query.platform != null) {
      q.where((t) => t.sourcePlatform.equals(query.platform!.value));
    }

    // media type filter
    if (query.mediaType != null) {
      q.where((t) => t.mediaType.equals(query.mediaType!.value));
    }

    // box filter (any-of semantics via EXISTS)
    if (query.selectedBoxIds.isNotEmpty) {
      q.where(
        (t) => existsQuery(
          _db.selectOnly(_db.savedItemBoxesTable)
            ..addColumns([_db.savedItemBoxesTable.itemId])
            ..where(
              _db.savedItemBoxesTable.itemId.equalsExp(t.id) &
                  _db.savedItemBoxesTable.boxId.isIn(query.selectedBoxIds),
            ),
        ),
      );
    }

    // search filter
    final keyword = query.searchQuery.trim();
    if (keyword.isNotEmpty) {
      final pattern = '%${_escapeLike(keyword)}%';
      q.where(
        (t) =>
            t.title.like(pattern, escapeChar: _likeEscapeChar) |
            t.description.like(pattern, escapeChar: _likeEscapeChar) |
            t.originalUrl.like(pattern, escapeChar: _likeEscapeChar) |
            t.normalizedUrl.like(pattern, escapeChar: _likeEscapeChar) |
            t.siteName.like(pattern, escapeChar: _likeEscapeChar) |
            t.author.like(pattern, escapeChar: _likeEscapeChar),
      );
    }

    // sort
    switch (query.sort) {
      case SavedItemsSort.updatedDesc:
        q.orderBy([
          (t) => OrderingTerm.desc(t.updatedAt),
          (t) => OrderingTerm.desc(t.createdAt),
        ]);
        break;
      case SavedItemsSort.createdDesc:
        q.orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
        break;
      case SavedItemsSort.createdAsc:
        q.orderBy([(t) => OrderingTerm.asc(t.createdAt)]);
        break;
      case SavedItemsSort.titleAsc:
        q.orderBy([(t) => OrderingTerm.asc(t.title)]);
        break;
      case SavedItemsSort.lastOpenedDesc:
        q.orderBy([
          (t) => OrderingTerm.desc(t.lastOpenedAt),
          (t) => OrderingTerm.desc(t.updatedAt),
        ]);
        break;
    }

    q.limit(query.limit, offset: query.offset);

    return q.get();
  }

  String _escapeLike(String input) {
    return input
        .replaceAll(r'\', r'\\')
        .replaceAll('%', r'\%')
        .replaceAll('_', r'\_');
  }
}
