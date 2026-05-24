import 'dart:io';

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
  const SavedItemCard({required this.item, super.key});

  final SavedItemsTableData item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final platform = SourcePlatform.fromValue(item.sourcePlatform);
    final mediaType = MediaType.fromValue(item.mediaType);
    final status = ConsumptionStatus.fromValue(item.status);
    final enrichmentStatus = EnrichmentStatus.fromValue(item.enrichmentStatus);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(
                    _iconFor(mediaType),
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
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
                        item.description?.trim().isNotEmpty == true
                            ? item.description!
                            : item.normalizedUrl,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
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
                  child: Chip(label: Text(status.label)),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                _MetaChip(icon: Icons.public_rounded, label: platform.label),
                _MetaChip(
                  icon: Icons.category_outlined,
                  label: mediaType.label,
                ),
                _MetaChip(
                  icon: Icons.cloud_sync_outlined,
                  label: enrichmentStatus.label,
                ),
                if (item.lastOpenedAt != null)
                  const _MetaChip(
                    icon: Icons.open_in_new_rounded,
                    label: '已打开',
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.originalUrl,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      await _openOriginalUrl(item.originalUrl);
                      final repository = ref.read(
                        collectionsRepositoryProvider,
                      );
                      await repository.markOpened(item.id);
                      ref.invalidate(savedItemsListProvider);
                      messenger.showSnackBar(
                        const SnackBar(content: Text('已打开原链接')),
                      );
                    } catch (error) {
                      messenger.showSnackBar(
                        SnackBar(content: Text('打开失败：$error')),
                      );
                    }
                  },
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: const Text('打开'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openOriginalUrl(String url) async {
    final uri = Uri.parse(url.contains('://') ? url : 'https://$url');
    final command = Platform.isMacOS
        ? 'open'
        : Platform.isWindows
        ? 'cmd'
        : 'xdg-open';
    final args = Platform.isWindows
        ? ['/c', 'start', '', uri.toString()]
        : [uri.toString()];
    final result = await Process.run(command, args);
    if (result.exitCode != 0) {
      throw StateError('无法打开 ${uri.toString()}');
    }
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

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Chip(
      visualDensity: VisualDensity.compact,
      avatar: Icon(icon, size: 16),
      label: Text(label),
      labelStyle: theme.textTheme.labelMedium,
    );
  }
}
