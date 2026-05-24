class UrlNormalizer {
  const UrlNormalizer();

  String normalize(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('URL 不能为空');
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
      uri.queryParameters.entries.toList()
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
