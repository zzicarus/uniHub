import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uni_hub/src/core/database/app_database.dart';
import 'package:uni_hub/src/core/theme/app_tokens.dart';
import 'package:uni_hub/src/shared/tags/tag_models.dart';
import 'package:uni_hub/src/shared/ui/rich_text_editor/rich_text_editor.dart';
import 'package:uni_hub/src/shared/widgets/tags/app_more_tags_popover.dart';
import 'package:uni_hub/src/shared/widgets/tags/app_selected_tags_bar.dart';
import 'package:uni_hub/src/shared/widgets/tags/app_tag_chip.dart';

import '../../providers/thought_status_filter.dart';
import '../../providers/thoughts_providers.dart';
import '../widgets/thought_card.dart';
import '../widgets/thought_composer_controller.dart';
import '../widgets/thought_context_menu.dart';
import '../widgets/thought_state_templates.dart';
import 'thoughts_shared_widgets.dart';

/// Mobile layout for Thoughts Inbox V2.
///
/// Reads directly from shared providers (same as desktop):
/// - [thoughtStatusFilterProvider] — status filter state
/// - [thoughtSearchQueryProvider] — search query
/// - [selectedTagFiltersProvider] — active tag filters
/// - [archiveFilterProvider] — archive toggle
/// - [composerProvider] — composer controller
/// - [thoughtsListProvider] — filtered thought list
/// - [commonTagsProvider] — tag stats for chips
class ThoughtsMobileLayout extends ConsumerWidget {
  final void Function(int id) onThoughtTap;

