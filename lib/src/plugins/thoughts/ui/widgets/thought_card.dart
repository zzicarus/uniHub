import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_tokens.dart';

class ThoughtCard extends ConsumerWidget {
  final int id;
  final String content;
  final String? tags;
  final String? color;
  final bool isPinned;
  final DateTime createdAt;
  final VoidCallback onTap;
  final void Function(String tag) onTagTap;

  const ThoughtCard({
    required this.id,
    required this.content,
    required this.tags,
    required this.color,
    required this.isPinned,
    required this.createdAt,
    required this.onTap,
    required this.onTagTap,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tagList = (tags ?? '')
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final accent = color != null ? _hexToColor(color!) : _cardAccent(id);
    final background = color != null
        ? accent.withValues(alpha: 0.08)
        : _cardBackground(id);

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: AppSizes.cardMinHeight),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: accent.withValues(alpha: 0.16)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _formatTimestamp(createdAt),
                      style: theme.textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    isPinned ? Icons.star_rounded : Icons.more_horiz_rounded,
                    size: 18,
                    color: isPinned
                        ? AppColors.warning
                        : AppColors.textTertiary,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                _titleOf(content),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: Text(
                  content,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.55,
                  ),
                ),
              ),
              if (tagList.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: tagList.map((tag) {
                    return ActionChip(
                      label: Text(tag),
                      onPressed: () => onTagTap(tag),
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

  String _titleOf(String text) {
    final firstLine = text.trim().split(RegExp(r'\s*\n\s*')).first;
    if (firstLine.length <= 20) return firstLine;
    return '${firstLine.substring(0, 20)}...';
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
