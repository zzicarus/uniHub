import 'package:flutter/material.dart';
import 'package:uni_hub/src/core/theme/app_tokens.dart';
import 'package:uni_hub/src/plugins/thoughts/ui/layouts/thoughts_shared_widgets.dart';

/// Right rail panel with 2 disabled buttons: "转为待办", "转为笔记".
/// Each has Tooltip("即将推出").
/// Visual style: outlined buttons, M3 color scheme.
class ThoughtQuickActionsPanel extends StatelessWidget {
  const ThoughtQuickActionsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ThoughtPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ThoughtPanelHeader(title: '快捷操作', icon: Icons.bolt_outlined),
          const SizedBox(height: AppSpacing.md),
          Tooltip(
            message: '即将推出',
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.check_box_outlined, size: 18),
                label: const Text('转为待办'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.onSurfaceVariant,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Tooltip(
            message: '即将推出',
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.note_outlined, size: 18),
                label: const Text('转为笔记'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.onSurfaceVariant,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
