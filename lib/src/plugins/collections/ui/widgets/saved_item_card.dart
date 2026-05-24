import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uni_hub/src/core/database/app_database.dart';
import 'package:uni_hub/src/core/theme/app_tokens.dart';
import 'package:uni_hub/src/plugins/collections/domain/consumption_status.dart';
import 'package:uni_hub/src/plugins/collections/domain/enrichment_status.dart';
import 'package:uni_hub/src/plugins/collections/domain/media_type.dart';
import 'package:uni_hub/src/plugins/collections/domain/source_platform.dart';
import 'package:uni_hub/src/plugins/collections/providers/collections_providers.dart';

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

    final borderRadius = BorderRadius.circular(AppRadius.lg);

    return Material(
      type: MaterialType.transparency,
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          color: selected
              ? colorScheme.primaryContainer.withValues(alpha: 0.1)
              : Colors.transparent,
          border: Border.all(
            color: selected ? colorScheme.primary : colorScheme.outlineVariant,
            width: selected ? 1.5 : 1.0,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon column with failed indicator
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Icon(
                        _iconFor(mediaType),
                        size: 20,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    if (enrichmentStatus == EnrichmentStatus.failed)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: colorScheme.error,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colorScheme.surface,
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: AppSpacing.sm),
                // Content column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        item.title.isEmpty ? item.normalizedUrl : item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      // Description / URL
                      Text(
                        item.description?.trim().isNotEmpty == true
                            ? item.description!
                            : item.normalizedUrl,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      // Meta chips row
                      Wrap(
                        spacing: AppSpacing.xxs,
                        runSpacing: AppSpacing.xxs,
                        children: [
                          _CompactMetaChip(
                            icon: Icons.public_rounded,
                            label: platform.label,
                          ),
                          _CompactMetaChip(
                            icon: Icons.category_outlined,
                            label: mediaType.label,
                          ),
                          if (item.lastOpenedAt != null)
                            const _CompactMetaChip(
                              icon: Icons.open_in_new_rounded,
                              label: '已打开',
                            ),
                          _ItemBoxChips(itemId: item.id),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                _BoxAssignmentButton(itemId: item.id),
                const SizedBox(width: AppSpacing.xxs),
                // Status popup menu
                PopupMenuButton<ConsumptionStatus>(
                  tooltip: '切换状态',
                  initialValue: status,
                  onSelected: (next) async {
                    final repository = ref.read(collectionsRepositoryProvider);
                    await repository.updateStatus(item.id, next);
                    ref.invalidate(savedItemsListProvider);
                  },
                  itemBuilder: (context) => [
                    for (final value in ConsumptionStatus.values)
                      PopupMenuItem(value: value, child: Text(value.label)),
                  ],
                  child: Chip(
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    label: Text(
                      status.label,
                      style: theme.textTheme.labelSmall,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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

class _CompactMetaChip extends StatelessWidget {
  const _CompactMetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Chip(
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      avatar: Icon(icon, size: 12),
      label: Text(label, style: theme.textTheme.labelSmall),
      labelPadding: EdgeInsets.zero,
    );
  }
}

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

            final showCount = namedBoxes.length > 2 ? 2 : namedBoxes.length;
            final extraCount = namedBoxes.length - showCount;

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < showCount; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xxs),
                    child: _CompactMetaChip(
                      icon: Icons.folder_outlined,
                      label: namedBoxes[i],
                    ),
                  ),
                if (extraCount > 0)
                  _CompactMetaChip(
                    icon: Icons.more_horiz_rounded,
                    label: '+$extraCount',
                  ),
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

class _BoxAssignmentButton extends ConsumerWidget {
  const _BoxAssignmentButton({required this.itemId});

  static const _inboxValue = -1;

  final int itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      tooltip: '分配到 Box',
      icon: const Icon(Icons.folder_outlined, size: 18),
      visualDensity: VisualDensity.compact,
      onPressed: () => _showBoxMenu(context, ref),
    );
  }

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
