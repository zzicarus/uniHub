import 'package:flutter_test/flutter_test.dart';
import 'package:uni_hub/src/core/plugin/plugin_interface.dart';
import 'package:uni_hub/src/core/search/search_result.dart';
import 'package:uni_hub/src/core/search/search_service.dart';

/// A test plugin that returns controlled search results.
class _SearchTestPlugin extends UniHubPlugin {
  _SearchTestPlugin({
    required this.pluginId,
    required this.results,
  });

  @override
  String get id => pluginId;
  @override
  String get name => pluginId;
  final String pluginId;
  final List<SearchResult> results;

  @override
  List<NavEntry> get navEntries => [];

  @override
  Future<List<SearchResult>> search(String query) async => results;
}

void main() {
  group('GlobalSearchService', () {
    late GlobalSearchService service;

    setUp(() {
      service = GlobalSearchService();
    });

    test('returns empty for empty query', () async {
      final results = await service.search('', []);
      expect(results, isEmpty);
    });

    test('returns empty for blank query', () async {
      final results = await service.search('   ', []);
      expect(results, isEmpty);
    });

    test('returns empty with no plugins', () async {
      final results = await service.search('flutter', []);
      expect(results, isEmpty);
    });

    test('returns results from a single plugin', () async {
      final plugin = _SearchTestPlugin(
        pluginId: 'thoughts',
        results: [
          const SearchResult(
            id: '1',
            title: 'Flutter state management',
            routeName: 'thoughts',
            pluginId: 'thoughts',
            score: 0.9,
          ),
        ],
      );

      final results = await service.search('flutter', [plugin]);
      expect(results, hasLength(1));
      expect(results.first.title, 'Flutter state management');
    });

    test('aggregates results from multiple plugins', () async {
      final plugin1 = _SearchTestPlugin(
        pluginId: 'thoughts',
        results: [
          const SearchResult(
            id: 'a1',
            title: 'Result from thoughts',
            routeName: 'thoughts',
            pluginId: 'thoughts',
            score: 0.8,
          ),
        ],
      );
      final plugin2 = _SearchTestPlugin(
        pluginId: 'tasks',
        results: [
          const SearchResult(
            id: 'b1',
            title: 'Result from tasks',
            routeName: 'tasks',
            pluginId: 'tasks',
            score: 0.7,
          ),
        ],
      );

      final results = await service.search('test', [plugin1, plugin2]);
      expect(results, hasLength(2));
    });

    test('sorts results by score descending', () async {
      final plugin = _SearchTestPlugin(
        pluginId: 'all',
        results: [
          const SearchResult(
            id: 'low',
            title: 'Low score',
            routeName: 'r',
            pluginId: 'all',
            score: 0.3,
          ),
          const SearchResult(
            id: 'high',
            title: 'High score',
            routeName: 'r',
            pluginId: 'all',
            score: 0.9,
          ),
          const SearchResult(
            id: 'mid',
            title: 'Mid score',
            routeName: 'r',
            pluginId: 'all',
            score: 0.6,
          ),
        ],
      );

      final results = await service.search('test', [plugin]);
      expect(results, hasLength(3));
      expect(results[0].id, 'high');
      expect(results[1].id, 'mid');
      expect(results[2].id, 'low');
    });

    test('limits total to 20 results', () async {
      final manyResults = List.generate(
        25,
        (i) => SearchResult(
          id: '$i',
          title: 'Result $i',
          routeName: 'r',
          pluginId: 'many',
          score: 1.0 - (i * 0.01),
        ),
      );
      final plugin = _SearchTestPlugin(pluginId: 'many', results: manyResults);

      final results = await service.search('test', [plugin]);
      expect(results, hasLength(20));
    });
  });
}
