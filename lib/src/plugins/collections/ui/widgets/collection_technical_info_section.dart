import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uni_hub/src/core/database/app_database.dart';
import 'package:uni_hub/src/core/theme/app_tokens.dart';
import 'package:uni_hub/src/plugins/collections/domain/enrichment_status.dart';
import 'package:uni_hub/src/plugins/collections/domain/media_type.dart';
import 'package:uni_hub/src/plugins/collections/domain/source_platform.dart';

/// Technical / metadata section displayed at the bottom of the detail panel.
///
/// Shows enrichment status, source platform, media type, timestamps, etc.
/// Uses a collapsed [ExpansionTile] to keep the visual weight low —
/// no large color blocks, sits at the bottom of the detail panel.
class CollectionTechnicalInfoSection extends ConsumerWidget {
  const CollectionTechnicalInfoSection({required this.item, super.key});

  final SavedItemsTableData item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final enrichmentStatus = EnrichmentStatus.fromValue(item.enrichmentStatus);
    final sourcePlatform = SourcePlatform.fromValue(item.sourcePlatform);
    final mediaType = MediaType.fromValue(item.mediaType);

    return ExpansionTile(
      title: Text(
        '技术信息',
        style: theme.textTheme.labelLarge?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      initiallyExpanded: false,
      childrenPadding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      children: [
        _InfoRow(label: '抓取状态', value: enrichmentStatus.label),
        _InfoRow(label: '来源平台', value: sourcePlatform.label),
        _InfoRow(label: '媒介类型', value: mediaType.label),
        _InfoRow(
          label: '最后打开',
          value: item.lastOpenedAt != null
              ? _formatDateTime(item.lastOpenedAt!)
              : '从未',
        ),
        _InfoRow(label: '更新时间', value: _formatDateTime(item.updatedAt)),
        _InfoRow(label: '创建时间', value: _formatDateTime(item.createdAt)),
      ],
    );
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inHours < 1) return '${diff.inMinutes} 分钟前';
    if (diff.inDays < 1) return '${diff.inHours} 小时前';
    if (diff.inDays < 30) return '${diff.inDays} 天前';

    return '${dt.year}-${_pad(dt.month)}-${_pad(dt.day)} '
        '${_pad(dt.hour)}:${_pad(dt.minute)}';
  }

  String _pad(int n) => n.toString().padLeft(2, '0');
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Row(
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
}
