import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uni_hub/src/core/database/app_database.dart';
import 'package:uni_hub/src/core/theme/app_tokens.dart';
import 'package:uni_hub/src/plugins/collections/application/saved_item_detail_vm.dart';
import 'package:uni_hub/src/plugins/collections/application/saved_item_undo_snapshot.dart';
import 'package:uni_hub/src/plugins/collections/domain/consumption_status.dart';
import 'package:uni_hub/src/plugins/collections/domain/enrichment_status.dart';
import 'package:uni_hub/src/plugins/collections/domain/media_type.dart';
import 'package:uni_hub/src/plugins/collections/domain/source_platform.dart';
import 'package:uni_hub/src/plugins/collections/providers/collections_providers.dart';
import 'package:uni_hub/src/plugins/collections/ui/widgets/create_collection_folder_dialog.dart';
import 'package:uni_hub/src/shared/crud/crud.dart';
import 'package:uni_hub/src/shared/preferences/delete_confirm_prefs_provider.dart';
import 'package:uni_hub/src/shared/tags/providers/tags_providers.dart';
import 'package:uni_hub/src/shared/tags/tag_models.dart';
import 'package:uni_hub/src/shared/widgets/entity_picker/app_entity_picker.dart';
import 'package:uni_hub/src/shared/widgets/app_pill_chip.dart';
import 'package:uni_hub/src/shared/widgets/app_toast.dart';
import 'package:uni_hub/src/shared/widgets/delete_confirm_dialog.dart';
import 'package:uni_hub/src/shared/widgets/tags/app_tag_chip.dart';
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
/// Listens to [selectedSavedItemDetailProvider] internally so both the
/// desktop detail panel and the mobile bottom sheet always show the
/// latest data, regardless of how the panel was opened.
class SavedItemDetailPanel extends ConsumerStatefulWidget {
  const SavedItemDetailPanel({required this.itemId, super.key});

  final int itemId;

  @override
  ConsumerState<SavedItemDetailPanel> createState() =>
      _SavedItemDetailPanelState();
}

class _SavedItemDetailPanelState extends ConsumerState<SavedItemDetailPanel> {
  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(
      selectedSavedItemDetailProvider(widget.itemId),
    );
    return detailAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Text(
          '无法加载详情',
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ),
      data: (detail) => _buildDetail(context, ref, detail),
    );
  }

  // ---------------------------------------------------------------
  // Detail layout — six sections
  // ---------------------------------------------------------------

  Widget _buildDetail(BuildContext context, WidgetRef ref, SavedItemDetailVm detail) {
    final item = detail.item;
    final boxes = detail.boxes;
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
            _buildOrganizeSection(theme, colorScheme, item, boxes),
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
                  onPressed: () => _showToast('星标功能稍后接入'),
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
                  onPressed: () => _showToast('星标功能稍后接入'),
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
    List<CollectionBoxesTableData> boxes,
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
          _TagsSection(item: item),
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
                unawaited(_copyLink(item.id));
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
                    final result = await controller.updateStatus(
                      item.id,
                      status,
                    );
                    if (!mounted) return;
                    ref.read(crudFeedbackCoordinatorProvider).handle(
                      context,
                      result,
                    );
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
                  onTap: () => _showToast('分享功能稍后接入'),
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
    ref.read(crudFeedbackCoordinatorProvider).handle(context, result);
  }

  Future<void> _copyLink(int itemId) async {
    final controller = ref.read(savedItemActionsControllerProvider);
    final result = await controller.copyUrl(itemId);
    if (!mounted) return;
    ref.read(crudFeedbackCoordinatorProvider).handle(context, result);
  }

  Future<void> _deleteItem(int itemId) async {
    final repository = ref.read(collectionsRepositoryProvider);
    final item = await repository.getSavedItem(itemId);
    if (item == null) return;

    final prefsAsync = ref.read(deleteConfirmPrefsProvider);
    final prefs = prefsAsync.valueOrNull;
    if (prefs == null) return;

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
        ref.read(crudFeedbackCoordinatorProvider).handle(context, deleteResult);
      }
      return;
    }

    // Full delete
    final deleteResult = await controller.deleteItem(itemId);
    if (!mounted) return;
    ref.read(crudFeedbackCoordinatorProvider).handle(context, deleteResult);
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
    ref.read(crudFeedbackCoordinatorProvider).handle(context, result);
  }

  Future<void> _showBoxMenu(int itemId) async {
    final controller = ref.read(savedItemActionsControllerProvider);
    final coordinator = ref.read(crudFeedbackCoordinatorProvider);
    final repository = ref.read(collectionsRepositoryProvider);

    final boxes = await repository.getBoxes();
    final currentBoxIds = await repository.getBoxIdsForItem(itemId);
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (_) => AppEntityPicker<CollectionBoxesTableData>(
        title: '添加到收藏夹',
        searchHint: '搜索收藏夹',
        items: boxes,
        selectedIds: currentBoxIds.toSet(),
        itemLabel: (b) => b.name,
        itemId: (b) => b.id,
        allowCreate: true,
        onToggle: (box, selected) async {
          final current = await repository.getBoxIdsForItem(itemId);
          final next = Set<int>.from(current);
          if (selected) {
            next.add(box.id);
          } else {
            next.remove(box.id);
          }
          final result = await controller.assignBoxes(itemId, next);
          if (mounted) {
            coordinator.handle(context, result);
          }
        },
        onCreate: (name) async {
          final boxCtrl = ref.read(collectionBoxActionsControllerProvider);
          final result = await boxCtrl.createBox(name);
          if (mounted) {
            coordinator.handle(context, result);
          }
          return result;
        },
      ),
    );
  }

  void _showToast(String message) {
    AppToast.show(context, message: message);
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
              AppToast.show(context, message: result.message ?? '');
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
  const _TagsSection({required this.item});

  final SavedItemsTableData item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tagsAsync = ref.watch(tagsForSavedItemProvider(item.id));
    final tags = tagsAsync.valueOrNull ?? const [];

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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxVisible = constraints.maxWidth < 260 ? 4 : 6;
                final visible = tags.take(maxVisible).toList();

                return Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    for (final tag in visible)
                      AppTagChip.fromTag(
                        tag: tag,
                        compact: true,
                        onTap: () => _removeTag(context, ref, tag.id),
                      ),
                    if (tags.length > maxVisible)
                      Text(
                        '+${tags.length - maxVisible}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    _AddTagButton(itemId: item.id),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _removeTag(BuildContext context, WidgetRef ref, int tagId) async {
    final controller = ref.read(tagActionsControllerProvider);
    final coordinator = ref.read(crudFeedbackCoordinatorProvider);
    final result = await controller.removeTagFromSavedItem(
      savedItemId: item.id,
      tagId: tagId,
    );
    if (!context.mounted) return;
    coordinator.handle(context, result);
  }
}

