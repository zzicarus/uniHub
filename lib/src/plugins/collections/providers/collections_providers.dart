import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uni_hub/src/core/database/app_database.dart';
import 'package:uni_hub/src/core/database/database_provider.dart';

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
import '../services/enrichment_job_service.dart';
import '../services/local_metadata_provider.dart';
import '../services/metadata_provider.dart';
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
  return LocalMetadataProvider(client: client);
});

final enrichmentJobServiceProvider = Provider<EnrichmentJobService>((ref) {
  return EnrichmentJobService(
    repository: ref.watch(collectionsRepositoryProvider),
    jobsDao: ref.watch(enrichmentJobsDaoProvider),
    metadataProvider: ref.watch(metadataProviderProvider),
    logoCacheService: ref.watch(websiteLogoCacheServiceProvider),
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

final websiteLogoCacheServiceProvider = Provider<WebsiteLogoCacheService>((ref) {
  return WebsiteLogoCacheService(
    dao: ref.watch(websiteLogoCacheDaoProvider),
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
