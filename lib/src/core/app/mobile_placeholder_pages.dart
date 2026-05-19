import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

class TodosPage extends StatelessWidget {
  const TodosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _MobilePageFrame(
      title: '待办',
      subtitle: '聚焦重要任务，专注当下',
      leadingIcon: Icons.check_box_outlined,
      actions: const [
        _HeaderAction(icon: Icons.search_rounded),
        _HeaderAction(icon: Icons.tune_rounded),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.xl),
          const _TodoStatsGrid(),
          const SizedBox(height: AppSpacing.xl),
          const _FilterBar(
            filters: ['全部', '今天', '本周', '已完成'],
            trailingLabel: '优先级',
          ),
          const SizedBox(height: AppSpacing.lg),
          _SectionHeader(title: '今天', count: '5'),
          const SizedBox(height: AppSpacing.sm),
          _Panel(
            child: Column(
              children: const [
                _TodoRow(
                  title: '完成产品原型设计',
                  tag: '工作',
                  time: '09:30',
                  priority: '高',
                ),
                _TodoRow(
                  title: '回复合作伙伴邮件',
                  tag: '工作',
                  time: '11:00',
                  done: true,
                ),
                _TodoRow(title: '晨跑 5 公里', tag: '生活', time: '07:00'),
                _TodoRow(title: '阅读《设计心理学》', tag: '学习', time: '20:00'),
                _TodoRow(title: '整理周报数据', tag: '工作', time: '21:30'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const _FocusPanel(),
          const SizedBox(height: AppSpacing.xl),
          const _ProgressPanel(),
        ],
      ),
    );
  }
}

class NotesPage extends StatelessWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _MobilePageFrame(
      title: '笔记',
      subtitle: '记录与沉淀知识',
      actions: const [_HeaderAction(icon: Icons.notifications_none_rounded)],
      floatingButton: const _FloatingAction(label: '新建笔记', icon: Icons.add),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          SizedBox(height: AppSpacing.xl),
          _HorizontalPills(
            labels: ['全部  42', '工作  16', '学习  12', '阅读  8', '归档  6'],
          ),
          SizedBox(height: AppSpacing.lg),
          _SearchField(hint: '搜索笔记', trailing: Icons.tune_rounded),
          SizedBox(height: AppSpacing.lg),
          _PinnedNoteList(),
          SizedBox(height: AppSpacing.lg),
          _EditorPreviewPanel(),
        ],
      ),
    );
  }
}

class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _MobilePageFrame(
      title: '日历',
      subtitle: '规划你的时间，专注每一天的成长',
      showBrand: true,
      actions: const [_HeaderAction(icon: Icons.notifications_none_rounded)],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          SizedBox(height: AppSpacing.xl),
          _CalendarOverview(),
          SizedBox(height: AppSpacing.xl),
          _SchedulePanel(),
          SizedBox(height: AppSpacing.xl),
          _ReminderAndHabitRow(),
        ],
      ),
    );
  }
}

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _MobilePageFrame(
      title: '收藏',
      subtitle: '你收藏的重要信息都在这里',
      showBrand: true,
      actions: const [
        _HeaderAction(icon: Icons.notifications_none_rounded),
        _HeaderAction(icon: Icons.search_rounded, filled: true),
        _HeaderAction(icon: Icons.more_vert_rounded, filled: true),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          SizedBox(height: AppSpacing.xl),
          _HorizontalPills(
            labels: ['全部  28', '想法  7', '笔记  9', '链接  6', '文件  6'],
          ),
          SizedBox(height: AppSpacing.lg),
          _FavoriteList(),
          SizedBox(height: AppSpacing.lg),
          _FavoriteFolders(),
        ],
      ),
    );
  }
}

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _MobilePageFrame(
      title: '搜索',
      subtitle: '快速查找你在 uniHub 中的所有内容',
      showBrand: true,
      actions: const [_HeaderAction(icon: Icons.notifications_none_rounded)],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          SizedBox(height: AppSpacing.xl),
          _SearchField(
            hint: '搜索想法、待办、笔记、日程、收藏...',
            trailing: Icons.mic_none_rounded,
          ),
          SizedBox(height: AppSpacing.lg),
          _RecentSearches(),
          SizedBox(height: AppSpacing.lg),
          _HorizontalPills(labels: ['全部', '想法', '待办', '笔记', '日历', '收藏']),
          SizedBox(height: AppSpacing.lg),
          _SearchResultGroups(),
          SizedBox(height: AppSpacing.lg),
          _SearchSuggestions(),
        ],
      ),
    );
  }
}

