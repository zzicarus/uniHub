import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:uni_hub/src/core/theme/app_tokens.dart';
import '../../providers/thoughts_providers.dart';

/// Tag filter bar showing top 6 tags with a "+" button for more tags.
///
/// Displays the most common tags from [commonTagsProvider] and opens
/// [ThoughtMoreTagsPopover] when the "+" button is tapped.
class ThoughtTagFilterBar extends ConsumerWidget {
  const ThoughtTagFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commonTags = ref.watch(commonTagsProvider);
    final selectedTag = ref.watch(tagFilterProvider);
    final colorScheme = Theme.of(context).colorScheme;

    final displayTags = commonTags.take(6).toList();

    return Row(
      children: [
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: displayTags.map((entry) {
            return _TagChip(
              label: entry.key,
              count: entry.value,
              selected: selectedTag == entry.key,
              onTap: () {
                final current = ref.read(tagFilterProvider);
                ref.read(tagFilterProvider.notifier).state =
                    current == entry.key ? null : entry.key;
              },
            );
          }).toList(),
        ),
        if (commonTags.length > 6) ...[
          const SizedBox(width: AppSpacing.xs),
          Material(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: InkWell(
              onTap: () => _showMoreTagsPopover(context, ref),
              borderRadius: BorderRadius.circular(AppRadius.full),
              child: Container(
                height: 32,
                width: 32,
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Icon(
                  Icons.add_rounded,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _showMoreTagsPopover(BuildContext context, WidgetRef ref) {
    final allTags = ref.read(commonTagsProvider);
    final selectedTag = ref.read(tagFilterProvider);

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        MediaQuery.of(context).size.width - 320,
        MediaQuery.of(context).viewPadding.top + 64,
        16,
        0,
      ),
      items: [
        PopupMenuItem<String>(
          enabled: false,
          height: 0,
          child: _PopoverContent(
            allTags: allTags,
            selectedTag: selectedTag,
            onTagSelected: (tag) {
              ref.read(tagFilterProvider.notifier).state = tag;
              Navigator.of(context).pop();
            },
          ),
        ),
      ],
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _TagChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: selected
          ? colorScheme.primaryContainer.withValues(alpha: 0.7)
          : colorScheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected
                  ? colorScheme.primary
                  : colorScheme.outlineVariant,
            ),
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.sell_outlined,
                size: 14,
                color: selected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.xxs),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: selected
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurfaceVariant,
                  fontWeight: selected ? FontWeight.w600 : null,
                ),
              ),
              const SizedBox(width: AppSpacing.xxs),
              Text(
                count.toString(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: selected
                      ? colorScheme.primary
                      : colorScheme.outline,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PopoverContent extends StatefulWidget {
  final List<MapEntry<String, int>> allTags;
  final String? selectedTag;
  final ValueChanged<String> onTagSelected;

  const _PopoverContent({
    required this.allTags,
    required this.selectedTag,
    required this.onTagSelected,
  });

  @override
  State<_PopoverContent> createState() => _PopoverContentState();
}

class _PopoverContentState extends State<_PopoverContent> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MapEntry<String, int>> get _filteredTags {
    if (_searchQuery.isEmpty) return widget.allTags;
    return widget.allTags
        .where((e) => e.key.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      width: 280,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: '搜索标签',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  borderSide: BorderSide(color: colorScheme.outlineVariant),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  borderSide: BorderSide(color: colorScheme.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  borderSide: BorderSide(color: colorScheme.primary),
                ),
              ),
              style: theme.textTheme.bodySmall,
            ),
          ),
          const Divider(height: 1),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.xs,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PopupMenuItem<String>(
                      value: '',
                      child: Text(
                        '全部标签',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: widget.selectedTag == null
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                          fontWeight: widget.selectedTag == null
                              ? FontWeight.w600
                              : null,
                        ),
                      ),
                    ),
                    ..._filteredTags.map((entry) {
                      final isSelected = widget.selectedTag == entry.key;
                      return PopupMenuItem<String>(
                        value: entry.key,
                        child: Row(
                          children: [
                            Icon(
                              Icons.sell_outlined,
                              size: 16,
                              color: isSelected
                                  ? colorScheme.primary
                                  : colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                entry.key,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: isSelected
                                      ? colorScheme.primary
                                      : colorScheme.onSurface,
                                  fontWeight:
                                      isSelected ? FontWeight.w600 : null,
                                ),
                              ),
                            ),
                            Text(
                              entry.value.toString(),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
