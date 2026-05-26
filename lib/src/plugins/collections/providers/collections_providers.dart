import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uni_hub/src/core/database/app_database.dart';
import 'package:uni_hub/src/core/database/database_provider.dart';
import 'package:uni_hub/src/core/storage/providers/storage_providers.dart';

import '../data/collection_boxes_dao.dart';
import '../data/collections_repository.dart';
import '../data/enrichment_jobs_dao.dart';
import '../data/saved_items_dao.dart';
import '../domain/collection_folder_counts.dart';
import '../domain/collection_models.dart';
import '../domain/consumption_status.dart';
import '../domain/media_type.dart';
import '../domain/platform_detector.dart';
import '../domain/source_platform.dart';
import '../domain/url_normalizer.dart';
import '../services/collection_capture_service.dart';
import '../data/website_logo_cache_dao.dart';
import '../application/enrichment_queue_controller.dart';
import '../application/saved_item_actions_controller.dart';
import '../application/saved_item_list_entry.dart';
import '../services/enrichment_job_service.dart';
import '../services/local_metadata_provider.dart';
import '../services/metadata_provider.dart';
import '../services/platform_adapters/bilibili_metadata_adapter.dart';
import '../services/platform_adapters/github_metadata_adapter.dart';
import '../services/platform_adapters/weibo_metadata_adapter.dart';
import '../services/platform_aware_metadata_provider.dart';
import '../services/website_logo_cache_service.dart';

final savedItemsDaoProvider = Provider<SavedItemsDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return SavedItemsDao(db);
});

final collectionBoxesDaoProvider = Provider<CollectionBoxesDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return CollectionBoxesDao(db);
});

final enrichmentJobsDaoProvider = Provider<EnrichmentJobsDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return EnrichmentJobsDao(db);
});

final collectionsRepositoryProvider = Provider<CollectionsRepository>((ref) {
  return CollectionsRepository(
    savedItemsDao: ref.watch(savedItemsDaoProvider),
    collectionBoxesDao: ref.watch(collectionBoxesDaoProvider),
    enrichmentJobsDao: ref.watch(enrichmentJobsDaoProvider),
  );
});

final urlNormalizerProvider = Provider<UrlNormalizer>((ref) {
  return const UrlNormalizer();
});

final platformDetectorProvider = Provider<PlatformDetector>((ref) {
  return const PlatformDetector();
});

final metadataProviderProvider = Provider<MetadataProvider>((ref) {
  final client = HttpClient();
  ref.onDispose(() => client.close(force: true));
  final local = LocalMetadataProvider(client: client);
  return PlatformAwareMetadataProvider(
    adapters: [
      BilibiliMetadataAdapter(client: client),
      WeiboMetadataAdapter(client: client),
      GitHubMetadataAdapter(client: client),
    ],
    fallback: local,
  );
});

final enrichmentQueueControllerProvider =
    Provider<EnrichmentQueueController>((ref) {
  return EnrichmentQueueController(
    jobService: ref.watch(enrichmentJobServiceProvider),
    ref: ref,
  );
});

final enrichmentJobServiceProvider = Provider<EnrichmentJobService>((ref) {
  return EnrichmentJobService(
    repository: ref.watch(collectionsRepositoryProvider),
    jobsDao: ref.watch(enrichmentJobsDaoProvider),
    metadataProvider: ref.watch(metadataProviderProvider),
    logoCacheService: ref.watch(websiteLogoCacheServiceProvider).valueOrNull,
    onLogoCached: () {
      // Increment the refresh counter after logo cache write completes,
      // so UI re-reads the cached logo from the database.
      ref.read(websiteLogoRefreshProvider.notifier).state++;
    },
  );
});

final savedItemActionsControllerProvider =
    Provider<SavedItemActionsController>((ref) {
  return SavedItemActionsController(
    repository: ref.watch(collectionsRepositoryProvider),
    enrichmentJobService: ref.watch(enrichmentJobServiceProvider),
    ref: ref,
  );
});

final collectionCaptureServiceProvider = Provider<CollectionCaptureService>((
  ref,
) {
  return CollectionCaptureService(
    repository: ref.watch(collectionsRepositoryProvider),
    urlNormalizer: ref.watch(urlNormalizerProvider),
    platformDetector: ref.watch(platformDetectorProvider),
  );
});

final collectionViewProvider = StateProvider<CollectionView>(
  (ref) => CollectionView.inbox,
);

final collectionStatusFilterProvider = StateProvider<ConsumptionStatus?>(
  (ref) => null,
);

final collectionPlatformFilterProvider = StateProvider<SourcePlatform?>(
  (ref) => null,
);

final collectionMediaTypeFilterProvider = StateProvider<MediaType?>(
  (ref) => null,
);

final selectedCollectionBoxIdsProvider = StateProvider<Set<int>>(
  (ref) => const <int>{},
);

final collectionSearchQueryProvider = StateProvider<String>((ref) => '');

final collectionBoxesProvider = FutureProvider<List<CollectionBoxesTableData>>((
  ref,
) {
  final repository = ref.watch(collectionsRepositoryProvider);
  return repository.getBoxes();
});

