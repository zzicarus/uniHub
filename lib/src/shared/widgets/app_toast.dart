import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:uni_hub/src/core/theme/app_tokens.dart';

enum AppToastType { info, success, warning, error, destructive }

class AppToast {
  const AppToast._();

  static const Duration defaultDuration = Duration(seconds: 5);
  static const double _desktopWidth = 420;
  static const double _edge = 24;

  static void show(
    BuildContext context, {
    required String message,
    AppToastType type = AppToastType.info,
    Duration duration = defaultDuration,
    String? actionLabel,
    FutureOr<void> Function()? onAction,
  }) {
    assert(
      (actionLabel == null && onAction == null) ||
          (actionLabel != null && onAction != null),
      'actionLabel and onAction must be provided together.',
    );
    _show(
      context,
      message: message,
      type: type,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void undo(
    BuildContext context, {
    required String message,
    required FutureOr<void> Function() onUndo,
    AppToastType type = AppToastType.destructive,
    Duration duration = defaultDuration,
  }) {
    _show(
      context,
      message: message,
      type: type,
      duration: duration,
      actionLabel: '撤销',
      onAction: onUndo,
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    required AppToastType type,
    required Duration duration,
    String? actionLabel,
    FutureOr<void> Function()? onAction,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.sizeOf(context).width;

    final isCompact = screenWidth < 600;
    final leftMargin = isCompact
        ? 16.0
        : math.max(16.0, screenWidth - _desktopWidth - _edge);

    final rightMargin = isCompact ? 16.0 : _edge;
    final bottomMargin = isCompact ? 16.0 : _edge;

    final icon = _iconFor(type);
    final iconColor = _iconColor(type, colorScheme);
    final iconBg = _iconBackground(type, colorScheme);

    final snackBar = SnackBar(
      behavior: SnackBarBehavior.floating,
      duration: duration,
      elevation: 10,
      backgroundColor: colorScheme.inverseSurface,
      margin: EdgeInsets.only(
        left: leftMargin,
        right: rightMargin,
        bottom: bottomMargin,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      content: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onInverseSurface,
                fontWeight: AppFontTokens.medium,
              ),
            ),
          ),
        ],
      ),
      action: actionLabel == null || onAction == null
          ? null
          : SnackBarAction(
              label: actionLabel,
              textColor: colorScheme.inversePrimary,
              onPressed: () {
                unawaited(Future<void>.sync(onAction));
              },
            ),
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }

  static IconData _iconFor(AppToastType type) {
    return switch (type) {
      AppToastType.info => Icons.info_outline_rounded,
      AppToastType.success => Icons.check_circle_outline_rounded,
      AppToastType.warning => Icons.warning_amber_rounded,
      AppToastType.error => Icons.error_outline_rounded,
      AppToastType.destructive => Icons.delete_outline_rounded,
    };
  }

  static Color _iconColor(AppToastType type, ColorScheme colorScheme) {
    return switch (type) {
      AppToastType.info => colorScheme.inversePrimary,
      AppToastType.success => colorScheme.tertiary,
      AppToastType.warning => colorScheme.secondary,
      AppToastType.error => colorScheme.error,
      AppToastType.destructive => colorScheme.error,
    };
  }

  static Color _iconBackground(AppToastType type, ColorScheme colorScheme) {
    return switch (type) {
      AppToastType.info => colorScheme.primaryContainer.withValues(alpha: 0.22),
      AppToastType.success => colorScheme.tertiaryContainer.withValues(
        alpha: 0.26,
      ),
      AppToastType.warning => colorScheme.secondaryContainer.withValues(
        alpha: 0.26,
      ),
      AppToastType.error => colorScheme.errorContainer.withValues(alpha: 0.26),
      AppToastType.destructive => colorScheme.errorContainer.withValues(
        alpha: 0.26,
      ),
    };
  }
}
