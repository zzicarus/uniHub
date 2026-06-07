import 'package:drift/drift.dart';
import 'package:uni_hub/src/core/database/app_database.dart';
import 'package:uni_hub/src/shared/crud/crud.dart';

import '../domain/collection_folder_counts.dart';
import '../domain/consumption_status.dart';
import '../domain/enrichment_status.dart';
import '../domain/media_type.dart';
import '../domain/saved_items_page.dart';
import '../domain/saved_items_query.dart';
import '../domain/source_platform.dart';
import 'collection_boxes_dao.dart';
import 'enrichment_jobs_dao.dart';
import 'saved_items_dao.dart';

class CollectionsRepository {
  static const maxBoxNameLength = 30;

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

  /// Restore a previously deleted saved item with all original fields.
  ///
  /// Creates a new row preserving title, timestamps, enrichment status,
  /// metadata, and box associations.
  Future<SavedItemsTableData> restoreSavedItem(
    SavedItemsTableData item,
    List<int> boxIds,
  ) async {
    // If the URL was re-bookmarked since deletion, return the existing entry.
    final existing = await findByNormalizedUrl(item.normalizedUrl);
    if (existing != null) return existing;

    final now = DateTime.now();
    final id = await _savedItemsDao.insert(
      SavedItemsTableCompanion(
        originalUrl: Value(item.originalUrl),
        normalizedUrl: Value(item.normalizedUrl),
        title: Value(item.title),
        description: Value(item.description),
        author: Value(item.author),
        siteName: Value(item.siteName),
        coverImage: Value(item.coverImage),
        favicon: Value(item.favicon),
        mediaType: Value(item.mediaType),
        sourcePlatform: Value(item.sourcePlatform),
        status: Value(item.status),
        isInInbox: Value(boxIds.isEmpty),
        enrichmentStatus: Value(item.enrichmentStatus),
        extractedText: Value(item.extractedText),
        summary: Value(item.summary),
        metadataJson: Value(item.metadataJson),
        createdAt: Value(item.createdAt),
        updatedAt: Value(now),
        lastOpenedAt: Value(item.lastOpenedAt),
        completedAt: Value(item.completedAt),
        archivedAt: Value(item.archivedAt),
      ),
    );

    if (boxIds.isNotEmpty) {
      await _collectionBoxesDao.setItemBoxes(id, boxIds.toSet());
    }

    final created = await _savedItemsDao.getById(id);
    if (created == null) {
      throw StateError('恢复收藏项失败：${item.originalUrl}');
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
            : status == ConsumptionStatus.unread
            ? const Value(null)
            : const Value.absent(),
        archivedAt: status == ConsumptionStatus.archived
            ? Value(now)
            : const Value(null),
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

  /// 批量查询多个 item 的收藏夹 ID 映射。
  ///
  /// 返回 itemId → boxIds 列表。未找到的 item 不会出现在返回的 map 中。
  Future<Map<int, List<int>>> getBoxIdsForItems(Iterable<int> itemIds) {
    return _collectionBoxesDao.getBoxIdsForItems(itemIds);
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

  /// Remove an item from a single collection box without deleting the item.
  ///
  /// If this was the last box assignment, moves the item back to Inbox.
  Future<void> removeItemFromBox(int itemId, int boxId) async {
    await _collectionBoxesDao.deleteItemBox(itemId, boxId);
    final remaining = await _collectionBoxesDao.getBoxIdsForItem(itemId);
    if (remaining.isEmpty) {
      await updateInboxState(itemId, true);
    }
  }

  /// Delete a saved item and all related data (box assignments, enrichment jobs).
  Future<void> deleteSavedItem(int itemId) async {
    await _collectionBoxesDao.deleteAllItemBoxes(itemId);
    await _enrichmentJobsDao.deleteByItemId(itemId);
    await _savedItemsDao.deleteById(itemId);
  }

  Future<CollectionBoxesTableData> createBox(String name) async {
    final existingBoxes = await _collectionBoxesDao.getAll();
    final failure = NameNormalizer.validateCollectionBoxName(
      name,
      siblingNames: existingBoxes.map((box) => box.name),
    );
    if (failure != null) {
      if (failure.code == AppFailureCode.duplicate) {
        throw StateError(failure.message);
      }
      throw ArgumentError(failure.message);
    }
    final trimmed = NameNormalizer.normalize(name);

    final now = DateTime.now();
    final id = await _collectionBoxesDao.insert(
      CollectionBoxesTableCompanion(
        name: Value(trimmed),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );
    final box = await _collectionBoxesDao.getById(id);
    if (box == null) throw StateError('Box 创建失败：$trimmed');
    return box;
  }

  /// 使用 SQL 化分页查询获取收藏列表。
  ///
  /// 所有筛选在数据库侧完成。
  /// Box 关系只查询当前页（limit + 1 判断 hasMore）。
  Future<SavedItemsPage> queryItems(SavedItemsQuery query) async {
    // 多查一条判断 hasMore
    final items = await _savedItemsDao.queryItemsPage(
      query.copyWith(limit: query.limit + 1),
    );

    final hasMore = items.length > query.limit;
    final pageItems = hasMore ? items.take(query.limit).toList() : items;

    // 只查当前页的 Box 关系
    final boxIdsByItemId = await _collectionBoxesDao.getBoxIdsForItems(
      pageItems.map((item) => item.id),
    );

    return SavedItemsPage(
      items: pageItems,
      boxIdsByItemId: boxIdsByItemId,
      hasMore: hasMore,
    );
  }
}
