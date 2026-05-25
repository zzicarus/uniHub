import 'package:flutter/material.dart';
import 'package:uni_hub/src/core/theme/app_tokens.dart';

class AppSectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final String? trailingText;
  final VoidCallback? onTrailingTap;

  const AppSectionHeader({
    required this.title,
    this.icon,
    this.trailingText,
    this.onTrailingTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: colorScheme.primary),
          const SizedBox(width: AppSpacing.xs),
        ],
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: AppFontTokens.bold,
            ),
          ),
        ),
        if (trailingText != null)
          Material(
            type: MaterialType.transparency,
            child: Ink(
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                onTap: onTrailingTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: AppSpacing.xxs,
                  ),
                  child: Text(
                    '$trailingText  →',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: AppFontTokens.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
