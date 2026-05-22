import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:uni_hub/src/core/theme/app_tokens.dart';
import '../../providers/thought_status_filter.dart';
import '../../providers/thoughts_providers.dart';

class ThoughtFilterBar extends ConsumerWidget {
  const ThoughtFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusFilter = ref.watch(thoughtStatusFilterProvider);
    final isArchived = ref.watch(archiveFilterProvider);

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: [
        _StatusChip(
          label: '全部',
          selected: statusFilter == ThoughtStatusFilter.all && !isArchived,
          onTap: () => _setFilter(ref, ThoughtStatusFilter.all),
        ),
        _StatusChip(
          label: '未整理',
          selected: statusFilter == ThoughtStatusFilter.unorganized,
          onTap: () => _setFilter(ref, ThoughtStatusFilter.unorganized),
        ),
        _StatusChip(
          label: '置顶',
          selected: statusFilter == ThoughtStatusFilter.pinned,
          onTap: () => _setFilter(ref, ThoughtStatusFilter.pinned),
        ),
        _StatusChip(
          label: '有图片',
          selected: statusFilter == ThoughtStatusFilter.withImages,
          onTap: () => _setFilter(ref, ThoughtStatusFilter.withImages),
        ),
        const Tooltip(
          message: '待办联动即将推出',
          child: _StatusChip(label: '待办', selected: false),
        ),
      ],
    );
  }

  void _setFilter(WidgetRef ref, ThoughtStatusFilter filter) {
    ref.read(archiveFilterProvider.notifier).state = false;
    ref.read(thoughtStatusFilterProvider.notifier).state = filter;
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _StatusChip({required this.label, required this.selected, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final enabled = onTap != null;

    return Material(
      color: selected ? AppColors.primary : colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : colorScheme.outlineVariant.withValues(alpha: 0.55),
            ),
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Center(
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: selected
                    ? Colors.white
                    : enabled
                    ? colorScheme.onSurfaceVariant
                    : colorScheme.outline,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
