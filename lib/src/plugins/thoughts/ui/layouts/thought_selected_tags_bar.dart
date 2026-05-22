import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:uni_hub/src/core/theme/app_tokens.dart';
import '../../providers/thoughts_providers.dart';

/// Displays the currently selected tag filter with a clear option.
///
/// Shows the active tag as a chip with an × button and a "清除" text link.
/// Hidden when no tag is selected.
class ThoughtSelectedTagsBar extends ConsumerWidget {
  const ThoughtSelectedTagsBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTag = ref.watch(tagFilterProvider);
    if (selectedTag == null || selectedTag.isEmpty) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xxs,
          ),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.sell_rounded,
                size: 14,
                color: colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.xxs),
              Text(
                selectedTag,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              InkWell(
                onTap: () =>
                    ref.read(tagFilterProvider.notifier).state = null,
                borderRadius: BorderRadius.circular(AppRadius.full),
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        InkWell(
          onTap: () => ref.read(tagFilterProvider.notifier).state = null,
          child: Text(
            '清除',
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.primary,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}
