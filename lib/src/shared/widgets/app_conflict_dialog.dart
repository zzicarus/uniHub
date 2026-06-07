import 'package:flutter/material.dart';
import 'package:uni_hub/src/core/theme/app_tokens.dart';

class AppConflictAction<T> {
  const AppConflictAction({
    required this.value,
    required this.label,
    this.description,
    this.destructive = false,
  });

  final T value;
  final String label;
  final String? description;
  final bool destructive;
}

class AppConflictDialog<T> extends StatelessWidget {
  const AppConflictDialog({
    super.key,
    required this.title,
    required this.message,
    required this.actions,
    this.icon = Icons.warning_amber_rounded,
  });

  final String title;
  final String message;
  final List<AppConflictAction<T>> actions;
  final IconData icon;

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required String message,
    required List<AppConflictAction<T>> actions,
    IconData icon = Icons.warning_amber_rounded,
  }) {
    return showDialog<T>(
      context: context,
      builder: (context) => AppConflictDialog<T>(
        title: title,
        message: message,
        actions: actions,
        icon: icon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Icon(icon, color: colorScheme.onSecondaryContainer),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: AppFontTokens.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              for (final action in actions) ...[
                _ConflictActionTile<T>(action: action),
                const SizedBox(height: AppSpacing.xs),
              ],
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConflictActionTile<T> extends StatelessWidget {
  const _ConflictActionTile({required this.action});

  final AppConflictAction<T> action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final foreground = action.destructive
        ? colorScheme.error
        : colorScheme.primary;

    return OutlinedButton(
      onPressed: () => Navigator.of(context).pop(action.value),
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        foregroundColor: foreground,
        padding: const EdgeInsets.all(AppSpacing.md),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              action.label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: foreground,
                fontWeight: AppFontTokens.semiBold,
              ),
            ),
            if (action.description != null) ...[
              const SizedBox(height: AppSpacing.xxs),
              Text(
                action.description!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
