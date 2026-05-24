import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uni_hub/src/core/theme/app_tokens.dart';
import 'package:uni_hub/src/plugins/collections/domain/consumption_status.dart';
import 'package:uni_hub/src/plugins/collections/providers/collections_providers.dart';

/// Minimal bulk action bar shown below the item list when an item is selected.
///
/// UI skeleton — batch logic (multi-select, bulk archive/move) is out of scope
/// for MVP. The "标记已看" button works on the currently selected item;
/// "归档" works similarly. "移动" and "添加到 Box" are disabled until
/// multi-select is implemented.
class CollectionBulkActionBar extends ConsumerWidget {
  const CollectionBulkActionBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedId = ref.watch(selectedSavedItemIdProvider);
    if (selectedId == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Text('已选择 1 项', style: theme.textTheme.bodySmall),
          const Spacer(),
          _ActionButton(
            icon: Icons.check_circle_outline,
            label: '标记已看',
            onPressed: () async {
              final repository = ref.read(collectionsRepositoryProvider);
              await repository.updateStatus(selectedId, ConsumptionStatus.done);
              ref.invalidate(savedItemsListProvider);
            },
            color: colorScheme.primary,
          ),
          const SizedBox(width: AppSpacing.xs),
          _ActionButton(
            icon: Icons.archive_outlined,
            label: '归档',
            onPressed: () async {
              final repository = ref.read(collectionsRepositoryProvider);
              await repository.updateStatus(
                selectedId,
                ConsumptionStatus.archived,
              );
              ref.read(selectedSavedItemIdProvider.notifier).state = null;
              ref.invalidate(savedItemsListProvider);
            },
            color: colorScheme.primary,
          ),
          const SizedBox(width: AppSpacing.xs),
          _ActionButton(
            icon: Icons.drive_file_move_outlined,
            label: '移动',
            onPressed: null, // disabled until multi-select
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.xs),
          _ActionButton(
            icon: Icons.folder_outlined,
            label: '添加到 Box',
            onPressed: null, // disabled until multi-select
            color: colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16, color: color),
      label: Text(
        label,
        style: TextStyle(color: color),
      ),
    );
  }
}
