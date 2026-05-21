import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:uni_hub/src/core/theme/app_tokens.dart';
import 'thought_color_picker.dart';
import 'thought_editor_controller.dart';
import 'thought_editor_image_strip.dart';
import 'package:uni_hub/src/shared/ui/rich_text_editor/rich_text_editor.dart';

class ThoughtEditorDrawer extends ConsumerStatefulWidget {
  final int thoughtId;
  final VoidCallback? onClose;

  const ThoughtEditorDrawer({required this.thoughtId, this.onClose, super.key});

  @override
  ConsumerState<ThoughtEditorDrawer> createState() =>
      _ThoughtEditorDrawerState();
}

class _ThoughtEditorDrawerState extends ConsumerState<ThoughtEditorDrawer> {
  late final ThoughtEditorController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ThoughtEditorController(
      ref: ref,
      thoughtId: widget.thoughtId,
      autoSaveInterval: const Duration(seconds: 2),
      onStateChanged: () {
        if (mounted) setState(() {});
      },
    )..initialize();
    unawaited(_controller.load());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    await _controller.save();
    widget.onClose?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ctrl = _controller;

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
                    ctrl.isArchived ? '编辑想法（已归档）' : '编辑想法',
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
          if (ctrl.images.isNotEmpty || ctrl.isLoaded) ...[
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
    final ctrl = _controller;
    if (!ctrl.isLoaded) return const Center(child: CircularProgressIndicator());

    return DecoratedBox(
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface),
      child: RichTextEditor(
        controller: ctrl.contentController,
        placeholder: '记录你的想法...',
        minHeight: 360,
        expands: true,
        onChanged: (_) => ctrl.markDirty(),
        onPickImage: ctrl.onPickImage,
        onPasteImage: ctrl.onPasteImage,
        onImageAdded: ctrl.onEditorImageAdded,
      ),
    );
  }

  Widget _buildImages(ThemeData theme) {
    final ctrl = _controller;
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
              Text('${ctrl.images.length} 张', style: theme.textTheme.bodySmall),
              const Spacer(),
              TextButton.icon(
                onPressed: () => ctrl.addImage(),
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
            child: ThoughtEditorImageStrip(
              images: ctrl.images,
              onRemove: ctrl.removeImage,
              thumbnailSize: 80,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(ThemeData theme) {
    final ctrl = _controller;
    if (!ctrl.isLoaded) return const SizedBox.shrink();
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
            if (ctrl.tagChips.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Wrap(
                  spacing: AppSpacing.xxs,
                  runSpacing: AppSpacing.xxs,
                  children: ctrl.tagChips
                      .map(
                        (t) => Chip(
                          label: Text(t),
                          labelStyle: const TextStyle(fontSize: 12),
                          deleteIcon: const Icon(Icons.close, size: 14),
                          onDeleted: () => ctrl.removeChip(t),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                      )
                      .toList(),
                ),
              ),
            TextField(
              controller: ctrl.tagTextController,
              onChanged: ctrl.handleTagInput,
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
                  isSelected: ctrl.selectedColor == null,
                  onTap: () => ctrl.setColor(null),
                ),
                ...thoughtAvailableColors(colorScheme).map(
                  (c) => ThoughtColorDot(
                    color: c,
                    isSelected: ctrl.selectedColor == thoughtColorToHex(c),
                    onTap: () => ctrl.setColor(thoughtColorToHex(c)),
                  ),
                ),
              ],
            ),

            // Pin
            if (!ctrl.isArchived)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('置顶'),
                value: ctrl.isPinned,
                onChanged: ctrl.togglePin,
                activeThumbColor: colorScheme.tertiary,
                dense: true,
              ),
            const SizedBox(height: AppSpacing.sm),

            // Actions
            if (ctrl.isArchived)
              OutlinedButton.icon(
                onPressed: () => ctrl.restore(),
                icon: const Icon(Icons.unarchive_outlined, size: 18),
                label: const Text('恢复'),
              )
            else ...[
              OutlinedButton.icon(
                onPressed: () => ctrl.archive(),
                icon: const Icon(Icons.archive_outlined, size: 18),
                label: const Text('归档'),
              ),
              const SizedBox(height: AppSpacing.xs),
              OutlinedButton.icon(
                onPressed: () => ctrl.delete(context),
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('删除'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                  side: BorderSide(
                      color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

