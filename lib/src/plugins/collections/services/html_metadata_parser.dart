import 'dart:convert';

import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;

import '../domain/collection_models.dart';

/// DOM-based HTML metadata parser using [package:html].
///
/// Extracts title, description, cover image, site name, author, and favicon
/// from `<meta>` tags (Open Graph, Twitter Card, standard HTML), `<title>`,
/// and `<link rel="icon">` elements using CSS selectors rather than regex.
///
/// All relative URLs are resolved against [baseUrl].
///
/// Usage:
/// ```dart
/// final parser = HtmlMetadataParser.parse(html, baseUrl: url);
/// final result = parser.result;
/// ```
class HtmlMetadataParser {
  final Uri _baseUri;
  final Document _document;

  HtmlMetadataParser._({
    required Uri baseUri,
    required Document document,
  })  : _baseUri = baseUri,
        _document = document;

  /// Parse an HTML string fetched from [baseUrl].
  ///
  /// The [baseUrl] is used to resolve relative URLs in meta tags.
  factory HtmlMetadataParser.parse(String html, {required String baseUrl}) {
    final doc = html_parser.parse(html);
    final uri = Uri.tryParse(baseUrl) ?? Uri();
    return HtmlMetadataParser._(baseUri: uri, document: doc);
  }

  /// Build a [MetadataResult] from the parsed HTML.
  MetadataResult get result => MetadataResult(
        title: _cleanTitle(_parseTitle()),
        description: _cleanDescription(_parseDescription()),
        author: _parseAuthor(),
        siteName: _parseSiteName(),
        coverImage: _resolveUrl(_parseCoverImage()),
        favicon: _parseFavicon(),
        metadataJson: jsonEncode({'source': 'local'}),
      );

  // ---------------------------------------------------------------------------
  // Title
  // ---------------------------------------------------------------------------
  //
  // Priority:
  //   1. og:title (property= or name=)
  //   2. twitter:title (name=)
  //   3. application-name (name=)
  //   4. <title> (from <head>)

