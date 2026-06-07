import 'dart:async';

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
import 'package:uni_hub/src/shared/widgets/app_pill_chip.dart';
import 'package:uni_hub/src/shared/widgets/app_toast.dart';
import 'package:uni_hub/src/shared/widgets/delete_confirm_dialog.dart';
import 'package:uni_hub/src/shared/widgets/website_logo.dart';

/// Full detail panel for a selected saved item entry.
///
/// Layout structure:
/// A. 内容身份卡 — prominent identity card with gradient, icon, title, source
/// B. 主操作行 — open original page, favorite
/// C. 整理信息区 — source, status, box, tags, notes (light dividers)
/// D. 内容补充区 — content tabs (weaker visual weight)
/// E. 技术信息区 — collapsed at bottom
///
/// Uses the [entry]'s pre-aggregated boxes instead of querying
/// [selectedSavedItemEntryProvider], ensuring data consistency with
/// the list that opened this panel.
class SavedItemDetailPanel extends ConsumerStatefulWidget {
  const SavedItemDetailPanel({required this.entry, super.key});

  final SavedItemListEntry entry;

  /// Convenience accessor for the underlying saved item.
  SavedItemsTableData get item => entry.item;

  @override
  ConsumerState<SavedItemDetailPanel> createState() =>
      _SavedItemDetailPanelState();
}

class _SavedItemDetailPanelState extends ConsumerState<SavedItemDetailPanel> {
  static const _inboxBoxValue = -1;

  /// 当前选中项的数据。使用 getter 而非 late final，
  /// 确保每次 build 都读到最新的 widget.entry，
  /// 避免点击不同卡片后右侧详情仍显示旧数据。
  SavedItemsTableData get item => widget.entry.item;
  List<CollectionBoxesTableData> get boxes => widget.entry.boxes;

  @override
  Widget build(BuildContext context) {
    return _buildDetail(context, ref);
  }

  // ---------------------------------------------------------------
  // Detail layout — six sections
  // ---------------------------------------------------------------

