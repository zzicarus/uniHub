import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_tokens.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 1120;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 920),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _HomeHeader(),
                          SizedBox(height: AppSpacing.xxl),
                          _QuickCaptureCard(),
                          SizedBox(height: AppSpacing.xxl),
                          _SectionTitle(title: '今日聚焦'),
                          SizedBox(height: AppSpacing.md),
                          _FocusGrid(),
                          SizedBox(height: AppSpacing.xxl),
                          _SectionTitle(title: '最近想法', trailing: '查看全部'),
                          SizedBox(height: AppSpacing.md),
                          _RecentThoughtsGrid(),
                          SizedBox(height: AppSpacing.xxl),
                          _SectionTitle(title: '快捷入口'),
                          SizedBox(height: AppSpacing.md),
                          _ShortcutGrid(),
                        ],
                      ),
                    ),
                  ),
                ),
                if (isWide) const _HomeRightRail(),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      '早上好，Alex',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Icon(
                    Icons.wb_sunny_rounded,
                    color: AppColors.warning,
                    size: 28,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text('快速记录、整理与找回你的信息', style: theme.textTheme.bodyLarge),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.xl),
        const _SearchBox(),
        const SizedBox(width: AppSpacing.md),
        const _NotificationButton(),
      ],
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 260,
      height: AppSizes.inputHeight,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: AppColors.textTertiary),
          const SizedBox(width: AppSpacing.xs),
          Text('Ctrl + K 全局搜索', style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: AppSizes.inputHeight,
          height: AppSizes.inputHeight,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
          ),
          child: const Icon(Icons.notifications_none_rounded),
        ),
        Positioned(
          right: 10,
          top: 10,
          child: Container(
            width: AppSpacing.xs,
            height: AppSpacing.xs,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickCaptureCard extends StatelessWidget {
  const _QuickCaptureCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _Panel(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _IconBubble(
            icon: Icons.edit_outlined,
            color: AppColors.primary,
            background: AppColors.primarySoft,
          ),
          const SizedBox(width: AppSpacing.xl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('快速记录想法', style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  height: 68,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    '快速记录你的想法...',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    const _PillButton(icon: Icons.sell_outlined, label: '添加标签'),
                    const SizedBox(width: AppSpacing.sm),
                    const _PillButton(icon: Icons.image_outlined, label: '图片'),
                    const SizedBox(width: AppSpacing.sm),
                    const _PillButton(
                      icon: Icons.check_box_outlined,
                      label: '待办',
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: const Text('记录想法'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FocusGrid extends StatelessWidget {
  const _FocusGrid();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _MetricCard(
            title: '今日待办',
            value: '5',
            note: '项待完成',
            color: AppColors.success,
            background: AppColors.greenSoft,
            icon: Icons.check_circle_outline_rounded,
          ),
        ),
        SizedBox(width: AppSpacing.md),
        Expanded(
          child: _MetricCard(
            title: '最近笔记',
            value: '3',
            note: '条新笔记',
            color: AppColors.primary,
            background: AppColors.blueSoft,
            icon: Icons.description_outlined,
          ),
        ),
        SizedBox(width: AppSpacing.md),
        Expanded(
          child: _MetricCard(
            title: '灵感想法',
            value: '8',
            note: '条未整理',
            color: AppColors.warning,
            background: AppColors.yellowSoft,
            icon: Icons.lightbulb_outline,
          ),
        ),
      ],
    );
  }
}

class _RecentThoughtsGrid extends StatelessWidget {
  const _RecentThoughtsGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      crossAxisSpacing: AppSpacing.md,
      mainAxisSpacing: AppSpacing.md,
      childAspectRatio: 0.82,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: const [
        _ThoughtPreviewCard(
          title: '产品想法：轻量级个人信息中心',
          body: '打造一个以个人为中心的信息枢纽，帮助用户快速记录、整理与找回想法、待办和笔记。',
          tag: '产品想法',
          time: '今天 08:47',
          color: AppColors.purple,
          background: AppColors.purpleSoft,
          pinned: true,
        ),
        _ThoughtPreviewCard(
          title: '读书笔记：《原子习惯》',
          body: '习惯是复利效应。微小改变，带来巨大回报。',
          tag: '阅读笔记',
          time: '昨天 22:15',
          color: AppColors.success,
          background: AppColors.greenSoft,
        ),
        _ThoughtPreviewCard(
          title: '采购清单',
          body: '鸡蛋、牛奶、燕麦片、蓝莓、卫生纸。',
          tag: '生活',
          time: '昨天 18:36',
          color: AppColors.warning,
          background: AppColors.accentSoft,
        ),
        _ThoughtPreviewCard(
          title: '本周复盘',
          body: '本周完成了产品原型设计，与团队讨论了核心功能优先级。',
          tag: '复盘',
          time: '5月18日 21:30',
          color: AppColors.primary,
          background: AppColors.blueSoft,
        ),
      ],
    );
  }
}

class _ShortcutGrid extends StatelessWidget {
  const _ShortcutGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      crossAxisSpacing: AppSpacing.md,
      childAspectRatio: 2.55,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: const [
        _ShortcutCard(
          icon: Icons.lightbulb_outline,
          title: '想法',
          subtitle: '随时记录灵感',
          color: AppColors.purple,
          background: AppColors.purpleSoft,
        ),
        _ShortcutCard(
          icon: Icons.check_circle_outline_rounded,
          title: '待办',
          subtitle: '管理任务清单',
          color: AppColors.success,
          background: AppColors.greenSoft,
        ),
        _ShortcutCard(
          icon: Icons.article_outlined,
          title: '笔记',
          subtitle: '沉淀知识',
          color: AppColors.primary,
          background: AppColors.blueSoft,
        ),
        _ShortcutCard(
          icon: Icons.search_rounded,
          title: '搜索',
          subtitle: '查找全部内容',
          color: AppColors.textSecondary,
          background: AppColors.surfaceMuted,
        ),
      ],
    );
  }
}

