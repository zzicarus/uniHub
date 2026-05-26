import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uni_hub/src/core/database/app_database.dart';
import 'package:uni_hub/src/core/plugin/plugin_registry.dart';
import 'package:uni_hub/src/plugins/collections/collections_plugin.dart';
import 'package:uni_hub/src/plugins/collections/data/website_logo_cache_dao.dart';
import 'package:uni_hub/src/plugins/collections/services/website_logo_cache_service.dart';

// ---------------------------------------------------------------------------
// Mock HTTP infrastructure
// ---------------------------------------------------------------------------

/// Configuration for a single mock response.
class _MockResponseConfig {
  _MockResponseConfig({
    required this.statusCode,
    required this.body,
    this.contentType,
  });

  final int statusCode;
  final List<int> body;
  final String? contentType;
}

/// Records every URL that was fetched through the mock client.
class _MockHttpClient implements HttpClient {
  _MockHttpClient(this._responseFactory);

  final _MockResponseConfig Function(String url) _responseFactory;

  final List<String> fetchedUrls = [];

  @override
  Future<_MockHttpClientRequest> getUrl(Uri url) async {
    fetchedUrls.add(url.toString());
    return _MockHttpClientRequest(_responseFactory(url.toString()));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _MockHttpClientRequest implements HttpClientRequest {
  _MockHttpClientRequest(this._config);

  final _MockResponseConfig _config;

  @override
  bool followRedirects = true;

  @override
  Future<_MockHttpClientResponse> close() async =>
      _MockHttpClientResponse(_config);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _MockHttpClientResponse implements HttpClientResponse {
  _MockHttpClientResponse(this._config);

  final _MockResponseConfig _config;

  @override
  int get statusCode => _config.statusCode;

  @override
  String get reasonPhrase => _config.statusCode == 200 ? 'OK' : 'Not Found';

  @override
  int get contentLength => _config.body.length;

  @override
  bool get persistentConnection => false;

  @override
  bool get isRedirect => false;

  @override
  List<RedirectInfo> get redirects => [];

  @override
  List<Cookie> get cookies => [];

  @override
  X509Certificate? get certificate => null;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  HttpHeaders get headers {
    final headers = _MockHttpHeaders();
    if (_config.contentType != null) {
      headers.set(HttpHeaders.contentTypeHeader, _config.contentType!);
    }
    return headers;
  }

  @override
  Future<Socket> detachSocket() => throw UnimplementedError();

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.value(_config.body).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _MockHttpHeaders implements HttpHeaders {
  final _values = <String, String>{};

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    _values[name] = value.toString();
  }

  @override
  String? value(String name) => _values[name];

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// A 1×1 transparent PNG in byte form (minimal valid PNG).
List<int> _minimalPng() {
  // Minimal valid PNG: 1x1 pixel, 8-bit RGBA
  final png = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAA'
    'ABJRU5ErkJggg==',
  );
  return png;
}

/// A minimal ICO file (1x1 32bpp).
List<int> _minimalIco() {
  // Minimal ICO file header + 1x1 32bpp entry (just enough to exist)
  return [
    0x00, 0x00, // reserved
    0x01, 0x00, // ICO type
    0x01, 0x00, // 1 image
    0x01, 0x01, // width=1, height=1
    0x00,       // palette
    0x00,       // reserved
    0x01, 0x00, // color planes
    0x20, 0x00, // 32 bpp
    0x2C, 0x00, 0x00, 0x00, // data size (44 bytes)
    0x16, 0x00, 0x00, 0x00, // offset
    // BITMAPINFOHEADER + raw pixel (1x1 blue pixel)
    0x28, 0x00, 0x00, 0x00, // header size
    0x01, 0x00, 0x00, 0x00, // width
    0x01, 0x00, 0x00, 0x00, // height
    0x01, 0x00,             // planes
    0x20, 0x00,             // bpp
    0x00, 0x00, 0x00, 0x00, // compression
    0x00, 0x00, 0x00, 0x00, // image size
    0x00, 0x00, 0x00, 0x00, // x pixels per meter
    0x00, 0x00, 0x00, 0x00, // y pixels per meter
    0x00, 0x00, 0x00, 0x00, // colors used
    0x00, 0x00, 0x00, 0x00, // important colors
    0xFF, 0x00, 0x00, 0x00, // blue pixel (BGRA)
  ];
}

/// Returns a `_MockResponseConfig` for a PNG favicon.
_MockResponseConfig _pngConfig({int statusCode = 200}) {
  return _MockResponseConfig(
    statusCode: statusCode,
    body: _minimalPng(),
    contentType: 'image/png',
  );
}

/// Returns a `_MockResponseConfig` for an ICO favicon.
_MockResponseConfig _icoConfig({int statusCode = 200}) {
  return _MockResponseConfig(
    statusCode: statusCode,
    body: _minimalIco(),
    contentType: 'image/x-icon',
  );
}

/// Returns a `_MockResponseConfig` for a PNG with charset parameter.
_MockResponseConfig _pngWithCharsetConfig({int statusCode = 200}) {
  return _MockResponseConfig(
    statusCode: statusCode,
    body: _minimalPng(),
    contentType: 'image/png; charset=utf-8',
  );
}

// ---------------------------------------------------------------------------
// Test environment builder
// ---------------------------------------------------------------------------

class _TestEnv {
  _TestEnv({
    required this.db,
    required this.dao,
    required this.service,
    required this.mockClient,
    required this.logosDir,
    required this.registry,
  });

  final AppDatabase db;
  final WebsiteLogoCacheDao dao;
  final WebsiteLogoCacheService service;
  final _MockHttpClient mockClient;
  final Directory logosDir;
  final PluginRegistry registry;

  Future<void> close() => db.close();
}

Future<_TestEnv> _createEnv(
  _MockResponseConfig Function(String url) responseFactory,
) async {
  final registry = PluginRegistry()..register(CollectionsPlugin());
  final db = AppDatabase(NativeDatabase.memory(), registry);
  final dao = WebsiteLogoCacheDao(db);

  final logosDir = Directory.systemTemp.createTempSync('logo_cache_test_');

  final mockClient = _MockHttpClient(responseFactory);

  final service = WebsiteLogoCacheService(
    dao: dao,
    client: mockClient,
    logosDir: logosDir,
  );

  return _TestEnv(
    db: db,
    dao: dao,
    service: service,
    mockClient: mockClient,
    logosDir: logosDir,
    registry: registry,
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('ensureLogoCached', () {
    test('success cache not expired — reuses existing entry', () async {
      final env = await _createEnv((url) => _pngConfig());
      final now = DateTime.now();

      // Pre-populate a success cache entry
      final dir = env.logosDir;
      final key = 'example.com';
      final fileName = '${base64Url.encode(utf8.encode(key))}.png';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(_minimalPng());

      await env.dao.upsert(WebsiteLogoCacheTableCompanion(
        siteKey: Value(key),
        host: Value('example.com'),
        remoteLogoUrl: const Value.absent(),
        localLogoPath: Value(file.path),
        mimeType: const Value('image/png'),
        status: const Value('success'),
        fetchedAt: Value(now),
        expiresAt: Value(now.add(const Duration(days: 30))),
        createdAt: Value(now),
        updatedAt: Value(now),
      ));

      final result = await env.service.ensureLogoCached(
        pageUrl: 'https://example.com/article',
      );

      expect(result, isNotNull);
      expect(result!.status, 'success');
      expect(result.localLogoPath, file.path);
      // No HTTP call was made
      expect(env.mockClient.fetchedUrls, isEmpty);

      await env.close();
    });

    test('success cache expired — re-fetches', () async {
      final env = await _createEnv((url) => _pngConfig());
      final now = DateTime.now();

      // Pre-populate an expired entry
      final dir = env.logosDir;
      final key = 'example.com';
      final fileName = '${base64Url.encode(utf8.encode(key))}.png';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(_minimalPng());

      await env.dao.upsert(WebsiteLogoCacheTableCompanion(
        siteKey: Value(key),
        host: Value('example.com'),
        localLogoPath: Value(file.path),
        mimeType: const Value('image/png'),
        status: const Value('success'),
        fetchedAt: Value(now),
        expiresAt: Value(now.subtract(const Duration(hours: 1))),
        createdAt: Value(now),
        updatedAt: Value(now),
      ));

      final result = await env.service.ensureLogoCached(
        pageUrl: 'https://example.com/article',
      );

      expect(result, isNotNull);
      expect(result!.status, 'success');
      // HTTP call was made
      expect(env.mockClient.fetchedUrls, isNotEmpty);

      await env.close();
    });

    test('success cache file missing — re-fetches', () async {
      final env = await _createEnv((url) => _pngConfig());
      final now = DateTime.now();

      await env.dao.upsert(WebsiteLogoCacheTableCompanion(
        siteKey: Value('example.com'),
        host: Value('example.com'),
        remoteLogoUrl: const Value.absent(),
        localLogoPath: Value('/nonexistent/path/logo.png'),
        mimeType: const Value('image/png'),
        status: const Value('success'),
        fetchedAt: Value(now),
        expiresAt: Value(now.add(const Duration(days: 30))),
        createdAt: Value(now),
        updatedAt: Value(now),
      ));

      final result = await env.service.ensureLogoCached(
        pageUrl: 'https://example.com/article',
      );

      expect(result, isNotNull);
      expect(result!.status, 'success');
      // HTTP call was made because local file was missing
      expect(env.mockClient.fetchedUrls, isNotEmpty);

      await env.close();
    });

    test('failed cache within 24h — does not re-fetch, returns failed entry', () async {
      final env = await _createEnv((url) => _pngConfig());
      final now = DateTime.now();

      await env.dao.upsert(WebsiteLogoCacheTableCompanion(
        siteKey: Value('example.com'),
        host: Value('example.com'),
        remoteLogoUrl: const Value.absent(),
        localLogoPath: const Value(null),
        mimeType: const Value(null),
        status: const Value('failed'),
        lastError: const Value('Network error'),
        expiresAt: Value(now.add(const Duration(hours: 23))),
        createdAt: Value(now),
        updatedAt: Value(now),
      ));

      final result = await env.service.ensureLogoCached(
        pageUrl: 'https://example.com/article',
      );

      // Returns the failed entry (not null) — status tells the UI to show fallback.
      expect(result, isNotNull);
      expect(result!.status, 'failed');
      expect(result.localLogoPath, isNull);
      // No HTTP call was made
      expect(env.mockClient.fetchedUrls, isEmpty);

      await env.close();
    });

    test('failed cache expired — re-fetches', () async {
      final env = await _createEnv((url) => _pngConfig());
      final now = DateTime.now();

      await env.dao.upsert(WebsiteLogoCacheTableCompanion(
        siteKey: Value('example.com'),
        host: Value('example.com'),
        remoteLogoUrl: const Value.absent(),
        localLogoPath: const Value(null),
        mimeType: const Value(null),
        status: const Value('failed'),
        lastError: const Value('Network error'),
        expiresAt: Value(now.subtract(const Duration(hours: 1))),
        createdAt: Value(now),
        updatedAt: Value(now),
      ));

      final result = await env.service.ensureLogoCached(
        pageUrl: 'https://example.com/article',
      );

      expect(result, isNotNull);
      expect(result!.status, 'success');
      // HTTP call was made
      expect(env.mockClient.fetchedUrls, isNotEmpty);

      await env.close();
    });

    test('same siteKey concurrent calls — only one HTTP request', () async {
      final env = await _createEnv((url) => _pngConfig());

      // Fire two concurrent requests for the same site
      final results = await Future.wait([
        env.service.ensureLogoCached(
          pageUrl: 'https://example.com/article',
        ),
        env.service.ensureLogoCached(
          pageUrl: 'https://example.com/other',
        ),
      ]);

      expect(results, hasLength(2));
      expect(results[0], isNotNull);
      expect(results[1], isNotNull);

      // Only one HTTP request should have been made
      expect(env.mockClient.fetchedUrls, hasLength(1));

      await env.close();
    });

    test('different siteKeys — two independent HTTP requests', () async {
      final env = await _createEnv((url) {
        if (url.contains('example.com')) return _pngConfig();
        if (url.contains('other.org')) return _icoConfig();
        return _pngConfig();
      });

      final results = await Future.wait([
        env.service.ensureLogoCached(
          pageUrl: 'https://example.com/article',
        ),
        env.service.ensureLogoCached(
          pageUrl: 'https://other.org/page',
        ),
      ]);

      expect(results, hasLength(2));
      expect(results[0], isNotNull);
      expect(results[1], isNotNull);

      // Two HTTP requests — one per site
      expect(env.mockClient.fetchedUrls, hasLength(2));

      await env.close();
    });
  });

  group('_extensionForMimeType (MIME charset handling)', () {
    test('image/png; charset=utf-8 returns .png', () async {
      final env = await _createEnv((url) => _pngWithCharsetConfig());

      final result = await env.service.ensureLogoCached(
        pageUrl: 'https://charset-test.example/article',
      );

      expect(result, isNotNull);
      expect(result!.status, 'success');
      expect(result.localLogoPath, endsWith('.png'));

      await env.close();
    });

    test('image/x-icon returns .ico', () async {
      final env = await _createEnv((url) => _icoConfig());

      final result = await env.service.ensureLogoCached(
        pageUrl: 'https://ico-test.example/article',
      );

      expect(result, isNotNull);
      expect(result!.status, 'success');
      expect(result.localLogoPath, endsWith('.ico'));

      await env.close();
    });
  });

  group('URL scheme validation', () {
    test('data: URL returns null (error caught internally)', () async {
      final env = await _createEnv((url) => _pngConfig());

      final result = await env.service.ensureLogoCached(
        pageUrl: 'https://data-url.example/article',
        remoteFaviconUrl: 'data:image/png;base64,iVBOR',
      );

      // Error is caught inside _ensureLogoCachedInternal and stored as failed
      expect(result, isNull);

      await env.close();
    });

    test('file: URL returns null (error caught internally)', () async {
      final env = await _createEnv((url) => _pngConfig());

      final result = await env.service.ensureLogoCached(
        pageUrl: 'https://file-url.example/article',
        remoteFaviconUrl: 'file:///tmp/favicon.ico',
      );

      expect(result, isNull);

      await env.close();
    });

    test('https URL works normally', () async {
      final env = await _createEnv((url) => _pngConfig());

      final result = await env.service.ensureLogoCached(
        pageUrl: 'https://normal-https.example/article',
      );

      expect(result, isNotNull);
      expect(result!.status, 'success');

      await env.close();
    });
  });
}
