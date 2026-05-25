import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uni_hub/src/core/database/app_database.dart';
import 'package:uni_hub/src/core/theme/app_tokens.dart';
import 'package:uni_hub/src/plugins/collections/domain/consumption_status.dart';
import 'package:uni_hub/src/plugins/collections/domain/media_type.dart';
import 'package:uni_hub/src/plugins/collections/domain/source_platform.dart';
import 'package:uni_hub/src/plugins/collections/providers/collections_providers.dart';
import 'package:uni_hub/src/shared/widgets/app_pill_chip.dart';
import 'package:uni_hub/src/shared/widgets/website_logo.dart';

/// Full detail panel for a selected [SavedItemsTableData].
///
/// Layout structure:
/// A. 内容身份卡 — prominent identity card with gradient, icon, title, source
/// B. 主操作行 — open original page, favorite
/// C. 整理信息区 — source, status, box, tags, notes (light dividers)
/// D. 内容补充区 — content tabs (weaker visual weight)
/// E. 技术信息区 — collapsed at bottom
class SavedItemDetailPanel extends ConsumerStatefulWidget {
  const SavedItemDetailPanel({required this.item, super.key});

  final SavedItemsTableData? item;

  @override
  ConsumerState<SavedItemDetailPanel> createState() =>
      _SavedItemDetailPanelState();
}

class _SavedItemDetailPanelState extends ConsumerState<SavedItemDetailPanel> {
  static const _inboxBoxValue = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.item == null) return _buildEmpty(context);
    return _buildDetail(context, ref);
  }

  // ---------------------------------------------------------------
  // Empty state
  // ---------------------------------------------------------------

  Widget _buildEmpty(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 260),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.bookmark_outline_rounded,
                size: 48,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                '选择一条收藏',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '从左侧列表选择一条收藏，\n在这里查看详情和整理。',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------
  // Detail layout — six sections
  // ---------------------------------------------------------------

  Widget _buildDetail(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final item = widget.item!;
    final mediaType = MediaType.fromValue(item.mediaType);
    final platform = SourcePlatform.fromValue(item.sourcePlatform);

    // Read local logo path from cache (non-blocking, shows fallback when null)
    final logoAsync = ref.watch(
      websiteLogoForUrlProvider(item.normalizedUrl),
    );
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
          _BoxSection(item: item),
          _sectionDivider(colorScheme),
          _TagsSection(item: item),
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
                _copyLink(item.originalUrl);
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
                    final repository = ref.read(collectionsRepositoryProvider);
                    await repository.updateStatus(item.id, status);
                    ref.invalidate(savedItemsListProvider);
                    ref.invalidate(collectionFolderCountsProvider);
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
                  onTap: () => _copyLink(item.originalUrl),
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
    final repository = ref.read(collectionsRepositoryProvider);
    await repository.markOpened(item.id);
    ref.invalidate(savedItemsListProvider);
    ref.invalidate(collectionFolderCountsProvider);
    if (!mounted) return;
    await _openUrl(item.originalUrl);
  }

  Future<void> _copyLink(String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    _showSnackBar('已复制链接');
  }

  Future<void> _deleteItem(int itemId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('删除后无法恢复，确定要删除这条收藏吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final repository = ref.read(collectionsRepositoryProvider);
    await repository.deleteSavedItem(itemId);
    ref.read(selectedSavedItemIdProvider.notifier).state = null;
    ref.invalidate(savedItemsListProvider);
    ref.invalidate(collectionFolderCountsProvider);
    if (!mounted) return;
    _showSnackBar('已删除');
  }

  Future<void> _archiveItem(int itemId) async {
    final repository = ref.read(collectionsRepositoryProvider);
    await repository.updateStatus(itemId, ConsumptionStatus.archived);
    ref.invalidate(savedItemsListProvider);
    ref.invalidate(collectionFolderCountsProvider);
    if (!mounted) return;
    _showSnackBar('已归档');
  }

  Future<void> _showBoxMenu(int itemId) async {
    final repository = ref.read(collectionsRepositoryProvider);
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

    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(savedItemsListProvider);
      ref.invalidate(collectionFolderCountsProvider);
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('无效的链接')));
      return;
    }
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('打开链接失败：$e')));
    }
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
// Tags Section
// ===============================================================

