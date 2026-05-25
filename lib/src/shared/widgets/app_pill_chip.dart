import 'package:flutter/material.dart';
import 'package:uni_hub/src/core/theme/app_tokens.dart';

/// A versatile pill-styled chip widget for filter bars, tab rows, and action
/// buttons.
///
/// Comes in two modes:
/// - **normal** (default): height 34, horizontal padding 12, icon size 15,
///   font size 13
/// - **compact**: height 30, horizontal padding 10, icon size 14, font size 12
///
/// Colors follow Material 3 conventions:
/// - Selected: `primaryContainer` background, `primary` foreground & border
/// - Unselected: `surfaceContainerLow` background, `onSurfaceVariant`
///   foreground, `outlineVariant` border
/// - Disabled: transparent background, reduced alpha foreground & border
class AppPillChip extends StatelessWidget {
  const AppPillChip({
    required this.label,
    required this.selected,
    this.onTap,
    this.icon,
    this.compact = false,
    this.enabled = true,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool compact;
  final bool enabled;

  double get _height => compact ? 30.0 : 34.0;
  double get _hPadding => compact ? 10.0 : 12.0;
  double get _iconSize => compact ? 14.0 : 15.0;
  double get _fontSize => compact ? 12.0 : 13.0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isActive = enabled && selected;
    final isInactive = enabled && !selected;

    // ── Colors ──
    final Color backgroundColor;
    final Color foregroundColor;
    final Color borderColor;

    if (isActive) {
      backgroundColor =
          colorScheme.primaryContainer.withValues(alpha: 0.50);
      foregroundColor = colorScheme.primary;
      borderColor = colorScheme.primary.withValues(alpha: 0.40);
    } else if (isInactive) {
      backgroundColor = colorScheme.surfaceContainerLow;
      foregroundColor = colorScheme.onSurfaceVariant;
      borderColor = colorScheme.outlineVariant.withValues(alpha: 0.75);
    } else {
      backgroundColor = Colors.transparent;
      foregroundColor =
          colorScheme.onSurfaceVariant.withValues(alpha: 0.40);
      borderColor = colorScheme.outlineVariant.withValues(alpha: 0.35);
    }

    final borderRadius = BorderRadius.circular(AppRadius.full);

    final textStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
          fontSize: _fontSize,
          height: 1.15,
          letterSpacing: 0,
          fontWeight:
              selected ? AppFontTokens.semiBold : AppFontTokens.medium,
          color: foregroundColor,
        );

    final effectiveOnTap = enabled ? onTap : null;

    return Material(
      type: MaterialType.transparency,
      child: Ink(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: borderRadius,
          border: Border.all(color: borderColor),
        ),
        child: InkWell(
          borderRadius: borderRadius,
          onTap: effectiveOnTap,
          child: SizedBox(
            height: _height,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: _hPadding),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: _iconSize,
                      color: foregroundColor,
                    ),
                    const SizedBox(width: AppSpacing.xxs),
                  ],
                  Text(label, style: textStyle),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
