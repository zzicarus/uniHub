import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:uni_hub/src/core/theme/app_tokens.dart';
import '../../providers/thoughts_providers.dart';

/// Popover for browsing and selecting from all available tags.
///
/// Includes a search field to filter the tag list and shows the full
/// set of tags sorted by usage count.
class ThoughtMoreTagsPopover extends ConsumerWidget {
  const ThoughtMoreTagsPopover({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _PopoverBody(ref: ref);
  }
}

class _PopoverBody extends ConsumerStatefulWidget {
  final WidgetRef ref;

  const _PopoverBody({required this.ref});

  @override
  ConsumerState<_PopoverBody> createState() => _PopoverBodyState();
}

class _PopoverBodyState extends ConsumerState<_PopoverBody> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _selectTag(String? tag) {
    ref.read(tagFilterProvider.notifier).state = tag;
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final allTags = ref.watch(commonTagsProvider);
    final selectedTag = ref.watch(tagFilterProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final filteredTags = _searchQuery.isEmpty
        ? allTags
        : allTags
            .where(
              (e) => e.key.toLowerCase().contains(_searchQuery.toLowerCase()),
            )
            .toList();

    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: SizedBox(
        width: 280,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Search field
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
            // Tag list
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // "All tags" option
                      InkWell(
                        onTap: () => _selectTag(null),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.tag_rounded,
                                size: 16,
                                color: selectedTag == null
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  '全部标签',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: selectedTag == null
                                        ? colorScheme.primary
                                        : colorScheme.onSurface,
                                    fontWeight: selectedTag == null
                                        ? FontWeight.w600
                                        : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Individual tags
                      ...filteredTags.map((entry) {
                        final isSelected = selectedTag == entry.key;
                        return InkWell(
                          onTap: () => _selectTag(entry.key),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
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
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : null,
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
                          ),
                        );
                      }),
                      if (filteredTags.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Center(
                            child: Text(
                              '没有找到匹配的标签',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
