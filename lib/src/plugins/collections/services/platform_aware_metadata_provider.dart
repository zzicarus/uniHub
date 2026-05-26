import '../domain/collection_models.dart';
import 'collection_debug_logger.dart';
import 'metadata_provider.dart';
import 'platform_metadata_adapter.dart';

/// Routes metadata fetch requests to platform-specific adapters, falling
/// back to a generic [MetadataProvider] when no adapter matches or all
/// adapters fail.
///
/// Adapter failures (network/parse errors) trigger fallback to the generic
/// provider.  Platform-restricted responses (limited=true) are returned
/// directly without fallback, since the adapter has already produced a
/// best-effort result.
class PlatformAwareMetadataProvider implements MetadataProvider {
  PlatformAwareMetadataProvider({
    required List<PlatformMetadataAdapter> adapters,
    required MetadataProvider fallback,
  })  : _adapters = adapters,
        _fallback = fallback;

  final List<PlatformMetadataAdapter> _adapters;
  final MetadataProvider _fallback;

  @override
  Future<MetadataResult> fetchMetadata(String url) async {
    final uri = Uri.parse(url);

    for (final adapter in _adapters) {
      if (!adapter.canHandle(uri)) continue;

      try {
        CollectionDebugLogger.log(
          'metadata adapter hit adapter=${adapter.runtimeType} url=$url',
        );
        final adapterResult = await adapter.fetch(uri);

        if (adapterResult.limited) {
          CollectionDebugLogger.log(
            'metadata adapter limited adapter=${adapter.runtimeType} '
            'reason=${adapterResult.reason} url=$url',
          );
        }

        return adapterResult.result;
      } catch (error, stackTrace) {
        CollectionDebugLogger.error(
          'metadata adapter failed adapter=${adapter.runtimeType} url=$url '
          'falling back to generic provider',
          error,
          stackTrace,
        );
        break; // One adapter failure → fallback; don't try other adapters
      }
    }

    CollectionDebugLogger.log(
      'metadata fallback local url=$url',
    );
    return _fallback.fetchMetadata(url);
  }
}
