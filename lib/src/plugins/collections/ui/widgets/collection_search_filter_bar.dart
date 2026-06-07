import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uni_hub/src/core/theme/app_tokens.dart';
import 'package:uni_hub/src/plugins/collections/domain/media_type.dart';
import 'package:uni_hub/src/plugins/collections/domain/source_platform.dart';
import 'package:uni_hub/src/plugins/collections/providers/collections_providers.dart';

/// A compact search + filter bar with a text field, source / media-type
/// dropdowns, a sort label, and a "clear all filters" button.
///
/// Resets all filtering providers on clear (except [collectionViewProvider]).
class CollectionSearchFilterBar extends ConsumerStatefulWidget {
  const CollectionSearchFilterBar({super.key});

  @override
  ConsumerState<CollectionSearchFilterBar> createState() =>
      _CollectionSearchFilterBarState();
}

class _CollectionSearchFilterBarState
    extends ConsumerState<CollectionSearchFilterBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(collectionSearchQueryProvider),
    );
    // #8: 同步 provider 变化回 controller，确保"清空筛选"后输入框也清空
    ref.listenManual<String>(collectionSearchQueryProvider, (prev, next) {
      if (next != _controller.text) {
        _controller.text = next;
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final platform = ref.watch(collectionPlatformFilterProvider);
    final mediaType = ref.watch(collectionMediaTypeFilterProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          SizedBox(
            width: 220,
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: '搜索标题、描述或 URL',
                prefixIcon: const Icon(Icons.search_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              onChanged: (v) =>
                  ref.read(collectionSearchQueryProvider.notifier).state = v,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          DropdownButton<SourcePlatform?>(
            value: platform,
            hint: const Text('全部来源'),
            underline: const SizedBox.shrink(),
            items: [
              const DropdownMenuItem(child: Text('全部来源')),
              for (final p in SourcePlatform.values)
                DropdownMenuItem(value: p, child: Text(p.label)),
            ],
            onChanged: (v) =>
                ref.read(collectionPlatformFilterProvider.notifier).state = v,
          ),
          const SizedBox(width: AppSpacing.sm),
          DropdownButton<MediaType?>(
            value: mediaType,
            hint: const Text('全部媒介'),
            underline: const SizedBox.shrink(),
            items: [
              const DropdownMenuItem(child: Text('全部媒介')),
              for (final m in MediaType.values)
                DropdownMenuItem(value: m, child: Text(m.label)),
            ],
            onChanged: (v) =>
                ref.read(collectionMediaTypeFilterProvider.notifier).state = v,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '最新收藏',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          TextButton(
            onPressed: () => _clearFilters(ref),
            child: const Text('清空筛选'),
          ),
        ],
      ),
    );
  }

  void _clearFilters(WidgetRef ref) {
    ref.read(collectionSearchQueryProvider.notifier).state = '';
    ref.read(collectionPlatformFilterProvider.notifier).state = null;
    ref.read(collectionMediaTypeFilterProvider.notifier).state = null;
    ref.read(collectionStatusFilterProvider.notifier).state = null;
    ref.read(selectedCollectionBoxIdsProvider.notifier).state = {};
    // DO NOT reset collectionViewProvider
  }
}
