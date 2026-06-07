import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:html/parser.dart' as html_parser;

import '../../domain/collection_models.dart';
import '../../services/html_metadata_parser.dart';
import '../../services/platform_metadata_adapter.dart';

/// Weibo-specific metadata adapter.
///
/// Supports weibo.com and m.weibo.cn.
/// Weibo pages typically require login. When the generic parser returns
/// limited results, this adapter provides a best-effort title and fixed
/// favicon, avoiding repeated retry.
class WeiboMetadataAdapter implements PlatformMetadataAdapter {
  WeiboMetadataAdapter({HttpClient? client})
      : _client = client ?? HttpClient();

  final HttpClient _client;
  static const _timeout = Duration(seconds: 8);

  static const _supportedHosts = <String>{
    'weibo.com',
    'www.weibo.com',
    'm.weibo.cn',
  };

  @override
  bool canHandle(Uri uri) {
    final host = uri.host.toLowerCase();
    return _supportedHosts.any((h) => host == h || host.endsWith('.$h'));
  }

  @override
  Future<PlatformAdapterResult> fetch(Uri uri) async {
    final request = await _client
        .getUrl(uri)
        .timeout(_timeout);
    request.followRedirects = true;
    _setBrowserHeaders(request);

    final response = await request.close().timeout(_timeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      // Non-2xx → limited success (login wall / anti-crawl)
      return _limitedSuccess(uri, reason: 'http_${response.statusCode}');
    }

    final contentType = response.headers.contentType?.mimeType ?? '';
    if (!contentType.contains('text/html') && contentType.isNotEmpty) {
      // Non-HTML → limited success
      return _limitedSuccess(uri, reason: 'non_html');
    }

    final bytes = await _readBody(response);
    final html = utf8.decode(bytes, allowMalformed: true);

    final parser = HtmlMetadataParser.parse(html, baseUrl: uri.toString());
    final metadata = parser.result;

    final title = metadata.title ?? _fallbackTitle(uri);

    // Detect login wall by checking for typical weibo login indicators
    final doc = html_parser.parse(html);
    final loginElements = doc.querySelectorAll(
      '.login, .W_login, [node-type=login_box], .login_wrap',
    );
    final hasLoginWall = loginElements.isNotEmpty ||
        html.contains('请登录') ||
        html.contains('登录微博');

    if (hasLoginWall) {
      return _limitedSuccess(uri, reason: 'login_wall');
    }

    return PlatformAdapterResult(
      result: MetadataResult(
        title: title,
        description: metadata.description,
        siteName: '微博',
        coverImage: metadata.coverImage,
        favicon: 'https://weibo.com/favicon.ico',
        metadataJson: jsonEncode({
          'source': 'weibo_adapter',
        }),
      ),
      source: 'weibo_adapter',
    );
  }

  String _fallbackTitle(Uri uri) {
    if (uri.path.contains('/u/') || uri.path.contains('/profile')) {
      final id = uri.pathSegments.last;
      return '微博 · $id';
    }
    return '微博 · ${uri.host}${uri.path}';
  }

  PlatformAdapterResult _limitedSuccess(Uri uri, {required String reason}) {
    return PlatformAdapterResult(
      result: MetadataResult(
        title: _fallbackTitle(uri),
        siteName: '微博',
        favicon: 'https://weibo.com/favicon.ico',
        metadataJson: jsonEncode({
          'source': 'weibo_adapter',
          'limited': true,
          'reason': reason,
        }),
      ),
      limited: true,
      reason: reason,
      source: 'weibo_adapter',
    );
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
      'zh-CN,zh;q=0.9,en;q=0.8',
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
