import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:uni_hub/src/core/database/app_database.dart';

import '../data/website_logo_cache_dao.dart';
import 'collection_debug_logger.dart';

/// Result returned by [WebsiteLogoCacheService.clearCache].
class CacheClearResult {
  final int deletedFiles;
  final int deletedDbRows;
  final int freedBytes;

  const CacheClearResult({
    required this.deletedFiles,
    required this.deletedDbRows,
    required this.freedBytes,
  });
}

/// Result returned by [WebsiteLogoCacheService] for UI consumption.
class WebsiteLogoCacheEntry {
  const WebsiteLogoCacheEntry({
    required this.siteKey,
    this.localLogoPath,
    this.status = 'pending',
  });

  final String siteKey;
  final String? localLogoPath;
  final String status;

  bool get isReady => status == 'success' && localLogoPath != null;
}

/// Manages site-level favicon caching.
///
/// Responsibilities:
/// - Compute site keys from URLs
/// - Query the cache table
/// - Download favicons to local storage
/// - Manage TTL-based expiration
/// - Provide cached entries for UI display
class WebsiteLogoCacheService {
  WebsiteLogoCacheService({
    required WebsiteLogoCacheDao dao,
    required Directory logosDir,
    HttpClient? client,
  }) : _dao = dao,
       _logosDir = logosDir,
       _client = client ?? HttpClient();

  final WebsiteLogoCacheDao _dao;
  final Directory _logosDir;
  final HttpClient _client;

  /// Tracks in-flight downloads per siteKey to prevent concurrent duplicates.
  final Map<String, Future<WebsiteLogoCacheEntry?>> _inFlight = {};

  // ------------------------------------------------------------------
  // Public API
  // ------------------------------------------------------------------

  /// Return a cached logo entry for [pageUrl], or null if not cached.
  ///
  /// Never performs network I/O — safe to call from the UI layer.
  Future<WebsiteLogoCacheEntry?> getCachedLogo(String pageUrl) async {
    final key = siteKey(pageUrl);
    final row = await _dao.getBySiteKey(key);
    if (row == null) return null;

    return WebsiteLogoCacheEntry(
      siteKey: row.siteKey,
      localLogoPath: row.localLogoPath,
      status: row.status,
    );
  }

  /// Ensure a logo is cached for [pageUrl].
  ///
  /// If a valid (success, not expired) cache entry exists, returns it
  /// immediately.  Otherwise triggers a background download.
  ///
  /// [remoteFaviconUrl] is the favicon URL parsed from the page metadata
  /// (optional — when null the service falls back to /favicon.ico).
  /// Ensure a logo is cached for [pageUrl].
  ///
  /// If a valid (success, not expired) cache entry exists, returns it
  /// immediately.  Otherwise triggers a background download.
  ///
  /// Guarantees that concurrent calls for the same [pageUrl] only trigger
  /// one network request — subsequent calls share the in-flight future.
  ///
  /// [remoteFaviconUrl] is the favicon URL parsed from the page metadata
  /// (optional — when null the service falls back to /favicon.ico).
  Future<WebsiteLogoCacheEntry?> ensureLogoCached({
    required String pageUrl,
    String? remoteFaviconUrl,
  }) async {
    final key = siteKey(pageUrl);

    // In-flight dedup: return the existing future if one is already running.
    final existing = _inFlight[key];
    if (existing != null) return existing;

    final future = _ensureLogoCachedInternal(
      pageUrl: pageUrl,
      remoteFaviconUrl: remoteFaviconUrl,
      siteKey: key,
    );

    _inFlight[key] = future;
    future.whenComplete(() => _inFlight.remove(key));
    return future;
  }

