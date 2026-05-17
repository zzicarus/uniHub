import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/plugin/plugin_interface.dart';
import '../../core/router/route_names.dart';
import 'thoughts_placeholder_page.dart';

class ThoughtsPlugin extends UniHubPlugin {
  @override
  String get id => 'thoughts';
  @override
  String get name => 'Thoughts';
  @override
  List<NavEntry> get navEntries => [
    const NavEntry(
      label: 'Thoughts',
      icon: Icons.lightbulb_outline,
      routeName: RouteNames.thoughts,
      path: '/thoughts',
    ),
  ];
  @override
  List<GoRoute> get routes => [
    GoRoute(
      path: '/thoughts',
      name: RouteNames.thoughts,
      builder: (context, state) => const ThoughtsPlaceholderPage(),
    ),
  ];
}
