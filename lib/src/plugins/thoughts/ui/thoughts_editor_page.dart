import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_tokens.dart';
import '../data/thought_content_codec.dart';
import '../data/thought_image_service.dart';
import '../providers/thoughts_providers.dart';
import 'widgets/thought_rich_editor.dart';

class ThoughtsEditorPage extends ConsumerStatefulWidget {
  final int thoughtId;

  const ThoughtsEditorPage({required this.thoughtId, super.key});

  @override
  ConsumerState<ThoughtsEditorPage> createState() => _ThoughtsEditorPageState();
}

class _ThoughtsEditorPageState extends ConsumerState<ThoughtsEditorPage> {
  late QuillController _contentController;
  final _tagTextController = TextEditingController();
  final _tagChips = <String>[];
  final _images = <String>[];
  String? _selectedColor;
  bool _isPinned = false;
  bool _isArchived = false;
  bool _isDirty = false;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _contentController = _createController(Document());
    unawaited(_loadThought());
  }

  @override
  void dispose() {
    _contentController.dispose();
    _tagTextController.dispose();
    super.dispose();
  }

  QuillController _createController(Document document) {
    return ThoughtRichEditor.createController(
      document: document,
      onImagePaste: (bytes) async {
        final path = await ref
            .read(thoughtImageServiceProvider)
            .saveImageBytes(bytes);
        if (mounted && !_images.contains(path)) {
          setState(() => _images.add(path));
        }
        _markDirty();
        return ThoughtContentCodec.imageSourceForPath(path);
      },
    );
  }

  void _markDirty() {
    if (!_isDirty) {
      setState(() => _isDirty = true);
    }
  }

  Future<void> _loadThought() async {
    if (_isLoaded) return;
    final thought = await ref.read(thoughtProvider(widget.thoughtId).future);
    if (thought == null || _isLoaded || !mounted) return;
    final controller = _createController(
      ThoughtContentCodec.documentFromStored(thought.content),
    );
    _contentController.dispose();
    setState(() {
      _contentController = controller;
      _tagChips.addAll(
        (thought.tags ?? '')
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty),
      );
      _images.addAll(
        ThoughtContentCodec.mergeImagePaths(
          thought.imagePaths,
          thought.content,
        ),
      );
      _selectedColor = thought.color;
      _isPinned = thought.isPinned;
      _isArchived = thought.archivedAt != null;
      _isLoaded = true;
      _isDirty = false;
    });
  }

  Future<void> _save() async {
    if (!_isDirty) return;
    final repo = ref.read(thoughtsRepositoryProvider);
    final tags = _tagChips.isNotEmpty ? _tagChips.join(',') : null;
    await repo.updateThought(
      widget.thoughtId,
      content: ThoughtContentCodec.encodeDocument(_contentController.document),
      tags: tags,
      color: _selectedColor,
      isPinned: _isPinned,
      imagePaths: ThoughtImageService.encodeImagePaths(_images),
    );
    ref.invalidate(thoughtProvider(widget.thoughtId));
    ref.invalidate(thoughtsListProvider);
    setState(() => _isDirty = false);
  }

  Future<void> _goBack() async {
    await _save();
    if (mounted) {
      context.pop();
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除想法'),
        content: const Text('确定要删除这条想法吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final repo = ref.read(thoughtsRepositoryProvider);
      await ref.read(thoughtImageServiceProvider).deleteImages(_images);
      await repo.deleteThought(widget.thoughtId);
      ref.invalidate(thoughtsListProvider);
      if (mounted) {
        context.pop();
      }
    }
  }

  Future<void> _archive() async {
    final repo = ref.read(thoughtsRepositoryProvider);
    await repo.archiveThought(widget.thoughtId);
    ref.invalidate(thoughtsListProvider);
    if (mounted) {
      context.pop();
    }
  }

  Future<void> _restore() async {
    final repo = ref.read(thoughtsRepositoryProvider);
    await repo.restoreThought(widget.thoughtId);
    ref.invalidate(thoughtsListProvider);
    setState(() {
      _isArchived = false;
      _isDirty = false;
    });
  }

  void _togglePin(bool value) {
    setState(() {
      _isPinned = value;
      _isDirty = true;
    });
  }

  void _handleTagInput(String value) {
    final delimiter = value.contains(',') ? ',' : ' ';
    if (value.endsWith(delimiter)) {
      final tag = value.substring(0, value.length - 1).trim();
      if (tag.isNotEmpty && !_tagChips.contains(tag)) {
        setState(() {
          _tagChips.add(tag);
          _isDirty = true;
        });
      }
      _tagTextController.clear();
    }
  }

  void _removeChip(String tag) {
    setState(() {
      _tagChips.remove(tag);
      _isDirty = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (!_isLoaded) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          unawaited(_goBack());
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: '返回（自动保存）',
            onPressed: _goBack,
          ),
          title: Text(
            _isArchived ? '编辑想法（已归档）' : '编辑想法',
            style: theme.textTheme.titleMedium,
          ),
          actions: [
            if (!_isArchived)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  switch (value) {
                    case 'delete':
                      _delete();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          size: 20,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          '删除',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              // Content editor
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: ThoughtRichEditor(
                    controller: _contentController,
                    imageService: ref.read(thoughtImageServiceProvider),
                    minHeight: 360,
                    placeholder: '记录你的想法...',
                    onChanged: (_) => _markDirty(),
                    onImageAdded: (path) {
                      if (!_images.contains(path)) {
                        setState(() => _images.add(path));
                      }
                    },
                  ),
                ),
              ),

              if (_images.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                _ImageStrip(
                  images: _images,
                  onRemove: (index) async {
                    final path = _images[index];
                    await ref
                        .read(thoughtImageServiceProvider)
                        .deleteImage(path);
                    final updatedDocument = ThoughtContentCodec.removeImage(
                      _contentController.document,
                      path,
                    );
                    _contentController.dispose();
                    _contentController = _createController(updatedDocument);
                    setState(() => _images.removeAt(index));
                    _markDirty();
                  },
                ),
              ],

              const SizedBox(height: AppSpacing.lg),

              // Tags section
              Text('标签', style: theme.textTheme.labelMedium),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.xxs,
                runSpacing: AppSpacing.xxs,
                children: [
                  ..._tagChips.map((tag) {
                    return Chip(
                      label: Text(tag),
                      labelStyle: const TextStyle(fontSize: 12),
                      deleteIcon: const Icon(Icons.close, size: 14),
                      onDeleted: () => _removeChip(tag),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    );
                  }),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              TextField(
                controller: _tagTextController,
                onChanged: _handleTagInput,
                decoration: const InputDecoration(
                  hintText: '添加标签（空格或逗号分隔）',
                  isDense: true,
                ),
                style: theme.textTheme.bodySmall,
              ),

              const SizedBox(height: AppSpacing.lg),

              // Color selector
              Text('颜色', style: theme.textTheme.labelMedium),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _ColorDot(
                    color: null,
                    label: '默认',
                    isSelected: _selectedColor == null,
                    onTap: () {
                      setState(() {
                        _selectedColor = null;
                        _isDirty = true;
                      });
                    },
                  ),
                  ..._availableColors(colorScheme).map((c) {
                    return _ColorDot(
                      color: c,
                      label: null,
                      isSelected: _selectedColor == _colorToHex(c),
                      onTap: () {
                        setState(() {
                          _selectedColor = _colorToHex(c);
                          _isDirty = true;
                        });
                      },
                    );
                  }),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),

              // Pin toggle
              if (!_isArchived)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('置顶'),
                  value: _isPinned,
                  onChanged: _togglePin,
                  activeThumbColor: colorScheme.tertiary,
                  secondary: const Icon(Icons.push_pin_outlined),
                ),

              const Divider(height: AppSpacing.xl),

              // Actions
              if (_isArchived) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _restore,
                    icon: const Icon(Icons.unarchive_outlined, size: 18),
                    label: const Text('恢复'),
                  ),
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _archive,
                    icon: const Icon(Icons.archive_outlined, size: 18),
                    label: const Text('归档'),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _delete,
                    icon: Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    label: Text('删除'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageStrip extends StatelessWidget {
  final List<String> images;
  final Future<void> Function(int index) onRemove;

  const _ImageStrip({required this.images, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 84,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (_, index) {
          final file = File(images[index]);
          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: file.existsSync()
                    ? Image.file(file, width: 84, height: 84, fit: BoxFit.cover)
                    : Container(
                        width: 84,
                        height: 84,
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHigh,
                        child: const Icon(Icons.broken_image_outlined),
                      ),
              ),
              Positioned(
                top: 3,
                right: 3,
                child: GestureDetector(
                  onTap: () => unawaited(onRemove(index)),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.xxs),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant.withValues(alpha: 0.54),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close,
                      size: 14,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  final Color? color;
  final String? label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorDot({
    this.color,
    this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color ?? Theme.of(context).colorScheme.surfaceContainerHigh,
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
            width: isSelected ? 2.5 : 1.5,
          ),
        ),
        child: color == null
            ? Center(
                child: Text(
                  'A',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}

List<Color> _availableColors(ColorScheme colorScheme) => [
  colorScheme.primary,
  colorScheme.secondary,
  colorScheme.tertiary,
  colorScheme.error,
  colorScheme.primaryContainer,
  colorScheme.secondaryContainer,
  colorScheme.tertiaryContainer,
];

String _colorToHex(Color c) {
  return '#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
}