  Future<WebsiteLogoCacheEntry?> _ensureLogoCachedInternal({
    required String pageUrl,
    String? remoteFaviconUrl,
    required String siteKey,
  }) async {
    final host = Uri.tryParse(pageUrl)?.host ?? siteKey;
    CollectionDebugLogger.log(
      'logo cache start pageUrl=$pageUrl siteKey=$siteKey remoteFaviconUrl=$remoteFaviconUrl',
    );

    final row = await _dao.getBySiteKey(siteKey);
    if (row != null) {
      CollectionDebugLogger.log(
        'logo cache row exists status=${row.status} localLogoPath=${row.localLogoPath} expiresAt=${row.expiresAt} remoteFaviconUrl=$remoteFaviconUrl',
      );

      if (_isSuccessEntryUsable(row)) {
        CollectionDebugLogger.log(
          'logo cache hit success siteKey=$siteKey path=${row.localLogoPath}',
        );
        return WebsiteLogoCacheEntry(
          siteKey: row.siteKey,
          localLogoPath: row.localLogoPath,
          status: row.status,
        );
      }

      if (_shouldSkipFailedRetry(row, remoteFaviconUrl: remoteFaviconUrl)) {
        CollectionDebugLogger.warn(
          'logo cache skip retry failed cooldown siteKey=$siteKey expiresAt=${row.expiresAt}',
        );
        return WebsiteLogoCacheEntry(
          siteKey: row.siteKey,
          localLogoPath: null,
          status: row.status,
        );
      }

      CollectionDebugLogger.log(
        'logo cache retry stale-or-failed siteKey=$siteKey status=${row.status}',
      );
    }

    // Need to fetch
    CollectionDebugLogger.log('logo cache fetch start siteKey=$siteKey');
    try {
      return await _fetchAndCache(
        siteKey: siteKey,
        host: host,
        remoteFaviconUrl: remoteFaviconUrl,
      );
    } catch (e) {
      // If we had a previous failed row, update it; otherwise create one
      if (row != null) {
        await _dao.markFailed(row.id, e.toString(), retryDelay: _failedTtl);
      } else {
        final now = DateTime.now();
        await _dao.upsert(
          WebsiteLogoCacheTableCompanion(
            siteKey: Value(siteKey),
            host: Value(host),
            remoteLogoUrl: remoteFaviconUrl != null
                ? Value(remoteFaviconUrl)
                : const Value.absent(),
            status: const Value('failed'),
            lastError: Value(e.toString()),
            expiresAt: Value(now.add(_failedTtl)),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
      }
      CollectionDebugLogger.warn('logo cache failed siteKey=$siteKey error=$e');
      return null;
    }
  }

  /// Force-refresh the cached logo for [pageUrl].
  Future<WebsiteLogoCacheEntry?> refreshLogo({
    required String pageUrl,
    String? remoteFaviconUrl,
  }) async {
    final key = siteKey(pageUrl);
    final host = Uri.tryParse(pageUrl)?.host ?? key;
    try {
      return await _fetchAndCache(siteKey: key, host: host, remoteFaviconUrl: remoteFaviconUrl);
    } catch (e) {
      debugPrint('WebsiteLogoCache: failed to refresh logo for $key: $e');
      return null;
    }
  }

  // ------------------------------------------------------------------
  // Site key computation
  // ------------------------------------------------------------------

  /// Compute a stable site key from a URL.
  ///
  /// Rules:
  /// - Lowercase
  /// - Strip leading "www."
  /// - Return host only (no path/query)
  ///
  /// Examples:
  ///   https://www.Bilibili.com/video/...  →  bilibili.com
  ///   https://bilibili.com                →  bilibili.com
  static String siteKey(String url) {
    final host = Uri.tryParse(url)?.host ?? url;
    var lowered = host.toLowerCase();
    if (lowered.startsWith('www.')) {
      lowered = lowered.substring(4);
    }
    return lowered;
  }

  // ------------------------------------------------------------------
  // Internal helpers
  // ------------------------------------------------------------------

  /// Whether a success cache entry is usable by the UI.
  ///
  /// Returns true only when:
  /// - status is 'success'
  /// - Not expired
  /// - Local file exists on disk
  bool _isSuccessEntryUsable(WebsiteLogoCacheTableData row) {
    if (row.status != 'success') return false;
    if (row.expiresAt == null) return false;
    if (!DateTime.now().isBefore(row.expiresAt!)) return false;

    final path = row.localLogoPath;
    if (path == null || path.isEmpty) return false;

    if (!File(path).existsSync()) {
      CollectionDebugLogger.warn(
        'logo success entry file missing siteKey=${row.siteKey} path=$path',
      );
      return false;
    }

    return true;
  }

  /// Whether to skip retrying a failed entry.
  ///
  /// Returns true (skip retry) only when:
  /// - status is 'failed'
  /// - Not yet expired (cooling down)
  /// - No new [remoteFaviconUrl] is available (otherwise we must retry)
  /// - Debug logging is DISABLED (during development always retry)
  bool _shouldSkipFailedRetry(
    WebsiteLogoCacheTableData row, {
    required String? remoteFaviconUrl,
  }) {
    if (row.status != 'failed') return false;
    if (row.expiresAt == null) return false;
    if (!DateTime.now().isBefore(row.expiresAt!)) return false;

    // If we've obtained a specific favicon URL from metadata, don't let
    // the old failed entry block the re-fetch.
    if (remoteFaviconUrl != null && remoteFaviconUrl.trim().isNotEmpty) {
      return false;
    }

    // During development with debug logging enabled, always retry failed
    // entries instead of waiting for the cooldown to expire.
    if (CollectionDebugLogger.enabled) {
      return false;
    }

    return true;
  }

  /// In debug mode, failed entries cool down for 10 minutes so developers
  /// can quickly re-test. In production, cool down for 24 hours to avoid
  /// hammering sites that don't serve favicons.
  Duration get _failedTtl =>
      CollectionDebugLogger.enabled
          ? const Duration(minutes: 10)
          : const Duration(hours: 24);

  /// Download and cache a favicon using multi-candidate fallback.
  ///
  /// Tries candidates in order: the metadata-parsed favicon URL,
  /// /favicon.ico, www variant /favicon.ico, and /favicon.png.
  /// Returns the first successful result; throws if all candidates fail.
  Future<WebsiteLogoCacheEntry> _fetchAndCache({
    required String siteKey,
    required String host,
    String? remoteFaviconUrl,
  }) async {
    final candidates = <String>[];

    // 1. The parsed favicon URL from metadata
    if (remoteFaviconUrl != null && remoteFaviconUrl.isNotEmpty) {
      candidates.add(remoteFaviconUrl);
    }

    // 2. /favicon.ico at the root
    candidates.add('https://$host/favicon.ico');

    // 3. www variant if host doesn't start with www
    if (!host.startsWith('www.')) {
      candidates.add('https://www.$host/favicon.ico');
    }

    // 4. PNG fallback
    candidates.add('https://$host/favicon.png');

    // Deduplicate while preserving order
    final unique = candidates.toSet().toList();

    Object? lastError;
    for (final candidateUrl in unique) {
      try {
        CollectionDebugLogger.log('logo candidate fetch url=$candidateUrl');
        return await _tryFetchCandidate(
          siteKey: siteKey,
          host: host,
          remoteFaviconUrl: remoteFaviconUrl,
          faviconUrl: candidateUrl,
        );
      } catch (e) {
        CollectionDebugLogger.warn(
          'logo candidate failed url=$candidateUrl error=$e',
        );
        lastError = e;
        continue;
      }
    }

    throw lastError ?? Exception('All favicon candidates failed for $siteKey');
  }

  /// Fetch and cache a single favicon URL candidate.
  Future<WebsiteLogoCacheEntry> _tryFetchCandidate({
    required String siteKey,
    required String host,
    String? remoteFaviconUrl,
    required String faviconUrl,
  }) async {
    final url = faviconUrl;
    final uri = Uri.parse(url);

    // Explicitly restrict favicon URLs to http/https only
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      CollectionDebugLogger.warn(
        'logo fetch rejected scheme=${uri.scheme} url=$url',
      );
      throw ArgumentError('Unsupported favicon URL scheme: ${uri.scheme}');
    }

    // Fetch
    final request = await _client.getUrl(uri).timeout(const Duration(seconds: 8));
    request.followRedirects = true;
    final response = await request.close().timeout(const Duration(seconds: 8));

    final contentLength = response.headers.value(HttpHeaders.contentLengthHeader);
    CollectionDebugLogger.log(
      'logo fetch response status=${response.statusCode} '
      'contentType=${response.headers.contentType?.value} '
      'contentLength=$contentLength',
    );

    if (response.statusCode != 200) {
      throw HttpException(
        'Favicon fetch failed with status ${response.statusCode}',
        uri: uri,
      );
    }

    // Read body with size limit (512 KB)
    final bytes = await _readWithLimit(response, maxBytes: 512 * 1024);

    // Determine mime type and extension
    final mimeType = response.headers.value(HttpHeaders.contentTypeHeader);

    // Check if response is HTML (blocked/redirected favicon)
    final contentTypeLower = (mimeType ?? '').toLowerCase();
    if (contentTypeLower.contains('text/html') ||
        contentTypeLower.contains('text/plain')) {
      final preview = utf8.decode(bytes.take(200).toList(), allowMalformed: true).toLowerCase();
      if (preview.contains('<!doctype html') ||
          preview.contains('<html') ||
          contentTypeLower.contains('text/html')) {
        CollectionDebugLogger.warn(
          'Favicon response is HTML (blocked/invalid): $url',
        );
        throw HttpException(
          'Favicon response is HTML, probably blocked or invalid: $url',
          uri: uri,
        );
      }
    }

    // Reject unsupported content types (favicon must be an image or allowed binary)
    final baseContentType = (mimeType ?? '').split(';').first.trim().toLowerCase();
    final ext = _extensionForMimeType(mimeType, url);
    final looksLikeImageType = baseContentType.startsWith('image/');
    final allowedBinaryIco =
        baseContentType == 'application/octet-stream' && ext == '.ico';

    if (baseContentType.isNotEmpty &&
        !looksLikeImageType &&
        !allowedBinaryIco) {
      throw HttpException(
        'Unsupported favicon content-type: $baseContentType',
        uri: uri,
      );
    }

    CollectionDebugLogger.log(
      'logo fetch bytesLength=${bytes.length} ext=$ext',
    );

    // Save to local file
    if (!_logosDir.existsSync()) {
      await _logosDir.create(recursive: true);
    }
    final fileName = '${_safeFileName(siteKey)}$ext';
    final file = File('${_logosDir.path}/$fileName');
    await file.writeAsBytes(bytes);

    CollectionDebugLogger.log(
      'logo saved path=${file.path}',
    );

    // Upsert database
    final now = DateTime.now();
    await _dao.upsert(
      WebsiteLogoCacheTableCompanion(
        siteKey: Value(siteKey),
        host: Value(host),
        remoteLogoUrl: remoteFaviconUrl != null ? Value(remoteFaviconUrl) : const Value.absent(),
        localLogoPath: Value(file.path),
        mimeType: mimeType != null ? Value(mimeType) : const Value.absent(),
        status: const Value('success'),
        lastError: const Value(null),
        fetchedAt: Value(now),
        expiresAt: Value(now.add(const Duration(days: 30))),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );
    CollectionDebugLogger.log(
      'logo dao upsert success siteKey=$siteKey',
    );

    return WebsiteLogoCacheEntry(
      siteKey: siteKey,
      localLogoPath: file.path,
      status: 'success',
    );
  }

  /// Read a response stream up to [maxBytes].
  Future<List<int>> _readWithLimit(
    HttpClientResponse response, {
    required int maxBytes,
  }) async {
    int total = 0;
    final chunks = <List<int>>[];
    await for (final chunk in response) {
      total += chunk.length;
      if (total > maxBytes) {
        throw const HttpException('Favicon exceeds maximum size (512KB)');
      }
      chunks.add(chunk);
    }
    return chunks.expand((c) => c).toList();
  }

  /// Map MIME type or URL to a file extension.
  ///
  /// Handles MIME types with parameters (e.g. "image/png; charset=utf-8")
  /// by stripping everything after the first semicolon.
  /// Allows application/octet-stream for .ico URLs.
  String _extensionForMimeType(String? mimeType, String url) {
    final extFromUrl = _extFromUrl(url);
    if (mimeType == null) return extFromUrl;

    // Strip charset or any MIME parameters
    final base = mimeType.split(';').first.trim().toLowerCase();

    switch (base) {
      case 'image/x-icon':
      case 'image/vnd.microsoft.icon':
        return '.ico';
      case 'image/png':
        return '.png';
      case 'image/svg+xml':
        return '.svg';
      case 'image/jpeg':
      case 'image/jpg':
        return '.jpg';
      case 'image/webp':
        return '.webp';
      case 'image/gif':
        return '.gif';
      case 'application/octet-stream':
        // Allow octet-stream for .ico URLs (some servers serve .ico this way)
        if (extFromUrl == '.ico') return '.ico';
        return extFromUrl;
      default:
        return extFromUrl;
    }
  }

  /// Guess extension from the URL path.
  String _extFromUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      final path = uri.path;
      final dot = path.lastIndexOf('.');
      if (dot > 0 && dot < path.length - 1) {
        final candidate = path.substring(dot);
        if (RegExp(
          r'\.(ico|png|jpg|jpeg|svg|webp|gif)$',
          caseSensitive: false,
        ).hasMatch(candidate)) {
          return candidate.toLowerCase();
        }
      }
    }
    return '.png';
  }

