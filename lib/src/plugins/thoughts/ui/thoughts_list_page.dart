import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_tokens.dart';
import '../data/thought_content_codec.dart';
import '../data/thought_image_service.dart';
import '../providers/thoughts_providers.dart';
import 'widgets/thought_card.dart';
import 'widgets/thought_editor_drawer.dart';
import 'widgets/thought_rich_editor.dart';

class ThoughtsListPage extends ConsumerStatefulWidget {
  const ThoughtsListPage({super.key});

  @override
  ConsumerState<ThoughtsListPage> createState() => _ThoughtsListPageState();
}

class _ThoughtsListPageState extends ConsumerState<ThoughtsListPage> {
  late QuillController _contentController;
  final _tagTextController = TextEditingController();
  final _tagChips = <String>[];
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isSubmitting = false;
  bool _hasContent = false;
  bool _isPinned = false;
  int? _selectedThoughtId;
  final _pendingImages = <String>[];

  @override
  void initState() {
    super.initState();
    _contentController = _createContentController();
  }

  @override
  void dispose() {
    _contentController.dispose();
    _tagTextController.dispose();
    super.dispose();
  }

  QuillController _createContentController() {
    return ThoughtRichEditor.createController(
      document: Document(),
      onImagePaste: (bytes) async {
        final path = await ref
            .read(thoughtImageServiceProvider)
            .saveImageBytes(bytes);
        if (mounted) {
          setState(() => _pendingImages.add(path));
        }
        return ThoughtContentCodec.imageSourceForPath(path);
      },
    );
  }

  void _syncContentState() {
    final encoded = ThoughtContentCodec.encodeDocument(
      _contentController.document,
    );
    final hasContent =
        _contentController.document.toPlainText().trim().isNotEmpty ||
        ThoughtContentCodec.imagePathsFromStored(encoded).isNotEmpty;
    if (hasContent != _hasContent) {
      setState(() => _hasContent = hasContent);
    }
  }

