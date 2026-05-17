import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/plugin/plugin_interface.dart';
import '../../core/router/route_names.dart';
import 'data/thoughts_table.dart';
import 'providers/thoughts_providers.dart';
import 'ui/thoughts_list_page.dart';
import 'ui/thoughts_editor_page.dart';

class ThoughtsPlugin extends UniHubPlugin {
  @override
  String get id => 'thoughts';

  @override
  String get name => 'Thoughts';

  @override
  List<NavEntry> get navEntries => [
    NavEntry(
      label: 'Thoughts',
      icon: Icons.lightbulb_outline,
      routeName: RouteNames.thoughts,
      path: '/thoughts',
      children: [
        const NavEntry(
          label: '所有想法',
          icon: Icons.list,
          routeName: RouteNames.thoughts,
          path: '/thoughts',
        ),
        const NavEntry(
          label: '归档',
          icon: Icons.archive_outlined,
          routeName: RouteNames.thoughts,
          path: '/thoughts',
          queryParams: {'filter': 'archived'},
        ),
      ],
    ),
  ];

  @override
  List<GoRoute> get routes => [
    GoRoute(
      path: '/thoughts',
      name: RouteNames.thoughts,
      builder: (context, state) {
        final filter = state.uri.queryParameters['filter'];
        final isArchived = filter == 'archived';
        return _ThoughtsListPageWithFilter(
          key: ValueKey('thoughts-$filter'),
          isArchived: isArchived,
        );
      },
    ),
    GoRoute(
      path: '/thoughts/:id',
      name: RouteNames.thoughtEditor,
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return ThoughtsEditorPage(thoughtId: id);
      },
    ),
  ];

  @override
  List<Type> get tables => [ThoughtsTable];

  @override
  int get schemaVersion => 1;
}

/// Wrapper that sets the archive filter provider when navigated to with filter param.
class _ThoughtsListPageWithFilter extends ConsumerStatefulWidget {
  final bool isArchived;

  const _ThoughtsListPageWithFilter({required this.isArchived, super.key});

  @override
  ConsumerState<_ThoughtsListPageWithFilter> createState() =>
      _ThoughtsListPageWithFilterState();
}

class _ThoughtsListPageWithFilterState
    extends ConsumerState<_ThoughtsListPageWithFilter> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(archiveFilterProvider.notifier).state = widget.isArchived;
    });
  }

  @override
  Widget build(BuildContext context) {
    return const ThoughtsListPage();
  }
}
