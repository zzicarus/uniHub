import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uni_hub/src/core/theme/app_tokens.dart';
import 'package:uni_hub/src/plugins/thoughts/providers/thoughts_providers.dart';
import 'package:uni_hub/src/plugins/thoughts/ui/layouts/thoughts_shared_widgets.dart';

/// Right rail panel showing count of untagged + unarchived thoughts.
/// Phase 1: count badge only, no status filter action on tap.
/// Data source: [pendingReviewProvider] (global, unarchived-only).
class ThoughtPendingReviewPanel extends ConsumerWidget {
  const ThoughtPendingReviewPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingReviewProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return ThoughtPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          pendingAsync.when(
            loading: () => const ThoughtPanelHeader(
              title: '待整理',
              icon: Icons.pending_outlined,
              count: 0,
            ),
            error: (_, _) => const ThoughtPanelHeader(
              title: '待整理',
              icon: Icons.pending_outlined,
              count: 0,
            ),
            data: (pending) => ThoughtPanelHeader(
              title: '待整理',
              icon: Icons.pending_outlined,
              count: pending.length,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          pendingAsync.when(
            loading: () => const ThoughtSmallMutedText('加载中...'),
            error: (_, _) => const ThoughtSmallMutedText('加载失败'),
            data: (pending) {
              if (pending.isEmpty) {
                return ThoughtSmallMutedText('所有想法都已整理');
              }
              return Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: colorScheme.secondary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      '${pending.length} 个想法缺少标签',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