  void _handleTagInput(String value) {
    if (value.isEmpty) return;
    final shouldCommit = value.endsWith(',') || value.endsWith(' ');
    if (!shouldCommit) return;

    final candidates = value
        .split(RegExp('[, ]+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty);

    setState(() {
      for (final tag in candidates) {
        if (!_tagChips.contains(tag)) {
          _tagChips.add(tag);
        }
      }
    });
    _tagTextController.clear();
  }

  void _removeChip(String tag) {
    setState(() {
      _tagChips.remove(tag);
    });
  }

  Future<void> _pickImageForComposer() async {
    final svc = ref.read(thoughtImageServiceProvider);
    final path = await svc.pickImage();
    if (path != null) {
      setState(() => _pendingImages.add(path));
      _insertImage(_contentController, path);
    }
  }

  void _removePendingImage(int index) {
    final path = _pendingImages[index];
    ref.read(thoughtImageServiceProvider).deleteImage(path);
    final updatedDocument = ThoughtContentCodec.removeImage(
      _contentController.document,
      path,
    );
    _contentController.dispose();
    _contentController = _createContentController();
    _contentController.document = updatedDocument;
    setState(() => _pendingImages.removeAt(index));
    _syncContentState();
  }

  Future<void> _submit() async {
    final content = ThoughtContentCodec.encodeDocument(
      _contentController.document,
    );
    final hasContent =
        _contentController.document.toPlainText().trim().isNotEmpty ||
        ThoughtContentCodec.imagePathsFromStored(content).isNotEmpty;
    if (!hasContent || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      final repo = ref.read(thoughtsRepositoryProvider);
      final tags = _tagChips.isNotEmpty ? _tagChips.join(',') : null;
      await repo.createThought(
        content: content,
        tags: tags,
        isPinned: _isPinned,
        imagePaths: ThoughtImageService.encodeImagePaths(
          ThoughtContentCodec.mergeImagePaths(
            ThoughtImageService.encodeImagePaths(_pendingImages),
            content,
          ),
        ),
      );
      ref.invalidate(thoughtsListProvider);
      _contentController.dispose();
      _contentController = _createContentController();
      if (mounted) {
        setState(() {
          _tagChips.clear();
          _hasContent = false;
          _isPinned = false;
          _pendingImages.clear();
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _insertImage(QuillController controller, String path) {
    final index = controller.selection.baseOffset;
    final length = controller.selection.extentOffset - index;
    final safeIndex = index < 0 ? controller.document.length - 1 : index;
    controller
      ..skipRequestKeyboard = true
      ..replaceText(
        safeIndex,
        length < 0 ? 0 : length,
        BlockEmbed.image(ThoughtContentCodec.imageSourceForPath(path)),
        null,
      )
      ..moveCursorToPosition(safeIndex + 1);
    _syncContentState();
  }

  void _openEditor(int id) {
    setState(() => _selectedThoughtId = id);
    _scaffoldKey.currentState?.openEndDrawer();
  }

  Future<void> _quickArchive(int id) async {
    final repo = ref.read(thoughtsRepositoryProvider);
    await repo.archiveThought(id);
    ref.invalidate(thoughtsListProvider);
  }

  Future<void> _quickRestore(int id) async {
    final repo = ref.read(thoughtsRepositoryProvider);
    await repo.restoreThought(id);
    ref.invalidate(thoughtsListProvider);
  }

  @override
  Widget build(BuildContext context) {
    final thoughtsAsync = ref.watch(thoughtsListProvider);
    final isArchived = ref.watch(archiveFilterProvider);

    return Focus(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.enter &&
            HardwareKeyboard.instance.isControlPressed) {
          _submit();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppColors.background,
        endDrawer: _selectedThoughtId != null
            ? Drawer(
                width: MediaQuery.of(context).size.width * 0.55,
                child: ThoughtEditorDrawer(thoughtId: _selectedThoughtId!),
              )
            : null,
        onEndDrawerChanged: (opened) {
          if (!opened && mounted) {
            setState(() => _selectedThoughtId = null);
          }
        },
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final showRightRail = constraints.maxWidth >= 1120;
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
                                contentController: _contentController,
                                tagTextController: _tagTextController,
                                tagChips: _tagChips,
                                isSubmitting: _isSubmitting,
                                canSubmit: _hasContent,
                                isPinned: _isPinned,
                                pendingImages: _pendingImages,
                                onSubmit: _submit,
                                onTagInput: _handleTagInput,
                                onRemoveChip: _removeChip,
                                onTogglePin: () =>
                                    setState(() => _isPinned = !_isPinned),
                                onPickImage: _pickImageForComposer,
                                onRemoveImage: _removePendingImage,
                                imageService: ref.read(
                                  thoughtImageServiceProvider,
                                ),
                                onContentChanged: _syncContentState,
                                onImageAdded: (path) {
                                  if (!_pendingImages.contains(path)) {
                                    setState(() => _pendingImages.add(path));
                                  }
                                },
                              ),
                              const SizedBox(height: AppSpacing.xxl),
                            ],
                            _ThoughtsToolbar(isArchived: isArchived),
                            const SizedBox(height: AppSpacing.lg),
                            thoughtsAsync.when(
                              loading: () => const _LoadingState(),
                              error: (err, _) => _ErrorState(error: err),
                              data: (thoughts) => _ThoughtsContent(
                                thoughts: thoughts,
                                isArchived: isArchived,
                                onOpen: _openEditor,
                                onTagTap: (tag) =>
                                    ref.read(tagFilterProvider.notifier).state =
                                        tag,
                                onArchive: _quickArchive,
                                onRestore: _quickRestore,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (showRightRail)
                    _ThoughtsRightRail(thoughtsAsync: thoughtsAsync),
                ],
              );
            },
          ),
        ),
      ),
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
          color: AppColors.textPrimary,
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
        const _SearchBox(),
        const SizedBox(width: AppSpacing.md),
        const _IconSquare(icon: Icons.notifications_none_rounded),
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
  final Future<void> Function() onSubmit;
  final ValueChanged<String> onTagInput;
  final ValueChanged<String> onRemoveChip;
  final VoidCallback? onTogglePin;
  final VoidCallback? onPickImage;
  final void Function(int index)? onRemoveImage;
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
    required this.imageService,
    required this.onContentChanged,
    required this.onImageAdded,
    this.onTogglePin,
    this.onPickImage,
    this.onRemoveImage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _Panel(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _IconBubble(
            icon: Icons.lightbulb_outline,
            color: AppColors.primary,
            background: AppColors.primarySoft,
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
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.border),
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
                                onTap: () => onRemoveImage?.call(i),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(2),
                                  child: const Icon(
                                    Icons.close,
                                    size: 12,
                                    color: Colors.white,
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
                    _PillButton(
                      icon: Icons.image_outlined,
                      label: pendingImages.isNotEmpty
                          ? '图片 (${pendingImages.length})'
                          : '图片',
                      onTap: onPickImage,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _PillButton(
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

class _ThoughtsToolbar extends ConsumerWidget {
  final bool isArchived;

  const _ThoughtsToolbar({required this.isArchived});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tagFilter = ref.watch(tagFilterProvider);
    final tagStats = ref.watch(tagStatsProvider);
    final allThoughtsAsync = ref.watch(allThoughtsProvider);
    final totalThoughts = allThoughtsAsync.valueOrNull?.length ?? 0;

    final sortedTags = tagStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Row(
      children: [
        _FilterChip(
          label: '全部',
          value: totalThoughts.toString(),
          selected: tagFilter == null,
          onTap: () => ref.read(tagFilterProvider.notifier).state = null,
        ),
        ...sortedTags.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(left: AppSpacing.sm),
            child: _FilterChip(
              label: entry.key,
              value: entry.value.toString(),
              selected: tagFilter == entry.key,
              onTap: () =>
                  ref.read(tagFilterProvider.notifier).state = entry.key,
            ),
          );
        }),
        if (tagFilter != null && tagFilter.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.sm),
            child: Chip(
              label: Text('#$tagFilter'),
              deleteIcon: const Icon(Icons.close, size: 14),
              onDeleted: () =>
                  ref.read(tagFilterProvider.notifier).state = null,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
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
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: AppColors.border),
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

class _ThoughtsContent extends ConsumerWidget {
  final List<ThoughtsTableData> thoughts;
  final bool isArchived;
  final ValueChanged<int> onOpen;
  final ValueChanged<String> onTagTap;
  final Future<void> Function(int id)? onArchive;
  final Future<void> Function(int id)? onRestore;

  const _ThoughtsContent({
    required this.thoughts,
    required this.isArchived,
    required this.onOpen,
    required this.onTagTap,
    this.onArchive,
    this.onRestore,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagFilter = ref.watch(tagFilterProvider);
    if (thoughts.isEmpty) {
      return _EmptyState(isArchived: isArchived, tagFilter: tagFilter);
    }

    final pinned = thoughts.where((t) => t.isPinned).toList();
    final unpinned = thoughts.where((t) => !t.isPinned).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!isArchived && pinned.isNotEmpty) ...[
          _SectionLabel(
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
        _SectionLabel(
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
  final ValueChanged<int> onOpen;
  final ValueChanged<String> onTagTap;
  final Future<void> Function(int id)? onArchive;
  final Future<void> Function(int id)? onRestore;

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
      decoration: const BoxDecoration(
        color: AppColors.surfaceElevated,
        border: Border(left: BorderSide(color: AppColors.borderSoft)),
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
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelHeader(
            title: '置顶想法',
            count: thoughts.length,
            icon: Icons.star_rounded,
          ),
          const SizedBox(height: AppSpacing.md),
          if (thoughts.isEmpty)
            const _SmallMutedText('暂无置顶想法')
          else
            ...thoughts.map(
              (t) => _CompactThoughtItem(
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
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelHeader(title: '想法统计', icon: Icons.bar_chart_rounded),
          const SizedBox(height: AppSpacing.md),
          _StatRow(
            icon: Icons.lightbulb_outline,
            label: '总想法',
            value: total.toString(),
            color: AppColors.primary,
            background: AppColors.blueSoft,
          ),
          _StatRow(
            icon: Icons.add_circle_outline_rounded,
            label: '本页展示',
            value: total.toString(),
            color: AppColors.success,
            background: AppColors.greenSoft,
          ),
          _StatRow(
            icon: Icons.star_outline_rounded,
            label: '置顶数量',
            value: pinned.toString(),
            color: AppColors.warning,
            background: AppColors.yellowSoft,
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
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelHeader(title: '热门标签', icon: Icons.sell_outlined),
          const SizedBox(height: AppSpacing.md),
          if (tags.isEmpty)
            const _SmallMutedText('暂无标签')
          else
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: tags.map((entry) {
                return Chip(
                  label: Text('${entry.key}  ${entry.value}'),
                  backgroundColor: AppColors.primarySoft,
                  side: BorderSide.none,
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _Panel({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _IconBubble extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color background;

  const _IconBubble({
    required this.icon,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Icon(icon, color: color, size: 28),
    );
  }
}

class _PillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool selected;

  const _PillButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: AppDesktopSizes.compactButtonHeight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          color: selected ? AppColors.yellowSoft : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: selected ? AppColors.warning : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? AppColors.warning : AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: selected ? AppColors.warning : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 260,
      height: AppSizes.inputHeight,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: AppColors.textTertiary),
          const SizedBox(width: AppSpacing.xs),
          Text('Ctrl + K 全局搜索', style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _IconSquare extends StatelessWidget {
  final IconData icon;

  const _IconSquare({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSizes.inputHeight,
      height: AppSizes.inputHeight,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Icon(icon),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final VoidCallback? onTap;

  const _FilterChip({
    required this.label,
    required this.value,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: AppDesktopSizes.compactButtonHeight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              value,
              style: theme.textTheme.labelMedium?.copyWith(
                color: selected ? Colors.white70 : AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String title;
  final int count;

  const _SectionLabel({
    required this.icon,
    required this.title,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: AppSpacing.xs),
        Text(title, style: theme.textTheme.titleMedium),
        const SizedBox(width: AppSpacing.xs),
        Chip(
          label: Text(count.toString()),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          side: BorderSide.none,
          backgroundColor: AppColors.surfaceMuted,
        ),
      ],
    );
  }
}

class _PanelHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final int? count;

  const _PanelHeader({required this.title, required this.icon, this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textPrimary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
        if (count != null)
          Chip(
            label: Text(count.toString()),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            side: BorderSide.none,
          ),
      ],
    );
  }
}

class _CompactThoughtItem extends StatelessWidget {
  final String title;
  final String subtitle;

  const _CompactThoughtItem({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          const _IconBubble(
            icon: Icons.lightbulb_outline,
            color: AppColors.warning,
            background: AppColors.yellowSoft,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Icon(Icons.star_rounded, color: AppColors.warning, size: 18),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color background;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          _IconBubble(icon: icon, color: color, background: background),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallMutedText extends StatelessWidget {
  final String text;

  const _SmallMutedText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.bodySmall);
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const _Panel(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xxl),
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final Object error;

  const _ErrorState({required this.error});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Text(
          '加载失败: $error',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isArchived;
  final String? tagFilter;

  const _EmptyState({required this.isArchived, required this.tagFilter});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _Panel(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          children: [
            Icon(
              isArchived ? Icons.archive_outlined : Icons.lightbulb_outline,
              size: 54,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              tagFilter != null
                  ? '没有匹配 "#$tagFilter" 的想法'
                  : isArchived
                  ? '归档里还没有想法'
                  : '还没有想法',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              isArchived ? '归档后的想法会在这里显示。' : '用上方输入框记录第一个想法。',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
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
