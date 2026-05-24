import '../data/collections_repository.dart';
import '../domain/collection_models.dart';
import '../domain/platform_detector.dart';
import '../domain/url_normalizer.dart';

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

  Future<CaptureResult> captureUrl(String input) async {
    final normalizedUrl = _urlNormalizer.normalize(input);
    final existing = await _repository.findByNormalizedUrl(normalizedUrl);
    if (existing != null) {
      return CaptureResult(itemId: existing.id, wasCreated: false);
    }

    final detection = _platformDetector.detect(normalizedUrl);
    final item = await _repository.createSavedItem(
      originalUrl: input.trim(),
      normalizedUrl: normalizedUrl,
      title: normalizedUrl,
      mediaType: detection.mediaType,
      sourcePlatform: detection.platform,
    );
    await _repository.enqueueEnrichmentJob(item.id);
    return CaptureResult(itemId: item.id, wasCreated: true);
  }
}
