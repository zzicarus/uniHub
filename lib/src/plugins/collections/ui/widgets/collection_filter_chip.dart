import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uni_hub/src/core/theme/app_tokens.dart';
import 'package:uni_hub/src/plugins/collections/domain/consumption_status.dart';
import 'package:uni_hub/src/plugins/collections/domain/media_type.dart';
import 'package:uni_hub/src/plugins/collections/domain/source_platform.dart';
import 'package:uni_hub/src/plugins/collections/providers/collections_providers.dart';

/// A reusable filter chip that opens a [PopupMenuButton] for selection.
///
/// [label] is the category prefix (e.g. "来源", "类型", "状态").
/// When [value] is null, shows [hint] with a dropdown arrow.
/// When [value] is set, shows the item label with a × clear button.
class CollectionFilterChip<T> extends StatelessWidget {
  const CollectionFilterChip({
    required this.label,
    required this.value,
    required this.hint,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    required this.onClear,
    super.key,
  });

  final String label;
  final T? value;
  final String hint;
  final List<T> items;
  final String Function(T value) itemLabel;
  final ValueChanged<T?> onChanged;
  final VoidCallback onClear;

  bool get isActive => value != null;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final Color bgColor;
    final Color borderColor;
    final Color textColor;

    if (isActive) {
      bgColor = colorScheme.primaryContainer.withValues(alpha: 0.50);
      borderColor = colorScheme.primary.withValues(alpha: 0.40);
      textColor = colorScheme.primary;
    } else {
      bgColor = colorScheme.surfaceContainerLow;
      borderColor = colorScheme.outlineVariant.withValues(alpha: 0.75);
      textColor = colorScheme.onSurfaceVariant;
    }

    final displayValue = isActive ? itemLabel(value as T) : hint;

    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: borderColor),
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.full),
          onTap: () => _showMenu(context),
          child: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$label：',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    letterSpacing: 0,
                    fontWeight: AppFontTokens.medium,
                    color: isActive
                        ? colorScheme.primary.withValues(alpha: 0.7)
                        : colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
                Text(
                  displayValue,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    letterSpacing: 0,
                    fontWeight: AppFontTokens.semiBold,
                    color: textColor,
                  ),
                ),
                const SizedBox(width: 4),
                if (isActive)
                  GestureDetector(
                    onTap: onClear,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: textColor,
                      ),
                    ),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(
                      Icons.expand_more_rounded,
                      size: 16,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMenu(BuildContext context) async {
    final result = await showMenu<T>(
      context: context,
      position: RelativeRect.fromLTRB(0, 48, 0, 0),
      initialValue: value,
      items: [
        ...items.map(
          (item) => PopupMenuItem<T>(
            value: item,
            child: Row(
              children: [
                Icon(
                  Icons.check_rounded,
                  size: 18,
                  color: value == item
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(itemLabel(item)),
              ],
            ),
          ),
        ),
      ],
    );
    if (result != null) {
      onChanged(result);
    }
  }
}

/// A group of filter chips for source, media type, and consumption status.
class CollectionFilterChipGroup extends ConsumerWidget {
  const CollectionFilterChipGroup({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final platform = ref.watch(collectionPlatformFilterProvider);
    final mediaType = ref.watch(collectionMediaTypeFilterProvider);
    final status = ref.watch(collectionStatusFilterProvider);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CollectionFilterChip<SourcePlatform>(
          label: '来源',
          value: platform,
          hint: '全部',
          items: SourcePlatform.values,
          itemLabel: (v) => v.label,
          onChanged: (v) {
            ref.read(collectionPlatformFilterProvider.notifier).state = v;
          },
          onClear: () {
            ref.read(collectionPlatformFilterProvider.notifier).state = null;
          },
        ),
        const SizedBox(width: AppSpacing.xs),
        CollectionFilterChip<MediaType>(
          label: '类型',
          value: mediaType,
          hint: '全部',
          items: MediaType.values,
          itemLabel: (v) => v.label,
          onChanged: (v) {
            ref.read(collectionMediaTypeFilterProvider.notifier).state = v;
          },
          onClear: () {
            ref.read(collectionMediaTypeFilterProvider.notifier).state = null;
          },
        ),
        const SizedBox(width: AppSpacing.xs),
        CollectionFilterChip<ConsumptionStatus>(
          label: '状态',
          value: status,
          hint: '全部',
          items: ConsumptionStatus.values,
          itemLabel: (v) => v.label,
          onChanged: (v) {
            ref.read(collectionStatusFilterProvider.notifier).state = v;
          },
          onClear: () {
            ref.read(collectionStatusFilterProvider.notifier).state = null;
          },
        ),
      ],
    );
  }
}
