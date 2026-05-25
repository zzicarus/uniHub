import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uni_hub/src/core/database/app_database.dart';

import '../data/website_logo_cache_dao.dart';

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
    HttpClient? client,
    Directory? logosDirectory,
  }) : _dao = dao,
       _client = client ?? HttpClient(),
       _logosDirectory = logosDirectory;

  final WebsiteLogoCacheDao _dao;
  final HttpClient _client;
  final Directory? _logosDirectory;

  /// Tracks in-flight downloads per siteKey to prevent concurrent duplicates.
  final Map<String, Future<WebsiteLogoCacheEntry?>> _inFlight = {};

  /// Default cache dir, lazily initialised and cached across instances.
  static Directory? _defaultCacheDir;

  Future<Directory> _getLogosDir() async {
    if (_logosDirectory != null) return _logosDirectory;
    final dir = _defaultCacheDir ?? Directory(
      '${(await getApplicationCacheDirectory()).path}/website_logos',
    );
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    _defaultCacheDir ??= dir;
    return dir;
  }

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
    final row = await _dao.getBySiteKey(siteKey);

    if (row != null && _isEntryValid(row)) {
      return WebsiteLogoCacheEntry(
        siteKey: row.siteKey,
        localLogoPath: row.localLogoPath,
        status: row.status,
      );
    }

    // Need to fetch
    try {
      return await _fetchAndCache(
        siteKey: siteKey,
        host: host,
        remoteFaviconUrl: remoteFaviconUrl,
      );
    } catch (e) {
      // If we had a previous failed row, update it; otherwise create one
      if (row != null) {
        await _dao.markFailed(row.id, e.toString());
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
            expiresAt: Value(now.add(const Duration(hours: 24))),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
      }
      debugPrint('WebsiteLogoCache: failed to cache logo for $siteKey: $e');
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

  /// Whether an existing cache entry is still valid.
  bool _isEntryValid(WebsiteLogoCacheTableData row) {
    if (row.status == 'success' && row.expiresAt != null) {
      // Verify the local file actually exists.
      if (row.localLogoPath == null || row.localLogoPath!.isEmpty) {
        return false;
      }
      if (!File(row.localLogoPath!).existsSync()) {
        return false;
      }
      return DateTime.now().isBefore(row.expiresAt!);
    }
    if (row.status == 'failed' && row.expiresAt != null) {
      // Failed entries also have a retry delay
      return DateTime.now().isBefore(row.expiresAt!);
    }
    return false;
  }

  /// Download and cache a favicon.
  Future<WebsiteLogoCacheEntry> _fetchAndCache({
    required String siteKey,
    required String host,
    String? remoteFaviconUrl,
  }) async {
    final url = remoteFaviconUrl ?? 'https://$host/favicon.ico';
    final uri = Uri.parse(url);

    // Explicitly restrict favicon URLs to http/https only
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      throw ArgumentError('Unsupported favicon URL scheme: ${uri.scheme}');
    }

    // Fetch
    final request = await _client.getUrl(uri).timeout(const Duration(seconds: 8));
    request.followRedirects = true;
    final response = await request.close().timeout(const Duration(seconds: 8));

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
    final ext = _extensionForMimeType(mimeType, url);

    // Save to local file
    final dir = await _getLogosDir();
    final fileName = '${_safeFileName(siteKey)}$ext';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);

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
  String _extensionForMimeType(String? mimeType, String url) {
    if (mimeType == null) return _extFromUrl(url);

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
      default:
        return _extFromUrl(url);
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
}
