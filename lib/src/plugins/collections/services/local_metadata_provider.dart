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

  /// Parse all favicon link tags and return the highest-priority candidate.
  ///
  /// Priority (highest → lowest):
  /// 1. apple-touch-icon (common on iOS/Safari, high quality PNG)
  /// 2. PNG icon (explicit type or .png URL)
  /// 3. WebP icon
  /// 4. JPEG icon
  /// 5. GIF icon
  /// 6. ICO icon (fallback)
  /// 7. SVG icon (support is limited in Image.file)
  ///
  /// When no link tag is found, falls back to /favicon.ico at the origin.
  String? _favicon(String url, String body) {
    final candidates = <_FaviconCandidate>[];

    // Pattern 1: rel="..." before href="..."
    final re1 = RegExp(
      r'''<link[^>]+rel=["']([^"']*icon[^"']*)["'][^>]+href=["']([^"']+)["']''',
      caseSensitive: false,
    );
    for (final m in re1.allMatches(body)) {
      final rel = m.group(1) ?? '';
      final href = _decodeHtml(m.group(2) ?? '');
      if (href.isNotEmpty) {
        candidates.add(_FaviconCandidate(
          score: _faviconScore(rel, href),
          href: href,
        ));
      }
    }

    // Pattern 2: href="..." before rel="..."
    final re2 = RegExp(
      r'''<link[^>]+href=["']([^"']+)["'][^>]+rel=["']([^"']*icon[^"']*)["']''',
      caseSensitive: false,
    );
    for (final m in re2.allMatches(body)) {
      final href = _decodeHtml(m.group(1) ?? '');
      final rel = m.group(2) ?? '';
      if (href.isNotEmpty) {
        candidates.add(_FaviconCandidate(
          score: _faviconScore(rel, href),
          href: href,
        ));
      }
    }

    if (candidates.isNotEmpty) {
      // Sort by score descending; stable sort preserves order for ties.
      candidates.sort((a, b) => b.score.compareTo(a.score));
      final base = Uri.parse(url);
      return base.resolve(candidates.first.href).toString();
    }

    // Fallback to /favicon.ico at the same origin
    return Uri.parse(url).resolve('/favicon.ico').toString();
  }

  /// Score a favicon candidate by its rel attribute and href extension.
  ///
  /// Higher score = higher priority.
  int _faviconScore(String rel, String href) {
    final lowerHref = href.toLowerCase();
    final lowerRel = rel.toLowerCase();

    // apple-touch-icon gets highest priority — high quality PNG.
    if (lowerRel.contains('apple-touch-icon')) return 100;

    // Explicit format hints from the URL extension.
    if (lowerHref.endsWith('.png')) return 80;
    if (lowerHref.endsWith('.webp')) return 75;
    if (lowerHref.endsWith('.jpg') || lowerHref.endsWith('.jpeg')) return 60;
    if (lowerHref.endsWith('.gif')) return 50;
    if (lowerHref.endsWith('.ico')) return 40;
    if (lowerHref.endsWith('.svg')) return 30;

    // Generic icon link with no recognised extension → medium priority.
    if (lowerRel.contains('icon') || lowerRel.contains('shortcut')) {
      return 70;
    }

    return 10;
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

/// Internal helper for scoring favicon candidates.
class _FaviconCandidate {
  const _FaviconCandidate({required this.score, required this.href});

  final int score;
  final String href;
}
