import 'package:drift/drift.dart';
import 'package:uni_hub/src/core/database/app_database.dart';

import '../domain/collection_folder_counts.dart';
import '../domain/collection_models.dart';
import '../domain/consumption_status.dart';
import '../domain/enrichment_status.dart';
import '../domain/media_type.dart';
import '../domain/source_platform.dart';
import 'collection_boxes_dao.dart';
import 'enrichment_jobs_dao.dart';
import 'saved_items_dao.dart';

class CollectionsRepository {
  CollectionsRepository({
    required SavedItemsDao savedItemsDao,
    required CollectionBoxesDao collectionBoxesDao,
    required EnrichmentJobsDao enrichmentJobsDao,
  }) : _savedItemsDao = savedItemsDao,
       _collectionBoxesDao = collectionBoxesDao,
       _enrichmentJobsDao = enrichmentJobsDao;

  final SavedItemsDao _savedItemsDao;
  final CollectionBoxesDao _collectionBoxesDao;
  final EnrichmentJobsDao _enrichmentJobsDao;

  Future<SavedItemsTableData?> findByNormalizedUrl(String normalizedUrl) {
    return _savedItemsDao.findByNormalizedUrl(normalizedUrl);
  }

  Future<SavedItemsTableData?> getSavedItem(int id) {
    return _savedItemsDao.getById(id);
  }

