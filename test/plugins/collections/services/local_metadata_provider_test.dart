import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:uni_hub/src/plugins/collections/services/local_metadata_provider.dart';

// ---------------------------------------------------------------------------
// Mock HTTP infrastructure for testing favicon parsing through the public API
// ---------------------------------------------------------------------------

class _MockHttpClient implements HttpClient {
  _MockHttpClient(this.body);

  final String body;

  @override
  Future<_MockHttpClientRequest> getUrl(Uri url) async =>
      _MockHttpClientRequest(body);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _MockHttpClientRequest implements HttpClientRequest {
  _MockHttpClientRequest(this.body);

  final String body;

  @override
  bool followRedirects = true;

  @override
  Future<_MockHttpClientResponse> close() async =>
      _MockHttpClientResponse(body);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _MockHttpClientResponse implements HttpClientResponse {
  _MockHttpClientResponse(this.body);

  final String body;

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
  dynamic noSuchMethod(Invocation invocation) {
    // Intercept .transform(utf8.decoder) to return a Stream<String>
    if (invocation.memberName == #transform &&
        invocation.positionalArguments.isNotEmpty) {
      final transformer = invocation.positionalArguments[0];
      if (transformer is StreamTransformer<List<int>, dynamic>) {
        return Stream<List<int>>.value(utf8.encode(body))
            .transform(transformer);
      }
      return Stream<String>.value(body);
    }
    return null;
  }

  // ---- HttpClientResponse required members ----

  @override
  int get statusCode => 200;

  @override
  String get reasonPhrase => 'OK';

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



  // All other HttpClientResponse / Stream members are handled by
  // noSuchMethod below.
}

LocalMetadataProvider _provider(String html) =>
    LocalMetadataProvider(client: _MockHttpClient(html));

void main() {
  group('LocalMetadataProvider favicon parsing', () {
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
}
