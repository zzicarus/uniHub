import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

/// 圆角标签（Pill），常用于列表项中的分类/状态标记。
///
/// ```dart
/// UniPill(
///   label: '课程',
///   color: colorScheme.primary,
///   tint: colorScheme.primaryContainer,
/// )
/// ```
class UniPill extends StatelessWidget {
  const UniPill({
    required this.label,
    required this.color,
    required this.tint,
    super.key,
  });

  final String label;
  final Color color;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xxs,
        ),
        child: Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelMedium
              ?.copyWith(color: color),
        ),
      ),
    );
  }
}
