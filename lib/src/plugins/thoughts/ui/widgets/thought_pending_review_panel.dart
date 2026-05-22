import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uni_hub/src/core/theme/app_tokens.dart';
import 'package:uni_hub/src/plugins/thoughts/providers/thought_status_filter.dart';
import 'package:uni_hub/src/plugins/thoughts/providers/thoughts_providers.dart';
import 'package:uni_hub/src/plugins/thoughts/ui/layouts/thoughts_shared_widgets.dart';

class ThoughtPendingReviewPanel extends ConsumerWidget {
  const ThoughtPendingReviewPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingReviewProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return ThoughtPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          pendingAsync.when(
            loading: () => const ThoughtPanelHeader(
              title: '待整理',
              icon: Icons.check_box_outlined,
              count: 0,
            ),
            error: (_, _) => const ThoughtPanelHeader(
              title: '待整理',
              icon: Icons.check_box_outlined,
              count: 0,
            ),
            data: (pending) => ThoughtPanelHeader(
              title: '待整理',
              icon: Icons.check_box_outlined,
              count: pending.length,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          pendingAsync.when(
            loading: () => const ThoughtSmallMutedText('加载中...'),
            error: (_, _) => const ThoughtSmallMutedText('加载失败'),
            data: (pending) {
              if (pending.isEmpty) {
                return const ThoughtSmallMutedText('所有想法都已整理');
              }
              return Row(
                children: [
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        children: [
                          TextSpan(
                            text: '${pending.length} 条未整理\n',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const TextSpan(text: '想法值得被好好整理'),
                        ],
                      ),
                    ),
                  ),
                  FilledButton(
                    onPressed: () {
                      ref.read(archiveFilterProvider.notifier).state = false;
                      ref.read(thoughtStatusFilterProvider.notifier).state =
                          ThoughtStatusFilter.unorganized;
                    },
                    child: const Text('开始整理'),
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
