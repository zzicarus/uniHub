import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../data/thought_image_service.dart';
import '../../../../core/database/app_database.dart';
import '../widgets/thought_card.dart';
import '../widgets/thought_rich_editor.dart';
import 'thoughts_shared_widgets.dart';

class ThoughtsMobileLayout extends ConsumerWidget {
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

  const ThoughtsMobileLayout({
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
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppMobileSizes.maxContentWidth,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppMobileSizes.pageHorizontalPadding,
            AppSpacing.lg,
            AppMobileSizes.pageHorizontalPadding,
            AppSpacing.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _MobileThoughtsHeader(isArchived: isArchived),
              const SizedBox(height: AppSpacing.xl),
              if (!isArchived) ...[
                _MobileThoughtComposer(
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
                const SizedBox(height: AppSpacing.xl),
              ],
              _MobileThoughtFilters(
                tagStats: tagStats,
                selectedTag: selectedTag,
                isArchived: isArchived,
                onTagFilterChanged: onTagFilterChanged,
              ),
              const SizedBox(height: AppSpacing.lg),
              thoughtsAsync.when(
                loading: () => const ThoughtLoadingState(),
                error: (err, _) => ThoughtErrorState(error: err),
                data: (thoughts) => _MobileThoughtGrid(
                  thoughts: thoughts,
                  isArchived: isArchived,
                  onArchive: onArchive,
                  onRestore: onRestore,
                  onThoughtTap: onThoughtTap,
                  onTagTap: onTagFilterChanged,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileThoughtsHeader extends StatelessWidget {
  final bool isArchived;

  const _MobileThoughtsHeader({required this.isArchived});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              isArchived ? Icons.archive_outlined : Icons.lightbulb_outline,
              size: 44,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                isArchived ? '归档想法' : '想法',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            IconButton(
              onPressed: () => context.go('/search'),
              icon: const Icon(Icons.search_rounded),
            ),
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  onPressed: () {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('通知功能暂未实现')));
                  },
                  icon: const Icon(Icons.notifications_none_rounded),
                ),
                const Positioned(
                  top: 10,
                  right: 10,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: SizedBox(
                      width: AppSpacing.xs,
                      height: AppSpacing.xs,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          isArchived ? '查看已经归档的记录，必要时可恢复。' : '捕捉灵感，整理想法，让每个念头都有价值',
          style: theme.textTheme.bodyLarge,
        ),
      ],
    );
  }
}

class _MobileThoughtComposer extends StatelessWidget {
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

