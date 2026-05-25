import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uni_hub/src/core/theme/app_tokens.dart';
import 'package:uni_hub/src/plugins/thoughts/providers/thoughts_providers.dart';
import 'package:uni_hub/src/plugins/thoughts/ui/layouts/thoughts_shared_widgets.dart';
import '../../data/thought_content_codec.dart';

/// Right rail panel showing top 3 pinned, unarchived thoughts.
/// Data source: [pinnedThoughtsProvider] (global, NOT filtered by main tag/search).
class ThoughtPinnedPanel extends ConsumerWidget {
  final void Function(int thoughtId)? onThoughtTap;

  const ThoughtPinnedPanel({this.onThoughtTap, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinnedAsync = ref.watch(pinnedThoughtsProvider);

    return ThoughtPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          pinnedAsync.when(
            loading: () => const ThoughtPanelHeader(
              title: '置顶想法',
              icon: Icons.push_pin_rounded,
              count: 0,
            ),
            error: (_, _) => const ThoughtPanelHeader(
              title: '置顶想法',
              icon: Icons.push_pin_rounded,
              count: 0,
            ),
            data: (pinned) => ThoughtPanelHeader(
              title: '置顶想法',
              icon: Icons.push_pin_rounded,
              count: pinned.length,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          pinnedAsync.when(
            loading: () => const ThoughtSmallMutedText('加载中...'),
            error: (_, _) => const ThoughtSmallMutedText('加载失败'),
            data: (pinned) => pinned.isEmpty
                ? const ThoughtSmallMutedText('暂无置顶想法')
                : Column(
                    children: pinned
                        .map(
                          (t) => InkWell(
                            onTap: onThoughtTap != null
                                ? () => onThoughtTap!(t.id)
                                : null,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.xs,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ThoughtContentCodec.titleFromStored(
                                      t.content,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontWeight: AppFontTokens.semiBold),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _formatTimestamp(t.createdAt),
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

String _formatTimestamp(DateTime dt) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final date = DateTime(dt.year, dt.month, dt.day);

  if (date == today) {
    return '今天 ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  } else if (date == yesterday) {
    return '昨天 ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  } else if (dt.year == now.year) {
    return '${dt.month}月${dt.day}日';
  }
  return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}