class _TagsSection extends ConsumerWidget {
  const _TagsSection({required this.item});

  final SavedItemsTableData item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final boxesAsync = ref.watch(collectionBoxesProvider);
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
            child: FutureBuilder<List<int>>(
              future: ref
                  .read(collectionsRepositoryProvider)
                  .getBoxIdsForItem(item.id),
              builder: (context, snapshot) {
                final boxIds = snapshot.data?.toSet() ?? const <int>{};
                return boxesAsync.when(
                  data: (boxes) {
                    final labels =
                        <String>[
                              for (final box in boxes)
                                if (boxIds.contains(box.id)) box.name,
                              mediaType.label,
                              platform.label,
                            ]
                            .where((label) => label.trim().isNotEmpty)
                            .take(4)
                            .toList();

                    return Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        for (final label in labels)
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
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('标签功能稍后接入')),
                            );
                          },
                        ),
                      ],
                    );
                  },
                  loading: () => const LinearProgressIndicator(minHeight: 2),
                  error: (error, stackTrace) => Text(
                    '标签加载失败：$error',
                    style: TextStyle(color: colorScheme.error),
                  ),
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
  const _BoxSection({required this.item});

  final SavedItemsTableData item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final boxesAsync = ref.watch(collectionBoxesProvider);

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
            child: FutureBuilder<List<int>>(
              future: ref
                  .read(collectionsRepositoryProvider)
                  .getBoxIdsForItem(item.id),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Text(
                    '加载中...',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  );
                }

                final currentBoxIds = snapshot.data!;
                final currentSet = currentBoxIds.toSet();

                return boxesAsync.when(
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

                    return Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        for (final box in boxes)
                          AppPillChip(
                            label: box.name,
                            selected: currentSet.contains(box.id),
                            compact: true,
                            onTap: () {
                              final repository = ref.read(
                                collectionsRepositoryProvider,
                              );
                              if (currentSet.contains(box.id)) {
                                final next = {...currentSet}..remove(box.id);
                                repository.setItemBoxes(item.id, next);
                                if (next.isEmpty) {
                                  repository.updateInboxState(item.id, true);
                                }
                              } else {
                                final next = {...currentSet, box.id};
                                repository.setItemBoxes(item.id, next);
                                if (currentSet.isEmpty) {
                                  repository.updateInboxState(item.id, false);
                                }
                              }
                              ref.invalidate(savedItemsListProvider);
                              ref.invalidate(collectionFolderCountsProvider);
                            },
                          ),
                        AppPillChip(
                          label: '+ 选择收藏夹',
                          selected: false,
                          compact: true,
                          icon: Icons.playlist_add_rounded,
                          onTap: () => _addBox(context, ref, boxes),
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
                  loading: () => const LinearProgressIndicator(minHeight: 2),
                  error: (e, _) => Text(
                    '加载收藏夹失败：$e',
                    style: TextStyle(color: colorScheme.error),
                  ),
                );
              },
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

  Future<void> _addBox(
    BuildContext context,
    WidgetRef ref,
    List<CollectionBoxesTableData> boxes,
  ) async {
    final repository = ref.read(collectionsRepositoryProvider);
    final currentBoxIds = await repository.getBoxIdsForItem(item.id);
    final currentSet = currentBoxIds.toSet();

    if (!context.mounted) return;

    final selected = await showMenu<int>(
      context: context,
      position: RelativeRect.fromLTRB(1000, 80, 1000, 80),
      items: boxes
          .where((b) => !currentSet.contains(b.id))
          .map(
            (b) => PopupMenuItem<int>(
              value: b.id,
              child: Row(
                children: [
                  const Icon(Icons.folder_outlined, size: 18),
                  const SizedBox(width: 8),
                  Text(b.name),
                ],
              ),
            ),
          )
          .toList(),
    );

    if (selected == null || !context.mounted) return;

    await repository.setItemBoxes(item.id, {...currentSet, selected});
    if (currentSet.isEmpty) {
      await repository.updateInboxState(item.id, false);
    }
    if (context.mounted) {
      // Defer invalidation to next frame so showMenu's popup elements
      // are fully deactivated before the parent rebuilds.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.invalidate(savedItemsListProvider);
        ref.invalidate(collectionFolderCountsProvider);
      });
    }
  }
}
