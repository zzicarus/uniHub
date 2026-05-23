import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../tags/tag_models.dart';
import 'app_tag_chip.dart';

/// Show a modal popover for browsing and toggling all available tags.
///
/// The popover is presented as a dialog centered on screen. Callers can
/// also embed [AppMoreTagsPopoverContent] directly in a [showMenu] or
/// similar custom popup.
///
/// ```dart
/// await showAppMoreTagsPopover(
///   context: context,
///   tags: tagStats,
///   selectedTags: selectedTags,
///   onTagToggle: (tag) => /* toggle */,
///   onClear: () => /* clear all */,
/// );
/// ```
Future<void> showAppMoreTagsPopover({
  required BuildContext context,
  required List<AppTagStat> tags,
  required Set<String> selectedTags,
  required ValueChanged<String> onTagToggle,
  VoidCallback? onClear,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xxl,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: AppMoreTagsPopoverContent(
          tags: tags,
          selectedTags: selectedTags,
          onTagToggle: onTagToggle,
          onClear: onClear,
        ),
      );
    },
  );
}

/// The inner content of the "more tags" popover.
///
/// Contains a title, search field, scrollable tag grid, and bottom action
/// bar (clear / finish). Stateful to manage the search query.
class AppMoreTagsPopoverContent extends StatefulWidget {
  /// All available tag statistics.
  final List<AppTagStat> tags;

  /// Currently selected tag names.
  final Set<String> selectedTags;

  /// Called when a tag chip is tapped.
  final ValueChanged<String> onTagToggle;

  /// When provided a "clear" button is shown alongside "finish".
  final VoidCallback? onClear;

  const AppMoreTagsPopoverContent({
    required this.tags,
    required this.selectedTags,
    required this.onTagToggle,
    this.onClear,
    super.key,
  });

  @override
  State<AppMoreTagsPopoverContent> createState() =>
      _AppMoreTagsPopoverContentState();
}

class _AppMoreTagsPopoverContentState
    extends State<AppMoreTagsPopoverContent> {
  final _searchController = TextEditingController();
  late Set<String> _localSelectedTags;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _localSelectedTags = Set<String>.from(widget.selectedTags);
  }

  @override
  void didUpdateWidget(covariant AppMoreTagsPopoverContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_hasSameTags(widget.selectedTags, oldWidget.selectedTags)) {
      _localSelectedTags = Set<String>.from(widget.selectedTags);
    }
  }

  bool _hasSameTags(Set<String> a, Set<String> b) {
    return a.length == b.length && a.containsAll(b);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);

    final filteredTags = _searchQuery.isEmpty
        ? widget.tags
        : widget.tags
            .where(
              (tag) =>
                  tag.name.toLowerCase().contains(_searchQuery.toLowerCase()),
            )
            .toList();

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- Title ---
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xs,
            ),
            child: Text(
              '更多标签',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          // --- Search box ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: '搜索标签...',
                prefixIcon: const Icon(Icons.search_rounded, size: 18),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  borderSide: BorderSide(color: colors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  borderSide: BorderSide(color: colors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  borderSide: BorderSide(color: colors.primary),
                ),
              ),
              style: theme.textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 1),
          // --- Tag grid ---
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: filteredTags.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xxl,
                      ),
                      child: Center(
                        child: Text(
                          '没有找到标签',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.textTertiary,
                          ),
                        ),
                      ),
                    )
                  : Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: filteredTags.map((tag) {
                        return AppTagChip(
                          label: tag.name,
                          count: tag.count,
                          selected: _localSelectedTags.contains(tag.name),
                          onTap: () {
                            setState(() {
                              if (_localSelectedTags.contains(tag.name)) {
                                _localSelectedTags.remove(tag.name);
                              } else {
                                _localSelectedTags.add(tag.name);
                              }
                            });
                            widget.onTagToggle(tag.name);
                          },
                        );
                      }).toList(),
                    ),
            ),
          ),
          // --- Bottom action bar ---
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (widget.onClear != null)
                  TextButton(
                    onPressed: () {
                      setState(_localSelectedTags.clear);
                      widget.onClear!();
                    },
                    child: Text(
                      '清空',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  )
                else
                  const Spacer(),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('完成'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
