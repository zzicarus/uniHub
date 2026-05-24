import '../data/collections_repository.dart';
import '../domain/enrichment_status.dart';
import 'metadata_provider.dart';

class EnrichmentJobService {
  EnrichmentJobService({
    required CollectionsRepository repository,
    required MetadataProvider metadataProvider,
  }) : _repository = repository,
       _metadataProvider = metadataProvider;

  final CollectionsRepository _repository;
  final MetadataProvider _metadataProvider;

  Future<void> enrichItem(int itemId) async {
    final item = await _repository.getSavedItem(itemId);
    if (item == null) {
      throw StateError('收藏项不存在：$itemId');
    }

    await _repository.updateMetadata(
      itemId,
      enrichmentStatus: EnrichmentStatus.running,
    );

    try {
      final metadata = await _metadataProvider.fetchMetadata(
        item.normalizedUrl,
      );
      await _repository.updateMetadata(
        itemId,
        title: metadata.title,
        description: metadata.description,
        author: metadata.author,
        siteName: metadata.siteName,
        coverImage: metadata.coverImage,
        favicon: metadata.favicon,
        metadataJson: metadata.metadataJson,
        enrichmentStatus: metadata.status,
      );
    } catch (_) {
      await _repository.updateMetadata(
        itemId,
        enrichmentStatus: EnrichmentStatus.failed,
      );
      rethrow;
    }
  }
}
