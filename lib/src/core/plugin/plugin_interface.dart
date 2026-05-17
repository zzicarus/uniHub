import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import '../search/search_result.dart';

class NavEntry {
  final String label;
  final IconData icon;
  final String routeName;
  final String path;
  final Map<String, String> routeParams;
  final Map<String, String> queryParams;
  final List<NavEntry>? children;

  const NavEntry({
    required this.label,
    required this.icon,
    required this.routeName,
    required this.path,
    this.routeParams = const {},
    this.queryParams = const {},
    this.children,
  });
}

abstract class UniHubPlugin {
  String get id;
  String get name;
  List<NavEntry> get navEntries => [];
  List<GoRoute> get routes => [];
  List<Type> get tables => [];
  int get schemaVersion => 0;
  Future<void> onInit() async {}
  Future<void> onDispose() async {}
  Future<List<SearchResult>> search(String query) async => [];
}
