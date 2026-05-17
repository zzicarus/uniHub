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

    final displayColor =
        color != null ? _hexToColor(color!) : null;

    return Card(
      color: displayColor?.withValues(alpha: 0.08) ?? AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(
          color: displayColor?.withValues(alpha: 0.3) ?? AppColors.border,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      content,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                        height: 1.5,
                      ),
                    ),
                  ),
                  if (isPinned)
                    const Padding(
                      padding: EdgeInsets.only(left: AppSpacing.xs),
                      child: Icon(
                        Icons.push_pin,
                        size: 16,
                        color: AppColors.warning,
                      ),
                    ),
                ],
              ),
              if (tagList.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xxs,
                  runSpacing: AppSpacing.xxs,
                  children: tagList.map((tag) {
                    return InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      onTap: () => onTagTap(tag),
                      child: Chip(
                        label: Text(tag),
                        labelStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      ),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: AppSpacing.xs),
              Text(
                _formatTimestamp(createdAt),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _hexToColor(String hex) {
    final cleaned = hex.replaceFirst('#', '');
    final intVal = int.tryParse(
      'FF$cleaned',
      radix: 16,
    );
    return Color(intVal ?? AppColors.primary.toARGB32());
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final date = DateTime(dt.year, dt.month, dt.day);

    if (date == today) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } else if (date == yesterday) {
      return '昨天';
    } else if (dt.year == now.year) {
      return '${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    } else {
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    }
  }
}
