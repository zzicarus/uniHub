import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uni_hub/src/core/theme/app_tokens.dart';
import 'package:uni_hub/src/plugins/collections/domain/media_type.dart';
import 'package:uni_hub/src/plugins/collections/domain/source_platform.dart';
import 'package:uni_hub/src/plugins/collections/providers/collections_providers.dart';

class CollectionListToolbar extends ConsumerWidget {
  const CollectionListToolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(collectionSearchQueryProvider);
    final platform = ref.watch(collectionPlatformFilterProvider);
    final mediaType = ref.watch(collectionMediaTypeFilterProvider);
    final status = ref.watch(collectionStatusFilterProvider);
    final selectedBoxIds = ref.watch(selectedCollectionBoxIdsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 260,
                child: TextFormField(
                  key: ValueKey('collection-list-search-$query'),
                  initialValue: query,
                  decoration: const InputDecoration(
                    hintText: '搜索标题、来源或内容',
                    prefixIcon: Icon(Icons.search_rounded),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onChanged: (value) {
                    ref.read(collectionSearchQueryProvider.notifier).state =
                        value;
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              _ToolbarDropdown<SourcePlatform?>(
                value: platform,
                hint: '全部来源',
                items: [
                  const DropdownMenuItem(value: null, child: Text('全部来源')),
                  for (final value in SourcePlatform.values)
                    DropdownMenuItem(value: value, child: Text(value.label)),
                ],
                onChanged: (value) {
                  ref.read(collectionPlatformFilterProvider.notifier).state =
                      value;
                },
              ),
              const SizedBox(width: AppSpacing.xs),
              _ToolbarDropdown<MediaType?>(
                value: mediaType,
                hint: '所有类型',
                items: [
                  const DropdownMenuItem(value: null, child: Text('所有类型')),
                  for (final value in MediaType.values)
                    DropdownMenuItem(value: value, child: Text(value.label)),
                ],
                onChanged: (value) {
                  ref.read(collectionMediaTypeFilterProvider.notifier).state =
                      value;
                },
              ),
              const SizedBox(width: AppSpacing.xs),
              _SortChip(colorScheme: colorScheme),
              if (_hasActiveFilters(
                query,
                platform,
                mediaType,
                status,
                selectedBoxIds,
              ))
                TextButton(
                  onPressed: () => _clearFilters(ref),
                  child: const Text('清空'),
                ),
              IconButton(
                tooltip: '切换视图',
                onPressed: () {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('视图切换稍后接入')));
                },
                icon: const Icon(Icons.grid_view_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _hasActiveFilters(
    String query,
    SourcePlatform? platform,
    MediaType? mediaType,
    Object? status,
    Set<int> selectedBoxIds,
  ) {
    return query.trim().isNotEmpty ||
        platform != null ||
        mediaType != null ||
        status != null ||
        selectedBoxIds.isNotEmpty;
  }

  void _clearFilters(WidgetRef ref) {
    ref.read(collectionSearchQueryProvider.notifier).state = '';
    ref.read(collectionPlatformFilterProvider.notifier).state = null;
    ref.read(collectionMediaTypeFilterProvider.notifier).state = null;
    ref.read(collectionStatusFilterProvider.notifier).state = null;
    ref.read(selectedCollectionBoxIdsProvider.notifier).state = const <int>{};
  }
}

class _ToolbarDropdown<T> extends StatelessWidget {
  const _ToolbarDropdown({
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  final T value;
  final String hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<T>(
        value: value,
        hint: Text(hint),
        items: items,
        onChanged: onChanged,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  const _SortChip({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Text(
          '最新收藏',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
