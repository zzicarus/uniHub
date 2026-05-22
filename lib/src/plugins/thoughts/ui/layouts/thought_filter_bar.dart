import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:uni_hub/src/core/theme/app_tokens.dart';
import '../../providers/thought_status_filter.dart';
import '../../providers/thoughts_providers.dart';

/// Status filter bar with chips: 全部 / 置顶 / 有图片 / 归档.
///
/// Uses [thoughtStatusFilterProvider] for the active filter and
/// [archiveFilterProvider] for the archive toggle.
class ThoughtFilterBar extends ConsumerWidget {
  const ThoughtFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusFilter = ref.watch(thoughtStatusFilterProvider);
    final isArchived = ref.watch(archiveFilterProvider);

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        _StatusChip(
          label: '全部',
          selected: statusFilter == ThoughtStatusFilter.all && !isArchived,
          onTap: () {
            ref.read(thoughtStatusFilterProvider.notifier).state =
                ThoughtStatusFilter.all;
            ref.read(archiveFilterProvider.notifier).state = false;
          },
        ),
        _StatusChip(
          label: '置顶',
          selected: statusFilter == ThoughtStatusFilter.pinned,
          onTap: () {
            ref.read(archiveFilterProvider.notifier).state = false;
            ref.read(thoughtStatusFilterProvider.notifier).state =
                ThoughtStatusFilter.pinned;
          },
        ),
        _StatusChip(
          label: '有图片',
          selected: statusFilter == ThoughtStatusFilter.withImages,
          onTap: () {
            ref.read(archiveFilterProvider.notifier).state = false;
            ref.read(thoughtStatusFilterProvider.notifier).state =
                ThoughtStatusFilter.withImages;
          },
        ),
        _StatusChip(
          label: '归档',
          selected: isArchived || statusFilter == ThoughtStatusFilter.archived,
          onTap: () {
            final currentlyArchived = isArchived ||
                statusFilter == ThoughtStatusFilter.archived;
            ref.read(archiveFilterProvider.notifier).state = !currentlyArchived;
            ref.read(thoughtStatusFilterProvider.notifier).state =
                !currentlyArchived
                    ? ThoughtStatusFilter.archived
                    : ThoughtStatusFilter.all;
          },
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _StatusChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: selected ? colorScheme.primaryContainer : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected
                  ? colorScheme.primary
                  : colorScheme.outlineVariant,
            ),
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Center(
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: selected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w600 : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
