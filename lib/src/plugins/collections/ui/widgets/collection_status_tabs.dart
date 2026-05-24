import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uni_hub/src/core/theme/app_tokens.dart';
import 'package:uni_hub/src/plugins/collections/domain/consumption_status.dart';
import 'package:uni_hub/src/plugins/collections/providers/collections_providers.dart';

class CollectionStatusTabs extends ConsumerWidget {
  const CollectionStatusTabs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(collectionStatusFilterProvider);
    final colorScheme = Theme.of(context).colorScheme;

    final tabs = <_StatusTab>[
      const _StatusTab(label: '全部'),
      const _StatusTab(label: '待看', status: ConsumptionStatus.unread),
      const _StatusTab(label: '阅读中', status: ConsumptionStatus.inProgress),
      const _StatusTab(label: '已看', status: ConsumptionStatus.done),
      const _StatusTab(label: '归档', status: ConsumptionStatus.archived),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final tab in tabs) ...[
            ChoiceChip(
              label: Text(tab.label),
              selected: selected == tab.status,
              onSelected: (_) {
                ref.read(collectionStatusFilterProvider.notifier).state =
                    tab.status;
              },
              selectedColor: colorScheme.primary,
              backgroundColor: colorScheme.surfaceContainerLow,
              side: BorderSide(
                color: selected == tab.status
                    ? colorScheme.primary
                    : colorScheme.outlineVariant,
              ),
              labelStyle: TextStyle(
                color: selected == tab.status
                    ? colorScheme.onPrimary
                    : colorScheme.onSurface,
                fontWeight: selected == tab.status
                    ? FontWeight.w700
                    : FontWeight.w500,
              ),
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
        ],
      ),
    );
  }
}

class _StatusTab {
  const _StatusTab({required this.label, this.status});

  final String label;
  final ConsumptionStatus? status;
}
