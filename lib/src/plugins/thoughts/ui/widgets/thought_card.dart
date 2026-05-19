import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../data/thought_content_codec.dart';

class ThoughtCard extends ConsumerStatefulWidget {
  final int id;
  final String content;
  final String? tags;
  final String? color;
  final bool isPinned;
  final DateTime createdAt;
  final String? imagePaths;
  final VoidCallback onTap;
  final void Function(String tag) onTagTap;
  final VoidCallback? onArchive;
  final VoidCallback? onRestore;

  const ThoughtCard({
    required this.id,
    required this.content,
    required this.tags,
    required this.color,
    required this.isPinned,
    required this.createdAt,
    this.imagePaths,
    required this.onTap,
    required this.onTagTap,
    this.onArchive,
    this.onRestore,
    super.key,
  });

  @override
  ConsumerState<ThoughtCard> createState() => _ThoughtCardState();
}

class _ThoughtCardState extends ConsumerState<ThoughtCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tagList = (widget.tags ?? '')
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final accent = widget.color != null
        ? _hexToColor(widget.color!)
        : _cardAccent(widget.id, colorScheme);
    final images = ThoughtContentCodec.mergeImagePaths(
      widget.imagePaths,
      widget.content,
    );
    final title = ThoughtContentCodec.titleFromStored(widget.content);
    final body = ThoughtContentCodec.plainTextFromStored(widget.content);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: widget.onTap,
          child: Container(
            constraints: const BoxConstraints(
              minHeight: AppSizes.cardMinHeight,
            ),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (images.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: _ThoughtCardImage(path: images.first),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                // ── Timestamp + Actions ──
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _formatTimestamp(widget.createdAt),
                        style: theme.textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.onRestore != null && _hovered)
                      _ActionIcon(
                        icon: Icons.unarchive_outlined,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        onTap: widget.onRestore,
                      ),
                    if (widget.onArchive != null &&
                        _hovered &&
                        !widget.isPinned)
                      _ActionIcon(
                        icon: Icons.archive_outlined,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        onTap: widget.onArchive,
                      ),
                    Icon(
                      widget.isPinned
                          ? Icons.star_rounded
                          : Icons.more_horiz_rounded,
                      size: 18,
                      color: widget.isPinned
                          ? colorScheme.tertiary
                          : colorScheme.outline,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // ── Title ──
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // ── Body ──
                Flexible(
                  child: Text(
                    body,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.55,
                    ),
                  ),
                ),

                // ── Images ──
                if (images.length > 1) ...[
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    height: 54,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: images.skip(1).take(4).length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(width: AppSpacing.xs),
                      itemBuilder: (_, index) {
                        final file = File(images[index + 1]);
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.xs),
                          child: file.existsSync()
                              ? Image.file(
                                  file,
                                  width: 64,
                                  height: 54,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  width: 64,
                                  height: 54,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHigh,
                                  child: const Icon(
                                    Icons.broken_image_outlined,
                                    size: 18,
                                  ),
                                ),
                        );
                      },
                    ),
                  ),
                ],

                // ── Tags ──
                if (tagList.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: tagList.map((tag) {
                      return ActionChip(
                        label: Text(tag),
                        onPressed: () => widget.onTagTap(tag),
                        backgroundColor: accent.withValues(alpha: 0.11),
                        side: BorderSide.none,
                        labelStyle: theme.textTheme.labelMedium?.copyWith(
                          color: accent,
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _hexToColor(String hex) {
    final cleaned = hex.replaceFirst('#', '');
    final normalized = cleaned.length == 6 ? 'FF$cleaned' : cleaned;
    final intVal = int.tryParse(normalized, radix: 16);
    return Color(intVal ?? Theme.of(context).colorScheme.primary.toARGB32());
  }

  Color _cardAccent(int index, ColorScheme colorScheme) {
    final accents = [
      colorScheme.tertiary,
      colorScheme.secondary,
      colorScheme.primary,
      colorScheme.error,
    ];
    return accents[index % accents.length];
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
      return '${dt.month}月${dt.day}日 ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}

class _ThoughtCardImage extends StatelessWidget {
  final String path;

  const _ThoughtCardImage({required this.path});

  @override
  Widget build(BuildContext context) {
    final file = File(path);
    if (!file.existsSync()) {
      return Container(
        height: 90,
        width: double.infinity,
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        child: const Icon(Icons.broken_image_outlined, size: 20),
      );
    }
    return Image.file(
      file,
      height: 90,
      width: double.infinity,
      fit: BoxFit.cover,
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _ActionIcon({required this.icon, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.xxs),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.xs),
            border: Border.all(color: colorScheme.outline),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}
