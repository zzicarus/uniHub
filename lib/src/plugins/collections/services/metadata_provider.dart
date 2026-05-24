import '../domain/collection_models.dart';

abstract interface class MetadataProvider {
  Future<MetadataResult> fetchMetadata(String url);
}
