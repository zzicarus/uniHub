import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uni_hub/src/core/database/app_database.dart';
import 'package:uni_hub/src/core/theme/app_breakpoints.dart';
import 'package:uni_hub/src/core/theme/app_tokens.dart';

import '../../providers/thoughts_providers.dart';
import '../widgets/thought_card.dart';
import '../widgets/thought_common_tags_panel.dart';
import '../widgets/thought_context_menu.dart';
import '../widgets/thought_pending_review_panel.dart';
import '../widgets/thought_pinned_panel.dart';
import '../widgets/thought_state_templates.dart';
import '../widgets/thought_stats_panel.dart';
import 'thought_composer.dart';
import 'thought_filter_panel.dart';
import 'thoughts_shared_widgets.dart';

class ThoughtsDesktopLayout extends ConsumerWidget {
  final void Function(int) onThoughtTap;

  const ThoughtsDesktopLayout({required this.onThoughtTap, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.of(context).size.width;
    final showRightRail = width >= AppBreakpoints.wideMin;
    final colorScheme = Theme.of(context).colorScheme;
    final thoughtsAsync = ref.watch(thoughtsListProvider);
    final isArchived = ref.watch(archiveFilterProvider);
    final selectedTags = ref.watch(selectedTagFiltersProvider);
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
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1080),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ThoughtsHeader(
                        isArchived: isArchived,
                        thoughtsCount: thoughtsCount,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (!isArchived) ...[
                        const ThoughtComposer(),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                      ThoughtFilterPanel(isArchived: isArchived),
                      const SizedBox(height: AppSpacing.lg),
                      thoughtsAsync.when(
                        loading: () => const ThoughtLoadingState(),
                        error: (err, _) => ThoughtStateTemplate.filterError(
                          onRetry: () => ref.invalidate(thoughtsListProvider),
                        ),
                        data: (thoughts) => _ThoughtsContent(
                          thoughts: thoughts,
                          isArchived: isArchived,
                          selectedTags: selectedTags,
                          searchQuery: searchQuery,
                          onOpen: onThoughtTap,
                        ),
                      ),
                    ],
                  ),
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
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.12),
            ),
          ),
          child: Icon(
            isArchived ? Icons.archive_outlined : Icons.lightbulb_outline,
            color: AppColors.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    isArchived ? '归档想法' : '想法',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _CountBadge(count: thoughtsCount),
                ],
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                isArchived ? '查看已经归档的记录，必要时可恢复。' : '捕捉灵感，整理想法，让每个念头都有价值。',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ThoughtsContent extends ConsumerWidget {
  final List<ThoughtsTableData> thoughts;
  final bool isArchived;
  final Set<String> selectedTags;
  final String searchQuery;
  final void Function(int) onOpen;

  const _ThoughtsContent({
    required this.thoughts,
    required this.isArchived,
    required this.selectedTags,
    required this.searchQuery,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (thoughts.isEmpty) {
      if (isArchived) {
        return ThoughtStateTemplate.archiveEmpty();
      }
      if (selectedTags.isNotEmpty) {
        return ThoughtStateTemplate.filterNoResults(
          selectedTags.join('、'),
          onClearFilter: () {
            ref.read(selectedTagFiltersProvider.notifier).state =
                const <String>{};
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
          title: isArchived
              ? '归档记录'
              : selectedTags.isEmpty
              ? '想法列表'
              : '想法列表（已按标签筛选）',
          count: thoughts.length,
        ),
        const SizedBox(height: AppSpacing.md),
        _ThoughtGrid(thoughts: thoughts, onOpen: onOpen),
      ],
    );
  }
}

class _ThoughtGrid extends ConsumerWidget {
  final List<ThoughtsTableData> thoughts;
  final void Function(int) onOpen;

  const _ThoughtGrid({required this.thoughts, required this.onOpen});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 3
            : constraints.maxWidth >= 620
            ? 2
            : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: columns == 1 ? 3.4 : 2.35,
          ),
          itemCount: thoughts.length,
          itemBuilder: (context, index) {
            final thought = thoughts[index];
            return ThoughtCard(
              id: thought.id,
              content: thought.content,
              tags: thought.tags,
              color: thought.color,
              isPinned: thought.isPinned,
              createdAt: thought.createdAt,
              imagePaths: thought.imagePaths,
              onTap: () => onOpen(thought.id),
              onTagTap: (tag) {
                final current = ref.read(selectedTagFiltersProvider);
                ref.read(selectedTagFiltersProvider.notifier).state =
                    toggleTagInFilter(current, tag);
              },
              onContextMenu: () => _handleContextMenu(context, ref, thought),
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
        onOpen(thought.id);
      case ThoughtContextAction.togglePin:
        await ref
            .read(thoughtsRepositoryProvider)
            .togglePin(thought.id, !thought.isPinned);
        ref.invalidate(allThoughtsProvider);
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
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('想法已恢复')));
          }
        } else {
          await ref.read(thoughtsRepositoryProvider).archiveThought(thought.id);
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('想法已归档')));
          }
        }
        ref.invalidate(allThoughtsProvider);
      case ThoughtContextAction.delete:
        final confirmed = await showThoughtDeleteDialog(context);
        if (confirmed && context.mounted) {
          await ref.read(thoughtsRepositoryProvider).deleteThought(thought.id);
          ref.invalidate(allThoughtsProvider);
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('想法已删除')));
          }
        }
      case ThoughtContextAction.convertToTodo:
      case ThoughtContextAction.convertToNote:
        break;
    }
  }
}

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
            const SizedBox(height: AppSpacing.lg),
            const ThoughtPendingReviewPanel(),
            const SizedBox(height: AppSpacing.lg),
            const ThoughtCommonTagsPanel(),
            const SizedBox(height: AppSpacing.lg),
            const ThoughtStatsPanel(),
            const SizedBox(height: AppSpacing.lg),
            const ThoughtHotTagsPanel(),
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

class _CountBadge extends StatelessWidget {
  final int count;

  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        count.toString(),
        style: theme.textTheme.labelMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
