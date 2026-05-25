import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../domain/collection_models.dart';
import 'collection_debug_logger.dart';
import 'html_metadata_parser.dart';
import 'metadata_provider.dart';

/// Thrown when metadata cannot be fetched (non-2xx response, non-HTML
/// content type, etc.).
class MetadataFetchException implements Exception {
  final String message;
  const MetadataFetchException(this.message);

  @override
  String toString() => 'MetadataFetchException: $message';
}

/// Fetches a URL and extracts metadata using [HtmlMetadataParser].
///
/// Changes from the previous regex-based implementation:
/// - DOM-based HTML parsing via [package:html] (robust to attribute order)
/// - Charset detection from Content-Type header and HTML meta tags
/// - Non-2xx responses and non-HTML content types rejected
/// - 1 MB body limit
/// - Supports og:title → twitter:title → application-name → <title> fallback
/// - Supports og:description → twitter:description → meta[name=description]
/// - Supports og:image → twitter:image → twitter:image:src → link[rel=image_src]
/// - Supports og:site_name / application-name
/// - Supports article:author / meta[name=author] / meta[name=byl]
class LocalMetadataProvider implements MetadataProvider {
  LocalMetadataProvider({HttpClient? client})
      : _client = client ?? HttpClient();

  final HttpClient _client;

  /// Maximum bytes to read from the response body (1 MB).
  static const int _maxBodyBytes = 1 << 20; // 1,048,576

  @override
  Future<MetadataResult> fetchMetadata(String url) async {
    final uri = Uri.parse(url);
    final request = await _client
        .getUrl(uri)
        .timeout(const Duration(seconds: 8));
    request.followRedirects = true;

    // 设置浏览器级请求头
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

    CollectionDebugLogger.log('metadata fetch start url=$url');
    final response = await request.close().timeout(const Duration(seconds: 10));

    // ── 1. Validate status code ────────────────────────────────────────
    if (response.statusCode < 200 || response.statusCode >= 300) {
      CollectionDebugLogger.warn(
        'metadata fetch non-2xx status=${response.statusCode} url=$url',
      );
      throw MetadataFetchException(
        'HTTP ${response.statusCode} ${response.reasonPhrase}',
      );
    }

    // ── 2. Validate Content-Type (only parse HTML / XHTML) ────────────
    final contentType = response.headers.contentType;
    final mimeType = contentType?.mimeType.toLowerCase() ?? '';
    final isHtml =
        mimeType.contains('text/html') ||
        mimeType.contains('application/xhtml+xml') ||
        mimeType.contains('application/xml');
    if (!isHtml && mimeType.isNotEmpty) {
      CollectionDebugLogger.warn(
        'metadata fetch non-HTML contentType=$mimeType url=$url',
      );
      throw MetadataFetchException('Not HTML: $mimeType');
    }

    // ── 3. Read body (max 1 MB) ───────────────────────────────────────
    final rawBytes = await _readBody(response);
    CollectionDebugLogger.log(
      'metadata fetch response status=${response.statusCode} '
      'contentType=${contentType?.value} bodyLength=${rawBytes.length}',
    );

    // ── 4. Detect charset & decode ────────────────────────────────────
    final charset = _detectCharset(contentType?.value, rawBytes);
    final html = _decodeBody(rawBytes, charset);

    // ── 5. Parse metadata ─────────────────────────────────────────────
    final parser = HtmlMetadataParser.parse(html, baseUrl: url);
    final metadata = parser.result;

    CollectionDebugLogger.log(
      'metadata parsed title=${metadata.title} '
      'hasDescription=${metadata.description != null && metadata.description!.isNotEmpty} '
      'coverImage=${metadata.coverImage} favicon=${metadata.favicon}',
    );

    return metadata;
  }

  /// Collect all bytes from a stream, capping at [_maxBodyBytes].
  Future<List<int>> _readBody(Stream<List<int>> stream) async {
    final chunks = <List<int>>[];
    int total = 0;

    await for (final chunk in stream) {
      if (total >= _maxBodyBytes) break;
      final remaining = _maxBodyBytes - total;
      if (chunk.length > remaining) {
        chunks.add(chunk.sublist(0, remaining));
        break;
      }
      chunks.add(chunk);
      total += chunk.length;
    }

    if (chunks.isEmpty) return const <int>[];
    if (chunks.length == 1) return chunks.first;
    return chunks.expand((c) => c).toList(growable: false);
  }

  // ---------------------------------------------------------------------------
  // Charset detection
  // ---------------------------------------------------------------------------

  /// Detect the character encoding used by an HTML response.
  ///
  /// Strategy (matching browser behaviour):
  ///   1. Content-Type header `charset` parameter
  ///   2. BOM (Byte Order Mark)
  ///   3. `<meta charset="...">` tag (scanned from preamble as Latin-1)
  ///   4. `<meta http-equiv="Content-Type" ... charset=...>` tag
  ///   5. Fallback to UTF-8
  Encoding _detectCharset(String? contentTypeHeader, List<int> rawBytes) {
    // 1. Content-Type header
    if (contentTypeHeader != null) {
      final charsetMatch = RegExp(
        r"charset\s*=\s*([^\s;'']+)",
        caseSensitive: false,
      ).firstMatch(contentTypeHeader);
      if (charsetMatch != null) {
        final name = charsetMatch.group(1)!.trim().toLowerCase();
        if (name == 'utf-8' || name == 'utf8') return utf8;
        final encoding = Encoding.getByName(name);
        if (encoding != null) return encoding;
      }
    }

    // 2. BOM
    if (rawBytes.length >= 3 &&
        rawBytes[0] == 0xEF &&
        rawBytes[1] == 0xBB &&
        rawBytes[2] == 0xBF) {
      return utf8;
    }

    // 3 & 4. Scan first 4 KB as Latin-1 (lossless for the ASCII range)
    final preambleLen = rawBytes.length > 4096 ? 4096 : rawBytes.length;
    final preamble = String.fromCharCodes(rawBytes.take(preambleLen));

    // <meta charset="xxx">
    final metaCharsetMatch = RegExp(
      r'''<meta[^>]+charset\s*=\s*["']?\s*([^"'\s;>/]+)''',
      caseSensitive: false,
    ).firstMatch(preamble);
    if (metaCharsetMatch != null) {
      final name = metaCharsetMatch.group(1)!.trim().toLowerCase();
      if (name == 'utf-8' || name == 'utf8') return utf8;
      final encoding = Encoding.getByName(name);
      if (encoding != null) return encoding;
    }

    // <meta http-equiv="Content-Type" content="...; charset=xxx">
    final httpEquivMatch = RegExp(
      r'''<meta[^>]+http-equiv\s*=\s*["']?\s*content-type\s*["']?[^>]+content\s*=\s*["'][^"']*charset\s*=\s*([^"'\s;]+)''',
      caseSensitive: false,
    ).firstMatch(preamble);
    if (httpEquivMatch != null) {
      final name = httpEquivMatch.group(1)!.trim().toLowerCase();
      if (name == 'utf-8' || name == 'utf8') return utf8;
      final encoding = Encoding.getByName(name);
      if (encoding != null) return encoding;
    }

    // 5. Default
    return utf8;
  }

  /// Decode raw bytes using the detected encoding.
  ///
  /// For UTF-8, uses permissive decoding (replaces invalid sequences with
  /// U+FFFD) to handle pages with minor encoding issues.
  String _decodeBody(List<int> rawBytes, Encoding encoding) {
    if (encoding == utf8) {
      return utf8.decode(rawBytes, allowMalformed: true);
    }
    return encoding.decode(rawBytes);
  }
}
