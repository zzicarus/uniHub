import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uni_hub/src/core/theme/app_tokens.dart';
import 'package:uni_hub/src/plugins/thoughts/providers/thoughts_providers.dart';
import 'package:uni_hub/src/plugins/thoughts/ui/layouts/thoughts_shared_widgets.dart';
import '../../data/thought_content_codec.dart';

/// Right rail panel showing 1 random thought created >7 days ago.
/// "换一个" button to get another random thought.
/// Session-based tracking: `Set&lt;int&gt;` of seen IDs, reset when all seen.
/// Data source: [randomReviewProvider].
class ThoughtRandomReviewPanel extends ConsumerWidget {
  final void Function(int thoughtId)? onThoughtTap;

  const ThoughtRandomReviewPanel({this.onThoughtTap, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final randomAsync = ref.watch(randomReviewProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return ThoughtPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ThoughtPanelHeader(title: '随机回顾', icon: Icons.casino_outlined),
          const SizedBox(height: AppSpacing.md),
          randomAsync.when(
            loading: () => const ThoughtSmallMutedText('加载中...'),
            error: (_, _) => const ThoughtSmallMutedText('加载失败'),
            data: (thought) {
              if (thought == null) {
                return const ThoughtSmallMutedText('没有可回顾的旧想法');
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: onThoughtTap != null
                        ? () => onThoughtTap!(thought.id)
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
                              thought.content,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: AppFontTokens.semiBold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatRelativeDate(thought.createdAt),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Force re-fetch by reading the provider again.
                        // The provider uses a StateProvider for seen IDs,
                        // so each call advances to the next unseen thought.
                        ref.invalidate(randomReviewProvider);
                      },
                      icon: const Icon(Icons.shuffle_rounded, size: 16),
                      label: const Text('换一个'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xs,
                        ),
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

String _formatRelativeDate(DateTime dt) {
  final now = DateTime.now();
  final diff = now.difference(dt);
  final days = diff.inDays;

  if (days == 0) return '今天';
  if (days == 1) return '昨天';
  if (days < 7) return '$days天前';
  if (days < 30) return '${(days / 7).floor()}周前';
  if (days < 365) return '${(days / 30).floor()}个月前';
  return '${dt.year}年${dt.month}月';
}
