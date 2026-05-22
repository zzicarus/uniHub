import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:uni_hub/src/core/theme/app_tokens.dart';
import '../../providers/thoughts_providers.dart';

class ThoughtMoreTagsPopover extends ConsumerWidget {
  const ThoughtMoreTagsPopover({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const _PopoverBody();
  }
}

class _PopoverBody extends ConsumerStatefulWidget {
  const _PopoverBody();

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

  @override
  Widget build(BuildContext context) {
    final allTags = ref.watch(commonTagsProvider);
    final selectedTags = ref.watch(selectedTagFiltersProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final filteredTags = _searchQuery.isEmpty
        ? allTags
        : allTags
              .where(
                (entry) => entry.key.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ),
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
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: '搜索标签',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    borderSide: BorderSide(color: colorScheme.outlineVariant),
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
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: filteredTags.map((entry) {
                      final isSelected = selectedTags.contains(entry.key);
                      return FilterChip(
                        label: Text('#${entry.key}  ${entry.value}'),
                        selected: isSelected,
                        onSelected: (_) {
                          final current = ref.read(selectedTagFiltersProvider);
                          ref.read(selectedTagFiltersProvider.notifier).state =
                              toggleTagInFilter(current, entry.key);
                        },
                      );
                    }).toList(),
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
