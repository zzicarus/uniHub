/// URL 归一化工具，提供 URL 的识别、归一化和参数清理功能。
///
/// 用作 Collections 和 Thoughts 两套 quickCreate 链路中 URL 判断的唯一来源。
/// 两模块通过 [tryNormalize] 方法统一判断输入是否为 URL，不再各自写正则。
library;

class UrlNormalizer {
  const UrlNormalizer();

  static const _trackingParams = {
    'utm_source',
    'utm_medium',
    'utm_campaign',
    'utm_term',
    'utm_content',
    'spm',
    'from',
    'share_source',
  };

  /// 尝试归一化输入为 URL；若输入不是合法 URL，返回 null。
  ///
  /// 与 [normalize] 不同，此方法不抛异常，用于 UI 层判断是否为 URL 候选。
  String? tryNormalize(String input) {
    try {
      return normalize(input);
    } on Exception {
      return null;
    }
  }

  /// 将输入归一化为标准 URL。
  ///
  /// - 自动补全 scheme（无 scheme 时添加 https://）
  /// - 移除常见的追踪参数（utm_source 等）
  /// - 归一化域名（小写）
  /// - 移除尾部斜杠
  ///
  /// 若输入不合法（包含空格、为空、格式不正确），抛出 [FormatException] 或 [ArgumentError]。
  String normalize(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('URL 不能为空');
    }
    if (trimmed.contains(' ')) {
      throw FormatException('URL 不能包含空格', input);
    }

    final withScheme = trimmed.contains('://') ? trimmed : 'https://$trimmed';
    final uri = Uri.parse(withScheme);
    if (!uri.hasScheme || uri.host.isEmpty) {
      throw FormatException('URL 格式不正确', input);
    }

    final scheme = uri.scheme.toLowerCase();
    final host = uri.host.toLowerCase();
    final normalizedPath = _normalizePath(uri.path);
    final queryParameters = Map.fromEntries(
      uri.queryParameters.entries
          .where((e) => !_trackingParams.contains(e.key.toLowerCase()))
          .toList()
        ..sort((a, b) => a.key.compareTo(b.key)),
    );

    return Uri(
      scheme: scheme,
      host: host,
      port: uri.hasPort ? uri.port : null,
      path: normalizedPath,
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    ).toString();
  }

  String _normalizePath(String path) {
    if (path.isEmpty || path == '/') return '';
    return path.endsWith('/') ? path.substring(0, path.length - 1) : path;
  }
}
