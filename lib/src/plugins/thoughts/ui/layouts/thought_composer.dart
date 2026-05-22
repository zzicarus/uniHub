import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:uni_hub/src/core/theme/app_tokens.dart';
import 'package:uni_hub/src/shared/ui/rich_text_editor/rich_text_editor.dart';
import '../widgets/thought_composer_controller.dart';
import 'thoughts_shared_widgets.dart';

/// Lightweight composer for quick thought entry.
///
/// Uses [ThoughtComposerController] via [composerProvider].
/// Constrained to max 1080px width with a 96-120px input area.
class ThoughtComposer extends ConsumerWidget {
  const ThoughtComposer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final composer = ref.watch(composerProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1080),
      child: ThoughtPanel(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Rich text input area (96-120px height)
            DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: RichTextEditor(
                  controller: composer.contentController,
                  minHeight: 96,
                  placeholder: '今天有什么新想法？',
                  onChanged: (_) => composer.syncContentState(),
                  onPickImage: composer.onPickEditorImage,
                  onPasteImage: composer.onPasteImage,
                  onImageAdded: composer.onEditorImageAdded,
                ),
              ),
            ),

            // Tag chips
            if (composer.tagChips.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
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

            // Pending images strip
            if (composer.pendingImagePaths.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: 56,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: composer.pendingImagePaths.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: AppSpacing.xs),
                  itemBuilder: (_, i) {
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.xs),
                          child: Image.file(
                            File(composer.pendingImagePaths[i]),
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 1,
                          right: 1,
                          child: GestureDetector(
                            onTap: () => composer.removePendingImage(i),
                            child: Container(
                              decoration: BoxDecoration(
                                color: colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.54),
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(AppSpacing.xxs),
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

            const SizedBox(height: AppSpacing.sm),

            // Action row
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Tag input
                SizedBox(
                  width: 140,
                  child: TextField(
                    controller: composer.tagTextController,
                    onChanged: composer.handleTagInput,
                    decoration: const InputDecoration(
                      hintText: '添加标签',
                      prefixIcon: Icon(Icons.sell_outlined, size: 18),
                      isDense: true,
                    ),
                    style: theme.textTheme.bodySmall,
                  ),
                ),

                // Image button
                ThoughtPillButton(
                  icon: Icons.image_outlined,
                  label: composer.pendingImagePaths.isNotEmpty
                      ? '图片 (${composer.pendingImagePaths.length})'
                      : '图片',
                  onTap: composer.pickImageForComposer,
                ),

                // Pin button
                ThoughtPillButton(
                  icon: composer.isPinned
                      ? Icons.push_pin_rounded
                      : Icons.push_pin_outlined,
                  label: composer.isPinned ? '已置顶' : '置顶',
                  selected: composer.isPinned,
                  onTap: composer.togglePin,
                ),

                // Disabled: Convert to todo
                Tooltip(
                  message: '即将推出',
                  child: ThoughtPillButton(
                    icon: Icons.check_box_outlined,
                    label: '转为待办',
                    onTap: null,
                  ),
                ),

                // Disabled: Convert to note
                Tooltip(
                  message: '即将推出',
                  child: ThoughtPillButton(
                    icon: Icons.note_alt_outlined,
                    label: '转为笔记',
                    onTap: null,
                  ),
                ),

                const Spacer(),

                // Submit button
                FilledButton.icon(
                  onPressed:
                      composer.canSubmit && !composer.isSubmitting
                          ? composer.submit
                          : null,
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: Text(composer.isSubmitting ? '保存中' : '记录想法'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