  /// Create a filesystem-safe name from a site key.
  String _safeFileName(String key) {
    return base64Url.encode(utf8.encode(key));
  }

  // ------------------------------------------------------------------
  // Cache clearing
  // ------------------------------------------------------------------

  /// 清除所有本地 Logo 缓存文件和数据库记录。
  ///
  /// 流程：
  /// 1. 丢弃所有 in-flight 下载
  /// 2. 统计缓存目录大小
  /// 3. 删除所有缓存文件
  /// 4. 清空数据库记录
  ///
  /// 并发安全：先清空 [_inFlight]，后删除文件。
  Future<CacheClearResult> clearCache() async {
    // 1. 丢弃 in-flight 下载
    for (final entry in _inFlight.entries) {
      entry.value.ignore();
    }
    _inFlight.clear();

    // 2. 统计大小
    final dir = _logosDir;
    int totalSize = 0;
    int fileCount = 0;
    if (dir.existsSync()) {
      try {
        for (final entity in dir.listSync(recursive: true, followLinks: false)) {
          if (entity is File) {
            totalSize += entity.lengthSync();
            fileCount++;
          }
        }
      } catch (_) {}
    }

    // 3. 删除文件并重建空目录
    if (dir.existsSync()) {
      await dir.delete(recursive: true);
      await dir.create(recursive: true);
    }

    // 4. 清空数据库记录
    final deletedRows = await _dao.clearAll();

    return CacheClearResult(
      deletedFiles: fileCount,
      deletedDbRows: deletedRows,
      freedBytes: totalSize,
    );
  }
}
