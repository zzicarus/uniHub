import '../data/collections_repository.dart';
import '../domain/collection_models.dart';
import '../domain/platform_detector.dart';
import '../domain/url_normalizer.dart';
import 'collection_debug_logger.dart';

class CollectionCaptureService {
  CollectionCaptureService({
    required CollectionsRepository repository,
    required UrlNormalizer urlNormalizer,
    required PlatformDetector platformDetector,
  }) : _repository = repository,
       _urlNormalizer = urlNormalizer,
       _platformDetector = platformDetector;

  final CollectionsRepository _repository;
  final UrlNormalizer _urlNormalizer;
  final PlatformDetector _platformDetector;

  Future<CaptureResult> captureUrl(String input, {int? boxId}) async {
    final normalizedUrl = _urlNormalizer.normalize(input);
    CollectionDebugLogger.log(
      'captureUrl input=$input normalized=$normalizedUrl boxId=$boxId',
    );

    final existing = await _repository.findByNormalizedUrl(normalizedUrl);
    if (existing != null) {
      CollectionDebugLogger.log(
        'captureUrl already exists id=${existing.id}',
      );
      return CaptureResult(itemId: existing.id, wasCreated: false);
    }

    final detection = _platformDetector.detect(normalizedUrl);
    final item = await _repository.createSavedItem(
      originalUrl: input.trim(),
      normalizedUrl: normalizedUrl,
      title: normalizedUrl,
      mediaType: detection.mediaType,
      sourcePlatform: detection.platform,
      isInInbox: boxId == null,
    );
    CollectionDebugLogger.log(
      'captureUrl created id=${item.id} platform=${detection.platform.name} mediaType=${detection.mediaType.name}',
    );

    if (boxId != null) {
      await _repository.setItemBoxes(item.id, {boxId});
      CollectionDebugLogger.log(
        'captureUrl set boxes itemId=${item.id} boxId=$boxId',
      );
    }
    final jobId = await _repository.enqueueEnrichmentJob(item.id);
    CollectionDebugLogger.log(
      'captureUrl enqueued enrichment id=$jobId itemId=${item.id}',
    );
    return CaptureResult(itemId: item.id, wasCreated: true);
  }
}