  Widget _buildDetail(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mediaType = MediaType.fromValue(item.mediaType);
    final platform = SourcePlatform.fromValue(item.sourcePlatform);

    // Read local logo path from cache (non-blocking, shows fallback when null)
    final logoAsync = ref.watch(websiteLogoForUrlProvider(item.normalizedUrl));
    final localLogoPath = logoAsync.valueOrNull?.localLogoPath;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
        boxShadow: const [AppShadows.cardSoft],
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildContentIdentity(
              theme,
              colorScheme,
              item,
              mediaType,
              platform,
              localLogoPath,
            ),
            _buildTopActionRow(theme, colorScheme, item),
            _plainDivider(colorScheme),
            _buildOrganizeSection(theme, colorScheme, item),
            _sectionDivider(colorScheme),
            _buildNotesBridgeSection(theme, colorScheme),
            _sectionDivider(colorScheme),
            _buildTimelineSection(theme, colorScheme, item),
            _sectionDivider(colorScheme),
            _buildQuickActionsSection(theme, colorScheme, item),
          ],
        ),
      ),
    );
  }

  // ===============================================================
  // A. Content Identity Card — prominent blue-tinted card
  // ===============================================================

  Widget _buildContentIdentity(
    ThemeData theme,
    ColorScheme colorScheme,
    SavedItemsTableData item,
    MediaType mediaType,
    SourcePlatform platform,
    String? localLogoPath,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 360;
          final tileSize = compact ? 56.0 : 64.0;
          final iconSize = compact ? 28.0 : 32.0;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WebsiteLogo(
                localPath: localLogoPath,
                fallbackIcon: _iconFor(mediaType),
                size: tileSize,
                iconSize: iconSize,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title.isEmpty ? item.normalizedUrl : item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: AppFontTokens.bold,
                        height: 1.28,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '${platform.label} · ${mediaType.label} · ${_relativeTime(item.createdAt)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              SizedBox(
                width: 34,
                height: 34,
                child: IconButton(
                  tooltip: '星标功能稍后接入',
                  icon: const Icon(Icons.star_rounded, size: 20),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  style: IconButton.styleFrom(
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: colorScheme.tertiary,
                  ),
                  onPressed: () => _showSnackBar('星标功能稍后接入'),
                ),
              ),
              SizedBox(
                width: 34,
                height: 34,
                child: IconButton(
                  tooltip: '在浏览器中打开',
                  icon: const Icon(Icons.open_in_new_rounded, size: 19),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  style: IconButton.styleFrom(
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: colorScheme.primary,
                  ),
                  onPressed: () => _openAndMark(item),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ===============================================================
  // B. Top Action Row
  // ===============================================================

  Widget _buildTopActionRow(
    ThemeData theme,
    ColorScheme colorScheme,
    SavedItemsTableData item,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 320;
          return Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _openAndMark(item),
                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                  label: Text(compact ? '打开网页' : '打开原网页'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
                    textStyle: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: AppFontTokens.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              SizedBox(
                width: AppSizes.buttonHeight,
                height: AppSizes.buttonHeight,
                child: IconButton(
                  tooltip: '星标功能稍后接入',
                  icon: const Icon(Icons.star_border_rounded, size: 22),
                  style: IconButton.styleFrom(
                    foregroundColor: colorScheme.onSurfaceVariant,
                    backgroundColor: colorScheme.surface,
                    side: BorderSide(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.7),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                  ),
                  onPressed: () => _showSnackBar('星标功能稍后接入'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ===============================================================
  // C. Organize Info Section — white bg + light dividers
  // ===============================================================

  Widget _buildOrganizeSection(
    ThemeData theme,
    ColorScheme colorScheme,
    SavedItemsTableData item,
  ) {
    return Container(
      width: double.infinity,
      color: colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLinkSection(theme, colorScheme, item),
          _sectionDivider(colorScheme),
          _buildStatusSection(theme, colorScheme, item),
          _sectionDivider(colorScheme),
          _BoxSection(item: item, currentBoxes: boxes),
          _sectionDivider(colorScheme),
          _TagsSection(item: item, boxes: boxes),
          _sectionDivider(colorScheme),
          _EnrichmentStatusSection(item: item),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------
  // C.1 Source Link
  // ---------------------------------------------------------------

  Widget _buildLinkSection(
    ThemeData theme,
    ColorScheme colorScheme,
    SavedItemsTableData item,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 64,
            child: Text(
              '来源',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: AppFontTokens.medium,
              ),
            ),
          ),
          Expanded(
            child: Text(
              item.originalUrl,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: AppFontTokens.medium,
                decoration: TextDecoration.underline,
                decorationColor: colorScheme.primary.withValues(alpha: 0.35),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          SizedBox(
            width: 28,
            height: 28,
            child: IconButton(
              tooltip: '复制链接',
              icon: const Icon(Icons.content_copy_rounded, size: 16),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              style: IconButton.styleFrom(
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: colorScheme.onSurfaceVariant,
              ),
              onPressed: () {
                _copyLink(item.id);
              },
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------
  // C.2 Status — AppPillChip
  // ---------------------------------------------------------------

  Widget _buildStatusSection(
    ThemeData theme,
    ColorScheme colorScheme,
    SavedItemsTableData item,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 64,
            child: Text(
              '状态',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: AppFontTokens.medium,
              ),
            ),
          ),
          Expanded(
            child: Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: ConsumptionStatus.values.map((status) {
                final isSelected =
                    ConsumptionStatus.fromValue(item.status) == status;
                return AppPillChip(
                  label: _statusLabel(status),
                  selected: isSelected,
                  onTap: () async {
                    final controller = ref.read(
                      savedItemActionsControllerProvider,
                    );
                    await controller.updateStatus(item.id, status);
                  },
                  compact: true,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesBridgeSection(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 64,
            child: Text(
              '备注',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: AppFontTokens.medium,
              ),
            ),
          ),
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 72),
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.7),
                ),
              ),
              child: Text(
                '暂未关联笔记、想法或 Todo。',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineSection(
    ThemeData theme,
    ColorScheme colorScheme,
    SavedItemsTableData item,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: _InfoTile(
              icon: Icons.access_time_rounded,
              label: '收藏时间',
              value: _formatDateTime(item.createdAt),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _InfoTile(
              icon: Icons.history_rounded,
              label: '最后访问',
              value: item.lastOpenedAt == null
                  ? '尚未访问'
                  : _formatDateTime(item.lastOpenedAt!),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection(
    ThemeData theme,
    ColorScheme colorScheme,
    SavedItemsTableData item,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '快速操作',
            style: theme.textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: AppFontTokens.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _QuickActionTile(
                  icon: Icons.content_copy_rounded,
                  label: '复制链接',
                  onTap: () => _copyLink(item.id),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: _QuickActionTile(
                  icon: Icons.share_outlined,
                  label: '分享',
                  onTap: () => _showSnackBar('分享功能稍后接入'),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: _QuickActionTile(
                  icon: Icons.folder_outlined,
                  label: '移动',
                  onTap: () => _showBoxMenu(item.id),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: _QuickActionTile(
                  icon: Icons.archive_outlined,
                  label: '归档',
                  onTap: () => _archiveItem(item.id),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: _QuickActionTile(
                  icon: Icons.delete_outline_rounded,
                  label: '删除',
                  destructive: true,
                  onTap: () => _deleteItem(item.id),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------
  // Shared helpers
  // ---------------------------------------------------------------

  Widget _plainDivider(ColorScheme colorScheme) => Divider(
    height: 1,
    thickness: 1,
    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
  );

  Widget _sectionDivider(ColorScheme colorScheme) => Divider(
    height: 1,
    thickness: 1,
    indent: AppSpacing.lg,
    endIndent: AppSpacing.lg,
    color: colorScheme.outlineVariant.withValues(alpha: 0.28),
  );

  String _relativeTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inHours < 1) return '${diff.inMinutes} 分钟前';
    if (diff.inDays < 1) return '${diff.inHours} 小时前';
    if (diff.inDays < 30) return '${diff.inDays} 天前';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()} 个月前';

    return '${(diff.inDays / 365).floor()} 年前';
  }

  String _formatDateTime(DateTime dt) {
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    return '${dt.year}-${twoDigits(dt.month)}-${twoDigits(dt.day)} '
        '${twoDigits(dt.hour)}:${twoDigits(dt.minute)}';
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

  String _statusLabel(ConsumptionStatus status) {
    return switch (status) {
      ConsumptionStatus.unread => '待看',
      ConsumptionStatus.inProgress => '阅读中',
      ConsumptionStatus.done => '已看',
      ConsumptionStatus.archived => '归档',
    };
  }

  Future<void> _openAndMark(SavedItemsTableData item) async {
    final controller = ref.read(savedItemActionsControllerProvider);
    final result = await controller.openItem(item.id);
    if (!mounted) return;
    if (!result.success && result.message != null) {
      _showSnackBar(result.message!);
    }
  }

  Future<void> _copyLink(int itemId) async {
    final controller = ref.read(savedItemActionsControllerProvider);
    final result = await controller.copyUrl(itemId);
    if (!mounted) return;
    _showSnackBar(result.message ?? '已复制链接');
  }

  Future<void> _deleteItem(int itemId) async {
    final item = this.item;

    final prefsAsync = ref.read(deleteConfirmPrefsProvider);
    final prefs = prefsAsync.valueOrNull;
    if (prefs == null) return;

    final repository = ref.read(collectionsRepositoryProvider);
    final controller = ref.read(savedItemActionsControllerProvider);
    final boxIds = await repository.getBoxIdsForItem(itemId);
    final boxes = boxIds.isNotEmpty
        ? await repository.getBoxes()
        : <CollectionBoxesTableData>[];
    if (!mounted) return;

    final boxNames = boxes
        .where((b) => boxIds.contains(b.id))
        .map((b) => b.name)
        .toList();

    final mediaType = MediaType.fromValue(item.mediaType);
    final platform = SourcePlatform.fromValue(item.sourcePlatform);

    DeleteConfirmResult? result;

    if (boxNames.length > 1) {
      result = await DeleteConfirmDialog.showMultiBox(
        context: context,
        title: item.title.isEmpty ? item.normalizedUrl : item.title,
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
        title: item.title.isEmpty ? item.normalizedUrl : item.title,
        source: item.siteName?.isNotEmpty == true
            ? item.siteName!
            : _domainOf(item.normalizedUrl),
        typeLabel: platform.label,
        relativeTime: _relativeTime(item.createdAt),
        fallbackIcon: _iconFor(mediaType),
        prefs: prefs,
      );
    }

    if (result == null || result == DeleteConfirmResult.cancel || !mounted) {
      return;
    }

    final displayTitle = item.title.isEmpty ? item.normalizedUrl : item.title;

    if (result == DeleteConfirmResult.removeFromBox) {
      if (boxIds.isNotEmpty) {
        final currentBoxName = boxNames.isNotEmpty ? boxNames.first : '收藏夹';
        final deleteResult = await controller.deleteItem(
          itemId,
          mode: DeleteMode.removeFromBox,
          boxId: boxIds.first,
          boxName: currentBoxName,
        );
        if (!mounted) return;
        if (deleteResult.undo != null) {
          _showUndoSnackBar(
            context,
            deleteResult.message ?? '已从「$currentBoxName」中移除',
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
      itemId,
    );
    if (!mounted) return;
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

  String _domainOf(String url) {
    final host = Uri.tryParse(url)?.host;
    if (host == null || host.isEmpty) return url;
    return host.startsWith('www.') ? host.substring(4) : host;
  }

  Future<void> _archiveItem(int itemId) async {
    final controller = ref.read(savedItemActionsControllerProvider);
    final result = await controller.archiveItem(itemId);
    if (!mounted) return;
    if (result.message != null) {
      _showSnackBar(result.message!);
    }
  }

  Future<void> _showBoxMenu(int itemId) async {
    final repository = ref.read(collectionsRepositoryProvider);
    final controller = ref.read(savedItemActionsControllerProvider);
    final boxes = await repository.getBoxes();
    final currentBoxIds = await repository.getBoxIdsForItem(itemId);
    final currentSet = currentBoxIds.toSet();

    if (!mounted) return;

    final selection = await showMenu<int>(
      context: context,
      position: const RelativeRect.fromLTRB(1000, 80, 1000, 80),
      items: [
        PopupMenuItem<int>(
          value: _inboxBoxValue,
          child: Row(
            children: [
              Icon(currentSet.isEmpty ? Icons.check : null, size: 18),
              const SizedBox(width: AppSpacing.xs),
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
                const SizedBox(width: AppSpacing.xs),
                Text(box.name),
              ],
            ),
          ),
      ],
    );

    if (selection == null || !mounted) return;

    if (selection == _inboxBoxValue) {
      await controller.assignBoxes(itemId, const {});
    } else if (currentSet.contains(selection)) {
      final next = {...currentSet}..remove(selection);
      await controller.assignBoxes(itemId, next);
    } else {
      final next = {...currentSet, selection};
      await controller.assignBoxes(itemId, next);
    }
  }

  void _showSnackBar(String message) {
    AppToast.show(
      context,
      message: message,
    );
  }

  /// Show a 5-second undo Toast with AppToast.
  static void _showUndoSnackBar(
    BuildContext context,
    String message,
    FutureOr<void> Function() onUndo,
  ) {
    AppToast.undo(
      context,
      message: message,
      onUndo: onUndo,
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      constraints: const BoxConstraints(minHeight: 58),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: AppFontTokens.medium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final foreground = destructive ? colorScheme.error : colorScheme.primary;
    final surface = destructive
        ? colorScheme.errorContainer.withValues(alpha: 0.24)
        : colorScheme.surfaceContainerLow;

    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 58),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xxs,
              vertical: AppSpacing.xs,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20, color: foreground),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: destructive
                        ? colorScheme.error
                        : colorScheme.onSurfaceVariant,
                    fontWeight: AppFontTokens.medium,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ===============================================================
// Enrichment Status Section
// ===============================================================

class _EnrichmentStatusSection extends ConsumerWidget {
  const _EnrichmentStatusSection({required this.item});

  final SavedItemsTableData item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final enrichmentStatus = EnrichmentStatus.fromValue(item.enrichmentStatus);

    if (enrichmentStatus != EnrichmentStatus.failed) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 64,
            child: Text(
              '抓取',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: AppFontTokens.medium,
              ),
            ),
          ),
          GestureDetector(
            onTap: () async {
              final controller = ref.read(savedItemActionsControllerProvider);
              final result = await controller.retryEnrichment(item.id);
              if (!context.mounted) return;
              AppToast.show(
                context,
                message: result.message ?? '',
              );
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 16,
                  color: colorScheme.error,
                ),
                const SizedBox(width: AppSpacing.xxs),
                Text(
                  '抓取失败 · 重试',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.error,
                    fontWeight: AppFontTokens.medium,
                    decoration: TextDecoration.underline,
                    decorationColor: colorScheme.error.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ===============================================================
// Tags Section
// ===============================================================

class _TagsSection extends ConsumerWidget {
  const _TagsSection({required this.item, this.boxes = const []});

  final SavedItemsTableData item;
  final List<CollectionBoxesTableData> boxes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mediaType = MediaType.fromValue(item.mediaType);
    final platform = SourcePlatform.fromValue(item.sourcePlatform);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 64,
            child: Text(
              '标签',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: AppFontTokens.medium,
              ),
            ),
          ),
          Expanded(
            child: Builder(
              builder: (context) {
                final rawLabels = <String>[
                  for (final box in boxes) box.name,
                  mediaType.label,
                  platform.label,
                ];

                final labels = <String>[];
                for (final label in rawLabels) {
                  final normalized = label.trim();
                  if (normalized.isEmpty) continue;
                  if (normalized == '未知') continue;
                  if (labels.contains(normalized)) continue;
                  labels.add(normalized);
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final maxVisibleLabels = constraints.maxWidth < 260
                        ? 3
                        : 4;
                    final visibleLabels = labels
                        .take(maxVisibleLabels)
                        .toList();

                    return Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        for (final label in visibleLabels)
                          AppPillChip(
                            label: label,
                            selected: false,
                            compact: true,
                          ),
                        AppPillChip(
                          label: '+ 添加标签',
                          selected: false,
                          compact: true,
                          icon: Icons.add_rounded,
                          onTap: () {
                            AppToast.show(
                              context,
                              message: '标签功能稍后接入',
                            );
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ===============================================================
// Box Section
// ===============================================================

class _BoxSection extends ConsumerWidget {
  const _BoxSection({required this.item, this.currentBoxes = const []});

  final SavedItemsTableData item;
  final List<CollectionBoxesTableData> currentBoxes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final boxesAsync = ref.watch(collectionBoxesProvider);
    final currentBoxIds = currentBoxes.map((b) => b.id).toSet();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 64,
            child: Text(
              '收藏夹',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: AppFontTokens.medium,
              ),
            ),
          ),
          Expanded(
            child: boxesAsync.when(
              data: (boxes) {
                if (boxes.isEmpty) {
                  return Row(
                    children: [
                      Text(
                        '暂无收藏夹',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      TextButton.icon(
                        onPressed: () => _createBox(context, ref),
                        icon: const Icon(Icons.add_rounded, size: 14),
                        label: const Text('新建收藏夹'),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          foregroundColor: colorScheme.primary,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                          ),
                        ),
                      ),
                    ],
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final selectedBoxes = boxes
                        .where((box) => currentBoxIds.contains(box.id))
                        .toList();
                    final maxVisibleItems = constraints.maxWidth < 260
                        ? 3
                        : 4;
                    final visibleBoxes = selectedBoxes
                        .take(maxVisibleItems)
                        .toList();

                    return Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        if (visibleBoxes.isEmpty)
                          const AppPillChip(
                            label: '待整理',
                            selected: true,
                            compact: true,
                          )
                        else
                          for (final box in visibleBoxes)
                            AppPillChip(
                              label: box.name,
                              selected: true,
                              compact: true,
                              onTap: () {
                                final controller = ref.read(
                                  savedItemActionsControllerProvider,
                                );
                                controller.removeFromBox(item.id, box.id);
                              },
                            ),
                        AppPillChip(
                          label: '+ 新建',
                          selected: false,
                          compact: true,
                          icon: Icons.add_rounded,
                          onTap: () => _createBox(context, ref),
                        ),
                      ],
                    );
                  },
                );
              },
              loading: () => const LinearProgressIndicator(minHeight: 2),
              error: (e, _) => Text(
                '加载收藏夹失败：$e',
                style: TextStyle(color: colorScheme.error),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createBox(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('新建收藏夹'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '收藏夹名称'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx, controller.text.trim());
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    await ref.read(collectionsRepositoryProvider).createBox(name);
    // Defer invalidation to next frame so the dialog's elements
    // (e.g. InputDecorator with active tickers) are fully deactivated
    // before the parent rebuilds. Without this, Flutter asserts
    // "Tried to build dirty widget in the wrong build scope".
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(collectionBoxesProvider);
    });
  }
}
