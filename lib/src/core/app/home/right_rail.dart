part of '../home_page.dart';

// ─── Home Right Rail ────────────────────────────────────────────────

class _HomeRightRail extends StatelessWidget {
  const _HomeRightRail();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: AppDesktopSizes.rightRailWideWidth,
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          left: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xxl,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        child: Column(
          children: [
            const _TodayOverviewPanel(),
            const SizedBox(height: AppSpacing.lg),
            const _UpcomingSchedulePanel(),
            const SizedBox(height: AppSpacing.lg),
            const _AnniversaryPanel(),
            const SizedBox(height: AppSpacing.lg),
            const _StreakPanel(),
            const SizedBox(height: AppSpacing.xxl),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 14, color: colorScheme.outline),
                const SizedBox(width: AppSpacing.xxs),
                Text(
                  '你的数据，仅你可见',
                  style: TextStyle(color: colorScheme.outline, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayOverviewPanel extends StatelessWidget {
  const _TodayOverviewPanel();

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          AppSectionHeader(title: '今日概览', icon: Icons.today_outlined),
          SizedBox(height: AppSpacing.md),
          _OverviewLine(
            label: '已完成待办',
            value: '2/6',
            color: AppColors.primary,
            background: AppColors.primarySoft,
          ),
          _OverviewLine(
            label: '今日想法',
            value: '3',
            color: AppColors.purple,
            background: AppColors.purpleSoft,
          ),
          _OverviewLine(
            label: '专注记录',
            value: '2.5 小时',
            color: AppColors.secondary,
            background: AppColors.greenSoft,
          ),
        ],
      ),
    );
  }
}

class _OverviewLine extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color background;

  const _OverviewLine({
    required this.label,
    required this.value,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: background.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpcomingSchedulePanel extends StatelessWidget {
  const _UpcomingSchedulePanel();

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          AppSectionHeader(title: '近日日程', icon: Icons.event_note_outlined),
          SizedBox(height: AppSpacing.sm),
          AppCompactListItem(
            icon: Icons.groups_2_outlined,
            color: AppColors.primary,
            background: AppColors.primarySoft,
            title: '产品评审会议',
            subtitle: '今天 14:00',
          ),
          AppCompactListItem(
            icon: Icons.draw_outlined,
            color: AppColors.purple,
            background: AppColors.purpleSoft,
            title: '设计走查',
            subtitle: '明天 10:00',
          ),
          AppCompactListItem(
            icon: Icons.fact_check_outlined,
            color: AppColors.accent,
            background: AppColors.yellowSoft,
            title: '周度复盘',
            subtitle: '周五 16:00',
          ),
        ],
      ),
    );
  }
}

class _AnniversaryPanel extends StatelessWidget {
  const _AnniversaryPanel();

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          AppSectionHeader(title: '纪念日提醒', icon: Icons.celebration_outlined),
          SizedBox(height: AppSpacing.sm),
          AppCompactListItem(
            icon: Icons.rocket_launch_outlined,
            color: AppColors.primary,
            background: AppColors.primarySoft,
            title: 'uniHub 启动纪念',
            subtitle: '1 天后',
          ),
          AppCompactListItem(
            icon: Icons.cake_outlined,
            color: AppColors.error,
            background: AppColors.roseSoft,
            title: 'Alex 生日',
            subtitle: '146 天后',
          ),
        ],
      ),
    );
  }
}

class _StreakPanel extends StatelessWidget {
  const _StreakPanel();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    const activeDays = [true, true, true, true, false, true, true];

    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(
            title: '连续记录',
            icon: Icons.local_fire_department_outlined,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '12',
                style: theme.textTheme.displaySmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w900,
                  height: 0.95,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(
                  '天',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              for (var i = 0; i < activeDays.length; i++) ...[
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: activeDays[i]
                        ? AppColors.primary
                        : colorScheme.surfaceContainerHigh,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: activeDays[i]
                          ? AppColors.primary.withValues(alpha: 0.4)
                          : colorScheme.outlineVariant,
                    ),
                  ),
                ),
                if (i != activeDays.length - 1)
                  const SizedBox(width: AppSpacing.xs),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Work Grid Panels ───────────────────────────────────────────────

class _TodoPanel extends StatelessWidget {
  const _TodoPanel();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(title: '今日待办', icon: Icons.check_box_outlined),
          const SizedBox(height: AppSpacing.md),
          AppCompactListItem(
            icon: Icons.radio_button_unchecked_rounded,
            color: AppColors.primary,
            background: AppColors.primarySoft,
            title: '整理 Dashboard 改造清单',
            subtitle: '今天 · 高优先级',
            trailing: Icon(
              Icons.more_horiz_rounded,
              color: colorScheme.outline,
            ),
          ),
          AppCompactListItem(
            icon: Icons.radio_button_unchecked_rounded,
            color: AppColors.secondary,
            background: AppColors.greenSoft,
            title: '复盘本周笔记结构',
            subtitle: '今天 · 30 分钟',
            trailing: Icon(
              Icons.more_horiz_rounded,
              color: colorScheme.outline,
            ),
          ),
          AppCompactListItem(
            icon: Icons.check_circle_rounded,
            color: AppColors.secondary,
            background: AppColors.greenSoft,
            title: '同步最近想法',
            subtitle: '已完成',
          ),
        ],
      ),
    );
  }
}

class _ActivityPanel extends StatelessWidget {
  const _ActivityPanel();

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          AppSectionHeader(title: '最近活动', icon: Icons.trending_up_rounded),
          SizedBox(height: AppSpacing.md),
          _ActivityLine(
            icon: Icons.lightbulb_outline,
            color: AppColors.purple,
            title: '创建了 3 条想法',
            time: '今天 10:24',
          ),
          _ActivityLine(
            icon: Icons.description_outlined,
            color: AppColors.primary,
            title: '更新了笔记《设计系统调研》',
            time: '昨天 20:11',
          ),
          _ActivityLine(
            icon: Icons.check_box_outlined,
            color: AppColors.secondary,
            title: '完成了待办《周报整理》',
            time: '昨天 18:35',
          ),
          _ActivityLine(
            icon: Icons.star_border_rounded,
            color: AppColors.error,
            title: '收藏了 1 条内容',
            time: '5月19日',
          ),
        ],
      ),
    );
  }
}
