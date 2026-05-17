class SearchResult {
  final String id;
  final String title;
  final String? subtitle;
  final String routeName;
  final Map<String, String> routeParams;
  final String pluginId;
  final double score;

  const SearchResult({
    required this.id,
    required this.title,
    this.subtitle,
    required this.routeName,
    this.routeParams = const {},
    required this.pluginId,
    this.score = 0.0,
  });
}