class _MobilePageFrame extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final IconData? leadingIcon;
  final List<Widget> actions;
  final bool showBrand;
  final Widget? floatingButton;

  const _MobilePageFrame({
    required this.title,
    required this.subtitle,
    required this.child,
    this.leadingIcon,
    this.actions = const [],
    this.showBrand = false,
    this.floatingButton,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      floatingActionButton: floatingButton,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppMobileSizes.maxContentWidth,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppMobileSizes.pageHorizontalPadding,
                AppSpacing.lg,
                AppMobileSizes.pageHorizontalPadding,
                AppSpacing.xxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showBrand) ...[
                    _BrandRow(actions: actions),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (leadingIcon != null) ...[
                        Icon(
                          leadingIcon,
                          size: 42,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              subtitle,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                      if (!showBrand) ...actions,
                    ],
                  ),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandRow extends StatelessWidget {
  final List<Widget> actions;

  const _BrandRow({required this.actions});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _LogoMark(),
        const SizedBox(width: AppSpacing.sm),
        Text(
          'uniHub',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        ...actions,
      ],
    );
  }
}

class _LogoMark extends StatelessWidget {
  const _LogoMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppMobileSizes.heroLogoSize,
      height: AppMobileSizes.heroLogoSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.primary,
          ],
        ),
      ),
      child: Center(
        child: Text(
          'U',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
            fontSize: 28,
            height: 1,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  final IconData icon;
  final bool filled;

  const _HeaderAction({required this.icon, this.filled = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.full),
        onTap: () => _showComingSoon(context),
        child: Container(
          width: AppSizes.inputHeight,
          height: AppSizes.inputHeight,
          decoration: BoxDecoration(
            color: filled
                ? Theme.of(context).colorScheme.surfaceContainerHigh
                : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _FloatingAction extends StatelessWidget {
  final String label;
  final IconData icon;

  const _FloatingAction({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => _showComingSoon(context),
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

class _Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _Panel({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: const [AppShadows.card],
      ),
      child: child,
    );
  }
}

class _SearchField extends StatelessWidget {
  final String hint;
  final IconData trailing;

  const _SearchField({required this.hint, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: () => _showComingSoon(context),
      child: Container(
        height: AppMobileSizes.searchHeight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: Theme.of(context).colorScheme.outline),
        ),
        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                hint,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              trailing,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _HorizontalPills extends StatelessWidget {
  final List<String> labels;

  const _HorizontalPills({required this.labels});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            _StaticPill(label: labels[i], selected: i == 0),
            if (i != labels.length - 1) const SizedBox(width: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _StaticPill extends StatelessWidget {
  final String label;
  final bool selected;

  const _StaticPill({required this.label, this.selected = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.full),
      onTap: () => _showComingSoon(context),
      child: Container(
        height: AppDesktopSizes.navItemHeight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: selected
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final List<String> filters;
  final String trailingLabel;

  const _FilterBar({required this.filters, required this.trailingLabel});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _HorizontalPills(labels: filters)),
        const SizedBox(width: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: () => _showComingSoon(context),
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          label: Text(trailingLabel),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? count;

  const _SectionHeader({required this.title, this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        if (count != null) ...[
          const SizedBox(width: AppSpacing.sm),
          Chip(
            label: Text(count!),
            side: BorderSide.none,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
          ),
        ],
      ],
    );
  }
}

class _TodoStatsGrid extends StatelessWidget {
  const _TodoStatsGrid();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: AppSpacing.md,
      mainAxisSpacing: AppSpacing.md,
      childAspectRatio: 1.15,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _MetricTile(
          title: '全部任务',
          value: '24',
          note: '查看全部',
          icon: Icons.inbox_outlined,
        ),
        _MetricTile(
          title: '今日待办',
          value: '5',
          note: '查看今日',
          icon: Icons.task_alt,
          accent: colorScheme.secondary,
        ),
        _MetricTile(
          title: '已完成',
          value: '12',
          note: '查看已完成',
          icon: Icons.done_all_rounded,
        ),
        _MetricTile(
          title: '完成率',
          value: '48%',
          note: '较昨日 ↑ 12%',
          icon: Icons.show_chart_rounded,
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String title;
  final String value;
  final String note;
  final IconData icon;
  final Color? accent;

  const _MetricTile({
    required this.title,
    required this.value,
    required this.note,
    required this.icon,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return _Panel(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: accent ?? colorScheme.primary),
          Text(title, style: Theme.of(context).textTheme.labelLarge),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          Text(
            note,
            style: Theme.of(context).textTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _TodoRow extends StatelessWidget {
  final String title;
  final String tag;
  final String time;
  final String priority;
  final bool done;

  const _TodoRow({
    required this.title,
    required this.tag,
    required this.time,
    this.priority = '中',
    this.done = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final priorityColor = switch (priority) {
      '高' => colorScheme.error,
      '低' => colorScheme.primary,
      _ => colorScheme.tertiary,
    };

    return InkWell(
      onTap: () => _showComingSoon(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Icon(
              done ? Icons.check_box_rounded : Icons.check_box_outline_blank,
              color: done ? colorScheme.primary : colorScheme.outline,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleSmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            _TagBadge(label: tag, color: colorScheme.primary),
            const SizedBox(width: AppSpacing.sm),
            Text(time, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(width: AppSpacing.sm),
            Text(
              priority,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: priorityColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _TagBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _TagBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color),
      ),
    );
  }
}

class _FocusPanel extends StatelessWidget {
  const _FocusPanel();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.track_changes_rounded, color: colorScheme.tertiary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  '今日专注',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              TextButton(
                onPressed: () => _showComingSoon(context),
                child: const Text('编辑'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '聚焦 1-3 件最重要的事，提升效率。',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          const Row(
            children: [
              Expanded(
                child: _FocusItem(
                  rank: '1',
                  title: '完成产品原型设计',
                  tag: '工作 · 09:30',
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _FocusItem(
                  rank: '2',
                  title: '回复合作伙伴邮件',
                  tag: '工作 · 11:00',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FocusItem extends StatelessWidget {
  final String rank;
  final String title;
  final String tag;

  const _FocusItem({
    required this.rank,
    required this.title,
    required this.tag,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Text(
            rank,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.outline,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  tag,
                  style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressPanel extends StatelessWidget {
  const _ProgressPanel();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Row(
        children: [
          Expanded(
            child: Text('今日进度', style: Theme.of(context).textTheme.titleMedium),
          ),
          const SizedBox(width: AppSpacing.md),
          FilledButton.icon(
            onPressed: () => _showComingSoon(context),
            icon: const Icon(Icons.add),
            label: const Text('添加任务'),
          ),
        ],
      ),
    );
  }
}

class _PinnedNoteList extends StatelessWidget {
  const _PinnedNoteList();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      padding: EdgeInsets.zero,
      child: Column(
        children: const [
          _NoteLine(title: '产品设计：轻量级个人知识管理', tag: '工作', pinned: true),
          Divider(),
          _NoteLine(title: '读书笔记：《原子习惯》', tag: '阅读'),
          Divider(),
          _NoteLine(title: '周会总结 - 2024.05.17', tag: '工作'),
          Divider(),
          _NoteLine(title: '旅行计划：日本关西', tag: '生活'),
          Divider(),
          _NoteLine(title: '学习计划：前端进阶路线', tag: '学习'),
        ],
      ),
    );
  }
}

class _NoteLine extends StatelessWidget {
  final String title;
  final String tag;
  final bool pinned;

  const _NoteLine({
    required this.title,
    required this.tag,
    this.pinned = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      onTap: () => _showComingSoon(context),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(pinned ? '今天 08:47' : '昨天 22:15'),
      trailing: Icon(
        pinned ? Icons.push_pin_rounded : Icons.bookmark_border_rounded,
      ),
      leading: _TagBadge(
        label: tag,
        color: pinned ? colorScheme.primary : colorScheme.secondary,
      ),
    );
  }
}

class _EditorPreviewPanel extends StatelessWidget {
  const _EditorPreviewPanel();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '产品设计：轻量级个人知识管理',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const Icon(Icons.more_horiz_rounded),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const _HorizontalPills(labels: ['产品设计', '轻量体验', '+']),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: Theme.of(context).colorScheme.outline),
            ),
            child: Text(
              '一、目标\n打造一款轻量、专注的个人知识管理应用，帮助用户快速记录、整理与回顾想法。\n\n二、核心功能\n• 快速记录\n• 分类管理\n• 智能回顾',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarOverview extends StatelessWidget {
  const _CalendarOverview();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 480;
        final calendar = _Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '2024年5月',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const Icon(Icons.chevron_left_rounded),
                  const Icon(Icons.chevron_right_rounded),
                  OutlinedButton(
                    onPressed: () => _showComingSoon(context),
                    child: const Text('今天'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              const _MiniCalendarGrid(),
            ],
          ),
        );
        final summary = const _DaySummaryCard();

        if (narrow) {
          return Column(
            children: [
              calendar,
              const SizedBox(height: AppSpacing.md),
              summary,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: calendar),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: summary),
          ],
        );
      },
    );
  }
}

class _MiniCalendarGrid extends StatelessWidget {
  const _MiniCalendarGrid();

  @override
  Widget build(BuildContext context) {
    final days = [
      '一',
      '二',
      '三',
      '四',
      '五',
      '六',
      '日',
      '29',
      '30',
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      '10',
      '11',
      '12',
      '13',
      '14',
      '15',
      '16',
      '17',
      '18',
      '19',
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: days.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
      ),
      itemBuilder: (context, index) {
        final selected = days[index] == '18';
        return Center(
          child: Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Text(
              days[index],
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: selected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: index < 7 ? FontWeight.w700 : null,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DaySummaryCard extends StatelessWidget {
  const _DaySummaryCard();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('5月18日  星期六', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text('农历四月十一 · 28°C', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.lg),
          const Row(
            children: [
              Expanded(
                child: _SmallMetric(
                  label: '日程',
                  value: '6',
                  icon: Icons.calendar_month_outlined,
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _SmallMetric(
                  label: '提醒',
                  value: '3',
                  icon: Icons.notifications_none_rounded,
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _SmallMetric(
                  label: '待办',
                  value: '5',
                  icon: Icons.check_box_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SmallMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SmallMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(icon, color: colorScheme.primary),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _SchedulePanel extends StatelessWidget {
  const _SchedulePanel();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _SectionHeader(title: '今天 · 5月18日 星期六'),
          SizedBox(height: AppSpacing.md),
          _ScheduleLine(time: '08:30 - 09:30', title: '晨间复盘与计划', tag: '个人成长'),
          _ScheduleLine(time: '10:00 - 11:30', title: '产品需求评审会', tag: '工作'),
          _ScheduleLine(time: '15:00 - 16:00', title: '健身 · 跑步 5km', tag: '健康'),
          _ScheduleLine(time: '19:00 - 20:00', title: '阅读《原子习惯》', tag: '学习'),
        ],
      ),
    );
  }
}

class _ScheduleLine extends StatelessWidget {
  final String time;
  final String title;
  final String tag;

  const _ScheduleLine({
    required this.time,
    required this.title,
    required this.tag,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Text(time, style: Theme.of(context).textTheme.bodySmall),
      title: Text(title),
      subtitle: Text(tag),
      trailing: const Icon(Icons.more_vert_rounded),
      onTap: () => _showComingSoon(context),
    );
  }
}

class _ReminderAndHabitRow extends StatelessWidget {
  const _ReminderAndHabitRow();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final reminders = _Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _SectionHeader(title: '提醒', count: '3'),
              _TodoRow(title: '喝水提醒', tag: '', time: '09:30'),
              _TodoRow(title: '上午站立活动', tag: '', time: '11:00'),
            ],
          ),
        );
        final habits = _Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionHeader(title: '习惯追踪'),
              const SizedBox(height: AppSpacing.md),
              Text(
                '早起        连续 12 天',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Text(
                '阅读 30 分钟   连续 8 天',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
          ),
        );
        if (constraints.maxWidth < 480) {
          return Column(
            children: [
              reminders,
              const SizedBox(height: AppSpacing.md),
              habits,
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: reminders),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: habits),
          ],
        );
      },
    );
  }
}

class _FavoriteList extends StatelessWidget {
  const _FavoriteList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _FavoriteItem(
          icon: Icons.lightbulb_outline,
          title: '原子习惯：1% 的改变带来复利成长',
          tag: '成长思维',
        ),
        _FavoriteItem(
          icon: Icons.description_outlined,
          title: '第二大脑构建指南',
          tag: '知识管理',
        ),
        _FavoriteItem(
          icon: Icons.link_rounded,
          title: 'Notion 使用技巧 20 例',
          tag: '效率工具',
        ),
        _FavoriteItem(
          icon: Icons.insert_drive_file_outlined,
          title: '2024 年度个人复盘模板',
          tag: '模板',
        ),
        _FavoriteItem(
          icon: Icons.lightbulb_outline,
          title: '专注力的本质是对注意力的管理',
          tag: '专注力',
        ),
      ],
    );
  }
}

class _FavoriteItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String tag;

  const _FavoriteItem({
    required this.icon,
    required this.title,
    required this.tag,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: _Panel(
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: colorScheme.onPrimaryContainer),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '想法 · 来自快速记录  |  5月18日',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    '养成好习惯的关键不是意志力，而是让好习惯显而易见...',
                    style: Theme.of(context).textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            _TagBadge(label: tag, color: colorScheme.tertiary),
            const SizedBox(width: AppSpacing.sm),
            const Icon(Icons.more_horiz_rounded),
          ],
        ),
      ),
    );
  }
}

class _FavoriteFolders extends StatelessWidget {
  const _FavoriteFolders();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '我的收藏夹',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            TextButton(
              onPressed: () => _showComingSoon(context),
              child: const Text('管理收藏夹'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        const _HorizontalPills(
          labels: ['全部收藏  28', '成长思维  7', '知识管理  6', '效率工具  5', '读书笔记  4'],
        ),
      ],
    );
  }
}

class _RecentSearches extends StatelessWidget {
  const _RecentSearches();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text('最近搜索'),
        SizedBox(height: AppSpacing.sm),
        _HorizontalPills(labels: ['产品思路 ×', '读书笔记：原则 ×', '旅行计划 ×']),
      ],
    );
  }
}

class _SearchResultGroups extends StatelessWidget {
  const _SearchResultGroups();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _ResultGroup(title: '想法', count: '3', icon: Icons.lightbulb_outline),
        SizedBox(height: AppSpacing.md),
        _ResultGroup(title: '待办', count: '5', icon: Icons.check_box_outlined),
        SizedBox(height: AppSpacing.md),
        _ResultGroup(title: '笔记', count: '5', icon: Icons.description_outlined),
      ],
    );
  }
}

class _ResultGroup extends StatelessWidget {
  final String title;
  final String count;
  final IconData icon;

  const _ResultGroup({
    required this.title,
    required this.count,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: colorScheme.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  '$title  ($count)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              TextButton(
                onPressed: () => _showComingSoon(context),
                child: const Text('查看全部'),
              ),
            ],
          ),
          const Divider(),
          const _ResultLine(title: '产品思路：轻量级个人信息管理平台', meta: '今天 08:47'),
          const _ResultLine(title: '灵感：建立每日复盘习惯', meta: '5月17日'),
          const _ResultLine(title: '想法箱：AI 助手在信息整理中的应用', meta: '5月12日'),
        ],
      ),
    );
  }
}

class _ResultLine extends StatelessWidget {
  final String title;
  final String meta;

  const _ResultLine({required this.title, required this.meta});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('打造一个以个人为中心的信息枢纽，帮助用户快速记录...'),
      trailing: Text(meta, style: Theme.of(context).textTheme.bodySmall),
      onTap: () => _showComingSoon(context),
    );
  }
}

class _SearchSuggestions extends StatelessWidget {
  const _SearchSuggestions();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _SectionHeader(title: '搜索建议'),
          SizedBox(height: AppSpacing.sm),
          _ResultLine(title: '搜索“产品思路”相关内容', meta: '→'),
          _ResultLine(title: '查找本周的待办事项', meta: '→'),
          _ResultLine(title: '搜索含有“复盘”的内容', meta: '→'),
        ],
      ),
    );
  }
}

void _showComingSoon(BuildContext context) {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(const SnackBar(content: Text('功能暂未实现，已保留入口')));
}
