import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../domain/collection_models.dart';
import '../domain/enrichment_status.dart';
import 'metadata_provider.dart';

class LocalMetadataProvider implements MetadataProvider {
  LocalMetadataProvider({HttpClient? client})
    : _client = client ?? HttpClient();

  final HttpClient _client;

  @override
  Future<MetadataResult> fetchMetadata(String url) async {
    final uri = Uri.parse(url);
    final request = await _client
        .getUrl(uri)
        .timeout(const Duration(seconds: 8));
    request.followRedirects = true;
    final response = await request.close().timeout(const Duration(seconds: 8));
    final body = await response.transform(utf8.decoder).join();

    return MetadataResult(
      title: _firstMatch(body, [
        RegExp(
          r'''<meta[^>]+property=["']og:title["'][^>]+content=["']([^"']+)["']''',
          caseSensitive: false,
        ),
        RegExp(
          r'''<title[^>]*>(.*?)</title>''',
          caseSensitive: false,
          dotAll: true,
        ),
      ])?.trim(),
      description: _firstMatch(body, [
        RegExp(
          r'''<meta[^>]+name=["']description["'][^>]+content=["']([^"']+)["']''',
          caseSensitive: false,
        ),
        RegExp(
          r'''<meta[^>]+property=["']og:description["'][^>]+content=["']([^"']+)["']''',
          caseSensitive: false,
        ),
      ])?.trim(),
      coverImage: _firstMatch(body, [
        RegExp(
          r'''<meta[^>]+property=["']og:image["'][^>]+content=["']([^"']+)["']''',
          caseSensitive: false,
        ),
      ])?.trim(),
      favicon: _favicon(url, body),
      metadataJson: jsonEncode({'source': 'local'}),
      status: EnrichmentStatus.success,
    );
  }

  String? _firstMatch(String body, List<RegExp> patterns) {
    for (final pattern in patterns) {
      final match = pattern.firstMatch(body);
      if (match != null && match.groupCount >= 1) {
        return _decodeHtml(match.group(1) ?? '');
      }
    }
    return null;
  }

  String? _favicon(String url, String body) {
    final href = _firstMatch(body, [
      // rel before href (e.g. <link rel="icon" href="/favicon.ico">)
      RegExp(
        r'''<link[^>]+rel=["'][^"']*icon[^"']*["'][^>]+href=["']([^"']+)["']''',
        caseSensitive: false,
      ),
      // href before rel (e.g. <link href="/favicon.ico" rel="icon">)
      RegExp(
        r'''<link[^>]+href=["']([^"']+)["'][^>]+rel=["'][^"']*icon[^"']*["']''',
        caseSensitive: false,
      ),
    ]);
    final base = Uri.parse(url);
    if (href != null && href.isNotEmpty) {
      return base.resolve(href).toString();
    }
    // Fallback to /favicon.ico at the same origin when no link declaration
    return base.resolve('/favicon.ico').toString();
  }

  String _decodeHtml(String value) {
    return value
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");
  }
}