  const ThoughtsMobileLayout({required this.onThoughtTap, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArchived = ref.watch(archiveFilterProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return ColoredBox(
      color: colorScheme.surfaceContainerLowest,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppMobileSizes.maxContentWidth,
          ),
          child: Column(
            children: [
              _MobileTopBar(isArchived: isArchived),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppMobileSizes.pageHorizontalPadding,
                    AppSpacing.md,
                    AppMobileSizes.pageHorizontalPadding,
                    AppSpacing.xxl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!isArchived) ...[
                        const _MobileComposer(),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                      const _MobileFilterChips(),
                      const SizedBox(height: AppSpacing.md),
                      const _SelectedTagBanner(),
                      const SizedBox(height: AppSpacing.md),
                      _MobileThoughtGrid(onThoughtTap: onThoughtTap),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Top Bar ─────────────────────────────────────────────────────────

class _MobileTopBar extends ConsumerWidget {
  final bool isArchived;

  const _MobileTopBar({required this.isArchived});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppMobileSizes.pageHorizontalPadding,
        AppSpacing.lg,
        AppMobileSizes.pageHorizontalPadding,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          Icon(
            isArchived ? Icons.archive_outlined : Icons.lightbulb_outline,
            size: 32,
            color: colorScheme.onSurface,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              isArchived ? '归档想法' : '想法',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: AppFontTokens.extraBold,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const _MobileSearchBox(),
        ],
      ),
    );
  }
}

// ─── Search Box (mobile-adapted) ─────────────────────────────────────

class _MobileSearchBox extends ConsumerWidget {
  const _MobileSearchBox();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(thoughtSearchQueryProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 160,
      child: TextField(
        onChanged: (v) =>
            ref.read(thoughtSearchQueryProvider.notifier).state = v,
        decoration: InputDecoration(
          hintText: '搜索想法',
          prefixIcon: const Icon(Icons.search_rounded, size: 20),
          suffixIcon: query.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () =>
                      ref.read(thoughtSearchQueryProvider.notifier).state = '',
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
        ),
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

// ─── Composer ────────────────────────────────────────────────────────

class _MobileComposer extends ConsumerWidget {
  const _MobileComposer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final composer = ref.watch(composerProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final existingTags = ref.watch(commonTagsProvider);
    final tagInput = composer.tagTextController.text.trim().toLowerCase();
    final tagSuggestions = tagInput.isEmpty
        ? const <String>[]
        : existingTags
            .map((e) => e.key)
            .where((tag) =>
                tag.toLowerCase().contains(tagInput) &&
                !composer.tagChips.contains(tag))
            .take(5)
            .toList();

    return ThoughtPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ThoughtIconBubble(
                icon: Icons.lightbulb_outline,
                color: colorScheme.onPrimaryContainer,
                background: colorScheme.primaryContainer,
              ),
              const SizedBox(width: AppSpacing.md),
              Text('快速记录想法', style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: colorScheme.outline),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: RichTextEditor(
                controller: composer.contentController,
                minHeight: 92,
                placeholder: '快速记录你的想法、灵感或闪念...',
                onChanged: (_) => composer.syncContentState(),
                onPickImage: composer.onPickEditorImage,
                onPasteImage: composer.onPasteImage,
                onImageAdded: composer.onEditorImageAdded,
              ),
            ),
          ),
          if (composer.tagChips.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: composer.tagChips.map((tag) {
                return Chip(
                  label: Text(tag),
                  deleteIcon: const Icon(Icons.close, size: 14),
                  onDeleted: () => composer.removeChip(tag),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
          ],
          if (composer.pendingImages.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 62,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: composer.pendingImages.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: AppSpacing.sm),
                itemBuilder: (_, i) {
                  final image = composer.pendingImages[i];
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                        child: Image.memory(
                          image.bytes,
                          width: 62,
                          height: 62,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: GestureDetector(
                          onTap: () => composer.removePendingImage(i),
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.xxs),
                            decoration: BoxDecoration(
                              color: colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.54,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              size: 12,
                              color: colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: composer.tagTextController,
            onChanged: composer.handleTagInput,
            decoration: InputDecoration(
              hintText: '添加标签，空格或逗号确认',
              prefixIcon: const Icon(Icons.sell_outlined, size: 18),
              isDense: true,
              errorText: composer.tagErrorMessage,
              errorStyle: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.error,
                fontSize: AppFontTokens.mini,
              ),
            ),
            style: theme.textTheme.bodySmall,
          ),
          if (tagSuggestions.isNotEmpty && composer.tagErrorMessage == null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xxs,
                children: tagSuggestions.map((tag) {
                  return Material(
                    color: colorScheme.tertiaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      onTap: () {
                        composer.tagTextController.clear();
                        composer.handleTagInput('$tag,');
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xxs,
                        ),
                        child: Text(
                          '#$tag',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onTertiaryContainer,
                            fontWeight: AppFontTokens.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ThoughtPillButton(
                icon: Icons.image_outlined,
                label: composer.pendingImages.isNotEmpty
                    ? '图片 (${composer.pendingImages.length})'
                    : '添加图片',
                onTap: composer.pickImageForComposer,
              ),
              ThoughtPillButton(
                icon: composer.isPinned
                    ? Icons.push_pin
                    : Icons.push_pin_outlined,
                label: composer.isPinned ? '已置顶' : '设为置顶',
                selected: composer.isPinned,
                onTap: composer.togglePin,
              ),
              FilledButton.icon(
                onPressed: composer.canSubmit && !composer.isSubmitting
                    ? composer.submit
                    : null,
                icon: const Icon(Icons.send_rounded, size: 18),
                label: Text(composer.isSubmitting ? '保存中' : '记录想法'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Filter Chips (Status + Tags) ────────────────────────────────────

class _MobileFilterChips extends ConsumerWidget {
  const _MobileFilterChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusFilter = ref.watch(thoughtStatusFilterProvider);
    final isArchived = ref.watch(archiveFilterProvider);
    final tagEntries = ref.watch(commonTagsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _StatusChip(
                label: '全部',
                status: ThoughtStatusFilter.all,
                current: statusFilter,
              ),
              const SizedBox(width: AppSpacing.sm),
              _StatusChip(
                label: '未整理',
                status: ThoughtStatusFilter.unorganized,
                current: statusFilter,
              ),
              const SizedBox(width: AppSpacing.sm),
              _StatusChip(
                label: '置顶',
                status: ThoughtStatusFilter.pinned,
                current: statusFilter,
              ),
              const SizedBox(width: AppSpacing.sm),
              _StatusChip(
                label: '有图片',
                status: ThoughtStatusFilter.withImages,
                current: statusFilter,
              ),
              const SizedBox(width: AppSpacing.sm),
              _StatusChip(
                label: '归档',
                status: ThoughtStatusFilter.archived,
                current: statusFilter,
                isArchiveToggle: true,
                isArchived: isArchived,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Tag filter chips
        if (tagEntries.isNotEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (int i = 0; i < tagEntries.length && i < 4; i++) ...[
                  _TagChip(entry: tagEntries[i]),
                  const SizedBox(width: AppSpacing.sm),
                ],
                if (tagEntries.length > 4) _MoreTagsButton(allTags: tagEntries),
              ],
            ),
          ),
      ],
    );
  }
}

class _StatusChip extends ConsumerWidget {
  final String label;
  final ThoughtStatusFilter status;
  final ThoughtStatusFilter current;
  final bool isArchiveToggle;
  final bool isArchived;

  const _StatusChip({
    required this.label,
    required this.status,
    required this.current,
    this.isArchiveToggle = false,
    this.isArchived = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = isArchiveToggle ? isArchived : status == current;
    return ThoughtFilterChip(
      label: label,
      value: '',
      selected: isSelected,
      onTap: () {
        if (isArchiveToggle) {
          ref.read(archiveFilterProvider.notifier).state = !isArchived;
          if (!isArchived) {
            ref.read(thoughtStatusFilterProvider.notifier).state =
                ThoughtStatusFilter.archived;
          } else {
            ref.read(thoughtStatusFilterProvider.notifier).state =
                ThoughtStatusFilter.all;
          }
        } else {
          ref.read(thoughtStatusFilterProvider.notifier).state = status;
          if (status != ThoughtStatusFilter.archived && isArchived) {
            ref.read(archiveFilterProvider.notifier).state = false;
          }
        }
      },
    );
  }
}

class _TagChip extends ConsumerWidget {
  final MapEntry<String, int> entry;

  const _TagChip({required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTags = ref.watch(selectedTagFiltersProvider);
    return AppTagChip(
      label: entry.key,
      count: entry.value,
      selected: selectedTags.contains(entry.key),
      compact: true,
      onTap: () {
        final current = ref.read(selectedTagFiltersProvider);
        ref.read(selectedTagFiltersProvider.notifier).state = toggleTagInFilter(
          current,
          entry.key,
        );
      },
    );
  }
}

class _MoreTagsButton extends ConsumerWidget {
  final List<MapEntry<String, int>> allTags;

  const _MoreTagsButton({required this.allTags});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppMoreTagsButton(
      onTap: () => _showTagsBottomSheet(context, ref),
    );
  }

  void _showTagsBottomSheet(BuildContext context, WidgetRef ref) {
    final tagStats = allTags
        .map((e) => AppTagStat(name: e.key, count: e.value))
        .toList();
    final selectedTags = ref.read(selectedTagFiltersProvider);

    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: AppMoreTagsPopoverContent(
              tags: tagStats,
              selectedTags: selectedTags,
              onTagToggle: (tag) {
                final current = ref.read(selectedTagFiltersProvider);
                ref.read(selectedTagFiltersProvider.notifier).state =
                    toggleTagInFilter(current, tag);
              },
              onClear: () {
                ref.read(selectedTagFiltersProvider.notifier).state =
                    const <String>{};
              },
            ),
          ),
        );
      },
    );
  }
}

// ─── Selected Tag Banner ─────────────────────────────────────────────

class _SelectedTagBanner extends ConsumerWidget {
  const _SelectedTagBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTags = ref.watch(selectedTagFiltersProvider);

    return AppSelectedTagsBar(
      selectedTags: selectedTags,
      label: '已选标签',
      clearLabel: '清除',
      onRemove: (tag) {
        final current = ref.read(selectedTagFiltersProvider);
        ref.read(selectedTagFiltersProvider.notifier).state =
            removeTagFromFilter(current, tag);
      },
      onClear: () {
        ref.read(selectedTagFiltersProvider.notifier).state =
            const <String>{};
      },
    );
  }
}

// ─── Thought Grid ────────────────────────────────────────────────────

class _MobileThoughtGrid extends ConsumerWidget {
  final void Function(int id) onThoughtTap;

  const _MobileThoughtGrid({required this.onThoughtTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArchived = ref.watch(archiveFilterProvider);
    final selectedTags = ref.watch(selectedTagFiltersProvider);
    final searchQuery = ref.watch(thoughtSearchQueryProvider);

    return ref
        .watch(thoughtsListProvider)
        .when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.xxl),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (err, _) => ThoughtStateTemplate.filterError(
            onRetry: () => ref.invalidate(thoughtsListProvider),
          ),
          data: (thoughts) {
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

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                childAspectRatio: 0.82,
              ),
              itemCount: thoughts.length,
              itemBuilder: (context, index) {
                final thought = thoughts[index];
                return _MobileThoughtCard(
                  thought: thought,
                  isArchived: isArchived,
                  onThoughtTap: onThoughtTap,
                );
              },
            );
          },
        );
  }
}

// ─── Mobile Thought Card (with long-press context menu) ──────────────

class _MobileThoughtCard extends ConsumerWidget {
  final ThoughtsTableData thought;
  final bool isArchived;
  final void Function(int id) onThoughtTap;

  const _MobileThoughtCard({
    required this.thought,
    required this.isArchived,
    required this.onThoughtTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onLongPress: () => _handleContextMenu(context, ref),
      child: ThoughtCard(
        id: thought.id,
        content: thought.content,
        tags: thought.tags,
        color: thought.color,
        isPinned: thought.isPinned,
        createdAt: thought.createdAt,
        imagePaths: thought.imagePaths,
        onTap: () => onThoughtTap(thought.id),
        onTagTap: (tag) {
          final current = ref.read(selectedTagFiltersProvider);
          ref.read(selectedTagFiltersProvider.notifier).state =
              toggleTagInFilter(current, tag);
        },
      ),
    );
  }

  Future<void> _handleContextMenu(BuildContext context, WidgetRef ref) async {
    final action = await showThoughtContextMenu(
      context: context,
      position: MediaQuery.of(context).size.center(Offset.zero),
      isPinned: thought.isPinned,
      isArchived: isArchived,
    );

    if (action == null || !context.mounted) return;

    switch (action) {
      case ThoughtContextAction.edit:
        _openEditor(context);
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
        if (isArchived) {
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

  void _openEditor(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('打开编辑器'), duration: Duration(seconds: 1)),
    );
  }
}
