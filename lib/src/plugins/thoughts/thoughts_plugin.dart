import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uni_hub/src/core/plugin/plugin_interface.dart';
import 'package:uni_hub/src/core/router/route_names.dart';
import 'package:uni_hub/src/core/database/tables/thoughts_table.dart';
import 'package:uni_hub/src/core/theme/app_tokens.dart';
import 'package:uni_hub/src/shared/editor/appflowy_document_tools.dart';
import 'package:uni_hub/src/shared/url/url_normalizer.dart';
import 'data/thought_content_codec.dart';
import 'providers/thoughts_providers.dart';
import 'ui/thoughts_list_page.dart';
import 'ui/widgets/thought_editor_workspace.dart';

class ThoughtsPlugin extends UniHubPlugin {
  @override
  String get id => 'thoughts';

  @override
  String get name => '想法';

  @override
  List<NavEntry> get navEntries => [
    NavEntry(
      label: '想法',
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
        final idStr = state.pathParameters['id']!;
        final id = int.tryParse(idStr);
        if (id == null) {
          return const ThoughtsListPage();
        }
        return _ThoughtEditorRoutePage(thoughtId: id);
      },
    ),
  ];

  @override
  List<Type> get tables => [ThoughtsTable];

  @override
  int get schemaVersion => 6;

  // ─── Dashboard methods ───────────────────────────────────────────

  @override
  Future<List<DashboardItem>> getRecentItems(Ref ref, {int count = 4}) async {
    final repo = ref.read(thoughtsRepositoryProvider);
    // #11: 使用 DAO 层 LIMIT 查询，避免全量读取后内存过滤
    final recent = await repo.getRecent(limit: count);
    return recent
        .map(
          (t) => DashboardItem(
            pluginId: id,
            itemId: t.id.toString(),
            content: ThoughtContentCodec.plainTextFromStored(t.content),
            tags: _parseTags(t.tags),
            colorHex: t.color,
            isPinned: t.isPinned,
            createdAt: t.createdAt,
            routePath: '/thoughts/${t.id}',
          ),
        )
        .toList();
  }

  @override
  Future<List<DashboardItem>> getPinnedItems(Ref ref, {int count = 3}) async {
    final repo = ref.read(thoughtsRepositoryProvider);
    // #11: 使用 DAO 层 LIMIT 查询，避免全量读取后内存过滤
    final pinned = await repo.getPinned(limit: count);
    return pinned
        .map(
          (t) => DashboardItem(
            pluginId: id,
            itemId: t.id.toString(),
            content: ThoughtContentCodec.plainTextFromStored(t.content),
            tags: _parseTags(t.tags),
            colorHex: t.color,
            isPinned: true,
            createdAt: t.createdAt,
            routePath: '/thoughts/${t.id}',
          ),
        )
        .toList();
  }

  @override
  Future<PluginStat?> getStat(Ref ref) async {
    final repo = ref.read(thoughtsRepositoryProvider);
    // #11: 使用 DAO 层 COUNT 查询，避免全量读取
    final count = await repo.countActive();
    return PluginStat(pluginId: id, label: '想法', count: count);
  }

  @override
  bool canHandleQuickCreate(String content) {
    // #7: Thoughts 处理非 URL 的普通文本
    // 使用 shared UrlNormalizer 与 Collections 保持一致
    final trimmed = content.trim();
    if (trimmed.isEmpty) return false;
    return const UrlNormalizer().tryNormalize(trimmed) == null;
  }

  @override
  Future<DashboardItem?> quickCreate(
    Ref ref, {
    required String content,
    String? tags,
  }) async {
    final repo = ref.read(thoughtsRepositoryProvider);
    final plainText = content.trim();
    final document = AppFlowyDocumentTools.documentJsonFromPlainText(plainText);
    final created = await repo.createThought(
      content: ThoughtContentCodec.encodeAppFlowy(
        document: document,
        plainText: plainText,
      ),
      tags: tags,
    );
    return DashboardItem(
      pluginId: id,
      itemId: created.id.toString(),
      content: ThoughtContentCodec.plainTextFromStored(created.content),
      tags: _parseTags(created.tags),
      colorHex: created.color,
      isPinned: created.isPinned,
      createdAt: created.createdAt,
      routePath: '/thoughts/${created.id}',
    );
  }

  List<String> _parseTags(String? tags) {
    if (tags == null || tags.isEmpty) return [];
    return tags
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }
}

/// Route host for `/thoughts/:id`.
///
/// Keeps the user-facing route on the AppFlowy workspace while leaving the
/// legacy Quill editor page available only as migration code.
class _ThoughtEditorRoutePage extends ConsumerWidget {
  const _ThoughtEditorRoutePage({required this.thoughtId});

  final int thoughtId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thoughtAsync = ref.watch(thoughtProvider(thoughtId));
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: thoughtAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _ThoughtEditorRouteMessage(
            icon: Icons.error_outline,
            title: '暂时无法加载想法',
            message: '请返回列表后重试。',
            actionLabel: '返回想法列表',
            onAction: () => context.go('/thoughts'),
          ),
          data: (thought) {
            if (thought == null) {
              return _ThoughtEditorRouteMessage(
                icon: Icons.lightbulb_outline,
                title: '找不到这条想法',
                message: '它可能已被删除，或链接已失效。',
                actionLabel: '返回想法列表',
                onAction: () => context.go('/thoughts'),
              );
            }

            return ThoughtEditorWorkspace(
              thoughtId: thoughtId,
              onClose: () => context.go('/thoughts'),
            );
          },
        ),
      ),
    );
  }
}

class _ThoughtEditorRouteMessage extends StatelessWidget {
  const _ThoughtEditorRouteMessage({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: AppSpacing.md),
            Text(title, style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.arrow_back),
              label: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
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