  const _MobileThoughtComposer({
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
    return ThoughtPanel(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const ThoughtIconBubble(
                icon: Icons.lightbulb_outline,
                color: AppColors.primary,
                background: AppColors.primarySoft,
              ),
              const SizedBox(width: AppSpacing.md),
              Text('快速记录想法', style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: Theme.of(context).colorScheme.outline),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: ThoughtRichEditor(
                controller: contentController,
                imageService: imageService,
                minHeight: 92,
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
              height: 62,
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
                          width: 62,
                          height: 62,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: GestureDetector(
                          onTap: () => onRemoveImage(i),
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.xxs),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.54),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              size: 12,
                              color: Theme.of(context).colorScheme.onPrimary,
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
            controller: tagTextController,
            onChanged: onTagInput,
            decoration: const InputDecoration(
              hintText: '添加标签，空格或逗号确认',
              prefixIcon: Icon(Icons.sell_outlined, size: 18),
              isDense: true,
            ),
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ThoughtPillButton(
                icon: Icons.image_outlined,
                label: pendingImages.isNotEmpty
                    ? '图片 (${pendingImages.length})'
                    : '添加图片',
                onTap: onPickImage,
              ),
              ThoughtPillButton(
                icon: isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                label: isPinned ? '已置顶' : '设为置顶',
                selected: isPinned,
                onTap: onTogglePin,
              ),
              FilledButton.icon(
                onPressed: canSubmit && !isSubmitting ? onSubmit : null,
                icon: const Icon(Icons.send_rounded, size: 18),
                label: Text(isSubmitting ? '保存中' : '记录想法'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MobileThoughtFilters extends StatelessWidget {
  final Map<String, int> tagStats;
  final String? selectedTag;
  final bool isArchived;
  final ValueChanged<String?> onTagFilterChanged;

  const _MobileThoughtFilters({
    required this.tagStats,
    required this.selectedTag,
    required this.isArchived,
    required this.onTagFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final total = tagStats.values.fold<int>(0, (sum, count) => sum + count);
    final entries = tagStats.entries.take(4).toList();

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ThoughtFilterChip(
                label: isArchived ? '归档' : '全部',
                value: total > 0 ? total.toString() : '',
                selected: selectedTag == null,
                onTap: () => onTagFilterChanged(null),
              ),
              const SizedBox(width: AppSpacing.sm),
              for (final entry in entries) ...[
                ThoughtFilterChip(
                  label: entry.key,
                  value: entry.value.toString(),
                  selected: selectedTag == entry.key,
                  onTap: () {
                    onTagFilterChanged(
                      selectedTag == entry.key ? null : entry.key,
                    );
                  },
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              if (entries.isEmpty) ...[
                const ThoughtFilterChip(label: '灵感', value: '0'),
                const SizedBox(width: AppSpacing.sm),
                const ThoughtFilterChip(label: '工作', value: '0'),
                const SizedBox(width: AppSpacing.sm),
                const ThoughtFilterChip(label: '生活', value: '0'),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('排序功能暂未实现')));
              },
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              label: const Text('最新'),
            ),
            const Spacer(),
            const ThoughtIconSquare(icon: Icons.grid_view_rounded),
            const SizedBox(width: AppSpacing.sm),
            const ThoughtIconSquare(icon: Icons.format_list_bulleted_rounded),
          ],
        ),
      ],
    );
  }
}

class _MobileThoughtGrid extends StatelessWidget {
  final List<ThoughtsTableData> thoughts;
  final bool isArchived;
  final Future<void> Function(int) onArchive;
  final Future<void> Function(int) onRestore;
  final void Function(int) onThoughtTap;
  final ValueChanged<String> onTagTap;

  const _MobileThoughtGrid({
    required this.thoughts,
    required this.isArchived,
    required this.onArchive,
    required this.onRestore,
    required this.onThoughtTap,
    required this.onTagTap,
  });

  @override
  Widget build(BuildContext context) {
    if (thoughts.isEmpty) {
      return ThoughtEmptyState(isArchived: isArchived, tagFilter: null);
    }

    final pinned = thoughts.where((t) => t.isPinned).toList();
    final regular = isArchived
        ? thoughts
        : thoughts.where((t) => !t.isPinned).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!isArchived && pinned.isNotEmpty) ...[
          ThoughtSectionLabel(
            icon: Icons.push_pin_rounded,
            title: '置顶',
            count: pinned.length,
          ),
          const SizedBox(height: AppSpacing.md),
          _MobileThoughtCardGrid(
            thoughts: pinned,
            isArchived: isArchived,
            onArchive: onArchive,
            onRestore: onRestore,
            onThoughtTap: onThoughtTap,
            onTagTap: onTagTap,
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
        ThoughtSectionLabel(
          icon: isArchived ? Icons.archive_outlined : Icons.grid_view_rounded,
          title: isArchived ? '归档记录' : '全部想法',
          count: regular.length,
        ),
        const SizedBox(height: AppSpacing.md),
        _MobileThoughtCardGrid(
          thoughts: regular,
          isArchived: isArchived,
          onArchive: onArchive,
          onRestore: onRestore,
          onThoughtTap: onThoughtTap,
          onTagTap: onTagTap,
        ),
      ],
    );
  }
}

class _MobileThoughtCardGrid extends StatelessWidget {
  final List<ThoughtsTableData> thoughts;
  final bool isArchived;
  final Future<void> Function(int) onArchive;
  final Future<void> Function(int) onRestore;
  final void Function(int) onThoughtTap;
  final ValueChanged<String> onTagTap;

  const _MobileThoughtCardGrid({
    required this.thoughts,
    required this.isArchived,
    required this.onArchive,
    required this.onRestore,
    required this.onThoughtTap,
    required this.onTagTap,
  });

  @override
  Widget build(BuildContext context) {
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
        return ThoughtCard(
          id: thought.id,
          content: thought.content,
          tags: thought.tags,
          color: thought.color,
          isPinned: thought.isPinned,
          createdAt: thought.createdAt,
          imagePaths: thought.imagePaths,
          onTap: () => onThoughtTap(thought.id),
          onTagTap: onTagTap,
          onArchive: isArchived ? null : () => onArchive(thought.id),
          onRestore: isArchived ? () => onRestore(thought.id) : null,
        );
      },
    );
  }
}
