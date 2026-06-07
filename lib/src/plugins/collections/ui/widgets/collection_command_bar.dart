import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uni_hub/src/core/theme/app_tokens.dart';
import 'package:uni_hub/src/plugins/collections/providers/collections_providers.dart';
import 'package:uni_hub/src/plugins/collections/ui/widgets/collection_filter_chip.dart';
import 'package:uni_hub/src/plugins/collections/ui/widgets/collection_search_capture_field.dart';
import 'package:uni_hub/src/plugins/collections/ui/widgets/collection_sort_menu.dart';

/// Unified Command Bar for the Collections page.
///
/// Combines search, URL capture, filter chips, sort, and view controls
/// into a single visually coherent element.
class CollectionCommandBar extends ConsumerWidget {
  const CollectionCommandBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine layout mode based on available width
        if (constraints.maxWidth < 640) {
          return _buildCompactLayout(context, ref);
        } else if (constraints.maxWidth < 860) {
          return _buildMediumLayout(context, ref);
        }
        return _buildDesktopLayout(context, ref);
      },
    );
  }

  Widget _buildDesktopLayout(BuildContext context, WidgetRef ref) {
    return const _ContainerBox(
      child: Row(
        children: [
          // Search / capture field (takes ~40% of space)
          Expanded(
            flex: 5,
            child: CollectionSearchCaptureField(),
          ),
          SizedBox(width: 12),
          // Filter chips
          Flexible(
            flex: 4,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: CollectionFilterChipGroup(),
            ),
          ),
          Spacer(),
          // Sort menu
          CollectionSortMenu(),
          SizedBox(width: 8),
          // Clear filter button
          _ClearFilterButton(),
        ],
      ),
    );
  }

  Widget _buildMediumLayout(BuildContext context, WidgetRef ref) {
    return const _ContainerBox(
      child: Row(
        children: [
          // Search / capture field (wider share)
          Expanded(
            flex: 6,
            child: CollectionSearchCaptureField(),
          ),
          SizedBox(width: 8),
          // Filter chips (scrollable)
          Flexible(
            flex: 4,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: CollectionFilterChipGroup(),
            ),
          ),
          // Sort
          SizedBox(width: 4),
          CollectionSortMenu(),
          SizedBox(width: 4),
          // Clear filter (icon-only)
          _ClearFilterButton(compact: true),
        ],
      ),
    );
  }

  Widget _buildCompactLayout(BuildContext context, WidgetRef ref) {
    return const _ContainerBox(
      height: 112,
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // First row: search / capture
          CollectionSearchCaptureField(),
          SizedBox(height: 8),
          // Second row: filters + sort + clear
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: CollectionFilterChipGroup(),
                ),
              ),
              SizedBox(width: 4),
              CollectionSortMenu(),
              SizedBox(width: 4),
              _ClearFilterButton(compact: true),
            ],
          ),
        ],
      ),
    );
  }
}

/// Outer container with the Command Bar visual styling.
class _ContainerBox extends StatelessWidget {
  const _ContainerBox({
    required this.child,
    this.height = 64,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
  });

  final Widget child;
  final double height;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: height,
      margin: const EdgeInsets.fromLTRB(24, 12, 24, 10),
      padding: padding,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// "清除筛选" button that appears when any filter is active.
class _ClearFilterButton extends ConsumerWidget {
  const _ClearFilterButton({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasActiveFilters = _hasAnyFilterActive(ref);

    if (!hasActiveFilters) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;

    if (compact) {
      return IconButton(
        icon: Icon(
          Icons.filter_alt_off_rounded,
          size: 18,
          color: colorScheme.primary,
        ),
        onPressed: () => _clearAllFilters(ref),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        tooltip: '清除筛选',
      );
    }

    return TextButton.icon(
      onPressed: () => _clearAllFilters(ref),
      icon: Icon(Icons.close_rounded, size: 16, color: colorScheme.primary),
      label: Text(
        '清除筛选',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: colorScheme.primary,
          fontWeight: AppFontTokens.semiBold,
          letterSpacing: 0,
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  bool _hasAnyFilterActive(WidgetRef ref) {
    final boxIds = ref.watch(selectedCollectionBoxIdsProvider);
    return boxIds.isNotEmpty ||
        ref.watch(collectionPlatformFilterProvider) != null ||
        ref.watch(collectionMediaTypeFilterProvider) != null ||
        ref.watch(collectionStatusFilterProvider) != null ||
        ref.watch(collectionSearchQueryProvider).trim().isNotEmpty;
  }

  /// 清除所有筛选条件，包括 Box 选定状态。
  /// 保留 [collectionViewProvider]（系统视图：Inbox/全部/归档）不变。
  void _clearAllFilters(WidgetRef ref) {
    ref.read(selectedCollectionBoxIdsProvider.notifier).state = const {};
    ref.read(collectionPlatformFilterProvider.notifier).state = null;
    ref.read(collectionMediaTypeFilterProvider.notifier).state = null;
    ref.read(collectionStatusFilterProvider.notifier).state = null;
    ref.read(collectionSearchQueryProvider.notifier).state = '';
    // Do NOT reset sort — sort is a browsing preference, not a filter.
  }
}
