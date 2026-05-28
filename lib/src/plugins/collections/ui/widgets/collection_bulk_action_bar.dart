import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uni_hub/src/core/theme/app_tokens.dart';
import 'package:uni_hub/src/plugins/collections/domain/consumption_status.dart';
import 'package:uni_hub/src/plugins/collections/domain/media_type.dart';
import 'package:uni_hub/src/plugins/collections/domain/source_platform.dart';
import 'package:uni_hub/src/plugins/collections/providers/collections_providers.dart';
import 'package:uni_hub/src/shared/preferences/delete_confirm_prefs_provider.dart';
import 'package:uni_hub/src/shared/widgets/delete_confirm_dialog.dart';

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
                  color: colorScheme.shadow.withValues(alpha: 0.04),
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
                        const SizedBox(width: AppSpacing.xs),
                        // Active: 删除 (destructive)
                        _BulkActionPill(
                          icon: Icons.delete_outline_rounded,
                          label: '删除',
                          enabled: true,
                          destructive: true,
                          colorScheme: colorScheme,
                          onPressed: () async {
                            final prefsAsync =
                                ref.read(deleteConfirmPrefsProvider);
                            final prefs = prefsAsync.valueOrNull;
                            if (prefs == null) return;

                            final repository =
                                ref.read(collectionsRepositoryProvider);
                            final item =
                                await repository.getSavedItem(selectedId);
                            if (item == null || !context.mounted) return;

                            final displayTitle = item.title.isEmpty
                                ? item.normalizedUrl
                                : item.title;
                            final mediaType =
                                MediaType.fromValue(item.mediaType);
                            final platform =
                                SourcePlatform.fromValue(item.sourcePlatform);

                            final boxIds =
                                await repository.getBoxIdsForItem(item.id);

                            DeleteConfirmResult? result;
                            if (boxIds.length > 1) {
                              final boxes = await repository.getBoxes();
                              final boxNames = boxes
                                  .where((b) => boxIds.contains(b.id))
                                  .map((b) => b.name)
                                  .toList();
                              result =
                                  await DeleteConfirmDialog.showMultiBox(
                                context: context,
                                title: displayTitle,
                                source: item.siteName?.isNotEmpty == true
                                    ? item.siteName!
                                    : _domainOf(item.normalizedUrl),
                                typeLabel: platform.label,
                                relativeTime:
                                    _relativeTime(item.createdAt),
                                fallbackIcon: _iconFor(mediaType),
                                boxNames: boxNames,
                                prefs: prefs,
                              );
                            } else {
                              result =
                                  await DeleteConfirmDialog.showSingle(
                                context: context,
                                title: displayTitle,
                                source: item.siteName?.isNotEmpty == true
                                    ? item.siteName!
                                    : _domainOf(item.normalizedUrl),
                                typeLabel: platform.label,
                                relativeTime:
                                    _relativeTime(item.createdAt),
                                fallbackIcon: _iconFor(mediaType),
                                prefs: prefs,
                              );
                            }

                            if (result == null ||
                                result == DeleteConfirmResult.cancel ||
                                !context.mounted) {
                              return;
                            }

                            if (result == DeleteConfirmResult.removeFromBox) {
                              if (boxIds.isNotEmpty) {
                                final boxes =
                                    await repository.getBoxes();
                                final boxName = boxes
                                        .where((b) => b.id == boxIds.first)
                                        .map((b) => b.name)
                                        .firstOrNull ??
                                    '收藏夹';
                                await repository.removeItemFromBox(
                                  item.id,
                                  boxIds.first,
                                );
                                ref.invalidate(savedItemsPageProvider);
                                ref.invalidate(
                                  collectionFolderCountsProvider,
                                );
                                if (!context.mounted) return;
                                _showUndoSnackBar(
                                  context,
                                  '已从「$boxName」中移除',
                                  () async {
                                    final currentBoxIds = await repository
                                        .getBoxIdsForItem(item.id);
                                    await repository.setItemBoxes(
                                      item.id,
                                      {...currentBoxIds, boxIds.first},
                                    );
                                    await repository.updateInboxState(
                                      item.id,
                                      false,
                                    );
                                    ref.invalidate(
                                      savedItemsPageProvider,
                                    );
                                    ref.invalidate(
                                      collectionFolderCountsProvider,
                                    );
                                  },
                                );
                              }
                              return;
                            }

                            final undoBoxIds = List<int>.from(boxIds);
                            await repository.deleteSavedItem(item.id);
                            ref
                                .read(selectedSavedItemIdProvider.notifier)
                                .state = null;
                            ref.invalidate(savedItemsPageProvider);
                            ref.invalidate(collectionFolderCountsProvider);
                            if (!context.mounted) return;
                            _showUndoSnackBar(
                              context,
                              '已删除「$displayTitle」',
                              () async {
                                final restored =
                                    await repository.createSavedItem(
                                  originalUrl: item.originalUrl,
                                  normalizedUrl: item.normalizedUrl,
                                  title: item.title,
                                  mediaType: mediaType,
                                  sourcePlatform: platform,
                                  isInInbox: undoBoxIds.isEmpty,
                                );
                                if (undoBoxIds.isNotEmpty) {
                                  await repository.setItemBoxes(
                                    restored.id,
                                    undoBoxIds.toSet(),
                                  );
                                  await repository.updateInboxState(
                                    restored.id,
                                    false,
                                  );
                                }
                                ref.invalidate(savedItemsPageProvider);
                                ref.invalidate(
                                  collectionFolderCountsProvider,
                                );
                              },
                            );
                          },
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
    this.destructive = false,
    this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final ColorScheme colorScheme;
  final bool destructive;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    const double height = 30.0;
    const double hPadding = 10.0;
    const double iconSize = 15.0;
    const double fontSize = 12.5;

    final foregroundColor = !enabled
        ? colorScheme.onSurfaceVariant.withValues(alpha: 0.40)
        : destructive
            ? colorScheme.error
            : colorScheme.primary;

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

// ---------------------------------------------------------------
// Top-level helpers used by the delete action in the build method
// ---------------------------------------------------------------

String _domainOf(String url) {
  final host = Uri.tryParse(url)?.host;
  if (host == null || host.isEmpty) return url;
  return host.startsWith('www.') ? host.substring(4) : host;
}

String _relativeTime(DateTime dt) {
  final now = DateTime.now();
  final diff = now.difference(dt);
  if (diff.inMinutes < 1) return '刚刚';
  if (diff.inHours < 1) return '${diff.inMinutes} 分钟前';
  if (diff.inDays < 1) return '${diff.inHours} 小时前';
  if (diff.inDays < 7) return '${diff.inDays} 天前';
  return '${dt.month}月${dt.day}日';
}

IconData _iconFor(MediaType mediaType) {
  return switch (mediaType) {
    MediaType.article => Icons.article_outlined,
    MediaType.video => Icons.play_circle_outline_rounded,
    MediaType.repository => Icons.code_rounded,
    MediaType.webpage => Icons.language_rounded,
    MediaType.image => Icons.image_outlined,
    MediaType.pdf => Icons.picture_as_pdf_rounded,
    MediaType.audio => Icons.headphones_rounded,
    MediaType.post => Icons.forum_outlined,
    MediaType.document => Icons.description_outlined,
    MediaType.unknown => Icons.link_rounded,
  };
}

void _showUndoSnackBar(
  BuildContext context,
  String message,
  VoidCallback onUndo,
) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 5),
      action: SnackBarAction(
        label: '撤销',
        onPressed: onUndo,
      ),
    ),
  );
}
