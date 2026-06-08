import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uni_hub/src/core/theme/app_tokens.dart';
import 'package:uni_hub/src/shared/ui/rich_text_editor/rich_text_editor.dart';

import '../providers/thoughts_providers.dart';
import 'widgets/thought_color_picker.dart';
import 'widgets/thought_editor_controller.dart';
import 'widgets/thought_editor_image_strip.dart';

class ThoughtsEditorPage extends ConsumerStatefulWidget {
  final int thoughtId;

  const ThoughtsEditorPage({required this.thoughtId, super.key});

  @override
  ConsumerState<ThoughtsEditorPage> createState() => _ThoughtsEditorPageState();
}

class _ThoughtsEditorPageState extends ConsumerState<ThoughtsEditorPage> {
  late final ThoughtEditorController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ThoughtEditorController(
      ref: ref,
      thoughtId: widget.thoughtId,
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

  Future<void> _goBack() async {
    await _controller.save();
    if (mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final ctrl = _controller;

    final existingTags = ref.watch(commonTagsProvider);
    final tagInput = ctrl.tagTextController.text.trim().toLowerCase();
    final tagSuggestions = tagInput.isEmpty
        ? const <String>[]
        : existingTags
            .map((e) => e.key)
            .where((tag) =>
                tag.toLowerCase().contains(tagInput) &&
                !ctrl.tagChips.contains(tag))
            .take(5)
            .toList();

    if (!ctrl.isLoaded) {
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
            ctrl.isArchived ? '编辑想法（已归档）' : '编辑想法',
            style: theme.textTheme.titleMedium,
          ),
          actions: [
            if (!ctrl.isArchived)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  switch (value) {
                    case 'delete':
                      unawaited(ctrl.delete(context));
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
                  child: RichTextEditor(
                    controller: ctrl.contentController,
                    minHeight: 360,
                    onChanged: (_) => ctrl.markDirty(),
                    onPickImage: ctrl.onPickImage,
                    onPasteImage: ctrl.onPasteImage,
                    onImageAdded: ctrl.onEditorImageAdded,
                  ),
                ),
              ),

              if (ctrl.images.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  height: 84,
                  child: ThoughtEditorImageStrip(
                    images: ctrl.images,
                    onRemove: ctrl.removeImage,
                    thumbnailSize: 84,
                  ),
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
                  ...ctrl.tagChips.map((tag) {
                    return Chip(
                      label: Text(tag),
                      labelStyle: const TextStyle(fontSize: AppFontTokens.labelMd),
                      deleteIcon: const Icon(Icons.close, size: 14),
                      onDeleted: () => ctrl.removeChip(tag),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    );
                  }),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              TextField(
                controller: ctrl.tagTextController,
                onChanged: ctrl.handleTagInput,
                decoration: InputDecoration(
                  hintText: '添加标签（空格或逗号分隔）',
                  isDense: true,
                  errorText: ctrl.tagErrorMessage,
                  errorStyle: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.error,
                    fontSize: AppFontTokens.mini,
                  ),
                ),
                style: theme.textTheme.bodySmall,
              ),
              if (tagSuggestions.isNotEmpty && ctrl.tagErrorMessage == null)
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
                            ctrl.tagTextController.clear();
                            ctrl.handleTagInput('$tag,');
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

              const SizedBox(height: AppSpacing.lg),

              // Color selector
              Text('颜色', style: theme.textTheme.labelMedium),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  ThoughtColorDot(
                    label: '默认',
                    isSelected: ctrl.selectedColor == null,
                    onTap: () => ctrl.setColor(null),
                  ),
                  ...thoughtAvailableColors(colorScheme).map((c) {
                    return ThoughtColorDot(
                      color: c,
                      isSelected: ctrl.selectedColor == thoughtColorToHex(c),
                      onTap: () => ctrl.setColor(thoughtColorToHex(c)),
                    );
                  }),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),

              // Pin toggle
              if (!ctrl.isArchived)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('置顶'),
                  value: ctrl.isPinned,
                  onChanged: ctrl.togglePin,
                  activeThumbColor: colorScheme.tertiary,
                  secondary: const Icon(Icons.push_pin_outlined),
                ),

              const Divider(height: AppSpacing.xl),

              // Actions
              if (ctrl.isArchived) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: ctrl.restore,
                    icon: const Icon(Icons.unarchive_outlined, size: 18),
                    label: const Text('恢复'),
                  ),
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: ctrl.archive,
                    icon: const Icon(Icons.archive_outlined, size: 18),
                    label: const Text('归档'),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => ctrl.delete(context),
                    icon: Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    label: const Text('删除'),
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
