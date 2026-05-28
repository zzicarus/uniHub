import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uni_hub/src/core/database/app_database.dart';
import 'package:uni_hub/src/core/theme/app_tokens.dart';
import 'package:uni_hub/src/plugins/collections/application/saved_item_list_entry.dart';
import 'package:uni_hub/src/plugins/collections/application/saved_item_undo_snapshot.dart';
import 'package:uni_hub/src/plugins/collections/domain/consumption_status.dart';
import 'package:uni_hub/src/plugins/collections/domain/enrichment_status.dart';
import 'package:uni_hub/src/plugins/collections/domain/media_type.dart';
import 'package:uni_hub/src/plugins/collections/domain/source_platform.dart';
import 'package:uni_hub/src/plugins/collections/providers/collections_providers.dart';
import 'package:uni_hub/src/shared/preferences/delete_confirm_prefs_provider.dart';
import 'package:uni_hub/src/shared/widgets/delete_confirm_dialog.dart';
import 'package:uni_hub/src/shared/widgets/website_logo.dart';

/// Content-style saved-item card for the collection list.
///
/// Accepts a [SavedItemListEntry] ViewModel which pre-aggregates the item
/// data, box assignments, logo cache, and selection state — eliminating
/// N+1 queries during list rendering.
class SavedItemCard extends ConsumerWidget {
  const SavedItemCard({required this.entry, this.onTap, super.key});

  final SavedItemListEntry entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final item = entry.item;
    final platform = SourcePlatform.fromValue(item.sourcePlatform);
    final mediaType = MediaType.fromValue(item.mediaType);
    final status = ConsumptionStatus.fromValue(item.status);
    final enrichmentStatus = EnrichmentStatus.fromValue(item.enrichmentStatus);
    // #1: 卡片内部判断选中态，避免父布局 watch selectedSavedItemIdProvider 导致整页重建
    final selected = ref.watch(
      selectedSavedItemIdProvider.select((id) => id == entry.item.id),
    );
    final localLogoPath = entry.logo?.localLogoPath;

