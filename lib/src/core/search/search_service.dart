import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../plugin/plugin_interface.dart';
import 'search_result.dart';

class GlobalSearchService {
  Future<List<SearchResult>> search(
    String query,
    List<UniHubPlugin> plugins,
  ) async {
    if (query.trim().isEmpty) return [];
    final results = await Future.wait(plugins.map((p) => p.search(query)));
    final combined = results.expand((r) => r).toList();
    combined.sort((a, b) => b.score.compareTo(a.score));
    return combined.take(20).toList();
  }
}

final globalSearchServiceProvider = Provider<GlobalSearchService>(
  (ref) => GlobalSearchService(),
);
