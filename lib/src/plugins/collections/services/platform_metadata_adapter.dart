import '../domain/collection_models.dart';

/// Result returned by a [PlatformMetadataAdapter].
///
/// On success, [result] carries the parsed metadata.
/// On platform restriction (login wall, anti-crawl, etc.), [limited] is true
/// and the adapter returns a best-effort result without retrying.
class PlatformAdapterResult {
  const PlatformAdapterResult({
    required this.result,
    this.limited = false,
    this.reason,
    this.source,
  });

  final MetadataResult result;
  final bool limited;
  final String? reason;
  final String? source;
}

/// Platform-specific metadata fetcher.
///
/// Each adapter handles one or more related domains (e.g. Bilibili, Weibo,
/// GitHub). When a platform restricts access (login wall, 412, 403), the
/// adapter should return a [PlatformAdapterResult] with [limited]=true and a
/// best-effort [result] (title fallback, fixed favicon), rather than throwing
/// or entering a retry loop.
abstract interface class PlatformMetadataAdapter {
  /// Whether this adapter can handle [uri].
  bool canHandle(Uri uri);

  /// Fetch and parse metadata from [uri].
  ///
  /// Throws on network or parse errors — the caller may fall back to the
  /// generic provider.  Returns a limited success when the platform restricts
  /// access, so the enrichment status can be marked success instead of
  /// repeated retries.
  Future<PlatformAdapterResult> fetch(Uri uri);
}