    final borderRadius = BorderRadius.circular(AppRadius.md);

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 92, maxHeight: 112),
      child: Material(
        type: MaterialType.transparency,
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            color: selected
                ? colorScheme.primaryContainer.withValues(alpha: 0.12)
                : colorScheme.surface,
            border: Border.all(
              color: selected
                  ? colorScheme.primary
                  : colorScheme.outlineVariant,
              width: selected ? 1.2 : 1.0,
            ),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: borderRadius,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm,
                AppSpacing.sm,
                AppSpacing.xs,
                AppSpacing.sm,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _iconColumn(
                    colorScheme,
                    mediaType,
                    enrichmentStatus,
                    localLogoPath,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title.isEmpty ? item.normalizedUrl : item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: AppFontTokens.semiBold,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          _metaText(item, platform, mediaType),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        _bottomChipsRow(
                          theme,
                          colorScheme,
                          platform,
                          mediaType,
                          enrichmentStatus,
                          entry.boxes,
                          item,
                          ref,
                          context,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  _rightColumn(context, theme, colorScheme, status, ref, item),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------
  // Icon column
  // ---------------------------------------------------------------

  Widget _iconColumn(
    ColorScheme colorScheme,
    MediaType mediaType,
    EnrichmentStatus enrichmentStatus,
    String? localLogoPath,
  ) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        WebsiteLogo(
          localPath: localLogoPath,
          fallbackIcon: _iconFor(mediaType),
          size: 48,
          iconSize: 24,
        ),
        if (enrichmentStatus == EnrichmentStatus.failed)
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: colorScheme.error,
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.surface, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------
  // Bottom chips row
  // ---------------------------------------------------------------

  Widget _bottomChipsRow(
    ThemeData theme,
    ColorScheme colorScheme,
    SourcePlatform platform,
    MediaType mediaType,
    EnrichmentStatus enrichmentStatus,
    List<CollectionBoxesTableData> boxes,
    SavedItemsTableData item,
    WidgetRef ref,
    BuildContext context,
  ) {
    return SizedBox(
      height: 22,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _miniChip(theme, colorScheme, platform.label),
            const SizedBox(width: AppSpacing.xxs),
            _miniChip(theme, colorScheme, mediaType.label),
            const SizedBox(width: AppSpacing.xxs),
            // Box chips from pre-aggregated entry data
            for (final box in boxes.take(2)) ...[
              const SizedBox(width: AppSpacing.xxs),
              _BoxMiniChip(label: box.name),
            ],
            if (boxes.length > 2) ...[
              const SizedBox(width: AppSpacing.xxs),
              Text(
                '+${boxes.length - 2}',
                style: TextStyle(
                  fontSize: AppFontTokens.mini,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (enrichmentStatus == EnrichmentStatus.failed) ...[
              const SizedBox(width: AppSpacing.xxs),
              _miniChip(
                theme,
                colorScheme,
                '抓取失败 · 重试',
                isError: true,
                onTap: () async {
                  final controller = ref.read(
                    savedItemActionsControllerProvider,
                  );
                  final result = await controller.retryEnrichment(item.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(result.message ?? '')),
                    );
                  }
                },
              ),
            ],
            if (item.lastOpenedAt != null) ...[
              const SizedBox(width: AppSpacing.xxs),
              _miniChip(theme, colorScheme, '已打开'),
            ],
          ],
        ),
      ),
    );
  }

  String _metaText(
    SavedItemsTableData item,
    SourcePlatform platform,
    MediaType mediaType,
  ) {
    final source = item.siteName?.trim().isNotEmpty == true
        ? item.siteName!.trim()
        : _domainOf(item.normalizedUrl);
    return '$source · ${platform.label} · ${mediaType.label} · ${_relativeTime(item.createdAt)}';
  }

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

  Widget _miniChip(
    ThemeData theme,
    ColorScheme colorScheme,
    String label, {
    bool isError = false,
    VoidCallback? onTap,
  }) {
    return Material(
      color: isError
          ? colorScheme.errorContainer.withValues(alpha: 0.65)
          : colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppRadius.xs),
      clipBehavior: Clip.antiAlias,
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: isError
                  ? colorScheme.onErrorContainer
                  : colorScheme.onSurfaceVariant,
              fontSize: AppFontTokens.mini,
              height: 1.4,
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------
  // Right column: status pill + open button
  // ---------------------------------------------------------------

  Widget _rightColumn(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    ConsumptionStatus status,
    WidgetRef ref,
    SavedItemsTableData item,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 76),
          child: PopupMenuButton<ConsumptionStatus>(
            tooltip: '切换状态',
            initialValue: status,
            onSelected: (next) async {
              final controller = ref.read(savedItemActionsControllerProvider);
              await controller.updateStatus(item.id, next);
            },
            itemBuilder: (context) => [
              for (final value in ConsumptionStatus.values)
                PopupMenuItem(value: value, child: Text(_statusLabel(value))),
            ],
            offset: const Offset(0, 32),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _statusColor(
                  status,
                  colorScheme,
                ).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: Border.all(
                  color: _statusColor(
                    status,
                    colorScheme,
                  ).withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Text(
                _statusLabel(status),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: _statusColor(status, colorScheme),
                  fontWeight: AppFontTokens.medium,
                  fontSize: AppFontTokens.caption,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: IconButton(
                tooltip: '星标功能稍后接入',
                icon: const Icon(Icons.star_border_rounded, size: 16),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                style: IconButton.styleFrom(
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: colorScheme.onSurfaceVariant,
                ),
                onPressed: () {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('星标功能稍后接入')));
                },
              ),
            ),
            _CardMoreMenu(item: item),
          ],
        ),
      ],
    );
  }

  String _statusLabel(ConsumptionStatus status) {
    return switch (status) {
      ConsumptionStatus.unread => '待看',
      ConsumptionStatus.inProgress => '阅读中',
      ConsumptionStatus.done => '已看',
      ConsumptionStatus.archived => '已归档',
    };
  }

  Color _statusColor(ConsumptionStatus status, ColorScheme colorScheme) {
    return switch (status) {
      ConsumptionStatus.unread => colorScheme.primary,
      ConsumptionStatus.inProgress => colorScheme.tertiary,
      ConsumptionStatus.done => colorScheme.secondary,
      ConsumptionStatus.archived => colorScheme.onSurfaceVariant,
    };
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
}

