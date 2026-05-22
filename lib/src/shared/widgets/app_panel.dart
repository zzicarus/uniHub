import 'package:flutter/material.dart';
import 'package:uni_hub/src/core/theme/app_tokens.dart';

/// UniHub dashboard panel with unified desktop card styling.
class AppPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final bool selected;
  final bool compact;
  final Color? background;
  final Color? borderColor;
  final double? radius;
  final List<BoxShadow>? shadows;

  const AppPanel({
    required this.child,
    this.padding,
    this.onTap,
    this.selected = false,
    this.compact = false,
    this.background,
    this.borderColor,
    this.radius,
    this.shadows,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final resolvedRadius = radius ?? AppRadius.xl;
    final resolvedBackground =
        background ??
        (selected
            ? Color.alphaBlend(
                colorScheme.primary.withValues(alpha: 0.06),
                colorScheme.surface,
              )
            : colorScheme.surface);
    final resolvedBorder =
        borderColor ??
        (selected
            ? colorScheme.primary.withValues(alpha: 0.42)
            : colorScheme.outlineVariant.withValues(alpha: 0.35));
    final resolvedPadding =
        padding ?? EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.lg);
    final borderRadius = BorderRadius.circular(resolvedRadius);

    final content = Padding(padding: resolvedPadding, child: child);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: resolvedBackground,
        borderRadius: borderRadius,
        border: Border.all(color: resolvedBorder),
        boxShadow: shadows ?? const [AppShadows.cardSoft],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAlias,
        child: onTap == null
            ? content
            : InkWell(borderRadius: borderRadius, onTap: onTap, child: content),
      ),
    );
  }
}
