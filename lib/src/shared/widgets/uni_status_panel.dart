import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../core/theme/app_tokens.dart';
import 'uni_icon_badge.dart';

/// 通用空状态/错误状态面板。
///
/// 带图标、标题、描述和操作按钮，适用于列表为空或发生错误时的占位展示。
///
/// ```dart
/// UniStatusPanel(
///   icon: Icons.inbox_outlined,
///   iconColor: colorScheme.secondary,
///   title: '今天还没有安排',
///   message: '添加事项后这里会展示。',
///   actionLabel: '添加事项',
/// )
/// ```
class UniStatusPanel extends StatelessWidget {
  const UniStatusPanel({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    this.actionLabel,
    this.isOutlinedAction = false,
    this.onAction,
    super.key,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final String? actionLabel;
  final bool isOutlinedAction;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            UniIconBadge(icon: icon, color: iconColor),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              style: textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: isOutlinedAction
                    ? OutlinedButton(
                        onPressed: onAction,
                        child: Text(actionLabel!),
                      )
                    : FilledButton(
                        onPressed: onAction,
                        child: Text(actionLabel!),
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------
// Previews
// ----------------------------------------------------------------------

@Preview(name: 'UniStatusPanel empty', group: 'Shared')
Widget uniStatusPanelEmptyPreview() {
  return const Padding(
    padding: EdgeInsets.all(16),
    child: SizedBox(
      width: 320,
      child: UniStatusPanel(
        icon: Icons.inbox_outlined,
        iconColor: Color(0xFF22C55E),
        title: '今天还没有安排',
        message: '添加课程、活动或待办后，这里会展示接下来要处理的事项。',
        actionLabel: '添加事项',
      ),
    ),
  );
}

@Preview(name: 'UniStatusPanel error', group: 'Shared')
Widget uniStatusPanelErrorPreview() {
  return const Padding(
    padding: EdgeInsets.all(16),
    child: SizedBox(
      width: 320,
      child: UniStatusPanel(
        icon: Icons.error_outline_rounded,
        iconColor: Color(0xFFF43F5E),
        title: '同步失败',
        message: '当前网络不稳定，部分数据可能不是最新状态。',
        actionLabel: '重试',
        isOutlinedAction: true,
      ),
    ),
  );
}
