import 'package:flutter/material.dart';
import 'package:uni_hub/src/core/theme/app_tokens.dart';

/// A responsive page header that adapts to available width.
///
/// Three layout modes (driven by [LayoutBuilder]):
/// - **Wide** (≥ [compactBreakpoint]): title + subtitle + search + actions in one Row.
/// - **Compact** ([narrowBreakpoint] ~ [compactBreakpoint]): first Row for
///   title/subtitle/actions, second row for search (full width).
/// - **Narrow** (< [narrowBreakpoint]): title + actions in first Row, subtitle
///   in second row, search in third row (all full-width).
///
/// [title] always uses `maxLines: 1` + `TextOverflow.ellipsis` to prevent
/// vertical stacking in narrow contexts — the most common layout bug in
/// Chinese Flutter apps.
///
/// [subtitle] uses `maxLines: 2` in compact mode, `maxLines: 1` in narrow,
/// and is hidden in narrow mode (shown in its own row instead).
///
/// [search] never enforces a `minWidth` — it becomes full-width below the
/// compact breakpoint.
///
/// **Actions**: each [action] is a widget rendered as-is. For responsive
/// icon-only behaviour, the caller should pass different widgets for
/// different width bands by using [LayoutBuilder] or [MediaQuery] _before_
/// constructing this widget.
class ResponsivePageHeader extends StatelessWidget {
  const ResponsivePageHeader({
    required this.title,
    this.subtitle,
    this.search,
    this.actions = const [],
    this.compactBreakpoint = 1100,
    this.narrowBreakpoint = 760,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? search;
  final List<Widget> actions;
  final double compactBreakpoint;
  final double narrowBreakpoint;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isCompact = width < compactBreakpoint;
        final isNarrow = width < narrowBreakpoint;

        if (!isCompact) {
          return _wideLayout(context);
        }
        if (isNarrow) {
          return _narrowLayout(context);
        }
        return _compactLayout(context);
      },
    );
  }

  // ---------------------------------------------------------------
  // Wide: single row
  // ---------------------------------------------------------------
  Widget _wideLayout(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Title + subtitle
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.headlineMedium,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  subtitle!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (search != null) ...[
          const SizedBox(width: AppSpacing.lg),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: search!,
          ),
        ],
        for (final action in actions) ...[
          const SizedBox(width: AppSpacing.sm),
          action,
        ],
      ],
    );
  }

  // ---------------------------------------------------------------
  // Compact: title + actions first row, search second row
  // ---------------------------------------------------------------
  Widget _compactLayout(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.headlineMedium,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            for (final action in actions) ...[
              const SizedBox(width: AppSpacing.sm),
              action,
            ],
          ],
        ),
        if (search != null) ...[
          const SizedBox(height: AppSpacing.sm),
          SizedBox(width: double.infinity, child: search!),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------
  // Narrow: title + actions first row, subtitle second, search third
  // ---------------------------------------------------------------
  Widget _narrowLayout(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Row 1: title + actions
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.headlineMedium,
              ),
            ),
            ...actions.map(
              (action) => Padding(
                padding: const EdgeInsets.only(left: AppSpacing.xs),
                child: action,
              ),
            ),
          ],
        ),
        // Row 2: subtitle
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.xxs),
          Text(
            subtitle!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        // Row 3: search
        if (search != null) ...[
          const SizedBox(height: AppSpacing.sm),
          SizedBox(width: double.infinity, child: search!),
        ],
      ],
    );
  }
}
