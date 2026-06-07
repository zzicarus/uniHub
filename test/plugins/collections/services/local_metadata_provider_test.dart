import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:uni_hub/src/plugins/collections/domain/enrichment_status.dart';
import 'package:uni_hub/src/plugins/collections/services/local_metadata_provider.dart';

// ---------------------------------------------------------------------------
// Configurable mock HTTP infrastructure
// ---------------------------------------------------------------------------

class _MockHttpClient implements HttpClient {
  _MockHttpClient(
    this.body, {
    this.statusCode = 200,
    this.contentTypeHeader,
  });

  final String body;
  final int statusCode;
  final String? contentTypeHeader;

  @override
  Future<_MockHttpClientRequest> getUrl(Uri url) async {
    return _MockHttpClientRequest(
      body,
      statusCode: statusCode,
      contentTypeHeader: contentTypeHeader,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _MockHttpClientRequest implements HttpClientRequest {
  _MockHttpClientRequest(
    this.body, {
    required this.statusCode,
    this.contentTypeHeader,
  });

  final String body;
  final int statusCode;
  final String? contentTypeHeader;

  @override
  bool followRedirects = true;

  @override
  HttpHeaders get headers => _MockHttpHeaders(contentTypeHeader);

  @override
  Future<_MockHttpClientResponse> close() async {
    return _MockHttpClientResponse(
      body,
      statusCode: statusCode,
      contentTypeHeader: contentTypeHeader,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _MockHttpClientResponse implements HttpClientResponse {
  _MockHttpClientResponse(
    this.body, {
    required this.statusCode,
    this.contentTypeHeader,
  });

  final String body;
  @override
  final int statusCode;
  final String? contentTypeHeader;

  @override
  HttpHeaders get headers => _MockHttpHeaders(contentTypeHeader);

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.value(utf8.encode(body)).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  String get reasonPhrase => statusCode == 200 ? 'OK' : 'Error';

  @override
  int get contentLength => body.length;

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
  Future<Socket> detachSocket() => throw UnimplementedError();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _MockHttpHeaders implements HttpHeaders {
  _MockHttpHeaders(this._contentTypeHeader);

  final String? _contentTypeHeader;

  @override
  ContentType? get contentType {
    if (_contentTypeHeader == null || _contentTypeHeader.trim().isEmpty) return null;
    try {
      return ContentType.parse(_contentTypeHeader);
    } catch (_) {
      return null;
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

LocalMetadataProvider _provider(
  String html, {
  int statusCode = 200,
  String? contentType,
}) {
  return LocalMetadataProvider(
    client: _MockHttpClient(
      html,
      statusCode: statusCode,
      contentTypeHeader: contentType,
    ),
  );
}

void main() {
  // ---------------------------------------------------------------------------
  // favicon parsing (regression — same logic via HtmlMetadataParser)
  // ---------------------------------------------------------------------------
  group('LocalMetadataProvider — favicon parsing', () {
    test('parses <link rel="icon" href="/favicon.ico">', () async {
      final provider = _provider(
        '<html><head><link rel="icon" href="/favicon.ico"></head></html>',
      );
      final result = await provider.fetchMetadata('https://example.com/page');
      expect(result.favicon, 'https://example.com/favicon.ico');
    });

    test(
      'parses <link href="/favicon.ico" rel="icon"> (reversed attribute order)',
      () async {
        final provider = _provider(
          '<html><head><link href="/favicon.ico" rel="icon"></head></html>',
        );
        final result =
            await provider.fetchMetadata('https://example.com/article');
        expect(result.favicon, 'https://example.com/favicon.ico');
      },
    );

    test('parses <link rel="shortcut icon" href="/favicon.ico">', () async {
      final provider = _provider(
        '<html><head><link rel="shortcut icon" href="/favicon.ico"></head></html>',
      );
      final result =
          await provider.fetchMetadata('https://example.com/page');
      expect(result.favicon, 'https://example.com/favicon.ico');
    });

    test('parses <link rel="apple-touch-icon" href="/apple-touch-icon.png">',
        () async {
      final provider = _provider(
        '<html><head><link rel="apple-touch-icon" href="/apple-touch-icon.png"></head></html>',
      );
      final result =
          await provider.fetchMetadata('https://example.com/page');
      expect(result.favicon, 'https://example.com/apple-touch-icon.png');
    });

    test(
      'falls back to /favicon.ico when no favicon link exists',
      () async {
        final provider = _provider(
          '<html><head><title>No Favicon</title></head></html>',
        );
        final result =
            await provider.fetchMetadata('https://example.com/page');
        expect(result.favicon, 'https://example.com/favicon.ico');
      },
    );

    test('resolves relative favicon URL to absolute', () async {
      final provider = _provider(
        '<html><head><link rel="icon" href="assets/favicon.ico"></head></html>',
      );
      final result =
          await provider.fetchMetadata('https://example.com/blog/post');
      expect(result.favicon, 'https://example.com/blog/assets/favicon.ico');
    });

    test('uses root-relative URL correctly', () async {
      final provider = _provider(
        '<html><head><link rel="icon" href="/static/favicon.ico"></head></html>',
      );
      final result =
          await provider.fetchMetadata('https://example.com/blog/post');
      expect(result.favicon, 'https://example.com/static/favicon.ico');
    });
  });

  // ---------------------------------------------------------------------------
  // Other metadata fields (title, description, etc.)
  // ---------------------------------------------------------------------------
  group('LocalMetadataProvider — other metadata', () {
    test('parses og:title and og:description from full page', () async {
      final provider = _provider(
        '''<html><head>
          <meta property="og:title" content="Full OG Title">
          <meta property="og:description" content="Full OG Description">
        </head></html>''',
      );
      final result =
          await provider.fetchMetadata('https://example.com/article');
      expect(result.title, 'Full OG Title');
      expect(result.description, 'Full OG Description');
    });

    test('parses <title> when no meta tags', () async {
      final provider = _provider(
        '<html><head><title>Plain Title</title><meta name="description" content="Desc"></head></html>',
      );
      final result =
          await provider.fetchMetadata('https://example.com/page');
      expect(result.title, 'Plain Title');
      expect(result.description, 'Desc');
    });

    test('parses og:site_name and author', () async {
      final provider = _provider(
        '''<html><head>
          <meta property="og:site_name" content="Example Blog">
          <meta name="author" content="Jane Doe">
          <title>Post Title</title>
        </head></html>''',
      );
      final result =
          await provider.fetchMetadata('https://example.com/blog');
      expect(result.siteName, 'Example Blog');
      expect(result.author, 'Jane Doe');
    });

    test('resolves relative og:image', () async {
      final provider = _provider(
        '''<html><head>
          <meta property="og:image" content="/images/hero.jpg">
        </head></html>''',
      );
      final result = await provider.fetchMetadata('https://example.com/blog');
      expect(result.coverImage, 'https://example.com/images/hero.jpg');
    });
  });

  // ---------------------------------------------------------------------------
  // HTTP-level behaviour
  // ---------------------------------------------------------------------------
  group('LocalMetadataProvider — HTTP validation', () {
    test('non-200 status code throws MetadataFetchException', () async {
      final provider = _provider(
        '<html><head><title>Error page</title></head></html>',
        statusCode: 404,
      );
      expect(
        () => provider.fetchMetadata('https://example.com/missing'),
        throwsA(isA<MetadataFetchException>()),
      );
    });

    test('500 status code throws MetadataFetchException', () async {
      final provider = _provider(
        '<html><head><title>Server Error</title></head></html>',
        statusCode: 500,
      );
      expect(
        () => provider.fetchMetadata('https://example.com/error'),
        throwsA(isA<MetadataFetchException>()),
      );
    });

    test('non-HTML content type throws MetadataFetchException', () async {
      final provider = _provider(
        '{"key":"value"}',
        contentType: 'application/json',
      );
      expect(
        () => provider.fetchMetadata('https://example.com/data.json'),
        throwsA(isA<MetadataFetchException>()),
      );
    });

    test('image content type throws MetadataFetchException', () async {
      final provider = _provider(
        '<fake>not html</fake>',
        contentType: 'image/png',
      );
      expect(
        () => provider.fetchMetadata('https://example.com/image.png'),
        throwsA(isA<MetadataFetchException>()),
      );
    });

    test('text/html content type is accepted', () async {
      final provider = _provider(
        '<html><head><title>HTML Page</title></head></html>',
        contentType: 'text/html; charset=utf-8',
      );
      final result =
          await provider.fetchMetadata('https://example.com/page');
      expect(result.title, 'HTML Page');
      expect(result.status, EnrichmentStatus.success);
    });

    test('application/xhtml+xml content type is accepted', () async {
      final provider = _provider(
        '<html xmlns="http://www.w3.org/1999/xhtml"><head><title>XHTML</title></head></html>',
        contentType: 'application/xhtml+xml',
      );
      final result =
          await provider.fetchMetadata('https://example.com/page');
      expect(result.title, 'XHTML');
    });

    test('null content type (no header) is accepted', () async {
      final provider = _provider(
        '<html><head><title>No Content-Type</title></head></html>',
      );
      final result =
          await provider.fetchMetadata('https://example.com/page');
      expect(result.title, 'No Content-Type');
    });

    test('empty content type is accepted', () async {
      final provider = _provider(
        '<html><head><title>Empty CT</title></head></html>',
        contentType: '',
      );
      final result =
          await provider.fetchMetadata('https://example.com/page');
      expect(result.title, 'Empty CT');
    });
  });
}
