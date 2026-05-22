import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:uni_hub/src/core/theme/app_tokens.dart';
import '../../providers/thoughts_providers.dart';
import 'thought_filter_bar.dart';
import 'thought_selected_tags_bar.dart';
import 'thought_tag_filter_bar.dart';
import 'thoughts_shared_widgets.dart';

/// Compact three-row filter panel for the thoughts desktop layout.
///
/// Row 1: Search box + status chips (ThoughtFilterBar) + sort button
/// Row 2: "按标签筛选：" label + common tag chips (ThoughtTagFilterBar)
/// Row 3: "已选标签：" + selected tag chips + clear button (ThoughtSelectedTagsBar)
class ThoughtFilterPanel extends ConsumerWidget {
  final bool isArchived;

  const ThoughtFilterPanel({required this.isArchived, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return ThoughtPanel(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Row 1: Search + Status chips + Sort
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Row(
              children: [
                const Expanded(
                  flex: 5,
                  child: _ThoughtFilterSearchBox(),
                ),
                const SizedBox(width: AppSpacing.md),
                if (!isArchived)
                  const Expanded(
                    flex: 9,
                    child: ThoughtFilterBar(),
                  )
                else
                  const Spacer(),
                const SizedBox(width: AppSpacing.md),
                const _SortButton(),
              ],
            ),
          ),
          if (!isArchived) ...[
            Divider(height: 1, color: colorScheme.outlineVariant),
            // Row 2: Tag filter
            const Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.xs,
              ),
              child: ThoughtTagFilterBar(),
            ),
            // Row 3: Selected tags (conditional - shows its own top border)
            const ThoughtSelectedTagsBar(),
          ],
        ],
      ),
    );
  }
}

class _ThoughtFilterSearchBox extends ConsumerStatefulWidget {
  const _ThoughtFilterSearchBox();

  @override
  ConsumerState<_ThoughtFilterSearchBox> createState() =>
      _ThoughtFilterSearchBoxState();
}

class _ThoughtFilterSearchBoxState
    extends ConsumerState<_ThoughtFilterSearchBox> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      height: 36,
      child: TextField(
        controller: _controller,
        onChanged: (value) {
          ref.read(thoughtSearchQueryProvider.notifier).state = value;
          setState(() {});
        },
        decoration: InputDecoration(
          hintText: '搜索想法、标签、内容...',
          hintStyle: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.outline,
          ),
          prefixIcon: const Icon(Icons.search_rounded, size: 18),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 16),
                  onPressed: () {
                    _controller.clear();
                    ref.read(thoughtSearchQueryProvider.notifier).state = '';
                    setState(() {});
                  },
                )
              : null,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide(color: colorScheme.outlineVariant),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide(color: colorScheme.outlineVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide(color: colorScheme.primary),
          ),
          filled: true,
          fillColor: colorScheme.surface,
        ),
        style: theme.textTheme.bodySmall,
      ),
    );
  }
}

class _SortButton extends StatelessWidget {
  const _SortButton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('最新', style: theme.textTheme.labelMedium),
          const SizedBox(width: AppSpacing.xs),
          Icon(Icons.expand_more_rounded, size: 18, color: colorScheme.outline),
        ],
      ),
    );
  }
}
