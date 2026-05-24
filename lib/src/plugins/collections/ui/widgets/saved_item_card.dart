import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uni_hub/src/core/database/app_database.dart';
import 'package:uni_hub/src/core/theme/app_tokens.dart';
import 'package:uni_hub/src/plugins/collections/domain/consumption_status.dart';
import 'package:uni_hub/src/plugins/collections/domain/enrichment_status.dart';
import 'package:uni_hub/src/plugins/collections/domain/media_type.dart';
import 'package:uni_hub/src/plugins/collections/domain/source_platform.dart';
import 'package:uni_hub/src/plugins/collections/providers/collections_providers.dart';

/// A compact saved-item card for the collection list.
///
/// Layout (height 112-132):
/// - Left: media type icon (32×32) with optional failed-enrichment hint
/// - Middle: title (1 line), description (2 lines), bottom row of chips
/// - Right: status pill + open-in-browser button
///
/// URL is hidden from the card to keep the focus on title and description.
/// Enrichment success is not shown; failure shows compact "抓取失败" text.
class SavedItemCard extends ConsumerWidget {
  const SavedItemCard({
    required this.item,
    this.selected = false,
    this.onTap,
    super.key,
  });

  final SavedItemsTableData item;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final platform = SourcePlatform.fromValue(item.sourcePlatform);
    final mediaType = MediaType.fromValue(item.mediaType);
    final status = ConsumptionStatus.fromValue(item.status);
    final enrichmentStatus = EnrichmentStatus.fromValue(item.enrichmentStatus);

    final borderRadius = BorderRadius.circular(AppRadius.md);

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 112, maxHeight: 132),
      child: Material(
        type: MaterialType.transparency,
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            color: selected
                ? colorScheme.primaryContainer.withValues(alpha: 0.06)
                : Colors.transparent,
            border: Border.all(
              color: selected
                  ? colorScheme.primary.withValues(alpha: 0.7)
                  : colorScheme.outlineVariant,
              width: selected ? 1.5 : 1.0,
            ),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: borderRadius,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm,
                AppSpacing.xxs,
                AppSpacing.xs,
                AppSpacing.xxs,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---- Icon ----
                  _iconColumn(colorScheme, mediaType, enrichmentStatus),

                  const SizedBox(width: AppSpacing.sm),

                  // ---- Content ----
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppSpacing.xxs),
                        // Title
                        Text(
                          item.title.isEmpty
                              ? item.normalizedUrl
                              : item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        // Description (2 lines)
                        if (item.description?.trim().isNotEmpty == true)
                          Text(
                            item.description!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              height: 1.3,
                            ),
                          ),
                        const Spacer(),
                        // Bottom chips row
                        _bottomChipsRow(
                          theme,
                          colorScheme,
                          platform,
                          mediaType,
                          enrichmentStatus,
                          item.id,
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                      ],
                    ),
                  ),

                  const SizedBox(width: AppSpacing.xs),

                  // ---- Right: status + open ----
                  _rightColumn(context, theme, colorScheme, status, ref),
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
  ) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
          child: Icon(
            _iconFor(mediaType),
            size: 18,
            color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
          ),
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
                border: Border.all(
                  color: colorScheme.surface,
                  width: 1.5,
                ),
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
    int itemId,
  ) {
    return Row(
      children: [
        _miniChip(theme, colorScheme, platform.label),
        const SizedBox(width: AppSpacing.xxs),
        _miniChip(theme, colorScheme, mediaType.label),
        const SizedBox(width: AppSpacing.xxs),
        _ItemBoxChips(itemId: itemId),
        if (enrichmentStatus == EnrichmentStatus.failed) ...[
          const SizedBox(width: AppSpacing.xxs),
          Text(
            '抓取失败',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.error,
              fontSize: 10,
            ),
          ),
        ],
        if (item.lastOpenedAt != null) ...[
          const SizedBox(width: AppSpacing.xxs),
          Icon(Icons.open_in_new_rounded, size: 10, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            '已打开',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
        ],
      ],
    );
  }

  Widget _miniChip(ThemeData theme, ColorScheme colorScheme, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontSize: 10,
          height: 1.4,
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
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const SizedBox(height: AppSpacing.xs),
        // Status pill (max 72px wide)
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 72),
          child: PopupMenuButton<ConsumptionStatus>(
            tooltip: '切换状态',
            initialValue: status,
            onSelected: (next) async {
              final repository = ref.read(collectionsRepositoryProvider);
              await repository.updateStatus(item.id, next);
              ref.invalidate(savedItemsListProvider);
            },
            itemBuilder: (context) => [
              for (final value in ConsumptionStatus.values)
                PopupMenuItem(
                  value: value,
                  child: Text(value.label),
                ),
            ],
            offset: const Offset(0, 32),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _statusColor(status, colorScheme).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: Border.all(
                  color: _statusColor(status, colorScheme).withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Text(
                status.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: _statusColor(status, colorScheme),
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        // Box assignment button (compact)
        _CompactBoxButton(itemId: item.id),
        const SizedBox(height: AppSpacing.xxs),
        // Open button
        SizedBox(
          width: 28,
          height: 28,
          child: IconButton(
            tooltip: '打开链接',
            icon: const Icon(Icons.open_in_new_rounded, size: 14),
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
                const SnackBar(
                  content: Text('链接已复制到剪贴板'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Color _statusColor(ConsumptionStatus status, ColorScheme colorScheme) {
    return switch (status) {
      ConsumptionStatus.unread => colorScheme.primary,
      ConsumptionStatus.inProgress => const Color(0xFFF59E0B),

      ConsumptionStatus.done => const Color(0xFF22C55E),
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

class _ItemBoxChips extends ConsumerWidget {
  const _ItemBoxChips({required this.itemId});

  final int itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.read(collectionsRepositoryProvider);
    final boxesAsync = ref.watch(collectionBoxesProvider);

    return FutureBuilder<List<int>>(
      future: repository.getBoxIdsForItem(itemId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final boxIds = snapshot.data!;

        return boxesAsync.when(
          data: (boxes) {
            final namedBoxes = boxes
                .where((b) => boxIds.contains(b.id))
                .map((b) => b.name)
                .toList();

            if (namedBoxes.isEmpty) return const SizedBox.shrink();

            final shown = namedBoxes.take(2).toList();
            final extra = namedBoxes.length - shown.length;

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final name in shown) ...[
                  const SizedBox(width: AppSpacing.xxs),
                  _BoxMiniChip(label: name),
                ],
                if (extra > 0) ...[
                  const SizedBox(width: AppSpacing.xxs),
                  Text(
                    '+$extra',
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
        );
      },
    );
  }
}

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
        tooltip: '分配到 Box',
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
              const Text('Inbox（不分配到 Box）'),
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
    ref.invalidate(savedItemsListProvider);
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
          fontSize: 10,
          color: colorScheme.onPrimaryContainer,
          height: 1.4,
        ),
      ),
    );
  }
}
