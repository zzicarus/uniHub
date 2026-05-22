part of '../home_page.dart';

// ─── Focus Grid ─────────────────────────────────────────────────────

class _FocusGrid extends ConsumerWidget {
  const _FocusGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        note: '2/6 已完成',
        color: AppColors.primary,
        background: AppColors.primarySoft,
        icon: Icons.fact_check_outlined,
      ),
      _MetricCard(
        title: '想法总数',
        value: '$thoughtsCount',
        note: '累计记录',
        color: AppColors.purple,
        background: AppColors.purpleSoft,
        icon: Icons.lightbulb_outline,
      ),
      _MetricCard(
        title: '本周笔记',
        value: '—',
        note: '较上周 +2',
        color: AppColors.secondary,
        background: AppColors.greenSoft,
        icon: Icons.description_outlined,
      ),
      _MetricCard(
        title: '纪念日',
        value: '—',
        note: '最近 1 天后',
        color: AppColors.error,
        background: AppColors.roseSoft,
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
            childAspectRatio: columns == 4 ? 2.05 : 2.2,
          ),
          itemBuilder: (context, index) => metrics[index],
        );
      },
    );
  }
}
