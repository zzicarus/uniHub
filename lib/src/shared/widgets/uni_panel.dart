import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

/// 带边框和轻阴影的通用内容面板。
///
/// 适用于桌面端卡片、区块容器。比标准 [Card] 更轻量（细边框 + 低阴影）。
///
/// ```dart
/// UniPanel(child: Text('内容'))
/// UniPanel(
///   padding: const EdgeInsets.all(AppSpacing.lg),
///   child: Column(children: [...]),
/// )
/// ```
class UniPanel extends StatelessWidget {
  const UniPanel({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    super.key,
  });

  final EdgeInsetsGeometry padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
