import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uni_hub/src/core/theme/app_tokens.dart';
import 'package:uni_hub/src/plugins/collections/domain/consumption_status.dart';
import 'package:uni_hub/src/plugins/collections/providers/collections_providers.dart';

/// A floating toolbar-style bulk action bar shown below the item list.
///
/// Visual style: white background, thin border, light shadow, rounded corners.
/// Active actions ("标记已看", "归档") look enabled.
/// Placeholder actions ("移动", "添加到收藏夹") are visually disabled.
class CollectionBulkActionBar extends ConsumerWidget {
  const CollectionBulkActionBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedId = ref.watch(selectedSavedItemIdProvider);
    if (selectedId == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 520;

        return Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.6),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Selection count
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color:
                        colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                  child: Text(
                    '已选择 1 项',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: AppFontTokens.medium,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                // Buttons - scrollable when narrow
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // Active: 标记已看
                        _BulkActionPill(
                          icon: Icons.check_circle_outline,
                          label: isCompact ? '已看' : '标记已看',
                          enabled: true,
                          onPressed: () async {
                            final repository =
                                ref.read(collectionsRepositoryProvider);
                            await repository.updateStatus(
                              selectedId,
                              ConsumptionStatus.done,
                            );
                            ref.invalidate(savedItemsListProvider);
                          },
                          colorScheme: colorScheme,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        // Active: 归档
                        _BulkActionPill(
                          icon: Icons.archive_outlined,
                          label: '归档',
                          enabled: true,
                          onPressed: () async {
                            final repository =
                                ref.read(collectionsRepositoryProvider);
                            await repository.updateStatus(
                              selectedId,
                              ConsumptionStatus.archived,
                            );
                            ref.read(selectedSavedItemIdProvider.notifier)
                                .state = null;
                            ref.invalidate(savedItemsListProvider);
                          },
                          colorScheme: colorScheme,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        // Disabled: 移动
                        _BulkActionPill(
                          icon: Icons.drive_file_move_outlined,
                          label: '移动',
                          enabled: false,
                          colorScheme: colorScheme,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        // Disabled: 添加到收藏夹
                        _BulkActionPill(
                          icon: Icons.folder_outlined,
                          label: isCompact ? '收藏夹' : '添加到收藏夹',
                          enabled: false,
                          colorScheme: colorScheme,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A lightweight pill-style action button for the bulk action bar.
///
/// Height 30, transparent background, subtle hover feedback via InkWell.
class _BulkActionPill extends StatelessWidget {
  const _BulkActionPill({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.colorScheme,
    this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final ColorScheme colorScheme;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    const double height = 30.0;
    const double hPadding = 10.0;
    const double iconSize = 15.0;
    const double fontSize = 12.5;

    final foregroundColor = enabled
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant.withValues(alpha: 0.40);

    final borderRadius = BorderRadius.circular(AppRadius.full);

    return Material(
      type: MaterialType.transparency,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
        ),
        child: InkWell(
          borderRadius: borderRadius,
          onTap: enabled ? onPressed : null,
          child: SizedBox(
            height: height,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: hPadding),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: iconSize,
                    color: foregroundColor,
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: fontSize,
                      height: 1.15,
                      fontWeight: AppFontTokens.medium,
                      color: foregroundColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
