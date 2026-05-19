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
    final tagList = (widget.tags ?? '')
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final accent = widget.color != null
        ? _hexToColor(widget.color!)
        : _cardAccent(widget.id);
    final background = widget.color != null
        ? accent.withValues(alpha: 0.08)
        : _cardBackground(widget.id);
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
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: widget.onTap,
          child: Container(
            constraints: const BoxConstraints(
              minHeight: AppSizes.cardMinHeight,
            ),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                        color: AppColors.textSecondary,
                        onTap: widget.onRestore,
                      ),
                    if (widget.onArchive != null &&
                        _hovered &&
                        !widget.isPinned)
                      _ActionIcon(
                        icon: Icons.archive_outlined,
                        color: AppColors.textSecondary,
                        onTap: widget.onArchive,
                      ),
                    Icon(
                      widget.isPinned
                          ? Icons.star_rounded
                          : Icons.more_horiz_rounded,
                      size: 18,
                      color: widget.isPinned
                          ? AppColors.warning
                          : AppColors.textTertiary,
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
                Expanded(
                  child: Text(
                    body,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.55,
                    ),
                  ),
                ),

                // ── Images ──
                if (images.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    height: 54,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: images.take(4).length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(width: AppSpacing.xs),
                      itemBuilder: (_, index) {
                        final file = File(images[index]);
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
                                  color: AppColors.surfaceMuted,
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
    return Color(intVal ?? AppColors.primary.toARGB32());
  }

  Color _cardAccent(int index) {
    const accents = [
      AppColors.warning,
      AppColors.success,
      AppColors.primary,
      AppColors.purple,
      AppColors.error,
      AppColors.secondary,
    ];
    return accents[index % accents.length];
  }

  Color _cardBackground(int index) {
    const backgrounds = [
      AppColors.yellowSoft,
      AppColors.greenSoft,
      AppColors.blueSoft,
      AppColors.purpleSoft,
      AppColors.roseSoft,
      AppColors.secondarySoft,
    ];
    return backgrounds[index % backgrounds.length].withValues(alpha: 0.62);
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

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _ActionIcon({required this.icon, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.xxs),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.xs),
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}
