import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../domain/collection_models.dart';
import '../../services/html_metadata_parser.dart';
import '../../services/platform_metadata_adapter.dart';

/// GitHub-specific metadata adapter.
///
/// Supports github.com URLs with structured title generation:
/// - Repository: owner/repo
/// - Issue: owner/repo#123
/// - Pull request: owner/repo PR #123
/// - File/blob: owner/repo · path
///
/// GitHub has stable HTML structure, so the generic parser often works well.
/// This adapter adds structured title/siteName on top of parsed metadata.
class GitHubMetadataAdapter implements PlatformMetadataAdapter {
  GitHubMetadataAdapter({HttpClient? client})
      : _client = client ?? HttpClient();

  final HttpClient _client;
  static const _timeout = Duration(seconds: 8);

  @override
  bool canHandle(Uri uri) {
    final host = uri.host.toLowerCase();
    return host == 'github.com' || host.endsWith('.github.com');
  }

  @override
  Future<PlatformAdapterResult> fetch(Uri uri) async {
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    final typeInfo = _classifyPath(segments);
    final title = _generateTitle(uri, segments, typeInfo);

    final request = await _client
        .getUrl(uri)
        .timeout(_timeout);
    request.followRedirects = true;
    _setBrowserHeaders(request);

    final response = await request.close().timeout(_timeout);

    if (response.statusCode == 404) {
      // Even on 404, return a sensible title so the item isn't abandoned
      return PlatformAdapterResult(
        result: MetadataResult(
          title: title,
          siteName: 'GitHub',
          favicon: 'https://github.com/favicon.ico',
          metadataJson: jsonEncode({
            'source': 'github_adapter',
            'type': typeInfo,
            'note': '404',
          }),
        ),
        source: 'github_adapter',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'GitHub HTTP ${response.statusCode}',
        uri: uri,
      );
    }

    final contentType = response.headers.contentType?.mimeType ?? '';
    if (!contentType.contains('text/html') && contentType.isNotEmpty) {
      throw const HttpException('GitHub non-HTML response');
    }

    final bytes = await _readBody(response);
    final html = utf8.decode(bytes, allowMalformed: true);

    final parser = HtmlMetadataParser.parse(html, baseUrl: uri.toString());
    final metadata = parser.result;

    return PlatformAdapterResult(
      result: MetadataResult(
        title: title,
        description: metadata.description,
        siteName: 'GitHub',
        coverImage: metadata.coverImage,
        favicon: 'https://github.com/favicon.ico',
        metadataJson: jsonEncode({
          'source': 'github_adapter',
          'type': typeInfo,
          'owner': segments.isNotEmpty ? segments[0] : null,
          'repo': segments.length > 1 ? segments[1] : null,
        }),
      ),
      source: 'github_adapter',
    );
  }

  String _classifyPath(List<String> segments) {
    if (segments.length >= 2) {
      if (segments.length > 2) {
        if (segments[2] == 'issues' && segments.length > 3) {
          return 'issue';
        }
        if (segments[2] == 'pull' && segments.length > 3) {
          return 'pull_request';
        }
        if (segments[2] == 'blob' ||
            segments[2] == 'tree' ||
            segments[2] == 'edit') {
          return 'blob';
        }
      }
      return 'repo';
    }
    return 'unknown';
  }

  String _generateTitle(Uri uri, List<String> segments, String type) {
    if (segments.length < 2) {
      return uri.toString();
    }

    final owner = segments[0];
    final repo = segments[1];

    return switch (type) {
      'issue' => '$owner/$repo#${segments[3]}',
      'pull_request' => '$owner/$repo PR #${segments[3]}',
      'blob' => '$owner/$repo · ${segments.skip(3).join('/')}',
      'repo' => '$owner/$repo',
      _ => '$owner/$repo',
    };
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
      'en,zh-CN;q=0.9,zh;q=0.8',
    );
  }

  Future<List<int>> _readBody(Stream<List<int>> stream) async {
    const maxBytes = 1 << 20;
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
