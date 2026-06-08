import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uni_hub/src/core/theme/app_tokens.dart';
import 'package:uni_hub/src/plugins/collections/providers/collections_providers.dart';
import 'package:uni_hub/src/plugins/collections/ui/widgets/collection_filter_chip.dart';
import 'package:uni_hub/src/plugins/collections/ui/widgets/collection_search_capture_field.dart';
import 'package:uni_hub/src/plugins/collections/ui/widgets/collection_sort_menu.dart';

/// Unified Command Bar for the Collections page.
///
/// Combines search, URL capture, filter dropdowns, sort, and a filter
/// summary line into a single container.
class CollectionCommandBar extends ConsumerWidget {
  const CollectionCommandBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasActiveFilters = _hasAnyActiveFilter(ref);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 640) {
              return const _CompactToolbar();
            } else if (constraints.maxWidth < 860) {
              return const _MediumToolbar();
            }
            return const _DesktopToolbar();
          },
        ),
        // ── Filter summary (only when any filter is active) ───────────────
        if (hasActiveFilters)
          const _FilterSummaryBar(),
      ],
    );
  }

  bool _hasAnyActiveFilter(WidgetRef ref) {
    return ref.watch(collectionPlatformFilterProvider) != null ||
        ref.watch(collectionMediaTypeFilterProvider) != null ||
        ref.watch(collectionStatusFilterProvider) != null ||
        ref.watch(selectedCollectionBoxIdsProvider).isNotEmpty ||
        ref.watch(collectionSearchQueryProvider).trim().isNotEmpty;
  }
}

// ---------------------------------------------------------------------------
// Desktop layout (≥ 860px)
// ---------------------------------------------------------------------------

class _DesktopToolbar extends StatelessWidget {
  const _DesktopToolbar();

  @override
  Widget build(BuildContext context) {
    return _ContainerBox(
      child: Row(
        children: [
          // Search / capture field (takes ~40% of space)
          const Expanded(
            flex: 5,
            child: CollectionSearchCaptureField(),
          ),
          const SizedBox(width: 12),
          // Filter dropdowns
          const Flexible(
            flex: 4,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: _FilterDropdownRow(),
            ),
          ),
          const Spacer(),
          // Sort
          const CollectionSortMenu(),
          const SizedBox(width: 12),
          // Clear filter button
          _ClearFilterButton(),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Medium layout (640–859px)
// ---------------------------------------------------------------------------

class _MediumToolbar extends StatelessWidget {
  const _MediumToolbar();

  @override
  Widget build(BuildContext context) {
    return _ContainerBox(
      child: Row(
        children: [
          // Search / capture field (wider share)
          const Expanded(
            flex: 6,
            child: CollectionSearchCaptureField(),
          ),
          const SizedBox(width: 8),
          // Filter + sort
          const Flexible(
            flex: 5,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: _FilterDropdownRow(),
            ),
          ),
          const SizedBox(width: 4),
          _ClearFilterButton(compact: true),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Compact layout (< 640px)
// ---------------------------------------------------------------------------

class _CompactToolbar extends StatelessWidget {
  const _CompactToolbar();

  @override
  Widget build(BuildContext context) {
    return _ContainerBox(
      height: 112,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // First row: search / capture
          const CollectionSearchCaptureField(),
          const SizedBox(height: 8),
          // Second row: filters + sort + clear
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const PlatformFilterDropdown(),
                      const SizedBox(width: AppSpacing.xxs),
                      const MediaTypeFilterDropdown(),
                      const SizedBox(width: AppSpacing.xxs),
                      const StatusFilterDropdown(),
                      const SizedBox(width: AppSpacing.xxs),
                      const CollectionSortMenu(),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              _ClearFilterButton(compact: true),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filter dropdown row (shared by desktop + medium)
// ---------------------------------------------------------------------------

class _FilterDropdownRow extends StatelessWidget {
  const _FilterDropdownRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const PlatformFilterDropdown(),
        const SizedBox(width: AppSpacing.xs),
        const MediaTypeFilterDropdown(),
        const SizedBox(width: AppSpacing.xs),
        const StatusFilterDropdown(),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Filter summary bar
// ---------------------------------------------------------------------------

class _FilterSummaryBar extends ConsumerWidget {
  const _FilterSummaryBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final labels = <String>[];

    final platform = ref.watch(collectionPlatformFilterProvider);
    final mediaType = ref.watch(collectionMediaTypeFilterProvider);
    final status = ref.watch(collectionStatusFilterProvider);

    if (platform != null) labels.add('来源=${platform.label}');
    if (mediaType != null) labels.add('类型=${mediaType.label}');
    if (status != null) labels.add('状态=${status.label}');

    if (labels.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(36, 0, 36, 0),
      child: SizedBox(
        height: 32,
        child: Row(
          children: [
            Icon(
              Icons.filter_alt_rounded,
              size: 14,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '已筛选：${labels.join('  ')}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _clearAllFilters(ref),
              child: Text(
                '清除全部',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _clearAllFilters(WidgetRef ref) {
    ref.read(collectionPlatformFilterProvider.notifier).state = null;
    ref.read(collectionMediaTypeFilterProvider.notifier).state = null;
    ref.read(collectionStatusFilterProvider.notifier).state = null;
    ref.read(selectedCollectionBoxIdsProvider.notifier).state = const {};
    ref.read(collectionSearchQueryProvider.notifier).state = '';
  }
}

// ---------------------------------------------------------------------------
// Outer container with the Command Bar visual styling
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// Clear-all-filters button
// ---------------------------------------------------------------------------

class _ClearFilterButton extends ConsumerWidget {
  const _ClearFilterButton({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasActiveFilters = _hasAnyActiveFilter(ref);
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

  bool _hasAnyActiveFilter(WidgetRef ref) {
    return ref.watch(collectionPlatformFilterProvider) != null ||
        ref.watch(collectionMediaTypeFilterProvider) != null ||
        ref.watch(collectionStatusFilterProvider) != null ||
        ref.watch(selectedCollectionBoxIdsProvider).isNotEmpty ||
        ref.watch(collectionSearchQueryProvider).trim().isNotEmpty;
  }

  void _clearAllFilters(WidgetRef ref) {
    ref.read(collectionPlatformFilterProvider.notifier).state = null;
    ref.read(collectionMediaTypeFilterProvider.notifier).state = null;
    ref.read(collectionStatusFilterProvider.notifier).state = null;
    ref.read(selectedCollectionBoxIdsProvider.notifier).state = const {};
    ref.read(collectionSearchQueryProvider.notifier).state = '';
  }
}
