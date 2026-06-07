import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uni_hub/src/core/theme/app_tokens.dart';
import 'package:uni_hub/src/plugins/collections/providers/collections_providers.dart';

import '../widgets/collection_command_bar.dart';
import '../widgets/saved_item_card.dart';
import '../widgets/saved_item_detail_panel.dart';

/// 移动端收藏布局：简化版列表，无侧栏和详情面板。
///
/// 点击卡片弹出详情 bottom sheet。
class CollectionsMobileLayout extends ConsumerWidget {
  const CollectionsMobileLayout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(savedItemListEntriesProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '内容库',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: AppFontTokens.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const CollectionCommandBar(),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: entriesAsync.when(
                data: (entries) {
                  if (entries.isEmpty) {
                    return _buildEmptyState(context);
                  }
                  return ListView.separated(
                    itemCount: entries.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (ctx, index) {
                      final entry = entries[index];
                      return SavedItemCard(
                        key: ValueKey(entry.item.id),
                        entry: entry,
                        onTap: () {
                          ref
                              .read(selectedSavedItemIdProvider.notifier)
                              .state = entry.item.id;
                          showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            useSafeArea: true,
                            builder: (_) {
                              return FractionallySizedBox(
                                heightFactor: 0.92,
                                child: SavedItemDetailPanel(entry: entry),
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (e, _) => Center(
                  child: Text('加载失败：$e'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.bookmark_add_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '还没有收藏',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ],
      ),
    );
  }
}