class _HomeRightRail extends StatelessWidget {
  const _HomeRightRail();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppDesktopSizes.rightRailWideWidth,
      decoration: const BoxDecoration(
        color: AppColors.surfaceElevated,
        border: Border(left: BorderSide(color: AppColors.borderSoft)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: const [
            _PinnedPanel(),
            SizedBox(height: AppSpacing.xl),
            _TodoPanel(),
            SizedBox(height: AppSpacing.xl),
            _DataPanel(),
            SizedBox(height: AppSpacing.xxl),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 14,
                  color: AppColors.textTertiary,
                ),
                SizedBox(width: AppSpacing.xxs),
                Text(
                  '你的数据，仅你可见',
                  style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PinnedPanel extends StatelessWidget {
  const _PinnedPanel();

  @override
  Widget build(BuildContext context) {
    return const _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelHeader(title: '置顶', icon: Icons.push_pin_outlined),
          SizedBox(height: AppSpacing.md),
          _CompactListItem(
            icon: Icons.bookmark_rounded,
            color: AppColors.purple,
            background: AppColors.purpleSoft,
            title: '人生愿景清单',
            subtitle: '目标 · 长期',
          ),
          _CompactListItem(
            icon: Icons.folder_rounded,
            color: AppColors.warning,
            background: AppColors.yellowSoft,
            title: '旅行计划：日本关西',
            subtitle: '计划 · 6月',
          ),
          _CompactListItem(
            icon: Icons.article_rounded,
            color: AppColors.success,
            background: AppColors.greenSoft,
            title: '如何打造高效的个人系统',
            subtitle: '笔记 · 5月10日',
          ),
        ],
      ),
    );
  }
}

class _TodoPanel extends StatelessWidget {
  const _TodoPanel();

  @override
  Widget build(BuildContext context) {
    return const _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelHeader(title: '今日待办', icon: Icons.check_box_outlined),
          SizedBox(height: AppSpacing.md),
          _TodoLine(title: '完成产品原型评审', time: '09:30'),
          _TodoLine(title: '回复合作伙伴邮件', time: '11:00'),
          _TodoLine(title: '晨跑 5 公里', time: '07:00', done: true),
          _TodoLine(title: '阅读《设计心理学》', time: '20:00'),
          _TodoLine(title: '整理周报数据', time: '21:30'),
        ],
      ),
    );
  }
}

