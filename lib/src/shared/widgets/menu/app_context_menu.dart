import 'package:flutter/material.dart';

import 'app_menu_tokens.dart';

/// An action menu (a.k.a. "more" / overflow menu) triggered by an icon
/// button, typically three dots or a gear icon.
///
/// Replaces scattered [PopupMenuButton] usages for action menus (open,
/// copy, archive, delete, etc.) so that destructive items, disabled
/// items, and dividers are rendered consistently.
///
/// ```dart
/// AppContextMenu(
///   items: [
///     AppContextMenuAction(label: '打开', icon: Icons.open_in_new, onPressed: onOpen),
///     AppContextMenuDivider(),
///     AppContextMenuAction(label: '删除', icon: Icons.delete, destructive: true, onPressed: onDelete),
///   ],
/// )
/// ```
class AppContextMenu extends StatelessWidget {
  const AppContextMenu({
    super.key,
    required this.items,
    this.tooltip = '更多操作',
    this.icon = Icons.more_horiz_rounded,
    this.onAny,
  });

  /// Menu entries (actions and dividers).
  final List<AppContextMenuEntry> items;

  /// Tooltip for the trigger icon button.
  final String tooltip;

  /// Icon shown on the trigger button.
  final IconData icon;

  /// Optional callback invoked when **any** action fires (in addition to
  /// the per-item [AppContextMenuAction.onPressed]).
  final VoidCallback? onAny;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopupMenuButton<_ActionValue>(
      tooltip: tooltip,
      padding: EdgeInsets.zero,
      icon: Icon(icon, size: 16),
      iconColor: colorScheme.onSurfaceVariant,

      // ── Menu visual ────────────────────────────────────────────────────
      color: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: AppMenuTokens.elevation,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppMenuTokens.borderRadius),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),

      // ── Build items ────────────────────────────────────────────────────
      itemBuilder: (context) {
        final entries = <PopupMenuEntry<_ActionValue>>[];
        var actionIndex = 0;

        for (final entry in items) {
          switch (entry) {
            case AppContextMenuAction(:final label, :final icon, :final destructive, :final enabled):
              entries.add(
                PopupMenuItem<_ActionValue>(
                  value: _ActionValue(index: actionIndex++),
                  enabled: enabled,
                  height: AppMenuTokens.itemHeight,
                  child: _MenuItemRow(
                    icon: icon,
                    label: label,
                    isSelected: false,
                    isEnabled: enabled,
                    destructive: destructive,
                    colorScheme: colorScheme,
                  ),
                ),
              );

            case AppContextMenuDivider():
              entries.add(const PopupMenuDivider(height: AppMenuTokens.dividerHeight));
          }
        }

        return entries;
      },

      onSelected: (value) {
        // Find the matching action entry by index.
        var idx = 0;
        for (final entry in items) {
          if (entry is AppContextMenuAction) {
            if (idx == value.index) {
              entry.onPressed();
              onAny?.call();
              return;
            }
            idx++;
          }
        }
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Entry types
// ---------------------------------------------------------------------------

/// A single entry inside an [AppContextMenu].
sealed class AppContextMenuEntry {
  const AppContextMenuEntry();
}

/// A menu action item with optional icon and destructive style.
class AppContextMenuAction extends AppContextMenuEntry {
  const AppContextMenuAction({
    required this.label,
    required this.onPressed,
    this.icon,
    this.destructive = false,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool destructive;
  final bool enabled;
}

/// A visual divider between groups of menu items.
class AppContextMenuDivider extends AppContextMenuEntry {
  const AppContextMenuDivider();
}

// ---------------------------------------------------------------------------
// Internal value type (avoids leaking action objects into PopupMenuButton)
// ---------------------------------------------------------------------------

class _ActionValue {
  const _ActionValue({required this.index});
  final int index;
}

// ---------------------------------------------------------------------------
// Reusable menu row (same visual as AppSelectMenu's row)
// ---------------------------------------------------------------------------

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
        // Check indicator (always invisible in context menu — space kept for alignment)
        SizedBox(
          width: AppMenuTokens.checkSize,
          child: isSelected
              ? Icon(Icons.check_rounded, size: AppMenuTokens.checkSize, color: colorScheme.primary)
              : null,
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
