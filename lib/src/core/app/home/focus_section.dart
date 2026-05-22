part of '../home_page.dart';

// ─── Focus Grid ─────────────────────────────────────────────────────

class _FocusGrid extends ConsumerWidget {
  const _FocusGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final statsAsync = ref.watch(dashboardStatsProvider);
    final thoughtsCount =
        statsAsync.whenOrNull(
          data: (stats) {
            final thoughts = stats
                .where((s) => s.pluginId == 'thoughts')
                .firstOrNull;
            return thoughts?.count ?? 0;
          },
        ) ??
        0;

    final metrics = [
      _MetricCard(
        title: '今日待办',
        value: '—',
        note: '待完成',
        color: colorScheme.primary,
        background: colorScheme.primaryContainer,
        icon: Icons.fact_check_outlined,
      ),
      _MetricCard(
        title: '想法总数',
        value: '$thoughtsCount',
        note: '累计记录',
        color: colorScheme.tertiary,
        background: colorScheme.tertiaryContainer,
        icon: Icons.lightbulb_outline,
      ),
      _MetricCard(
        title: '本周笔记',
        value: '—',
        note: '较上周 +2',
        color: colorScheme.secondary,
        background: colorScheme.secondaryContainer,
        icon: Icons.description_outlined,
      ),
      _MetricCard(
        title: '纪念日',
        value: '—',
        note: '即将到来',
        color: colorScheme.error,
        background: colorScheme.errorContainer,
        icon: Icons.event_available_outlined,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 860 ? 4 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: metrics.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: columns == 4 ? 1.4 : 1.5,
          ),
          itemBuilder: (context, index) => metrics[index],
        );
      },
    );
  }
}
