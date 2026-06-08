import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';

/// A searchable dialog for selecting from a list of entities.
///
/// Supports both single-select and multi-select modes.  When the search
/// query produces no matches and [allowCreate] is true, the user can
/// create a new entity inline.
///
/// ### Box picker
/// ```dart
/// final result = await showDialog<Set<int>>(
///   context: context,
///   builder: (_) => AppEntityPicker<int>(
///     title: '添加到收藏夹',
///     searchHint: '搜索收藏夹',
///     items: allBoxes,
///     selectedIds: currentBoxIds,
///     itemLabel: (box) => box.name,
///     itemId: (box) => box.id,
///     onCreate: (name) => controller.createBox(name),
///     createLabelBuilder: (input) => '创建收藏夹「$input」',
///   ),
/// );
/// if (result != null) { /* apply changes */ }
/// ```
class AppEntityPicker<T> extends StatefulWidget {
  const AppEntityPicker({
    super.key,
    required this.title,
    required this.searchHint,
    required this.items,
    required this.selectedIds,
    required this.itemLabel,
    required this.itemId,
    required this.onToggle,
    this.onCreate,
    this.allowCreate = true,
    this.multiSelect = true,
    this.emptyText,
    this.createLabelBuilder,
  });

  /// Dialog title (e.g. "添加到收藏夹", "添加标签").
  final String title;

  /// Placeholder text in the search field.
  final String searchHint;

  /// All available entities to display.
  final List<T> items;

  /// IDs of currently selected entities.
  final Set<dynamic> selectedIds;

  /// Build a display label for an entity.
  final String Function(T item) itemLabel;

  /// Extract a stable ID from an entity.
  final Object Function(T item) itemId;

  /// Called when an item is toggled.  Receives the item and whether it
  /// should now be selected.
  final Future<void> Function(T item, bool selected) onToggle;

  /// Called with the raw search-text when the user wants to create a
  /// new entity.  Should return a [CrudResult] or throw on failure.
  final Future<Object?> Function(String name)? onCreate;

  /// Whether to show a "create" entry when the search produces no match.
  final bool allowCreate;

  /// Whether multiple entities can be selected.
  final bool multiSelect;

  /// Text shown when [items] is empty.
  final String? emptyText;

  /// Build the label for the create button.  Default: `'创建"xxx"'`.
  final String Function(String input)? createLabelBuilder;

  @override
  State<AppEntityPicker<T>> createState() => _AppEntityPickerState<T>();
}

class _AppEntityPickerState<T> extends State<AppEntityPicker<T>> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _errorText;
  bool _creating = false;

  /// Local copy of selected IDs so the user can toggle freely
  /// before confirming.
  late Set<dynamic> _localSelected;

  @override
  void initState() {
    super.initState();
    _localSelected = Set<dynamic>.from(widget.selectedIds);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<T> get _filteredItems {
    if (_query.isEmpty) return widget.items;
    final q = _query.toLowerCase();
    return widget.items
        .where((item) => widget.itemLabel(item).toLowerCase().contains(q))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _toggleItem(T item) async {
    final id = widget.itemId(item);
    final currentlySelected = _localSelected.contains(id);

    if (!widget.multiSelect) {
      // Single-select: clear all and select only this one.
      _localSelected = {id};
    } else if (currentlySelected) {
      _localSelected.remove(id);
    } else {
      _localSelected.add(id);
    }

    setState(() {});

    await widget.onToggle(item, !currentlySelected);
  }

  Future<void> _createEntity() async {
    final name = _query.trim();
    if (name.isEmpty) return;

    final onCreate = widget.onCreate;
    if (onCreate == null) return;

    setState(() => _creating = true);

    try {
      final result = await onCreate(name);
      if (!mounted) return;

      // If the creation returned an entity with an ID, auto-select it.
      if (result != null) {
        // The caller handles auto-selection via the returned result.
      }

      // Clear the search query and error on success.
      _searchController.clear();
      setState(() {
        _query = '';
        _errorText = null;
        _creating = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorText = e is Exception ? e.toString().replaceFirst('Exception: ', '') : '创建失败';
        _creating = false;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final filtered = _filteredItems;
    final hasMatch = filtered.isNotEmpty;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380, maxHeight: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // ── Search field ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: (v) => setState(() => _query = v),
                onSubmitted: (_) {
                  if (!hasMatch && widget.allowCreate && _query.trim().isNotEmpty) {
                    unawaited(_createEntity());
                  }
                },
                decoration: InputDecoration(
                  hintText: widget.searchHint,
                  prefixIcon: const Icon(Icons.search_rounded, size: 18),
                  isDense: true,
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
                  errorText: _errorText,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
                style: theme.textTheme.bodyMedium,
                textInputAction: TextInputAction.search,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Divider(height: 1),

            // ── Items list ──────────────────────────────────────────────
            Expanded(
              child: _creating
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 3))
                  : _buildList(theme, colorScheme, filtered, hasMatch),
            ),

            // ── Bottom bar ──────────────────────────────────────────────
            if (_query.trim().isNotEmpty && !hasMatch && widget.allowCreate)
              _buildCreateFooter(theme, colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildList(
    ThemeData theme,
    ColorScheme colorScheme,
    List<T> filtered,
    bool hasMatch,
  ) {
    if (widget.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(
            widget.emptyText ?? '暂无数据',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    if (!hasMatch) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(
            '未找到匹配项',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      itemCount: filtered.length,
      separatorBuilder: (_, _) => const Divider(height: 1, indent: 16, endIndent: 16),
      itemBuilder: (ctx, index) {
        final item = filtered[index];
        final id = widget.itemId(item);
        final selected = _localSelected.contains(id);

        return _EntityPickerRow(
          label: widget.itemLabel(item),
          selected: selected,
          onTap: () => _toggleItem(item),
          colorScheme: colorScheme,
        );
      },
    );
  }

  Widget _buildCreateFooter(ThemeData theme, ColorScheme colorScheme) {
    final label = widget.createLabelBuilder?.call(_query.trim()) ??
        '创建「${_query.trim()}」';

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      child: InkWell(
        onTap: (_query.trim().isNotEmpty && !_creating) ? _createEntity : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Icon(
                  Icons.add_rounded,
                  size: 16,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Single entity row
// ---------------------------------------------------------------------------

class _EntityPickerRow extends StatelessWidget {
  const _EntityPickerRow({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.colorScheme,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primaryContainer.withValues(alpha: 0.25)
              : null,
        ),
        child: Row(
          children: [
            // Check indicator
            SizedBox(
              width: 22,
              child: Icon(
                selected ? Icons.check_rounded : null,
                size: 20,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