// ---------------------------------------------------------------
// Item box chips (reused from previous impl, simplified)
// ---------------------------------------------------------------

class _CardMoreMenu extends ConsumerWidget {
  const _CardMoreMenu({required this.item});

  final SavedItemsTableData item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 28,
      height: 28,
      child: PopupMenuButton<_CardAction>(
        tooltip: '更多操作',
        padding: EdgeInsets.zero,
        icon: const Icon(Icons.more_horiz_rounded, size: 16),
        iconColor: colorScheme.onSurfaceVariant,
        onSelected: (action) async {
          switch (action) {
            case _CardAction.open:
              final controller = ref.read(savedItemActionsControllerProvider);
              final result = await controller.openItem(item.id);
              if (!context.mounted || result.message == null) return;
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(result.message!)));
            case _CardAction.copy:
              final controller = ref.read(savedItemActionsControllerProvider);
              await controller.copyUrl(item.id);
              if (!context.mounted) return;
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('链接已复制到剪贴板')));
            case _CardAction.folder:
              await _CompactBoxButton(
                itemId: item.id,
              )._showBoxMenu(context, ref);
            case _CardAction.archive:
              final ctrl = ref.read(savedItemActionsControllerProvider);
              await ctrl.archiveItem(item.id);
            case _CardAction.delete:
              await _handleDelete(context, ref, item);
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(value: _CardAction.open, child: Text('打开内容')),
          const PopupMenuItem(value: _CardAction.folder, child: Text('分配收藏夹')),
          const PopupMenuItem(value: _CardAction.copy, child: Text('复制链接')),
          const PopupMenuItem(value: _CardAction.archive, child: Text('归档')),
          const PopupMenuDivider(),
          PopupMenuItem(
            value: _CardAction.delete,
            child: Text('删除', style: TextStyle(color: colorScheme.error)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDelete(
    BuildContext context,
    WidgetRef ref,
    SavedItemsTableData item,
  ) async {
    final prefsAsync = ref.read(deleteConfirmPrefsProvider);
    final prefs = prefsAsync.valueOrNull;
    if (prefs == null) return;

    final displayTitle = item.title.isEmpty ? item.normalizedUrl : item.title;
    final mediaType = MediaType.fromValue(item.mediaType);
    final platform = SourcePlatform.fromValue(item.sourcePlatform);
    final repository = ref.read(collectionsRepositoryProvider);
    final controller = ref.read(savedItemActionsControllerProvider);

    final boxIds = await repository.getBoxIdsForItem(item.id);
    if (!context.mounted) return;

    DeleteConfirmResult? result;
    if (boxIds.length > 1) {
      final boxes = await repository.getBoxes();
      final boxNames = boxes
          .where((b) => boxIds.contains(b.id))
          .map((b) => b.name)
          .toList();
      if (!context.mounted) return;
      result = await DeleteConfirmDialog.showMultiBox(
        context: context,
        title: displayTitle,
        source: item.siteName?.isNotEmpty == true
            ? item.siteName!
            : _domainOf(item.normalizedUrl),
        typeLabel: platform.label,
        relativeTime: _relativeTime(item.createdAt),
        fallbackIcon: _iconFor(mediaType),
        boxNames: boxNames,
        prefs: prefs,
      );
    } else {
      result = await DeleteConfirmDialog.showSingle(
        context: context,
        title: displayTitle,
        source: item.siteName?.isNotEmpty == true
            ? item.siteName!
            : _domainOf(item.normalizedUrl),
        typeLabel: platform.label,
        relativeTime: _relativeTime(item.createdAt),
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
        final boxes = await repository.getBoxes();
        final boxName =
            boxes
                .where((b) => b.id == boxIds.first)
                .map((b) => b.name)
                .firstOrNull ??
            '收藏夹';
        final deleteResult = await controller.deleteItem(
          item.id,
          mode: DeleteMode.removeFromBox,
          boxId: boxIds.first,
          boxName: boxName,
        );
        if (!context.mounted) return;
        if (deleteResult.undo != null) {
          _showUndoSnackBar(
            context,
            deleteResult.message ?? '已从「$boxName」中移除',
            () async {
              await deleteResult.undo!.execute();
            },
          );
        }
      }
      return;
    }

    // Full delete
    final deleteResult = await controller.deleteItem(
      item.id,
      mode: DeleteMode.fullDelete,
    );
    if (!context.mounted) return;
    if (deleteResult.undo != null) {
      _showUndoSnackBar(
        context,
        deleteResult.message ?? '已删除「$displayTitle」',
        () async {
          await deleteResult.undo!.execute();
        },
      );
    }
  }

  // --- Helpers (duplicated from SavedItemCard for standalone access) ---

  static String _domainOf(String url) {
    final host = Uri.tryParse(url)?.host;
    if (host == null || host.isEmpty) return url;
    return host.startsWith('www.') ? host.substring(4) : host;
  }

  static String _relativeTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inHours < 1) return '${diff.inMinutes} 分钟前';
    if (diff.inDays < 1) return '${diff.inHours} 小时前';
    if (diff.inDays < 7) return '${diff.inDays} 天前';
    return '${dt.month}月${dt.day}日';
  }

  static IconData _iconFor(MediaType mediaType) {
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

  static void _showUndoSnackBar(
    BuildContext context,
    String message,
    VoidCallback onUndo,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(label: '撤销', onPressed: onUndo),
      ),
    );
  }
}