  Future<SavedItemsTableData> createSavedItem({
    required String originalUrl,
    required String normalizedUrl,
    String? title,
    MediaType mediaType = MediaType.unknown,
    SourcePlatform sourcePlatform = SourcePlatform.unknown,
    bool isInInbox = true,
  }) async {
    final existing = await findByNormalizedUrl(normalizedUrl);
    if (existing != null) return existing;

    final now = DateTime.now();
    final id = await _savedItemsDao.insert(
      SavedItemsTableCompanion(
        originalUrl: Value(originalUrl),
        normalizedUrl: Value(normalizedUrl),
        title: Value(title ?? normalizedUrl),
        mediaType: Value(mediaType.value),
        sourcePlatform: Value(sourcePlatform.value),
        isInInbox: Value(isInInbox),
        status: Value(ConsumptionStatus.unread.value),
        enrichmentStatus: Value(EnrichmentStatus.pending.value),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );
    final created = await _savedItemsDao.getById(id);
    if (created == null) {
      throw StateError('收藏项创建失败：$normalizedUrl');
    }
    return created;
  }

  Future<void> updateMetadata(
    int itemId, {
    String? title,
    String? description,
    String? author,
    String? siteName,
    String? coverImage,
    String? favicon,
    String? metadataJson,
    required EnrichmentStatus enrichmentStatus,
  }) {
    return _savedItemsDao.updateById(
      itemId,
      SavedItemsTableCompanion(
        title: title != null ? Value(title) : const Value.absent(),
        description: description != null
            ? Value(description)
            : const Value.absent(),
        author: author != null ? Value(author) : const Value.absent(),
        siteName: siteName != null ? Value(siteName) : const Value.absent(),
        coverImage: coverImage != null
            ? Value(coverImage)
            : const Value.absent(),
        favicon: favicon != null ? Value(favicon) : const Value.absent(),
        metadataJson: metadataJson != null
            ? Value(metadataJson)
            : const Value.absent(),
        enrichmentStatus: Value(enrichmentStatus.value),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> updateStatus(int itemId, ConsumptionStatus status) {
    final now = DateTime.now();
    return _savedItemsDao.updateById(
      itemId,
      SavedItemsTableCompanion(
        status: Value(status.value),
        completedAt: status == ConsumptionStatus.done
            ? Value(now)
            : const Value.absent(),
        archivedAt: status == ConsumptionStatus.archived
            ? Value(now)
            : const Value.absent(),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> updateInboxState(int itemId, bool isInInbox) {
    return _savedItemsDao.updateById(
      itemId,
      SavedItemsTableCompanion(
        isInInbox: Value(isInInbox),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> markOpened(int itemId) {
    return _savedItemsDao.updateLastOpenedAt(itemId, DateTime.now());
  }

  Future<List<int>> getBoxIdsForItem(int itemId) {
    return _collectionBoxesDao.getBoxIdsForItem(itemId);
  }

  Future<void> setItemBoxes(int itemId, Set<int> boxIds) {
    return _collectionBoxesDao.setItemBoxes(itemId, boxIds);
  }

  Future<int> enqueueEnrichmentJob(int itemId) {
    return _enrichmentJobsDao.enqueue(itemId);
  }

  Future<List<CollectionBoxesTableData>> getBoxes() {
    return _collectionBoxesDao.getAll();
  }

  /// Global navigation counts (unaffected by UI filters).
  Future<CollectionFolderCounts> getFolderCounts() async {
    final results = await Future.wait([
      _savedItemsDao.countAllItems(),
      _savedItemsDao.countInboxItems(),
      _savedItemsDao.countUnreadItems(),
      _collectionBoxesDao.countItemsByBox(),
    ]);

    return CollectionFolderCounts(
      all: results[0] as int,
      inbox: results[1] as int,
      unread: results[2] as int,
      byBoxId: results[3] as Map<int, int>,
    );
  }

  /// Delete a saved item and all related data (box assignments, enrichment jobs).
  Future<void> deleteSavedItem(int itemId) async {
    await _collectionBoxesDao.deleteAllItemBoxes(itemId);
    await _enrichmentJobsDao.deleteByItemId(itemId);
    await _savedItemsDao.deleteById(itemId);
  }

  Future<CollectionBoxesTableData> createBox(String name) async {
    final now = DateTime.now();
    final id = await _collectionBoxesDao.insert(
      CollectionBoxesTableCompanion(
        name: Value(name.trim()),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );
    final box = await _collectionBoxesDao.getById(id);
    if (box == null) throw StateError('Box 创建失败：$name');
    return box;
  }

  Future<List<SavedItemsTableData>> queryItems({
    required CollectionView view,
    ConsumptionStatus? status,
    SourcePlatform? platform,
    MediaType? mediaType,
    Set<int> boxIds = const {},
    String query = '',
  }) async {
    final items = await _savedItemsDao.getAll();
    final itemBoxIds = await _collectionBoxesDao.getBoxIdsForItems(
      items.map((item) => item.id),
    );
    final normalizedQuery = query.trim().toLowerCase();

    return items.where((item) {
      if (!_matchesView(item, view)) return false;
      if (status != null && item.status != status.value) return false;
      if (platform != null && item.sourcePlatform != platform.value) {
        return false;
      }
      if (mediaType != null && item.mediaType != mediaType.value) return false;
      if (boxIds.isNotEmpty) {
        final ids = itemBoxIds[item.id]?.toSet() ?? const <int>{};
        if (!boxIds.any(ids.contains)) return false;
      }
      if (normalizedQuery.isEmpty) return true;
      final haystack = [
        item.title,
        item.description,
        item.originalUrl,
        item.normalizedUrl,
        item.siteName,
      ].whereType<String>().join(' ').toLowerCase();
      return haystack.contains(normalizedQuery);
    }).toList();
  }

  bool _matchesView(SavedItemsTableData item, CollectionView view) {
    final status = ConsumptionStatus.fromValue(item.status);
    return switch (view) {
      CollectionView.inbox =>
        item.isInInbox && status != ConsumptionStatus.archived,
      CollectionView.all => true,
      CollectionView.unread => status == ConsumptionStatus.unread,
      CollectionView.inProgress => status == ConsumptionStatus.inProgress,
      CollectionView.done => status == ConsumptionStatus.done,
      CollectionView.archived => status == ConsumptionStatus.archived,
    };
  }
}
