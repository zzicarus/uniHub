import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uni_hub/src/core/theme/app_tokens.dart';
import 'package:uni_hub/src/plugins/collections/domain/media_type.dart';
import 'package:uni_hub/src/plugins/collections/domain/source_platform.dart';
import 'package:uni_hub/src/plugins/collections/providers/collections_providers.dart';

class CollectionContentTypeChips extends ConsumerWidget {
  const CollectionContentTypeChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaType = ref.watch(collectionMediaTypeFilterProvider);
    final platform = ref.watch(collectionPlatformFilterProvider);
    final colorScheme = Theme.of(context).colorScheme;

    final entries = <_ContentTypeEntry>[
      const _ContentTypeEntry(label: '全部', icon: Icons.explore_outlined),
      const _ContentTypeEntry(
        label: '网页',
        icon: Icons.language_rounded,
        mediaType: MediaType.webpage,
      ),
      const _ContentTypeEntry(
        label: '视频',
        icon: Icons.play_circle_outline_rounded,
        mediaType: MediaType.video,
      ),
      const _ContentTypeEntry(
        label: '公众号',
        icon: Icons.chat_bubble_outline_rounded,
        platform: SourcePlatform.wechat,
      ),
      const _ContentTypeEntry(
        label: '文章',
        icon: Icons.article_outlined,
        mediaType: MediaType.article,
      ),
      const _ContentTypeEntry(
        label: '工具',
        icon: Icons.extension_outlined,
        mediaType: MediaType.repository,
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final entry in entries) ...[
            ChoiceChip(
              avatar: Icon(entry.icon, size: 16),
              label: Text(entry.label),
              selected: _isSelected(entry, mediaType, platform),
              onSelected: (_) => _select(ref, entry),
              selectedColor: colorScheme.primaryContainer,
              backgroundColor: colorScheme.surface,
              side: BorderSide(color: colorScheme.outlineVariant),
              visualDensity: VisualDensity.compact,
              labelStyle: TextStyle(
                color: _isSelected(entry, mediaType, platform)
                    ? colorScheme.primary
                    : colorScheme.onSurface,
                fontWeight: _isSelected(entry, mediaType, platform)
                    ? AppFontTokens.bold
                    : AppFontTokens.medium,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          ActionChip(
            avatar: const Icon(Icons.more_horiz_rounded, size: 16),
            label: const Text('更多'),
            onPressed: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('更多类型稍后接入')));
            },
            side: BorderSide(color: colorScheme.outlineVariant),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  bool _isSelected(
    _ContentTypeEntry entry,
    MediaType? mediaType,
    SourcePlatform? platform,
  ) {
    if (entry.mediaType == null && entry.platform == null) {
      return mediaType == null && platform == null;
    }
    return entry.mediaType == mediaType && entry.platform == platform;
  }

  void _select(WidgetRef ref, _ContentTypeEntry entry) {
    ref.read(collectionMediaTypeFilterProvider.notifier).state =
        entry.mediaType;
    ref.read(collectionPlatformFilterProvider.notifier).state = entry.platform;
  }
}

class _ContentTypeEntry {
  const _ContentTypeEntry({
    required this.label,
    required this.icon,
    this.mediaType,
    this.platform,
  });

  final String label;
  final IconData icon;
  final MediaType? mediaType;
  final SourcePlatform? platform;
}