final savedItemsListProvider = FutureProvider<List<SavedItemsTableData>>((ref) {
  final repository = ref.watch(collectionsRepositoryProvider);
  return repository.queryItems(
    view: ref.watch(collectionViewProvider),
    status: ref.watch(collectionStatusFilterProvider),
    platform: ref.watch(collectionPlatformFilterProvider),
    mediaType: ref.watch(collectionMediaTypeFilterProvider),
    boxIds: ref.watch(selectedCollectionBoxIdsProvider),
    query: ref.watch(collectionSearchQueryProvider),
  );
});

final selectedSavedItemIdProvider = StateProvider<int?>((ref) => null);

/// Global navigation counts for the sidebar.
///
/// NOT affected by search query, platform/media-type/status filters,
/// or selected box IDs — these are data-layer counts.
final collectionFolderCountsProvider =
    FutureProvider<CollectionFolderCounts>((ref) {
  final repository = ref.watch(collectionsRepositoryProvider);
  return repository.getFolderCounts();
});

// ---------------------------------------------------------------------------
// Website Logo Cache
// ---------------------------------------------------------------------------

final websiteLogoCacheDaoProvider = Provider<WebsiteLogoCacheDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return WebsiteLogoCacheDao(db);
});

final websiteLogoCacheServiceProvider = FutureProvider<WebsiteLogoCacheService>((ref) async {
  final storagePaths = await ref.watch(appStoragePathsProvider.future);
  return WebsiteLogoCacheService(
    dao: ref.watch(websiteLogoCacheDaoProvider),
    logosDir: storagePaths.websiteLogosDir,
  );
});

/// Increment this counter to trigger a global refresh of all cached
/// website logo lookups (e.g. after enrichment completes).
final websiteLogoRefreshProvider = StateProvider<int>((ref) => 0);

/// Look up the cached logo for a URL from the database.
///
/// Never performs network I/O — reads directly from the cache table.
/// Returns null when no cache entry exists yet.
final websiteLogoForUrlProvider =
    FutureProvider.family<WebsiteLogoCacheEntry?, String>((ref, url) async {
  // Re-fetch when the refresh trigger fires
  ref.watch(websiteLogoRefreshProvider);
  final dao = ref.watch(websiteLogoCacheDaoProvider);
  final key = WebsiteLogoCacheService.siteKey(url);
  final row = await dao.getBySiteKey(key);
  if (row == null) return null;
  return WebsiteLogoCacheEntry(
    siteKey: row.siteKey,
    localLogoPath: row.localLogoPath,
    status: row.status,
  );
});

// ---------------------------------------------------------------------------
// ViewModel list
// ---------------------------------------------------------------------------

/// 聚合收藏列表数据，消除列表渲染时的 N+1 查询。
///
/// 每个 [SavedItemListEntry] 包含 item 本身、所属 Box、Logo 缓存、选中状态。
final savedItemListEntriesProvider =
    FutureProvider<List<SavedItemListEntry>>((ref) async {
  // Watch the refresh counter so that logos update after enrichment completes.
  ref.watch(websiteLogoRefreshProvider);
  final items = await ref.watch(savedItemsListProvider.future);
  final selectedId = ref.watch(selectedSavedItemIdProvider);

  final repository = ref.watch(collectionsRepositoryProvider);
  final boxIdsMap = await repository.getBoxIdsForItems(
    items.map((item) => item.id),
  );

  final boxes = await ref.watch(collectionBoxesProvider.future);
  final boxById = {for (final box in boxes) box.id: box};

  // Batch load logos
  final logoDao = ref.watch(websiteLogoCacheDaoProvider);
  final siteKeys = items
      .map((item) => WebsiteLogoCacheService.siteKey(item.originalUrl));
  final logoRows = await logoDao.getLogosBySiteKeys(siteKeys);
  final logos = <String, WebsiteLogoCacheEntry?>{};
  for (final entry in logoRows.entries) {
    final row = entry.value;
    logos[entry.key] = row != null
        ? WebsiteLogoCacheEntry(
            siteKey: row.siteKey,
            localLogoPath: row.localLogoPath,
            status: row.status,
          )
        : null;
  }

  return [
    for (final item in items)
      SavedItemListEntry(
        item: item,
        boxes: [
          for (final boxId in boxIdsMap[item.id] ?? const <int>[])
            if (boxById[boxId] != null) boxById[boxId]!,
        ],
        logo: logos[WebsiteLogoCacheService.siteKey(item.originalUrl)],
        selected: item.id == selectedId,
      ),
  ];
});

/// 当前选中的收藏项的 ViewModel。
final selectedSavedItemEntryProvider = Provider<SavedItemListEntry?>((ref) {
  final entriesAsync = ref.watch(savedItemListEntriesProvider);
  final selectedId = ref.watch(selectedSavedItemIdProvider);
  if (selectedId == null) return null;
  return entriesAsync.valueOrNull
      ?.where((e) => e.item.id == selectedId)
      .firstOrNull;
});
