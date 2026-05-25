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

import 'collection_technical_info_section.dart';

/// Full detail panel for a selected [SavedItemsTableData].
///
/// Layout structure:
/// A. 内容身份卡 — prominent identity card with gradient, icon, title, source
/// B. 主操作行 — open original page, favorite
/// C. 整理信息区 — source, status, box, tags, notes (light dividers)
/// D. 内容补充区 — content tabs (weaker visual weight)
/// E. 技术信息区 — collapsed at bottom
/// F. 底部固定操作栏 — fixed bottom action bar
class SavedItemDetailPanel extends ConsumerStatefulWidget {
  const SavedItemDetailPanel({required this.item, super.key});

  final SavedItemsTableData? item;

  @override
  ConsumerState<SavedItemDetailPanel> createState() =>
      _SavedItemDetailPanelState();
}

class _SavedItemDetailPanelState extends ConsumerState<SavedItemDetailPanel>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // A. Content Identity Card
                  _buildContentIdentity(
                    theme,
                    colorScheme,
                    item,
                    mediaType,
                    platform,
                  ),
                  // B. Top Action Row
                  _buildTopActionRow(theme, colorScheme, item),
                  _plainDivider(colorScheme),
                  // C. Organize Info Section
                  _buildOrganizeSection(theme, colorScheme, item),
                  _plainDivider(colorScheme),
                  // D. Content Tabs
                  _buildContentTabs(theme, colorScheme, item),
                  // E. Technical Info (collapsed, bottom)
                  CollectionTechnicalInfoSection(item: item),
                ],
              ),
            ),
          ),
          // F. Bottom Fixed Action Bar
          _buildBottomActionBar(theme, colorScheme, item),
        ],
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
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xxs,
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primaryContainer.withValues(alpha: 0.30),
              colorScheme.surface,
            ],
          ),
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Large icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: _identityIconBg(colorScheme, mediaType),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                _iconFor(mediaType),
                size: 28,
                color: colorScheme.onPrimaryContainer.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Title + source
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
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    '${platform.label} · ${mediaType.label} · ${_relativeTime(item.createdAt)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            // Star + Open buttons
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: '星标功能稍后接入',
                  icon: const Icon(Icons.star_border_rounded, size: 20),
                  visualDensity: VisualDensity.compact,
                  style: IconButton.styleFrom(
                    foregroundColor: colorScheme.onSurfaceVariant,
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('星标功能稍后接入')),
                    );
                  },
                ),
                IconButton(
                  tooltip: '在浏览器中打开',
                  icon: const Icon(Icons.open_in_new_rounded, size: 20),
                  visualDensity: VisualDensity.compact,
                  style: IconButton.styleFrom(
                    foregroundColor: colorScheme.primary,
                  ),
                  onPressed: () => _openUrl(item.originalUrl),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _identityIconBg(ColorScheme colorScheme, MediaType mediaType) {
    return switch (mediaType) {
      MediaType.video => colorScheme.tertiaryContainer.withValues(alpha: 0.5),
      MediaType.repository => colorScheme.secondaryContainer.withValues(alpha: 0.5),
      MediaType.article => colorScheme.primaryContainer.withValues(alpha: 0.5),
      _ => colorScheme.primaryContainer.withValues(alpha: 0.5),
    };
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
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () async {
                final repository = ref.read(collectionsRepositoryProvider);
                await repository.markOpened(item.id);
                ref.invalidate(savedItemsListProvider);
                if (!mounted) return;
                await _openUrl(item.originalUrl);
              },
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: const Text('打开原网页', style: TextStyle(fontSize: 13)),
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                foregroundColor: colorScheme.primary,
                side: BorderSide(
                  color: colorScheme.primary.withValues(alpha: 0.4),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            tooltip: '星标功能稍后接入',
            icon: const Icon(Icons.star_border_rounded, size: 20),
            visualDensity: VisualDensity.compact,
            style: IconButton.styleFrom(
              foregroundColor: colorScheme.onSurfaceVariant,
              side: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.6),
              ),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('星标功能稍后接入')),
              );
            },
          ),
        ],
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
          _sectionDivider(colorScheme),
          _buildNotesSection(theme, colorScheme),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '来源',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: AppFontTokens.medium,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  item.originalUrl,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                    decoration: TextDecoration.underline,
                    decorationColor: colorScheme.primary.withValues(alpha: 0.35),
                  ),
                ),
              ],
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
                Clipboard.setData(ClipboardData(text: item.originalUrl));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('已复制链接')),
                );
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '状态',
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: AppFontTokens.medium,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
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
                },
                compact: true,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------
  // C.5 Notes — custom drawn note box
  // ---------------------------------------------------------------

  Widget _buildNotesSection(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '备注',
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: AppFontTokens.medium,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: double.infinity,
            height: 96,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.7),
              ),
            ),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Align(
              alignment: Alignment.topLeft,
              child: Text(
                '写下你收藏这条内容的想法或要点...',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.55),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '备注功能稍后接入',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
              Text(
                '0/500',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===============================================================
  // D. Content Tabs — weaker visual weight
  // ===============================================================

  Widget _buildContentTabs(
    ThemeData theme,
    ColorScheme colorScheme,
    SavedItemsTableData item,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: TabBar(
            controller: _tabController,
            isScrollable: false,
            labelColor: colorScheme.primary,
            unselectedLabelColor:
                colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            indicatorColor: colorScheme.primary.withValues(alpha: 0.5),
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorWeight: 2,
            labelStyle: theme.textTheme.labelMedium?.copyWith(
              fontSize: 12,
              fontWeight: AppFontTokens.semiBold,
            ),
            unselectedLabelStyle: theme.textTheme.labelMedium?.copyWith(
              fontSize: 12,
            ),
            onTap: (index) {
              setState(() {
                _tabIndex = index;
              });
            },
            tabs: const [
              Tab(text: '摘要'),
              Tab(text: '内容预览'),
              Tab(text: '笔记'),
              Tab(text: '相关'),
            ],
          ),
        ),
        _buildCurrentTabContent(theme, colorScheme, item),
      ],
    );
  }

  Widget _buildCurrentTabContent(
    ThemeData theme,
    ColorScheme colorScheme,
    SavedItemsTableData item,
  ) {
    return switch (_tabIndex) {
      0 => _buildSummaryTab(theme, colorScheme, item),
      1 => _buildPreviewTab(theme, colorScheme, item),
      2 => _buildPlaceholderTab(theme, colorScheme, '笔记功能稍后接入'),
      3 => _buildPlaceholderTab(theme, colorScheme, '相关想法 / 待办 / 笔记稍后接入'),
      _ => const SizedBox.shrink(),
    };
  }

  // Summary tab
  Widget _buildSummaryTab(
    ThemeData theme,
    ColorScheme colorScheme,
    SavedItemsTableData item,
  ) {
    final hasDescription =
        item.description != null && item.description!.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: hasDescription
          ? Text(
              item.description!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
                height: 1.6,
              ),
            )
          : Text(
              '暂无摘要',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
    );
  }

  // Preview tab
  Widget _buildPreviewTab(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoLine(theme, colorScheme, '标题', item.title),
          if (item.siteName != null && item.siteName!.isNotEmpty)
            _buildInfoLine(theme, colorScheme, '站点', item.siteName!),
          if (item.author != null && item.author!.isNotEmpty)
            _buildInfoLine(theme, colorScheme, '作者', item.author!),
          if (item.coverImage != null && item.coverImage!.isNotEmpty)
            _buildInfoLine(theme, colorScheme, '封面', item.coverImage!),
          _buildInfoLine(theme, colorScheme, '原始 URL', item.originalUrl),
          _buildInfoLine(theme, colorScheme, '标准化 URL', item.normalizedUrl),
        ],
      ),
    );
  }

  // Placeholder tab
  Widget _buildPlaceholderTab(
    ThemeData theme,
    ColorScheme colorScheme,
    String message,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Text(
        message,
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------
  // Shared helpers
  // ---------------------------------------------------------------

  Widget _buildInfoLine(
    ThemeData theme,
    ColorScheme colorScheme,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

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

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('无效的链接')),
      );
      return;
    }
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('打开链接失败：$e')),
      );
    }
  }

  // ===============================================================
  // F. Bottom Fixed Action Bar
  // ===============================================================

  Widget _buildBottomActionBar(
    ThemeData theme,
    ColorScheme colorScheme,
    SavedItemsTableData item,
  ) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () async {
                  await ref
                      .read(collectionsRepositoryProvider)
                      .markOpened(item.id);
                  ref.invalidate(savedItemsListProvider);
                  if (!mounted) return;
                  await _openUrl(item.originalUrl);
                },
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: const Text('打开内容'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('编辑功能稍后接入')),
                  );
                },
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('编辑'),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            IconButton(
              tooltip: '更多操作',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('更多操作稍后接入')),
                );
              },
              icon: const Icon(Icons.more_horiz_rounded),
            ),
          ],
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '标签',
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: AppFontTokens.medium,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          FutureBuilder<List<int>>(
            future: ref
                .read(collectionsRepositoryProvider)
                .getBoxIdsForItem(item.id),
            builder: (context, snapshot) {
              final boxIds = snapshot.data?.toSet() ?? const <int>{};
              return boxesAsync.when(
                data: (boxes) {
                  final labels = <String>[
                    for (final box in boxes)
                      if (boxIds.contains(box.id)) box.name,
                    mediaType.label,
                    platform.label,
                  ].where((label) => label.trim().isNotEmpty).take(4).toList();

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '收藏夹',
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: AppFontTokens.medium,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          FutureBuilder<List<int>>(
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
                            final repository =
                                ref.read(collectionsRepositoryProvider);
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
    ref.invalidate(collectionBoxesProvider);
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
      ref.invalidate(savedItemsListProvider);
    }
  }
}
