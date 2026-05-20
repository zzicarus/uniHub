import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:uni_hub/src/core/theme/app_tokens.dart';
import '../../data/thought_content_codec.dart';
import '../../data/thought_image_service.dart';
import '../../providers/thoughts_providers.dart';
import 'thought_color_picker.dart';
import 'thought_rich_editor.dart';

class ThoughtEditorDrawer extends ConsumerStatefulWidget {
  final int thoughtId;
  final VoidCallback? onClose;

  const ThoughtEditorDrawer({required this.thoughtId, this.onClose, super.key});

  @override
  ConsumerState<ThoughtEditorDrawer> createState() =>
      _ThoughtEditorDrawerState();
}

class _ThoughtEditorDrawerState extends ConsumerState<ThoughtEditorDrawer> {
  late QuillController _contentCtrl;
  final _tagCtrl = TextEditingController();
  final _tagChips = <String>[];
  String? _color;
  bool _pinned = false;
  bool _archived = false;
  bool _loaded = false;
  bool _dirty = false;
  List<String> _images = [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _contentCtrl = _createController(Document());
    unawaited(_load());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _contentCtrl.dispose();
    _tagCtrl.dispose();
    super.dispose();
  }

  QuillController _createController(Document document) {
    return ThoughtRichEditor.createController(
      document: document,
      onImagePaste: (bytes) async {
        final path = await ref
            .read(thoughtImageServiceProvider)
            .saveImageBytes(bytes);
        if (mounted) {
          setState(() => _images = {..._images, path}.toList());
        }
        _markDirty();
        return ThoughtContentCodec.imageSourceForPath(path);
      },
    );
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 2), _save);
  }

  Future<void> _load() async {
    if (_loaded) return;
    final t = await ref.read(thoughtProvider(widget.thoughtId).future);
    if (t == null || _loaded || !mounted) return;
    final controller = _createController(
      ThoughtContentCodec.documentFromStored(t.content),
    );
    _contentCtrl.dispose();
    setState(() {
      _contentCtrl = controller;
      _tagChips.addAll(
        (t.tags ?? '')
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty),
      );
      _color = t.color;
      _pinned = t.isPinned;
      _archived = t.archivedAt != null;
      _images = ThoughtContentCodec.mergeImagePaths(t.imagePaths, t.content);
      _loaded = true;
      _dirty = false;
    });
  }

  Future<void> _save() async {
    if (!_dirty || !_loaded) return;
    await ref
        .read(thoughtsRepositoryProvider)
        .updateThought(
          widget.thoughtId,
          content: ThoughtContentCodec.encodeDocument(_contentCtrl.document),
          tags: _tagChips.isNotEmpty ? _tagChips.join(',') : null,
          color: _color,
          isPinned: _pinned,
          imagePaths: ThoughtImageService.encodeImagePaths(_images),
        );
    ref.invalidate(thoughtProvider(widget.thoughtId));
    ref.invalidate(thoughtsListProvider);
    if (mounted) setState(() => _dirty = false);
  }

  Future<void> _close() async {
    await _save();
    widget.onClose?.call();
  }

  Future<void> _addImage() async {
    final svc = ref.read(thoughtImageServiceProvider);
    final path = await svc.pickImage();
    if (path != null) {
      setState(() => _images.add(path));
      _insertImage(path);
      _markDirty();
    }
  }

  void _insertImage(String path) {
    final index = _contentCtrl.selection.baseOffset;
    final length = _contentCtrl.selection.extentOffset - index;
    final safeIndex = index < 0 ? _contentCtrl.document.length - 1 : index;
    _contentCtrl
      ..skipRequestKeyboard = true
      ..replaceText(
        safeIndex,
        length < 0 ? 0 : length,
        BlockEmbed.image(ThoughtContentCodec.imageSourceForPath(path)),
        null,
      )
      ..moveCursorToPosition(safeIndex + 1);
  }

  Future<void> _removeImage(int i) async {
    final path = _images[i];
    await ref.read(thoughtImageServiceProvider).deleteImage(path);
    final updatedDocument = ThoughtContentCodec.removeImage(
      _contentCtrl.document,
      path,
    );
    _contentCtrl.dispose();
    _contentCtrl = _createController(updatedDocument);
    setState(() => _images.removeAt(i));
    _markDirty();
  }

  Future<void> _archive() async {
    await ref.read(thoughtsRepositoryProvider).archiveThought(widget.thoughtId);
    ref.invalidate(thoughtsListProvider);
    widget.onClose?.call();
  }

  Future<void> _restore() async {
    await ref.read(thoughtsRepositoryProvider).restoreThought(widget.thoughtId);
    ref.invalidate(thoughtsListProvider);
    if (mounted) setState(() => _archived = false);
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('删除想法'),
        content: const Text('确定要删除吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(c).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(thoughtImageServiceProvider).deleteImages(_images);
    await ref.read(thoughtsRepositoryProvider).deleteThought(widget.thoughtId);
    ref.invalidate(thoughtsListProvider);
    widget.onClose?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _archived ? '编辑想法（已归档）' : '编辑想法',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: '关闭（自动保存）',
                  onPressed: _close,
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Content area
          Expanded(child: _buildContent(theme)),

          // Images
          if (_images.isNotEmpty || _loaded) ...[
            const Divider(height: 1),
            _buildImages(theme),
          ],

          // Footer
          const Divider(height: 1),
          _buildFooter(theme),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (!_loaded) return const Center(child: CircularProgressIndicator());

    return DecoratedBox(
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface),
      child: ThoughtRichEditor(
        controller: _contentCtrl,
        imageService: ref.read(thoughtImageServiceProvider),
        placeholder: '记录你的想法...',
        minHeight: 360,
        expands: true,
        onChanged: (_) => _markDirty(),
        onImageAdded: (path) {
          if (!_images.contains(path)) {
            setState(() => _images.add(path));
          }
        },
      ),
    );
  }

  Widget _buildImages(ThemeData theme) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 100),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('图片', style: theme.textTheme.labelMedium),
              const SizedBox(width: AppSpacing.sm),
              Text('${_images.length} 张', style: theme.textTheme.bodySmall),
              const Spacer(),
              TextButton.icon(
                onPressed: _addImage,
                icon: const Icon(Icons.add_photo_alternate_outlined, size: 16),
                label: const Text('添加'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _images.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (_, i) {
                final f = File(_images[i]);
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: f.existsSync()
                          ? Image.file(
                              f,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: 80,
                              height: 80,
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHigh,
                              child: const Icon(Icons.broken_image_outlined),
                            ),
                    ),
                    Positioned(
                      top: 2,
                      right: 2,
                      child: GestureDetector(
                        onTap: () => _removeImage(i),
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
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(ThemeData theme) {
    if (!_loaded) return const SizedBox.shrink();
    final colorScheme = theme.colorScheme;

    return Container(
      constraints: const BoxConstraints(maxHeight: 260),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tags
            Text('标签', style: theme.textTheme.labelMedium),
            const SizedBox(height: AppSpacing.xs),
            if (_tagChips.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Wrap(
                  spacing: AppSpacing.xxs,
                  runSpacing: AppSpacing.xxs,
                  children: _tagChips
                      .map(
                        (t) => Chip(
                          label: Text(t),
                          labelStyle: const TextStyle(fontSize: 12),
                          deleteIcon: const Icon(Icons.close, size: 14),
                          onDeleted: () {
                            setState(() => _tagChips.remove(t));
                            _markDirty();
                          },
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                      )
                      .toList(),
                ),
              ),
            TextField(
              controller: _tagCtrl,
              onChanged: (v) {
                final d = v.contains(',') ? ',' : ' ';
                if (!v.endsWith(d)) return;
                final tag = v.substring(0, v.length - 1).trim();
                if (tag.isNotEmpty && !_tagChips.contains(tag)) {
                  setState(() => _tagChips.add(tag));
                  _markDirty();
                }
                _tagCtrl.clear();
              },
              decoration: const InputDecoration(
                hintText: '添加标签（空格/逗号分隔）',
                isDense: true,
              ),
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),

            // Color
            Text('颜色', style: theme.textTheme.labelMedium),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                ThoughtColorDot(
                  color: null,
                  label: '默认',
                  isSelected: _color == null,
                  onTap: () {
                    setState(() => _color = null);
                    _markDirty();
                  },
                ),
                ...thoughtAvailableColors(colorScheme).map(
                  (c) => ThoughtColorDot(
                    color: c,
                    isSelected: _color == thoughtColorToHex(c),
                    onTap: () {
                      setState(() => _color = thoughtColorToHex(c));
                      _markDirty();
                    },
                  ),
                ),
              ],
            ),

            // Pin
            if (!_archived)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('置顶'),
                value: _pinned,
                onChanged: (v) {
                  setState(() => _pinned = v);
                  _markDirty();
                },
                activeThumbColor: colorScheme.tertiary,
                dense: true,
              ),
            const SizedBox(height: AppSpacing.sm),

            // Actions
            if (_archived)
              OutlinedButton.icon(
                onPressed: _restore,
                icon: const Icon(Icons.unarchive_outlined, size: 18),
                label: const Text('恢复'),
              )
            else ...[
              OutlinedButton.icon(
                onPressed: _archive,
                icon: const Icon(Icons.archive_outlined, size: 18),
                label: const Text('归档'),
              ),
              const SizedBox(height: AppSpacing.xs),
              OutlinedButton.icon(
                onPressed: _delete,
                icon: Icon(Icons.delete_outline, size: 18),
                label: Text('删除'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                  side: BorderSide(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