/// Add-tag button inside [_TagsSection].
class _AddTagButton extends ConsumerWidget {
  const _AddTagButton({required this.itemId});

  final int itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => _openPicker(context, ref),
      child: Container(
        height: 24,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, size: 14, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 2),
            Text(
              '添加标签',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openPicker(BuildContext context, WidgetRef ref) async {
    final tagsDao = ref.read(tagsDaoProvider);
    final controller = ref.read(tagActionsControllerProvider);
    final coordinator = ref.read(crudFeedbackCoordinatorProvider);

    final allTags = await tagsDao.getAllTags();
    final currentTags = await tagsDao.getTagsForSavedItem(itemId);
    final currentIds = currentTags.map((t) => t.id as Object).toSet();
    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (_) => AppEntityPicker<AppTag>(
        title: '添加标签',
        searchHint: '搜索标签或创建新标签',
        items: allTags,
        selectedIds: currentIds,
        itemLabel: (tag) => tag.name,
        itemId: (tag) => tag.id,
        allowCreate: true,
        createLabelBuilder: (input) => '创建标签「$input」',
        onToggle: (tag, selected) async {
          final result = selected
              ? await controller.addTagToSavedItem(
                  savedItemId: itemId,
                  tagName: tag.name,
                )
              : await controller.removeTagFromSavedItem(
                  savedItemId: itemId,
                  tagId: tag.id,
                );
          if (context.mounted) {
            coordinator.handle(context, result);
          }
        },
        onCreate: (name) async {
          final result = await controller.createTag(name);
          if (context.mounted) {
            coordinator.handle(context, result);
          }
          if (result.success && result.data != null) {
            return result.data;
          }
          return null;
        },
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
                    final maxVisibleItems = constraints.maxWidth < 260 ? 3 : 4;
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
                                unawaited(
                                  controller.removeFromBox(item.id, box.id),
                                );
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
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colorScheme.error),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createBox(BuildContext context, WidgetRef ref) async {
    final boxes = ref.read(collectionBoxesProvider).valueOrNull ?? const [];
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => CreateCollectionFolderDialog(
        existingNames: boxes.map((box) => box.name),
      ),
    );
    if (name == null || name.isEmpty) return;
    final controller = ref.read(collectionBoxActionsControllerProvider);
    final result = await controller.createBox(name);
    if (!context.mounted) return;
    ref.read(crudFeedbackCoordinatorProvider).handle(context, result);
    if (result.success) {
      ref.invalidate(collectionBoxesProvider);
    }
  }
}
