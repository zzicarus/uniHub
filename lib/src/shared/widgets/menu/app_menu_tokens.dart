import 'package:flutter/material.dart';

/// Design tokens shared by all AppMenu* widgets.
///
/// Every menu (select, context, dropdown) uses these constants so that
/// border radius, padding, height, shadow and typography are consistent
/// across the entire app.
abstract final class AppMenuTokens {
  const AppMenuTokens._();

  // ── Sizing ───────────────────────────────────────────────────────────────
  static const double minWidth = 160;
  static const double maxWidth = 320;
  static const double itemHeight = 42;
  static const double dividerHeight = 8;

  // ── Shape ────────────────────────────────────────────────────────────────
  static const double borderRadius = 16;
  static const double horizontalPadding = 14;
  static const double verticalPadding = 8;

  // ── Icons ────────────────────────────────────────────────────────────────
  static const double iconSize = 18;
  static const double checkSize = 18;

  // ── Elevation ────────────────────────────────────────────────────────────
  static const double elevation = 6;
  static const double blurRadius = 12;

  /// Build the [ShapeBorder] for a popup menu.
  static ShapeBorder menuShape() {
    return RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
    );
  }

  /// Build the custom clipping shape that matches [menuShape].
  static ShapeBorderClipper menuClipper() {
    return ShapeBorderClipper(shape: menuShape());
  }

  /// Build the [BoxShadow] applied to the menu surface.
  static List<BoxShadow> menuShadows(ColorScheme colorScheme) {
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.10),
        blurRadius: blurRadius,
        offset: const Offset(0, elevation),
      ),
    ];
  }

  /// The pill-style trigger button dimensions.
  static BoxConstraints pillConstraints() {
    return const BoxConstraints(minHeight: 36, maxHeight: 40);
  }

  /// The icon-only trigger button dimensions.
  static BoxConstraints iconTriggerConstraints() {
    return const BoxConstraints(minWidth: 28, minHeight: 28);
  }
}
