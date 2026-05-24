import 'package:flutter/material.dart';
import 'package:uni_hub/src/core/theme/app_tokens.dart';

class AppSearchBox extends StatelessWidget {
  final double? width;
  final String hintText;
  final VoidCallback? onTap;

  const AppSearchBox({
    required this.hintText,
    this.width,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final borderRadius = BorderRadius.circular(AppRadius.xl);

    final box = Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: borderRadius,
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.35),
          ),
          boxShadow: const [AppShadows.cardSoft],
        ),
        child: InkWell(
          borderRadius: borderRadius,
          onTap: onTap,
          child: SizedBox(
            width: width,
            height: AppSizes.inputHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, color: colorScheme.outline),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      hintText,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.keyboard_command_key_rounded,
                    color: colorScheme.outline,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (width == null) return box;
    return SizedBox(width: width, child: box);
  }
}
