import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../domain/collection_models.dart';
import '../../domain/enrichment_status.dart';
import '../../services/collection_debug_logger.dart';
import '../../services/html_metadata_parser.dart';
import '../../services/platform_metadata_adapter.dart';

/// Bilibili-specific metadata adapter.
///
/// Supports bilibili.com, www.bilibili.com, m.bilibili.com, and b23.tv.
/// b23.tv URLs are followed via redirect to get the canonical page.
///
/// On 412 / 403 (anti-crawl), returns limited success with fixed siteName
/// and favicon, avoiding repeated retry.
class BilibiliMetadataAdapter implements PlatformMetadataAdapter {
  BilibiliMetadataAdapter({HttpClient? client})
      : _client = client ?? HttpClient();

  final HttpClient _client;
  static const _timeout = Duration(seconds: 8);

  static const _supportedHosts = <String>{
    'bilibili.com',
    'www.bilibili.com',
    'm.bilibili.com',
    'b23.tv',
  };

  @override
  bool canHandle(Uri uri) {
    final host = uri.host.toLowerCase();
    return _supportedHosts.any((h) => host == h || host.endsWith('.$h'));
  }

  @override
  Future<PlatformAdapterResult> fetch(Uri uri) async {
    // Follow b23.tv short URLs to the real page
    var targetUri = uri;
    if (targetUri.host.toLowerCase() == 'b23.tv') {
      targetUri = await _followRedirect(targetUri);
      CollectionDebugLogger.log(
        'bilibili b23.tv resolved to=$targetUri',
      );
    }

    final request = await _client
        .getUrl(targetUri)
        .timeout(_timeout);
    request.followRedirects = true;

    _setBrowserHeaders(request);

    final response = await request.close().timeout(_timeout);

    // 412 / 403 / 429 → limited success
    if (response.statusCode == 412 ||
        response.statusCode == 403 ||
        response.statusCode == 429) {
      return _limitedSuccess(
        targetUri,
        reason: 'http_${response.statusCode}',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      CollectionDebugLogger.warn(
        'bilibili non-2xx status=${response.statusCode} url=$targetUri',
      );
      throw HttpException(
        'Bilibili HTTP ${response.statusCode}',
        uri: targetUri,
      );
    }

    final contentType = response.headers.contentType?.mimeType ?? '';
    if (!contentType.contains('text/html') && contentType.isNotEmpty) {
      throw const HttpException('Bilibili non-HTML response');
    }

    final bytes = await _readBody(response);
    final html = utf8.decode(bytes, allowMalformed: true);

    final parser = HtmlMetadataParser.parse(html, baseUrl: targetUri.toString());
    final metadata = parser.result;

    return PlatformAdapterResult(
      result: MetadataResult(
        title: metadata.title,
        description: metadata.description,
        siteName: metadata.siteName ?? 'Bilibili',
        coverImage: metadata.coverImage,
        favicon: metadata.favicon,
        metadataJson: jsonEncode({
          'source': 'bilibili_adapter',
          'finalUrl': targetUri.toString(),
        }),
        status: EnrichmentStatus.success,
      ),
      source: 'bilibili_adapter',
    );
  }

  Future<Uri> _followRedirect(Uri uri) async {
    try {
      final request = await _client.getUrl(uri).timeout(_timeout);
      request.followRedirects = false;
      final response = await request.close().timeout(_timeout);
      // Consume the response body to free resources
      await response.drain<List<int>>();
      final location = response.headers.value(HttpHeaders.locationHeader);
      if (location != null && location.isNotEmpty) {
        final resolved = uri.resolve(location);
        CollectionDebugLogger.log(
          'b23.tv redirect location=$resolved',
        );
        return resolved;
      }
    } catch (_) {}
    return uri;
  }

  PlatformAdapterResult _limitedSuccess(Uri uri, {required String reason}) {
    return PlatformAdapterResult(
      result: MetadataResult(
        title: uri.toString(),
        description: null,
        siteName: 'Bilibili',
        favicon: 'https://www.bilibili.com/favicon.ico',
        metadataJson: jsonEncode({
          'source': 'bilibili_adapter',
          'limited': true,
          'reason': reason,
        }),
        status: EnrichmentStatus.success,
      ),
      limited: true,
      reason: reason,
      source: 'bilibili_adapter',
    );
  }

  void _setBrowserHeaders(HttpClientRequest request) {
    request.headers.set(
      HttpHeaders.userAgentHeader,
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    );
    request.headers.set(
      HttpHeaders.acceptHeader,
      'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    );
    request.headers.set(
      HttpHeaders.acceptLanguageHeader,
      'zh-CN,zh;q=0.9,en;q=0.8',
    );
  }

  Future<List<int>> _readBody(Stream<List<int>> stream) async {
    const maxBytes = 1 << 20; // 1 MB
    final chunks = <List<int>>[];
    int total = 0;

    await for (final chunk in stream) {
      if (total >= maxBytes) break;
      final remaining = maxBytes - total;
      if (chunk.length > remaining) {
        chunks.add(chunk.sublist(0, remaining));
        total += remaining;
        break;
      }
      chunks.add(chunk);
      total += chunk.length;
    }

    if (chunks.isEmpty) return const <int>[];
    if (chunks.length == 1) return chunks.first;
    return chunks.expand((c) => c).toList(growable: false);
  }
}
