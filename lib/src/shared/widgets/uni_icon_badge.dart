import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../core/theme/app_tokens.dart';

/// 带半透明底色 + 圆角矩形的图标装饰。
///
/// 适用于状态图标、分类标识等纯装饰场景。
///
/// ```dart
/// UniIconBadge(
///   icon: Icons.task_alt_rounded,
///   color: colorScheme.primary,
/// )
/// ```
class UniIconBadge extends StatelessWidget {
  const UniIconBadge({
    required this.icon,
    required this.color,
    this.size = AppSizes.statusIcon,
    super.key,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: SizedBox.square(
        dimension: size,
        child: Icon(icon, color: color),
      ),
    );
  }
}

// ----------------------------------------------------------------------
// Previews
// ----------------------------------------------------------------------

@Preview(name: 'UniIconBadge primary', group: 'Shared')
Widget uniIconBadgePrimaryPreview() {
  return const Padding(
    padding: EdgeInsets.all(8),
    child: UniIconBadge(
      icon: Icons.task_alt_rounded,
      color: Color(0xFF4F6BFF),
    ),
  );
}

@Preview(name: 'UniIconBadge secondary', group: 'Shared')
Widget uniIconBadgeSecondaryPreview() {
  return const Padding(
    padding: EdgeInsets.all(8),
    child: UniIconBadge(
      icon: Icons.lightbulb_outline,
      color: Color(0xFF22C55E),
    ),
  );
}

@Preview(name: 'UniIconBadge custom size', group: 'Shared')
Widget uniIconBadgeCustomSizePreview() {
  return const Padding(
    padding: EdgeInsets.all(8),
    child: UniIconBadge(
      icon: Icons.error_outline_rounded,
      color: Color(0xFFF43F5E),
      size: 64,
    ),
  );
}
