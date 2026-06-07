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

    expect(first.success, isTrue);
    final firstResult = first.data!;
    expect(second.success, isTrue);
    final secondResult = second.data!;
    expect(firstResult.wasCreated, isTrue);
    expect(secondResult.wasCreated, isFalse);
    expect(secondResult.itemId, firstResult.itemId);

    final item = await repository.getSavedItem(firstResult.itemId);
    expect(item!.sourcePlatform, SourcePlatform.github.value);
    expect(item.mediaType, MediaType.repository.value);
  });

  test('capture with boxId assigns item to box and sets isInInbox=false',
      () async {
    final box = await repository.createBox('待读');

    final result = await service.captureUrl(
      'https://example.com/boxed-article',
      boxId: box.id,
    );

    expect(result.success, isTrue);
    final capResult = result.data!;
    expect(capResult.wasCreated, isTrue);

    final item = await repository.getSavedItem(capResult.itemId);
    expect(item, isNotNull);
    expect(item!.isInInbox, false);

    final boxIds = await repository.getBoxIdsForItem(capResult.itemId);
    expect(boxIds, [box.id]);
  });

  test('capture without boxId keeps isInInbox=true', () async {
    final result = await service.captureUrl('https://example.com/inbox-item');

    expect(result.success, isTrue);
    final capResult = result.data!;
    expect(capResult.wasCreated, isTrue);

    final item = await repository.getSavedItem(capResult.itemId);
    expect(item, isNotNull);
    expect(item!.isInInbox, true);

    final boxIds = await repository.getBoxIdsForItem(capResult.itemId);
    expect(boxIds, isEmpty);
  });
}
