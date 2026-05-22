import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uni_hub/src/core/theme/app_breakpoints.dart';
import 'package:uni_hub/src/core/theme/app_tokens.dart';
import 'package:uni_hub/src/core/database/app_database.dart';
import '../widgets/thought_card.dart';
import '../widgets/thought_pinned_panel.dart';
import '../widgets/thought_pending_review_panel.dart';
import '../widgets/thought_common_tags_panel.dart';
import '../widgets/thought_random_review_panel.dart';
import '../widgets/thought_quick_actions_panel.dart';
import '../widgets/thought_context_menu.dart';
import '../widgets/thought_state_templates.dart';
import '../../providers/thoughts_providers.dart';
import 'thoughts_shared_widgets.dart';
import 'thought_composer.dart';
import 'thought_filter_bar.dart';
import 'thought_tag_filter_bar.dart';
import 'thought_selected_tags_bar.dart';

class ThoughtsDesktopLayout extends ConsumerWidget {
  final void Function(int) onThoughtTap;

  const ThoughtsDesktopLayout({
    required this.onThoughtTap,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.of(context).size.width;
    final showRightRail = width >= AppBreakpoints.wideMin;
    final colorScheme = Theme.of(context).colorScheme;
    final thoughtsAsync = ref.watch(thoughtsListProvider);
    final isArchived = ref.watch(archiveFilterProvider);
    final selectedTag = ref.watch(tagFilterProvider);
    final thoughtsCount = ref.watch(thoughtsCountProvider);

    final searchQuery = ref.watch(thoughtSearchQueryProvider);

    return ColoredBox(
      color: colorScheme.surfaceContainerLowest,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xxl,
                AppSpacing.xl,
                AppSpacing.xxl,
                AppSpacing.section,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1080),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dynamic header with title, count, and search
                    _ThoughtsHeader(
                      isArchived: isArchived,
                      thoughtsCount: thoughtsCount,
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Lightweight composer (only when not archived)
                    if (!isArchived) ...[
                      const ThoughtComposer(),
                      const SizedBox(height: AppSpacing.lg),
                    ],

                    // Status filter chips
                    if (!isArchived) ...[
                      const ThoughtFilterBar(),
                      const SizedBox(height: AppSpacing.sm),
                    ],

                    // Tag filter bar
                    if (!isArchived) ...[
                      const ThoughtTagFilterBar(),
                      const SizedBox(height: AppSpacing.sm),
                    ],

                    // Selected tags bar
                    const ThoughtSelectedTagsBar(),
                    const SizedBox(height: AppSpacing.lg),

                    // Single grid (no pinned/unpinned split)
                    thoughtsAsync.when(
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(AppSpacing.xxl),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (err, _) => ThoughtStateTemplate.filterError(
                        onRetry: () => ref.invalidate(thoughtsListProvider),
                      ),
                      data: (thoughts) => _ThoughtsContent(
                        thoughts: thoughts,
                        isArchived: isArchived,
                        selectedTag: selectedTag,
                        searchQuery: searchQuery,
                        onOpen: onThoughtTap,
                        onTagTap: (tag) {
                          ref.read(tagFilterProvider.notifier).state = tag;
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (showRightRail) _ThoughtsRightRail(onThoughtTap: onThoughtTap),
        ],
      ),
    );
  }
}

// ─── Header with Dynamic Title and Search ────────────────────────────

class _ThoughtsHeader extends StatelessWidget {
  final bool isArchived;
  final int thoughtsCount;

  const _ThoughtsHeader({
    required this.isArchived,
    required this.thoughtsCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: colorScheme.tertiaryContainer,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Icon(
            isArchived ? Icons.archive_outlined : Icons.lightbulb_outline,
            color: colorScheme.tertiary,
            size: 30,
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    isArchived ? '归档想法' : '想法',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      thoughtsCount.toString(),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                isArchived ? '查看已经归档的记录，必要时可恢复。' : '捕捉灵感，整理想法，让每个念头都有价值',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        const _ThoughtLocalSearchBox(),
        const SizedBox(width: AppSpacing.md),
        Stack(
          clipBehavior: Clip.none,
          children: [
            const ThoughtIconSquare(icon: Icons.notifications_none_rounded),
            Positioned(
              right: 10,
              top: 10,
              child: Container(
                width: AppSpacing.xs,
                height: AppSpacing.xs,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Local Search Box ────────────────────────────────────────────────

class _ThoughtLocalSearchBox extends ConsumerStatefulWidget {
  const _ThoughtLocalSearchBox();

  @override
  ConsumerState<_ThoughtLocalSearchBox> createState() =>
      _ThoughtLocalSearchBoxState();
}

class _ThoughtLocalSearchBoxState
    extends ConsumerState<_ThoughtLocalSearchBox> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      width: 240,
      child: TextField(
        controller: _controller,
        onChanged: (value) {
          ref.read(thoughtSearchQueryProvider.notifier).state = value;
        },
        decoration: InputDecoration(
          hintText: '搜索想法',
          prefixIcon: const Icon(Icons.search_rounded, size: 20),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () {
                    _controller.clear();
                    ref.read(thoughtSearchQueryProvider.notifier).state = '';
                  },
                )
              : null,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide(color: colorScheme.outlineVariant),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide(color: colorScheme.outlineVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide(color: colorScheme.primary),
          ),
          filled: true,
          fillColor: colorScheme.surface,
        ),
        style: theme.textTheme.bodyMedium,
      ),
    );
  }
}

// ─── Content (Single Grid) ───────────────────────────────────────────

class _ThoughtsContent extends ConsumerWidget {
  final List<ThoughtsTableData> thoughts;
  final bool isArchived;
  final String? selectedTag;
  final String searchQuery;
  final void Function(int) onOpen;
  final ValueChanged<String> onTagTap;

  const _ThoughtsContent({
    required this.thoughts,
    required this.isArchived,
    required this.selectedTag,
    required this.searchQuery,
    required this.onOpen,
    required this.onTagTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (thoughts.isEmpty) {
      if (isArchived) {
        return ThoughtStateTemplate.archiveEmpty();
      }
      if (selectedTag != null && selectedTag!.isNotEmpty) {
        return ThoughtStateTemplate.filterNoResults(
          selectedTag!,
          onClearFilter: () {
            ref.read(tagFilterProvider.notifier).state = null;
          },
        );
      }
      if (searchQuery.isNotEmpty) {
        return ThoughtStateTemplate.searchNoResults(
          searchQuery,
          onClearSearch: () {
            ref.read(thoughtSearchQueryProvider.notifier).state = '';
          },
        );
      }
      return ThoughtStateTemplate.noThoughts();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ThoughtSectionLabel(
          icon: isArchived ? Icons.archive_outlined : Icons.grid_view_rounded,
          title: isArchived ? '归档记录' : '全部想法',
          count: thoughts.length,
        ),
        const SizedBox(height: AppSpacing.md),
        _ThoughtGrid(
          thoughts: thoughts,
          onOpen: onOpen,
          onTagTap: onTagTap,
        ),
      ],
    );
  }
}

// ─── Thought Grid ────────────────────────────────────────────────────

class _ThoughtGrid extends ConsumerWidget {
  final List<ThoughtsTableData> thoughts;
  final void Function(int) onOpen;
  final ValueChanged<String> onTagTap;

  const _ThoughtGrid({
    required this.thoughts,
    required this.onOpen,
    required this.onTagTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 980
            ? 4
            : constraints.maxWidth >= 640
            ? 2
            : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: columns == 1 ? 3.2 : 1.45,
          ),
          itemCount: thoughts.length,
          itemBuilder: (context, index) {
            final t = thoughts[index];
            return ThoughtCard(
              id: t.id,
              content: t.content,
              tags: t.tags,
              color: t.color,
              isPinned: t.isPinned,
              createdAt: t.createdAt,
              imagePaths: t.imagePaths,
              onTap: () => onOpen(t.id),
              onTagTap: onTagTap,
              onContextMenu: () => _handleContextMenu(
                context,
                ref,
                t,
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleContextMenu(
    BuildContext context,
    WidgetRef ref,
    ThoughtsTableData thought,
  ) async {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final position = renderBox.localToGlobal(Offset.zero);

    final action = await showThoughtContextMenu(
      context: context,
      position: position,
      isPinned: thought.isPinned,
      isArchived: thought.archivedAt != null,
    );

    if (action == null || !context.mounted) return;

    switch (action) {
      case ThoughtContextAction.edit:
        _openEditor(context, thought.id);
      case ThoughtContextAction.togglePin:
        await ref.read(thoughtsRepositoryProvider).togglePin(
              thought.id,
              !thought.isPinned,
            );
        ref.invalidate(thoughtsListProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(thought.isPinned ? '已取消置顶' : '已置顶'),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      case ThoughtContextAction.addTag:
        await showThoughtTagDialog(
          context: context,
          ref: ref,
          thoughtId: thought.id,
        );
      case ThoughtContextAction.toggleArchive:
        if (thought.archivedAt != null) {
          await ref.read(thoughtsRepositoryProvider).restoreThought(thought.id);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('想法已恢复')),
            );
          }
        } else {
          await ref.read(thoughtsRepositoryProvider).archiveThought(thought.id);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('想法已归档')),
            );
          }
        }
        ref.invalidate(thoughtsListProvider);
      case ThoughtContextAction.delete:
        final confirmed = await showThoughtDeleteDialog(context);
        if (confirmed && context.mounted) {
          await ref.read(thoughtsRepositoryProvider).deleteThought(thought.id);
          ref.invalidate(thoughtsListProvider);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('想法已删除')),
            );
          }
        }
      case ThoughtContextAction.convertToTodo:
      case ThoughtContextAction.convertToNote:
        break;
    }
  }

  void _openEditor(BuildContext context, int thoughtId) {
    // Navigate to editor page or open drawer
    // For now, show a snackbar since the editor route depends on app structure
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('打开编辑器'),
        action: SnackBarAction(
          label: '前往',
          onPressed: () {
            // Navigate to editor - depends on app routing
          },
        ),
      ),
    );
  }
}

// ─── Right Rail ──────────────────────────────────────────────────────

class _ThoughtsRightRail extends StatelessWidget {
  final void Function(int thoughtId)? onThoughtTap;

  const _ThoughtsRightRail({this.onThoughtTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: AppDesktopSizes.rightRailWideWidth,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        border: Border(left: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            ThoughtPinnedPanel(onThoughtTap: onThoughtTap),
            const SizedBox(height: AppSpacing.xl),
            const ThoughtPendingReviewPanel(),
            const SizedBox(height: AppSpacing.xl),
            const ThoughtCommonTagsPanel(),
            const SizedBox(height: AppSpacing.xl),
            ThoughtRandomReviewPanel(onThoughtTap: onThoughtTap),
            const SizedBox(height: AppSpacing.xl),
            const ThoughtQuickActionsPanel(),
            const SizedBox(height: AppSpacing.xxl),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 14, color: colorScheme.outline),
                const SizedBox(width: AppSpacing.xxs),
                Text(
                  '你的数据，仅你可见',
                  style: TextStyle(color: colorScheme.outline, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
