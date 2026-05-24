import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uni_hub/src/core/database/app_database.dart';
import 'package:uni_hub/src/core/plugin/plugin_registry.dart';
import 'package:uni_hub/src/plugins/collections/collections_plugin.dart';
import 'package:uni_hub/src/plugins/collections/data/collection_boxes_dao.dart';
import 'package:uni_hub/src/plugins/collections/data/collections_repository.dart';
import 'package:uni_hub/src/plugins/collections/data/enrichment_jobs_dao.dart';
import 'package:uni_hub/src/plugins/collections/data/saved_items_dao.dart';
import 'package:uni_hub/src/plugins/collections/domain/media_type.dart';
import 'package:uni_hub/src/plugins/collections/domain/platform_detector.dart';
import 'package:uni_hub/src/plugins/collections/domain/source_platform.dart';
import 'package:uni_hub/src/plugins/collections/domain/url_normalizer.dart';
import 'package:uni_hub/src/plugins/collections/services/collection_capture_service.dart';

void main() {
  late AppDatabase db;
  late CollectionsRepository repository;
  late CollectionCaptureService service;

  setUp(() {
    final registry = PluginRegistry()..register(CollectionsPlugin());
    db = AppDatabase(NativeDatabase.memory(), registry);
    repository = CollectionsRepository(
      savedItemsDao: SavedItemsDao(db),
      collectionBoxesDao: CollectionBoxesDao(db),
      enrichmentJobsDao: EnrichmentJobsDao(db),
    );
    service = CollectionCaptureService(
      repository: repository,
      urlNormalizer: const UrlNormalizer(),
      platformDetector: const PlatformDetector(),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('captures URL, detects platform and avoids duplicates', () async {
    final first = await service.captureUrl('github.com/flutter/flutter');
    final second = await service.captureUrl(
      'https://github.com/flutter/flutter/',
    );

    expect(first.wasCreated, true);
    expect(second.wasCreated, false);
    expect(second.itemId, first.itemId);

    final item = await repository.getSavedItem(first.itemId);
    expect(item!.sourcePlatform, SourcePlatform.github.value);
    expect(item.mediaType, MediaType.repository.value);
  });
}
