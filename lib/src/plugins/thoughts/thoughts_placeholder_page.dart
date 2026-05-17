import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_tokens.dart';

class ThoughtsPlaceholderPage extends ConsumerWidget {
  const ThoughtsPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 48,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Thoughts', style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text('Coming soon', style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