enum _CardAction { open, folder, copy, archive, delete }

/// Compact box assignment icon button for the card right column.
class _CompactBoxButton extends ConsumerWidget {
  const _CompactBoxButton({required this.itemId});

  final int itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 28,
      height: 28,
      child: IconButton(
        tooltip: '分配到收藏夹',
        icon: const Icon(Icons.folder_outlined, size: 16),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 28, height: 28),
        style: IconButton.styleFrom(
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          foregroundColor: colorScheme.onSurfaceVariant,
        ),
        onPressed: () => _showBoxMenu(context, ref),
      ),
    );
  }

  static const _inboxValue = -1;

  Future<void> _showBoxMenu(BuildContext context, WidgetRef ref) async {
    final repository = ref.read(collectionsRepositoryProvider);
    final boxes = await repository.getBoxes();
    final currentBoxIds = await repository.getBoxIdsForItem(itemId);
    final currentSet = currentBoxIds.toSet();

    if (!context.mounted) return;

    final selection = await showMenu<int>(
      context: context,
      position: RelativeRect.fromLTRB(1000, 80, 1000, 80),
      items: [
        PopupMenuItem<int>(
          value: _inboxValue,
          child: Row(
            children: [
              Icon(currentSet.isEmpty ? Icons.check : null, size: 18),
              const SizedBox(width: 8),
              const Text('待整理（不分配到收藏夹）'),
            ],
          ),
        ),
        if (boxes.isNotEmpty) const PopupMenuDivider(),
        for (final box in boxes)
          PopupMenuItem<int>(
            value: box.id,
            child: Row(
              children: [
                Icon(
                  currentSet.contains(box.id)
                      ? Icons.check_box_rounded
                      : Icons.check_box_outline_blank_rounded,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(box.name),
              ],
            ),
          ),
      ],
    );

    if (selection == null || !context.mounted) return;

    if (selection == _inboxValue) {
      await repository.setItemBoxes(itemId, const {});
      await repository.updateInboxState(itemId, true);
    } else if (currentSet.contains(selection)) {
      final next = {...currentSet}..remove(selection);
      await repository.setItemBoxes(itemId, next);
      if (next.isEmpty) {
        await repository.updateInboxState(itemId, true);
      }
    } else {
      final next = {...currentSet, selection};
      await repository.setItemBoxes(itemId, next);
      await repository.updateInboxState(itemId, false);
    }

    if (!context.mounted) return;
    // Defer invalidation to next frame so showMenu's popup elements
    // are fully deactivated before the parent rebuilds.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(savedItemsPageProvider);
    });
  }
}

class _BoxMiniChip extends StatelessWidget {
  const _BoxMiniChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: AppFontTokens.mini,
          color: colorScheme.onPrimaryContainer,
          height: 1.4,
        ),
      ),
    );
  }
}
