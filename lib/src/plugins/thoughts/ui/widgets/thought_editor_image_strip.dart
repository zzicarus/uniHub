import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:uni_hub/src/core/theme/app_tokens.dart';

/// 水平可滚动的图片缩略图列表，用于想法编辑器。
///
/// 供 [ThoughtsEditorPage] 与 [ThoughtEditorDrawer] 共用。
class ThoughtEditorImageStrip extends StatelessWidget {
  final List<String> images;
  final Future<void> Function(int index) onRemove;
  final double thumbnailSize;

  const ThoughtEditorImageStrip({
    required this.images,
    required this.onRemove,
    this.thumbnailSize = 80,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
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
                  ? Image.file(
                      file,
                      width: thumbnailSize,
                      height: thumbnailSize,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: thumbnailSize,
                      height: thumbnailSize,
                      color: Theme.of(context).colorScheme.surfaceContainerHigh,
                      child: const Icon(Icons.broken_image_outlined),
                    ),
            ),
            Positioned(
              top: 2,
              right: 2,
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
    );
  }
}
