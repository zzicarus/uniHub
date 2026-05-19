import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_breakpoints.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/database/app_database.dart';
import '../../data/thought_content_codec.dart';
import '../../data/thought_image_service.dart';
import '../widgets/thought_card.dart';
import '../widgets/thought_rich_editor.dart';
import 'thoughts_shared_widgets.dart';

class ThoughtsDesktopLayout extends ConsumerWidget {
  final AsyncValue<List<ThoughtsTableData>> thoughtsAsync;
  final bool isArchived;
  final QuillController contentController;
  final TextEditingController tagTextController;
  final List<String> tagChips;
  final bool isSubmitting;
  final bool canSubmit;
  final bool isPinned;
  final List<String> pendingImages;
  final VoidCallback onSubmit;
  final ValueChanged<String> onTagInput;
  final ValueChanged<String> onRemoveChip;
  final VoidCallback onTogglePin;
  final VoidCallback onPickImage;
  final void Function(int) onRemoveImage;
  final ThoughtImageService imageService;
  final VoidCallback onContentChanged;
  final ValueChanged<String> onImageAdded;
  final void Function(int) onThoughtTap;
  final Future<void> Function(int) onArchive;
  final Future<void> Function(int) onRestore;
  final Map<String, int> tagStats;
  final String? selectedTag;
  final ValueChanged<String?> onTagFilterChanged;

  const ThoughtsDesktopLayout({
    required this.thoughtsAsync,
    required this.isArchived,
    required this.contentController,
    required this.tagTextController,
    required this.tagChips,
    required this.isSubmitting,
    required this.canSubmit,
    required this.isPinned,
    required this.pendingImages,
    required this.onSubmit,
    required this.onTagInput,
    required this.onRemoveChip,
    required this.onTogglePin,
    required this.onPickImage,
    required this.onRemoveImage,
    required this.imageService,
    required this.onContentChanged,
    required this.onImageAdded,
    required this.onThoughtTap,
    required this.onArchive,
    required this.onRestore,
    required this.tagStats,
    required this.selectedTag,
    required this.onTagFilterChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.of(context).size.width;
    final showRightRail = width >= AppBreakpoints.wideMin;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ThoughtsHeader(isArchived: isArchived),
                  const SizedBox(height: AppSpacing.xxl),
                  if (!isArchived) ...[
                    _ThoughtComposer(
                      contentController: contentController,
                      tagTextController: tagTextController,
                      tagChips: tagChips,
                      isSubmitting: isSubmitting,
                      canSubmit: canSubmit,
                      isPinned: isPinned,
                      pendingImages: pendingImages,
                      onSubmit: onSubmit,
                      onTagInput: onTagInput,
                      onRemoveChip: onRemoveChip,
                      onTogglePin: onTogglePin,
                      onPickImage: onPickImage,
                      onRemoveImage: onRemoveImage,
                      imageService: imageService,
                      onContentChanged: onContentChanged,
                      onImageAdded: onImageAdded,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                  _ThoughtsToolbar(
                    tagStats: tagStats,
                    selectedTag: selectedTag,
                    isArchived: isArchived,
                    onTagFilterChanged: onTagFilterChanged,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  thoughtsAsync.when(
                    loading: () => const ThoughtLoadingState(),
                    error: (err, _) => ThoughtErrorState(error: err),
                    data: (thoughts) => _ThoughtsContent(
                      thoughts: thoughts,
                      isArchived: isArchived,
                      selectedTag: selectedTag,
                      onOpen: onThoughtTap,
                      onTagTap: onTagFilterChanged,
                      onArchive: onArchive,
                      onRestore: onRestore,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showRightRail) _ThoughtsRightRail(thoughtsAsync: thoughtsAsync),
      ],
    );
  }
}

class _ThoughtsHeader extends StatelessWidget {
  final bool isArchived;

  const _ThoughtsHeader({required this.isArchived});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          isArchived ? Icons.archive_outlined : Icons.lightbulb_outline,
          size: 36,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isArchived ? '归档想法' : '想法',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                isArchived ? '查看已经归档的记录，必要时可恢复。' : '捕捉灵感，整理想法，让每个念头都有价值',
                style: theme.textTheme.bodyLarge,
              ),
            ],
          ),
        ),
        const ThoughtSearchBox(),
        const SizedBox(width: AppSpacing.md),
        const ThoughtIconSquare(icon: Icons.notifications_none_rounded),
      ],
    );
  }
}