class _DataPanel extends StatelessWidget {
  const _DataPanel();

  @override
  Widget build(BuildContext context) {
    return const _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelHeader(title: '数据概览', icon: Icons.bar_chart_rounded),
          SizedBox(height: AppSpacing.md),
          _DataLine(
            icon: Icons.lightbulb_outline,
            label: '想法',
            value: '128',
            change: '+18%',
            color: AppColors.purple,
            background: AppColors.purpleSoft,
          ),
          _DataLine(
            icon: Icons.check_circle_outline,
            label: '待办',
            value: '24',
            change: '-8%',
            color: AppColors.success,
            background: AppColors.greenSoft,
          ),
          _DataLine(
            icon: Icons.article_outlined,
            label: '笔记',
            value: '56',
            change: '+12%',
            color: AppColors.primary,
            background: AppColors.blueSoft,
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? trailing;

  const _SectionTitle({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(child: Text(title, style: theme.textTheme.titleLarge)),
        if (trailing != null)
          Text(
            '$trailing  →',
            style: theme.textTheme.labelLarge?.copyWith(
              color: AppColors.primary,
            ),
          ),
      ],
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
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _IconBubble extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color background;

  const _IconBubble({
    required this.icon,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Icon(icon, color: color, size: 28),
    );
  }
}

class _PillButton extends StatelessWidget {
  final IconData icon;
  final String label;

  const _PillButton({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: AppDesktopSizes.compactButtonHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.xs),
          Text(label, style: theme.textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String note;
  final Color color;
  final Color background;
  final IconData icon;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.note,
    required this.color,
    required this.background,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _Panel(
      child: SizedBox(
        height: AppSizes.dashboardCardHeight,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: color, size: 24),
                  Text(title, style: theme.textTheme.labelLarge),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        value,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
                        child: Text(note, style: theme.textTheme.bodySmall),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Icon(icon, color: color.withValues(alpha: 0.65), size: 32),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThoughtPreviewCard extends StatelessWidget {
  final String title;
  final String body;
  final String tag;
  final String time;
  final Color color;
  final Color background;
  final bool pinned;

  const _ThoughtPreviewCard({
    required this.title,
    required this.body,
    required this.tag,
    required this.time,
    required this.color,
    required this.background,
    this.pinned = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: background.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(time, style: theme.textTheme.bodySmall)),
              Icon(
                pinned ? Icons.star_rounded : Icons.star_border_rounded,
                color: pinned ? AppColors.warning : AppColors.textTertiary,
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: Text(
              body,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.xxs,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Text(
              tag,
              style: theme.textTheme.labelMedium?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShortcutCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color background;

  const _ShortcutCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _Panel(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          _IconBubble(icon: icon, color: color, background: background),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall,
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

class _PanelHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _PanelHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textPrimary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
      ],
    );
  }
}

class _CompactListItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color background;
  final String title;
  final String subtitle;

  const _CompactListItem({
    required this.icon,
    required this.color,
    required this.background,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          _IconBubble(icon: icon, color: color, background: background),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Icon(Icons.more_vert_rounded, color: AppColors.textTertiary),
        ],
      ),
    );
  }
}

class _TodoLine extends StatelessWidget {
  final String title;
  final String time;
  final bool done;

  const _TodoLine({required this.title, required this.time, this.done = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_box_rounded : Icons.check_box_outline_blank,
            size: 20,
            color: done ? AppColors.primary : AppColors.textTertiary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                decoration: done ? TextDecoration.lineThrough : null,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(time, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _DataLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String change;
  final Color color;
  final Color background;

  const _DataLine({
    required this.icon,
    required this.label,
    required this.value,
    required this.change,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPositive = change.startsWith('+');
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          _IconBubble(icon: icon, color: color, background: background),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodySmall),
                Text(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Text(
            change,
            style: theme.textTheme.labelMedium?.copyWith(
              color: isPositive ? AppColors.success : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }
}
