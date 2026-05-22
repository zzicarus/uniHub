import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:uni_hub/src/core/theme/app_tokens.dart';
import '../../providers/thoughts_providers.dart';

class ThoughtTagFilterBar extends ConsumerWidget {
  const ThoughtTagFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commonTags = ref.watch(commonTagsProvider);
    final selectedTags = ref.watch(selectedTagFiltersProvider);
    final displayTags = commonTags.take(5).toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '按标签筛选：',
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              ...displayTags.map((entry) {
                return _TagChip(
                  label: '#${entry.key}',
                  count: entry.value,
                  selected: selectedTags.contains(entry.key),
                  onTap: () {
                    final current = ref.read(selectedTagFiltersProvider);
                    ref.read(selectedTagFiltersProvider.notifier).state =
                        toggleTagInFilter(current, entry.key);
                  },
                );
              }),
              if (commonTags.length > displayTags.length)
                _MoreTagsButton(
                  onTap: () => _showMoreTagsPopover(context, ref),
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _showMoreTagsPopover(BuildContext context, WidgetRef ref) {
    showMenu<void>(
      context: context,
      position: RelativeRect.fromLTRB(
        MediaQuery.of(context).size.width - 560,
        MediaQuery.of(context).viewPadding.top + 220,
        24,
        0,
      ),
      items: [
        PopupMenuItem<void>(
          enabled: false,
          padding: EdgeInsets.zero,
          child: _MoreTagsPopover(ref: ref),
        ),
      ],
      elevation: 8,
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
      color: selected ? AppColors.primary : colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? AppColors.primary : colorScheme.outlineVariant,
            ),
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: selected ? Colors.white : colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                count.toString(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.78)
                      : colorScheme.outline,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoreTagsButton extends StatelessWidget {
  final VoidCallback onTap;

  const _MoreTagsButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _PlainTagButton(
      icon: Icons.add_rounded,
      label: '更多标签',
      onTap: onTap,
    );
  }
}

class _PlainTagButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PlainTagButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            border: Border.all(color: colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: AppSpacing.xxs),
              Text(label, style: Theme.of(context).textTheme.labelMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoreTagsPopover extends ConsumerStatefulWidget {
  final WidgetRef ref;

  const _MoreTagsPopover({required this.ref});

  @override
  ConsumerState<_MoreTagsPopover> createState() => _MoreTagsPopoverState();
}

class _MoreTagsPopoverState extends ConsumerState<_MoreTagsPopover> {
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

    return SizedBox(
      width: 320,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: '搜索标签',
                prefixIcon: const Icon(Icons.search_rounded, size: 18),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: filteredTags.map((entry) {
                    final selected = selectedTags.contains(entry.key);
                    return FilterChip(
                      label: Text('#${entry.key}  ${entry.value}'),
                      selected: selected,
                      onSelected: (_) {
                        final current = ref.read(selectedTagFiltersProvider);
                        ref.read(selectedTagFiltersProvider.notifier).state =
                            toggleTagInFilter(current, entry.key);
                      },
                      selectedColor: AppColors.primarySoft,
                      checkmarkColor: AppColors.primary,
                      side: BorderSide(
                        color: selected
                            ? AppColors.primary
                            : colorScheme.outlineVariant,
                      ),
                      labelStyle: theme.textTheme.labelMedium?.copyWith(
                        color: selected
                            ? AppColors.primary
                            : colorScheme.onSurfaceVariant,
                        fontWeight: selected
                            ? FontWeight.w800
                            : FontWeight.w600,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