class _ThoughtComposer extends StatelessWidget {
  final QuillController contentController;
  final TextEditingController tagTextController;
  final List<String> tagChips;
  final bool isSubmitting;
  final bool canSubmit;
  final bool isPinned;
  final List<String> pendingImages;
  final VoidCallback onSubmit;
  final ValueChanged<String> onTagInput;
  final ValueChanged<String> onRemoveChip;
  final VoidCallback onTogglePin;
  final VoidCallback onPickImage;
  final void Function(int) onRemoveImage;
  final ThoughtImageService imageService;
  final VoidCallback onContentChanged;
  final ValueChanged<String> onImageAdded;

  const _ThoughtComposer({
    required this.contentController,
    required this.tagTextController,
    required this.tagChips,
    required this.isSubmitting,
    required this.canSubmit,
    required this.isPinned,
    required this.pendingImages,
    required this.onSubmit,
    required this.onTagInput,
    required this.onRemoveChip,
    required this.onTogglePin,
    required this.onPickImage,
    required this.onRemoveImage,
    required this.imageService,
    required this.onContentChanged,
    required this.onImageAdded,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return ThoughtPanel(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ThoughtIconBubble(
            icon: Icons.lightbulb_outline,
            color: colorScheme.onPrimaryContainer,
            background: colorScheme.primaryContainer,
          ),
          const SizedBox(width: AppSpacing.xl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('快速记录想法', style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.md),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: ThoughtRichEditor(
                      controller: contentController,
                      imageService: imageService,
                      minHeight: 112,
                      placeholder: '快速记录你的想法、灵感或闪念...',
                      onChanged: (_) => onContentChanged(),
                      onImageAdded: onImageAdded,
                    ),
                  ),
                ),
                if (tagChips.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: tagChips.map((tag) {
                      return Chip(
                        label: Text(tag),
                        deleteIcon: const Icon(Icons.close, size: 14),
                        onDeleted: () => onRemoveChip(tag),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      );
                    }).toList(),
                  ),
                ],
                if (pendingImages.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    height: 60,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: pendingImages.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(width: AppSpacing.sm),
                      itemBuilder: (_, i) {
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(AppRadius.xs),
                              child: Image.file(
                                File(pendingImages[i]),
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 1,
                              right: 1,
                              child: GestureDetector(
                                onTap: () => onRemoveImage(i),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant
                                        .withValues(alpha: 0.54),
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(AppSpacing.xxs),
                                  child: Icon(
                                    Icons.close,
                                    size: 12,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimary,
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
                Row(
                  children: [
                    SizedBox(
                      width: 160,
                      child: TextField(
                        controller: tagTextController,
                        onChanged: onTagInput,
                        decoration: const InputDecoration(
                          hintText: '添加标签',
                          prefixIcon: Icon(Icons.sell_outlined, size: 18),
                          isDense: true,
                        ),
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    ThoughtPillButton(
                      icon: Icons.image_outlined,
                      label: pendingImages.isNotEmpty
                          ? '图片 (${pendingImages.length})'
                          : '图片',
                      onTap: onPickImage,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    ThoughtPillButton(
                      icon: isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                      label: isPinned ? '已置顶' : '设为置顶',
                      selected: isPinned,
                      onTap: onTogglePin,
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: canSubmit && !isSubmitting ? onSubmit : null,
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: Text(isSubmitting ? '保存中' : '记录想法'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThoughtsToolbar extends StatelessWidget {
  final Map<String, int> tagStats;
  final String? selectedTag;
  final bool isArchived;
  final ValueChanged<String?> onTagFilterChanged;

  const _ThoughtsToolbar({
    required this.tagStats,
    required this.selectedTag,
    required this.isArchived,
    required this.onTagFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sortedTags = tagStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = tagStats.values.fold<int>(0, (sum, count) => sum + count);

    return Row(
      children: [
        ThoughtFilterChip(
          label: '全部',
          value: total.toString(),
          selected: selectedTag == null,
          onTap: () => onTagFilterChanged(null),
        ),
        ...sortedTags.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(left: AppSpacing.sm),
            child: ThoughtFilterChip(
              label: entry.key,
              value: entry.value.toString(),
              selected: selectedTag == entry.key,
              onTap: () => onTagFilterChanged(
                selectedTag == entry.key ? null : entry.key,
              ),
            ),
          );
        }),
        if (selectedTag != null && selectedTag!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.sm),
            child: Chip(
              label: Text('#$selectedTag'),
              deleteIcon: const Icon(Icons.close, size: 14),
              onDeleted: () => onTagFilterChanged(null),
              backgroundColor: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.12),
              side: BorderSide.none,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
        const Spacer(),
        Container(
          height: AppDesktopSizes.compactButtonHeight,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: Theme.of(context).colorScheme.outline),
          ),
          child: Row(
            children: [
              Text(
                isArchived ? '归档' : '最新',
                style: theme.textTheme.labelMedium,
              ),
              const SizedBox(width: AppSpacing.xs),
              const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
            ],
          ),
        ),
      ],
    );
  }
}

class _ThoughtsContent extends StatelessWidget {
  final List<ThoughtsTableData> thoughts;
  final bool isArchived;
  final String? selectedTag;
  final void Function(int) onOpen;
  final ValueChanged<String> onTagTap;
  final Future<void> Function(int)? onArchive;
  final Future<void> Function(int)? onRestore;

  const _ThoughtsContent({
    required this.thoughts,
    required this.isArchived,
    required this.selectedTag,
    required this.onOpen,
    required this.onTagTap,
    this.onArchive,
    this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    if (thoughts.isEmpty) {
      return ThoughtEmptyState(isArchived: isArchived, tagFilter: selectedTag);
    }

    final pinned = thoughts.where((t) => t.isPinned).toList();
    final unpinned = thoughts.where((t) => !t.isPinned).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!isArchived && pinned.isNotEmpty) ...[
          ThoughtSectionLabel(
            icon: Icons.push_pin_rounded,
            title: '置顶想法',
            count: pinned.length,
          ),
          const SizedBox(height: AppSpacing.md),
          _ThoughtGrid(
            thoughts: pinned,
            onOpen: onOpen,
            onTagTap: onTagTap,
            onArchive: isArchived ? null : onArchive,
            onRestore: isArchived ? onRestore : null,
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
        ThoughtSectionLabel(
          icon: isArchived ? Icons.archive_outlined : Icons.grid_view_rounded,
          title: isArchived ? '归档记录' : '全部想法',
          count: unpinned.length,
        ),
        const SizedBox(height: AppSpacing.md),
        _ThoughtGrid(
          thoughts: isArchived ? thoughts : unpinned,
          onOpen: onOpen,
          onTagTap: onTagTap,
          onArchive: isArchived ? null : onArchive,
          onRestore: isArchived ? onRestore : null,
        ),
      ],
    );
  }
}

class _ThoughtGrid extends StatelessWidget {
  final List<ThoughtsTableData> thoughts;
  final void Function(int) onOpen;
  final ValueChanged<String> onTagTap;
  final Future<void> Function(int)? onArchive;
  final Future<void> Function(int)? onRestore;

  const _ThoughtGrid({
    required this.thoughts,
    required this.onOpen,
    required this.onTagTap,
    this.onArchive,
    this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 760 ? 3 : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: columns == 1 ? 3.2 : 1.25,
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
              onArchive: onArchive != null ? () => onArchive!(t.id) : null,
              onRestore: onRestore != null ? () => onRestore!(t.id) : null,
            );
          },
        );
      },
    );
  }
}

class _ThoughtsRightRail extends StatelessWidget {
  final AsyncValue<List<ThoughtsTableData>> thoughtsAsync;

  const _ThoughtsRightRail({required this.thoughtsAsync});

  @override
  Widget build(BuildContext context) {
    final thoughts = thoughtsAsync.valueOrNull ?? const <ThoughtsTableData>[];
    final pinned = thoughts.where((t) => t.isPinned).take(5).toList();
    final tags = <String, int>{};
    for (final thought in thoughts) {
      for (final tag in _parseTags(thought.tags)) {
        tags[tag] = (tags[tag] ?? 0) + 1;
      }
    }
    final tagEntries = tags.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      width: AppDesktopSizes.rightRailWideWidth,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        border: Border(
          left: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            _PinnedThoughtsPanel(thoughts: pinned),
            const SizedBox(height: AppSpacing.xl),
            _StatsPanel(total: thoughts.length, pinned: pinned.length),
            const SizedBox(height: AppSpacing.xl),
            _TagsPanel(tags: tagEntries.take(10).toList()),
          ],
        ),
      ),
    );
  }
}

class _PinnedThoughtsPanel extends StatelessWidget {
  final List<ThoughtsTableData> thoughts;

  const _PinnedThoughtsPanel({required this.thoughts});

  @override
  Widget build(BuildContext context) {
    return ThoughtPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ThoughtPanelHeader(
            title: '置顶想法',
            count: thoughts.length,
            icon: Icons.star_rounded,
          ),
          const SizedBox(height: AppSpacing.md),
          if (thoughts.isEmpty)
            const ThoughtSmallMutedText('暂无置顶想法')
          else
            ...thoughts.map(
              (t) => ThoughtCompactItem(
                title: ThoughtContentCodec.titleFromStored(t.content),
                subtitle: _formatTimestamp(t.createdAt),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatsPanel extends StatelessWidget {
  final int total;
  final int pinned;

  const _StatsPanel({required this.total, required this.pinned});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ThoughtPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ThoughtPanelHeader(
            title: '想法统计',
            icon: Icons.bar_chart_rounded,
          ),
          const SizedBox(height: AppSpacing.md),
          ThoughtStatRow(
            icon: Icons.lightbulb_outline,
            label: '总想法',
            value: total.toString(),
            color: colorScheme.primary,
            background: colorScheme.primaryContainer,
          ),
          ThoughtStatRow(
            icon: Icons.add_circle_outline_rounded,
            label: '本页展示',
            value: total.toString(),
            color: colorScheme.secondary,
            background: colorScheme.secondaryContainer,
          ),
          ThoughtStatRow(
            icon: Icons.star_outline_rounded,
            label: '置顶数量',
            value: pinned.toString(),
            color: colorScheme.tertiary,
            background: colorScheme.tertiaryContainer,
          ),
        ],
      ),
    );
  }
}

class _TagsPanel extends StatelessWidget {
  final List<MapEntry<String, int>> tags;

  const _TagsPanel({required this.tags});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ThoughtPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ThoughtPanelHeader(title: '热门标签', icon: Icons.sell_outlined),
          const SizedBox(height: AppSpacing.md),
          if (tags.isEmpty)
            const ThoughtSmallMutedText('暂无标签')
          else
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: tags.map((entry) {
                return Chip(
                  label: Text('${entry.key}  ${entry.value}'),
                  backgroundColor: colorScheme.primaryContainer,
                  side: BorderSide.none,
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

List<String> _parseTags(String? tags) {
  return (tags ?? '')
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
}

String _formatTimestamp(DateTime dt) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final date = DateTime(dt.year, dt.month, dt.day);

  if (date == today) {
    return '今天 ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  } else if (date == yesterday) {
    return '昨天 ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  } else if (dt.year == now.year) {
    return '${dt.month}月${dt.day}日';
  }
  return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}