  String? _parseTitle() {
    final ogTitle = _metaFor('og:title');
    if (ogTitle != null) return ogTitle;

    final twTitle = _meta('twitter:title', attr: 'name');
    if (twTitle != null) return twTitle;

    final appName = _meta('application-name', attr: 'name');
    if (appName != null) return appName;

    final titleEl = _document.head?.querySelector('title');
    if (titleEl != null) {
      final text = titleEl.text.trim();
      if (text.isNotEmpty) return text;
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // Description
  // ---------------------------------------------------------------------------
  //
  // Priority:
  //   1. og:description (property= or name=)
  //   2. twitter:description (name=)
  //   3. meta[name=description]

  String? _parseDescription() {
    final ogDesc = _metaFor('og:description');
    if (ogDesc != null) return ogDesc;

    final twDesc = _meta('twitter:description', attr: 'name');
    if (twDesc != null) return twDesc;

    final metaDesc = _meta('description', attr: 'name');
    if (metaDesc != null) return metaDesc;

    return null;
  }

  // ---------------------------------------------------------------------------
  // Cover Image
  // ---------------------------------------------------------------------------
  //
  // Priority:
  //   1. og:image (property= or name=)
  //   2. twitter:image (name=)
  //   3. twitter:image:src (name=)
  //   4. link[rel=image_src]

  String? _parseCoverImage() {
    final ogImage = _metaFor('og:image');
    if (ogImage != null) return ogImage;

    final twImage = _meta('twitter:image', attr: 'name');
    if (twImage != null) return twImage;

    final twImageSrc = _meta('twitter:image:src', attr: 'name');
    if (twImageSrc != null) return twImageSrc;

    final imageSrc = _document.querySelector('link[rel="image_src"]');
    if (imageSrc != null) {
      final href = imageSrc.attributes['href'];
      if (href != null && href.isNotEmpty) return href;
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // Site Name
  // ---------------------------------------------------------------------------
  //
  // Priority:
  //   1. og:site_name (property= or name=)
  //   2. application-name (name=)
  //   3. Fallback to host from base URL

  String? _parseSiteName() {
    final ogSite = _metaFor('og:site_name');
    if (ogSite != null) return ogSite;

    final appName = _meta('application-name', attr: 'name');
    if (appName != null) return appName;

    if (_baseUri.host.isNotEmpty) return _baseUri.host;

    return null;
  }

  // ---------------------------------------------------------------------------
  // Author
  // ---------------------------------------------------------------------------
  //
  // Priority:
  //   1. article:author (property= or name=)
  //   2. meta[name=author]
  //   3. meta[name=byl]

  String? _parseAuthor() {
    final articleAuthor = _metaFor('article:author');
    if (articleAuthor != null) return articleAuthor;

    final author = _meta('author', attr: 'name');
    if (author != null) return author;

    final byl = _meta('byl', attr: 'name');
    if (byl != null) return byl;

    return null;
  }

  // ---------------------------------------------------------------------------
  // Favicon
  // ---------------------------------------------------------------------------
  //
  // Scans all <link rel="...icon..."> tags and scores candidates by type and
  // file extension. Falls back to /favicon.ico at the origin.

  static const _faviconScores = <String, int>{
    '.png': 90,
    '.webp': 85,
    '.svg': 80,
    '.ico': 70,
    '.jpg': 60,
    '.jpeg': 60,
    '.gif': 50,
  };

  String? _parseFavicon() {
    final links = _document.querySelectorAll('link[rel]');
    final candidates = <_FaviconCandidate>[];

    for (final link in links) {
      final rel = (link.attributes['rel'] ?? '').toLowerCase();
      if (!rel.contains('icon') && !rel.contains('shortcut')) continue;
      final href = link.attributes['href'];
      if (href == null || href.isEmpty) continue;

      final score = _faviconScore(rel, href);
      candidates.add(_FaviconCandidate(score: score, href: href));
    }

    if (candidates.isNotEmpty) {
      candidates.sort((a, b) => b.score.compareTo(a.score));
      final resolved = _resolveUrl(candidates.first.href);
      return resolved;
    }

    // Fallback to /favicon.ico at the same origin
    return _baseUri.resolve('/favicon.ico').toString();
  }

  static int _faviconScore(String rel, String href) {
    if (rel.contains('apple-touch-icon')) return 100;

    final lowerHref = href.toLowerCase();
    for (final entry in _faviconScores.entries) {
      if (lowerHref.endsWith(entry.key)) return entry.value;
    }

    // Generic icon link with no recognised extension
    if (rel.contains('icon') || rel.contains('shortcut')) return 70;

    return 10;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Match a meta tag where [value] can be in either `property=` or `name=`.
  ///
  /// This is the most permissive lookup — suitable for OG tags that are
  /// sometimes authored with `name=` instead of the spec's `property=` (and
  /// vice-versa).
  String? _metaFor(String value) {
    for (final attr in ['property', 'name']) {
      final el = _document.querySelector('meta[$attr="$value"]');
      if (el != null) {
        final content = el.attributes['content'];
        if (content != null && content.isNotEmpty) return content;
      }
    }
    return null;
  }

  /// Match a meta tag by a specific attribute.
  String? _meta(String value, {required String attr}) {
    final el = _document.querySelector('meta[$attr="$value"]');
    if (el != null) {
      final content = el.attributes['content'];
      if (content != null && content.isNotEmpty) return content;
    }
    return null;
  }

  /// Resolve a potentially relative URL against [_baseUri].
  String? _resolveUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    final parsed = Uri.tryParse(url);
    if (parsed == null) return url;
    if (parsed.hasScheme) return url; // already absolute
    return _baseUri.resolve(url).toString();
  }

  // ---------------------------------------------------------------------------
  // Cleaning
  // ---------------------------------------------------------------------------

  static String? _cleanTitle(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final collapsed = trimmed.replaceAll(RegExp(r'\s+'), ' ');

    // Filter known error / challenge page titles that are clearly not the
    // intended content of the page.
    if (_isErrorTitle(collapsed)) return null;

    return collapsed.length > 160
        ? collapsed.substring(0, 160).trimRight()
        : collapsed;
  }

  static bool _isErrorTitle(String title) {
    const errorPrefixes = <String>[
      'just a moment',
      'please wait while',
      'access denied',
      '403 forbidden',
      '404 not found',
      'sorry',
    ];
    final lower = title.toLowerCase();
    for (final prefix in errorPrefixes) {
      if (lower.startsWith(prefix)) return true;
    }
    return false;
  }

  static String? _cleanDescription(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final collapsed = trimmed.replaceAll(RegExp(r'\s+'), ' ');
    return collapsed.length > 500
        ? collapsed.substring(0, 500).trimRight()
        : collapsed;
  }
}

/// Internal helper for scoring favicon candidates.
class _FaviconCandidate {
  const _FaviconCandidate({required this.score, required this.href});
  final int score;
  final String href;
}
