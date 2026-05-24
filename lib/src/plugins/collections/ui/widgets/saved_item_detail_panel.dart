import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uni_hub/src/core/database/app_database.dart';
import 'package:uni_hub/src/core/theme/app_tokens.dart';
import 'package:uni_hub/src/plugins/collections/domain/consumption_status.dart';
import 'package:uni_hub/src/plugins/collections/domain/media_type.dart';
import 'package:uni_hub/src/plugins/collections/domain/source_platform.dart';
import 'package:uni_hub/src/plugins/collections/providers/collections_providers.dart';

import 'collection_technical_info_section.dart';

/// Full detail panel for a selected [SavedItemsTableData].
///
/// Layout (top to bottom):
/// 1. Header (icon + title + subtitle + open URL button)
/// 2. Link section (URL + copy)
/// 3. Status section (ChoiceChips)
/// 4. Box section (FilterChips for assignment)
/// 5. Tags placeholder
/// 6. Notes placeholder
/// 7. Content tabs (摘要 / 内容预览 / 笔记 / 相关)
/// 8. Technical info (collapsed ExpansionTile)
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

  // -------------------------------------------------------
  // Empty state
  // -------------------------------------------------------

  Widget _buildEmpty(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: colorScheme.outlineVariant),
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

  // -------------------------------------------------------
  // Detail state
  // -------------------------------------------------------

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
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---- Header ----
            _buildHeader(theme, colorScheme, item, mediaType, platform),

            _divider(),

            // ---- Link section ----
            _buildLinkSection(theme, colorScheme, item),

            _divider(),

            // ---- Status section ----
            _buildStatusSection(theme, colorScheme, item),

            _divider(),

            // ---- Box section ----
            _BoxSection(item: item),

            _divider(),

            // ---- Tags placeholder ----
            _buildPlaceholderSection(
              theme,
              colorScheme,
              label: '标签',
              message: '标签功能稍后接入',
            ),

            _divider(),

            // ---- Notes placeholder ----
            _buildPlaceholderSection(
              theme,
              colorScheme,
              label: '备注',
              message: '备注功能稍后接入',
            ),

            _divider(),

            // ---- Content tabs ----
            _buildContentTabs(theme, colorScheme, item),

            _divider(),

            // ---- Technical info ----
            CollectionTechnicalInfoSection(item: item),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------
  // Header (Section 15)
  // -------------------------------------------------------

  Widget _buildHeader(
    ThemeData theme,
    ColorScheme colorScheme,
    SavedItemsTableData item,
    MediaType mediaType,
    SourcePlatform platform,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Media type icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(
              _iconFor(mediaType),
              size: 22,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Title + subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title.isEmpty ? item.normalizedUrl : item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '${platform.label} · ${_relativeTime(item.createdAt)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          // Open URL button
          IconButton(
            tooltip: '打开链接',
            icon: const Icon(Icons.open_in_new_rounded, size: 20),
            visualDensity: VisualDensity.compact,
            onPressed: () {
              // URL opening is platform-specific and out of scope for MVP;
              // copy to clipboard as fallback
              Clipboard.setData(ClipboardData(text: item.originalUrl));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('链接已复制到剪贴板')),
              );
            },
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------
  // Link Section (Section 16)
  // -------------------------------------------------------

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
                  '链接',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  item.originalUrl,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          IconButton(
            tooltip: '复制链接',
            icon: const Icon(Icons.content_copy_rounded, size: 20),
            visualDensity: VisualDensity.compact,
            onPressed: () {
              Clipboard.setData(ClipboardData(text: item.originalUrl));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已复制链接')),
              );
            },
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------
  // Status Section (Section 17)
  // -------------------------------------------------------

  Widget _buildStatusSection(
    ThemeData theme,
    ColorScheme colorScheme,
    SavedItemsTableData item,
  ) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '状态',
            style: theme.textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: ConsumptionStatus.values.map((status) {
              final isSelected =
                  ConsumptionStatus.fromValue(item.status) == status;
              return ChoiceChip(
                label: Text(status.label),
                selected: isSelected,
                onSelected: (selected) {
                  if (!selected) return;
                  final repository =
                      ref.read(collectionsRepositoryProvider);
                  repository.updateStatus(item.id, status);
                  ref.invalidate(savedItemsListProvider);
                },
                selectedColor: colorScheme.primary,
                backgroundColor: colorScheme.surfaceContainerLow,
                labelStyle: TextStyle(
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurface,
                ),
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------
  // Content Tabs (Section 20)
  // -------------------------------------------------------

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
            unselectedLabelColor: colorScheme.onSurfaceVariant,
            indicatorColor: colorScheme.primary,
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
      2 => _buildNotesPlaceholderTab(theme, colorScheme),
      3 => _buildRelatedPlaceholderTab(theme, colorScheme),
      _ => const SizedBox.shrink(),
    };
  }

  /// Summary — appears ONLY in the "摘要" tab, NOT above tabs (Section 20.6).
  Widget _buildSummaryTab(
    ThemeData theme,
    ColorScheme colorScheme,
    SavedItemsTableData item,
  ) {
    final hasDescription = item.description != null &&
        item.description!.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: hasDescription
          ? Text(
              item.description!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
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

  Widget _buildPreviewTab(
    ThemeData theme,
    ColorScheme colorScheme,
    SavedItemsTableData item,
  ) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
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

  Widget _buildNotesPlaceholderTab(
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Text(
        '笔记功能稍后接入',
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildRelatedPlaceholderTab(
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Text(
        '相关想法 / 待办 / 笔记稍后接入',
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  // -------------------------------------------------------
  // Shared helpers
  // -------------------------------------------------------

  Widget _buildPlaceholderSection(
    ThemeData theme,
    ColorScheme colorScheme, {
    required String label,
    required String message,
  }) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            message,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

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

  Widget _divider() => const Divider(height: 1, thickness: 1);

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
}

// ---------------------------------------------------------------
// Box Section (Section 18)
// ---------------------------------------------------------------

class _BoxSection extends ConsumerWidget {
  const _BoxSection({required this.item});

  final SavedItemsTableData item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final boxesAsync = ref.watch(collectionBoxesProvider);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '所属 Box',
            style: theme.textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
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
                    return Text(
                      '暂无 Box，请先在上方创建 Box。',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    );
                  }

                  return Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      for (final box in boxes) ...[
                        FilterChip(
                          label: Text(box.name),
                          selected: currentSet.contains(box.id),
                          onSelected: (selected) {
                            final repository =
                                ref.read(collectionsRepositoryProvider);
                            if (selected) {
                              final next = {...currentSet, box.id};
                              repository.setItemBoxes(item.id, next);
                              if (currentSet.isEmpty) {
                                repository.updateInboxState(item.id, false);
                              }
                            } else {
                              final next = {...currentSet}..remove(box.id);
                              repository.setItemBoxes(item.id, next);
                              if (next.isEmpty) {
                                repository.updateInboxState(item.id, true);
                              }
                            }
                            ref.invalidate(savedItemsListProvider);
                          },
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                      ActionChip(
                        label: const Text('+ 选择 Box'),
                        onPressed: () => _addBox(context, ref, boxes),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  );
                },
                loading: () => const LinearProgressIndicator(minHeight: 2),
                error: (e, _) => Text(
                  '加载 Box 失败：$e',
                  style: TextStyle(color: colorScheme.error),
                ),
              );
            },
          ),
        ],
      ),
    );
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

    await repository.setItemBoxes(
      item.id,
      {...currentSet, selected},
    );
    if (currentSet.isEmpty) {
      await repository.updateInboxState(item.id, false);
    }
    if (context.mounted) {
      ref.invalidate(savedItemsListProvider);
    }
  }
}
