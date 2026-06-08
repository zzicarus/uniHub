import 'package:flutter/material.dart';

import 'app_menu_tokens.dart';

/// A single-select dropdown menu with a pill-style trigger button.
///
/// Replaces scattered [PopupMenuButton] / [DropdownButton] / [showMenu]
/// usages across the app so that every select menu has the same border
/// radius, font, check behaviour, and hover state.
///
/// ```dart
/// AppSelectMenu<String>(
///   value: currentSort,
///   items: sortItems,
///   onChanged: (v) => ref.read(sortProvider.notifier).state = v,
///   label: '排序',
///   leadingIcon: Icons.swap_vert_rounded,
/// )
/// ```
class AppSelectMenu<T> extends StatelessWidget {
  const AppSelectMenu({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.label,
    this.leadingIcon,
    this.minWidth,
    this.enabled = true,
  });

  /// Currently selected value.
  final T value;

  /// Available options.
  final List<AppSelectMenuItem<T>> items;

  /// Called when the user picks a new value.
  final ValueChanged<T> onChanged;

  /// Optional label shown after the arrow (e.g. "来源：网页").
  ///
  /// When null, the label of the currently selected item is used.
  final String? label;

  /// Optional icon shown before the label on the pill trigger.
  final IconData? leadingIcon;

  /// Overrides the default minimum menu width.
  final double? minWidth;

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final currentItem = _currentItem;
    final displayLabel = currentItem?.label ?? items.firstOrNull?.label ?? '';
    final showLabel = label ?? displayLabel;

    return PopupMenuButton<T>(
      initialValue: value,
      onSelected: onChanged,
      enabled: enabled,

      // ── Menu visual ────────────────────────────────────────────────────
      color: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: AppMenuTokens.elevation,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppMenuTokens.borderRadius),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),

      // ── Menu items ─────────────────────────────────────────────────────
      itemBuilder: (context) => [
        for (final item in items)
          PopupMenuItem<T>(
            value: item.value,
            enabled: item.enabled,
            height: AppMenuTokens.itemHeight,
            child: _MenuItemRow(
              icon: item.icon,
              label: item.label,
              isSelected: item.value == value,
              isEnabled: item.enabled,
              destructive: false,
              colorScheme: colorScheme,
            ),
          ),
      ],

      // ── Trigger: pill button ───────────────────────────────────────────
      child: _SelectPill(
        label: showLabel,
        leadingIcon: leadingIcon,
        enabled: enabled,
        colorScheme: colorScheme,
      ),
    );
  }

  AppSelectMenuItem<T>? get _currentItem {
    try {
      return items.firstWhere((e) => e.value == value);
    } catch (_) {
      return null;
    }
  }
}

// ---------------------------------------------------------------------------
// Item data class
// ---------------------------------------------------------------------------

/// A single option inside an [AppSelectMenu].
class AppSelectMenuItem<T> {
  const AppSelectMenuItem({
    required this.value,
    required this.label,
    this.icon,
    this.enabled = true,
  });

  /// Unique value returned via [AppSelectMenu.onChanged].
  final T value;

  /// Display label.
  final String label;

  /// Optional leading icon.
  final IconData? icon;

  /// Whether this item can be selected.
  final bool enabled;
}

// ---------------------------------------------------------------------------
// Trigger pill widget
// ---------------------------------------------------------------------------

class _SelectPill extends StatelessWidget {
  const _SelectPill({
    required this.label,
    this.leadingIcon,
    required this.enabled,
    required this.colorScheme,
  });

  final String label;
  final IconData? leadingIcon;
  final bool enabled;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = enabled
        ? colorScheme.onSurfaceVariant
        : colorScheme.onSurfaceVariant.withValues(alpha: 0.4);

    return Container(
      constraints: AppMenuTokens.pillConstraints(),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppMenuTokens.borderRadius),
        border: Border.all(
          color: enabled
              ? colorScheme.outlineVariant.withValues(alpha: 0.7)
              : colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leadingIcon != null) ...[
            Icon(
              leadingIcon,
              size: 16,
              color: textColor,
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.expand_more_rounded,
            size: 16,
            color: textColor.withValues(alpha: 0.6),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable menu row (shared between select and context menus)
// ---------------------------------------------------------------------------

/// A single row inside a menu.
///
///   ┌─────────────────────────────────────────┐
///   │  [icon]  [label]                 [check] │
///   └─────────────────────────────────────────┘
class _MenuItemRow extends StatelessWidget {
  const _MenuItemRow({
    this.icon,
    required this.label,
    required this.isSelected,
    required this.isEnabled,
    required this.destructive,
    required this.colorScheme,
  });

  final IconData? icon;
  final String label;
  final bool isSelected;
  final bool isEnabled;
  final bool destructive;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = destructive
        ? colorScheme.error
        : isEnabled
            ? colorScheme.onSurface
            : colorScheme.onSurface.withValues(alpha: 0.35);
    final iconColor = destructive
        ? colorScheme.error
        : isEnabled
            ? colorScheme.onSurfaceVariant
            : colorScheme.onSurfaceVariant.withValues(alpha: 0.35);

    return Row(
      children: [
        // Check indicator
        SizedBox(
          width: AppMenuTokens.checkSize,
          child: Icon(
            isSelected ? Icons.check_rounded : null,
            size: AppMenuTokens.checkSize,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(width: 8),

        // Leading icon
        if (icon != null) ...[
          Icon(icon, size: AppMenuTokens.iconSize, color: iconColor),
          const SizedBox(width: 8),
        ],

        // Label
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge?.copyWith(
              color: textColor,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}
