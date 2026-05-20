import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_breakpoints.dart';
import '../theme/app_tokens.dart';
import 'dashboard_providers.dart';
import '../plugin/plugin_interface.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < AppBreakpoints.tabletMin) {
              return const _MobileHomeView();
            }
            final isWide = constraints.maxWidth >= AppBreakpoints.wideMin;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xxl,
                      AppSpacing.xxl,
                      AppSpacing.xxl,
                      AppSpacing.section,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1080),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _HomeHeader(),
                          const SizedBox(height: AppSpacing.xxl),
                          const _FocusGrid(),
                          const SizedBox(height: AppSpacing.lg),
                          _QuickAccessPanel(
                            onThoughtsTap: () => context.go('/thoughts'),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _RecentThoughtsPanel(
                            onOpen: () => context.go('/thoughts'),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          const _HomeWorkGrid(),
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

// ─── Header ─────────────────────────────────────────────────────────

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: colorScheme.tertiaryContainer,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(_greetingIcon(), color: colorScheme.tertiary, size: 28),
        ),
        const SizedBox(width: AppSpacing.xl),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildGreeting(theme),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                '专注当下，持续进步',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
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

  Widget _buildGreeting(ThemeData theme) {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour >= 6 && hour < 12) {
      greeting = '早上好，Alex';
    } else if (hour >= 12 && hour < 18) {
      greeting = '下午好，Alex';
    } else {
      greeting = '晚上好，Alex';
    }
    return Text(
      greeting,
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      overflow: TextOverflow.ellipsis,
    );
  }

  IconData _greetingIcon() {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 12) return Icons.wb_sunny_rounded;
    if (hour >= 12 && hour < 18) return Icons.wb_cloudy_rounded;
    return Icons.nights_stay_rounded;
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('全局搜索即将上线')));
        },
        child: Container(
          width: 360,
          height: 48,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: colorScheme.outlineVariant),
            boxShadow: const [AppShadows.cardSoft],
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: [
              Icon(Icons.search_rounded, color: colorScheme.outline),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  '搜索想法、笔记、待办...',
                  style: theme.textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.crop_free_rounded, color: colorScheme.outline, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: colorScheme.outlineVariant),
            boxShadow: const [AppShadows.cardSoft],
          ),
          child: Icon(
            Icons.notifications_none_rounded,
            color: colorScheme.onSurfaceVariant,
            size: 22,
          ),
        ),
        Positioned(
          right: 8,
          top: 8,
          child: Container(
            width: AppSpacing.xs,
            height: AppSpacing.xs,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}

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
        // TODO: 待插件实现后替换为真实数据
        value: '6',
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
        // TODO: 待插件实现后替换为真实数据
        value: '8',
        note: '较上周 +2',
        color: colorScheme.secondary,
        background: colorScheme.secondaryContainer,
        icon: Icons.description_outlined,
      ),
      _MetricCard(
        title: '纪念日',
        value: '2',
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
            childAspectRatio: columns == 4 ? 1.55 : 2.0,
          ),
          itemBuilder: (context, index) => metrics[index],
        );
      },
    );
  }
}

// ─── Recent Thoughts Grid ───────────────────────────────────────────

class _RecentThoughtsGrid extends ConsumerWidget {
  const _RecentThoughtsGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(dashboardItemsProvider);

    return itemsAsync.when(
      loading: () => _buildLoadingGrid(context),
      error: (error, stack) => _buildErrorState(context, ref, error),
      data: (items) {
        if (items.isEmpty) return _buildEmptyState(context);
        return _buildDataGrid(context, items);
      },
    );
  }

  Widget _buildLoadingGrid(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: List.generate(
        4,
        (_) => SizedBox(
          width: 200,
          height: 244,
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Center(child: CircularProgressIndicator()),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    final colorScheme = Theme.of(context).colorScheme;
    return _Panel(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: colorScheme.error, size: 32),
            const SizedBox(height: AppSpacing.sm),
            Text('加载失败', style: TextStyle(color: colorScheme.onSurfaceVariant)),
            const SizedBox(height: AppSpacing.sm),
            FilledButton.tonalIcon(
              onPressed: () {
                ref.invalidate(dashboardItemsProvider);
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return _Panel(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                size: 48,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                '还没有想法，点击上方快速记录第一条吧',
                style: TextStyle(color: colorScheme.outline),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataGrid(BuildContext context, List<DashboardItem> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = AppSpacing.md;
        final columns = constraints.maxWidth >= 760 ? 3 : 1;
        final cardWidth =
            (constraints.maxWidth - (columns - 1) * spacing) / columns;
        const cardHeight = 104.0;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: items.map((item) {
            return SizedBox(
              width: cardWidth,
              height: cardHeight,
              child: _ThoughtPreviewCard(
                item: item,
                onTap: () => context.go(item.routePath),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _QuickAccessPanel extends StatelessWidget {
  final VoidCallback? onThoughtsTap;

  const _QuickAccessPanel({this.onThoughtsTap});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(title: '快捷入口', icon: Icons.favorite_border),
          const SizedBox(height: AppSpacing.md),
          _ShortcutGrid(onThoughtsTap: onThoughtsTap),
        ],
      ),
    );
  }
}

class _RecentThoughtsPanel extends StatelessWidget {
  final VoidCallback onOpen;

  const _RecentThoughtsPanel({required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            title: '最近想法',
            icon: Icons.lightbulb_outline,
            trailing: '查看全部',
            onTap: onOpen,
          ),
          const SizedBox(height: AppSpacing.md),
          const _RecentThoughtsGrid(),
        ],
      ),
    );
  }
}

class _HomeWorkGrid extends StatelessWidget {
  const _HomeWorkGrid();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTwoColumn = constraints.maxWidth >= 720;
        final children = const [_TodoPanel(), _ActivityPanel()];
        if (!isTwoColumn) {
          return const Column(
            children: [
              _TodoPanel(),
              SizedBox(height: AppSpacing.lg),
              _ActivityPanel(),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              Expanded(child: children[i]),
              if (i != children.length - 1)
                const SizedBox(width: AppSpacing.lg),
            ],
          ],
        );
      },
    );
  }
}

// ─── Shortcut Grid ──────────────────────────────────────────────────

class _ShortcutGrid extends StatelessWidget {
  final VoidCallback? onThoughtsTap;

  const _ShortcutGrid({this.onThoughtsTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final items = [
      _ShortcutCard(
        icon: Icons.add_rounded,
        title: '新建想法',
        subtitle: '快速记录想法',
        color: colorScheme.primary,
        background: colorScheme.primaryContainer,
        onTap: onThoughtsTap,
      ),
      _ShortcutCard(
        icon: Icons.edit_rounded,
        title: '新建笔记',
        subtitle: '沉淀知识',
        color: colorScheme.tertiary,
        background: colorScheme.tertiaryContainer,
      ),
      _ShortcutCard(
        icon: Icons.check_box_outlined,
        title: '添加待办',
        subtitle: '管理任务',
        color: colorScheme.secondary,
        background: colorScheme.secondaryContainer,
      ),
      _ShortcutCard(
        icon: Icons.bookmark_border_rounded,
        title: '收藏内容',
        subtitle: '稍后查看',
        color: colorScheme.error,
        background: colorScheme.errorContainer,
      ),
      _ShortcutCard(
        icon: Icons.event_available_outlined,
        title: '新建日程',
        subtitle: '安排时间',
        color: colorScheme.tertiary,
        background: colorScheme.tertiaryContainer,
      ),
      _ShortcutCard(
        icon: Icons.more_horiz_rounded,
        title: '更多',
        subtitle: '查看入口',
        color: colorScheme.onSurfaceVariant,
        background: colorScheme.surfaceContainerHigh,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 820 ? 6 : 3;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: 1.15,
          ),
          itemBuilder: (context, index) => items[index],
        );
      },
    );
  }
}

// ─── Home Right Rail ────────────────────────────────────────────────

class _HomeRightRail extends StatelessWidget {
  const _HomeRightRail();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: AppDesktopSizes.rightRailWideWidth,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        border: Border(left: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            const _PinnedPanel(),
            const SizedBox(height: AppSpacing.xl),
            const _TodoPanel(),
            const SizedBox(height: AppSpacing.xl),
            const _DataPanel(),
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

// ─── Pinned Panel ───────────────────────────────────────────────────

class _PinnedPanel extends ConsumerWidget {
  const _PinnedPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final pinnedAsync = ref.watch(dashboardPinnedProvider);

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelHeader(title: '置顶', icon: Icons.push_pin_outlined),
          const SizedBox(height: AppSpacing.md),
          pinnedAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            error: (error, stack) => const SizedBox.shrink(),
            data: (items) {
              if (items.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(
                    '暂无置顶内容',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.outline,
                      fontSize: 13,
                    ),
                  ),
                );
              }
              return Column(
                children: items.map((item) {
                  final title = _firstLine(item.content);
                  final subtitle = item.tags.isNotEmpty
                      ? item.tags.first
                      : '想法';
                  final color = _itemColor(item, colorScheme);
                  final background = _itemBackground(color, colorScheme);
                  return _CompactListItem(
                    icon: Icons.lightbulb_outline,
                    color: color,
                    background: background,
                    title: title,
                    subtitle: subtitle,
                    onTap: () => context.go(item.routePath),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── Todo Panel ─────────────────────────────────────────────────────

class _TodoPanel extends StatelessWidget {
  const _TodoPanel();

  @override
  Widget build(BuildContext context) {
    return const _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelHeader(title: '今日待办', icon: Icons.check_box_outlined),
          // TODO: 待插件实现后替换为真实数据
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

class _ActivityPanel extends StatelessWidget {
  const _ActivityPanel();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelHeader(title: '最近活动', icon: Icons.trending_up_rounded),
          const SizedBox(height: AppSpacing.md),
          _ActivityLine(
            icon: Icons.lightbulb_outline,
            color: colorScheme.primary,
            title: '创建了 3 条想法',
            time: '今天 10:24',
          ),
          _ActivityLine(
            icon: Icons.description_outlined,
            color: colorScheme.secondary,
            title: '更新了笔记《设计系统调研》',
            time: '昨天 20:11',
          ),
          _ActivityLine(
            icon: Icons.check_box_outlined,
            color: colorScheme.tertiary,
            title: '完成了待办《周报整理》',
            time: '昨天 18:35',
          ),
          _ActivityLine(
            icon: Icons.star_border_rounded,
            color: colorScheme.error,
            title: '收藏了 1 条内容',
            time: '5月19日',
          ),
        ],
      ),
    );
  }
}

// ─── Data Panel ─────────────────────────────────────────────────────

class _DataPanel extends ConsumerWidget {
  const _DataPanel();

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
        -1;

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelHeader(title: '数据概览', icon: Icons.bar_chart_rounded),
          const SizedBox(height: AppSpacing.md),
          _DataLine(
            icon: Icons.lightbulb_outline,
            label: '想法',
            value: thoughtsCount >= 0 ? '$thoughtsCount' : '—',
            change: '—',
            color: colorScheme.tertiary,
            background: colorScheme.tertiaryContainer,
          ),
          _DataLine(
            icon: Icons.check_circle_outline,
            label: '待办',
            // TODO: 待插件实现后替换为真实数据
            value: '24',
            change: '—',
            color: colorScheme.secondary,
            background: colorScheme.secondaryContainer,
          ),
          _DataLine(
            icon: Icons.article_outlined,
            label: '笔记',
            // TODO: 待插件实现后替换为真实数据
            value: '56',
            change: '—',
            color: colorScheme.primary,
            background: colorScheme.primaryContainer,
          ),
        ],
      ),
    );
  }
}

// ─── Reusable Section / Panel Widgets ───────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData? icon;
  final String? trailing;
  final VoidCallback? onTap;

  const _SectionTitle({
    required this.title,
    this.icon,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: AppSpacing.xs),
        ],
        Expanded(child: Text(title, style: theme.textTheme.titleLarge)),
        if (trailing != null)
          InkWell(
            borderRadius: BorderRadius.circular(AppRadius.xs),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: AppSpacing.xxs,
              ),
              child: Text(
                '$trailing  →',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
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
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      elevation: 0,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: colorScheme.outlineVariant),
          boxShadow: const [AppShadows.cardSoft],
        ),
        child: Padding(padding: padding, child: child),
      ),
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
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Icon(icon, color: color, size: 24),
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
    final colorScheme = theme.colorScheme;
    return Container(
      height: AppDesktopSizes.compactButtonHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
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
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      elevation: 0,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: theme.colorScheme.outlineVariant),
          boxShadow: const [AppShadows.cardSoft],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(title, style: theme.textTheme.labelLarge),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      value,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(note, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThoughtPreviewCard extends StatelessWidget {
  final DashboardItem item;
  final VoidCallback onTap;

  const _ThoughtPreviewCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final title = _firstLine(item.content);
    final body = _restLines(item.content);
    final tag = item.tags.isNotEmpty ? item.tags.first : '';
    final time = _formatTimestamp(item.createdAt);
    final color = _itemColor(item, colorScheme);
    final background = _itemBackground(color, colorScheme);

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      elevation: 0,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: colorScheme.outlineVariant),
          boxShadow: const [AppShadows.cardSoft],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (tag.isNotEmpty) ...[
                      const SizedBox(width: AppSpacing.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                          vertical: AppSpacing.xxs,
                        ),
                        decoration: BoxDecoration(
                          color: background.withValues(alpha: 0.62),
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text(
                          tag,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    Icon(
                      item.isPinned
                          ? Icons.push_pin_rounded
                          : Icons.star_border_rounded,
                      color: item.isPinned
                          ? colorScheme.primary
                          : colorScheme.outline,
                      size: 18,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Expanded(
                  child: Text(
                    body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Text(time, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ),
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
  final VoidCallback? onTap;

  const _ShortcutCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.background,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      elevation: 0,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: colorScheme.outlineVariant),
          boxShadow: const [AppShadows.cardSoft],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
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
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurface),
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
  final VoidCallback? onTap;

  const _CompactListItem({
    required this.icon,
    required this.color,
    required this.background,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Row(
          children: [
            _SmallIconBubble(icon: icon, color: color, background: background),
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
            if (onTap != null)
              Icon(
                Icons.more_vert_rounded,
                color: Theme.of(context).colorScheme.outline,
              ),
          ],
        ),
      ),
    );
  }
}

class _SmallIconBubble extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color background;

  const _SmallIconBubble({
    required this.icon,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Icon(icon, color: color, size: 20),
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
            color: done
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
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

class _ActivityLine extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String time;

  const _ActivityLine({
    required this.icon,
    required this.color,
    required this.title,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.bodyMedium,
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
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          _SmallIconBubble(icon: icon, color: color, background: background),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodySmall),
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Text(
            change,
            style: theme.textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Formatting Helpers ─────────────────────────────────────────────

String _firstLine(String text) {
  final trimmed = text.trim();
  final firstLine = trimmed.split(RegExp(r'\s*\n\s*')).first;
  if (firstLine.length <= 20) return firstLine;
  return '${firstLine.substring(0, 20)}...';
}

String _restLines(String text) {
  final trimmed = text.trim();
  final lines = trimmed.split(RegExp(r'\s*\n\s*'));
  if (lines.length <= 1) return trimmed;
  return lines.skip(1).join('\n').trim();
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
    return '${dt.month}月${dt.day}日 ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
  return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}

Color _itemColor(DashboardItem item, ColorScheme colorScheme) {
  if (item.colorHex != null && item.colorHex!.isNotEmpty) {
    final cleaned = item.colorHex!.replaceFirst('#', '');
    final normalized = cleaned.length == 6 ? 'FF$cleaned' : cleaned;
    final intVal = int.tryParse(normalized, radix: 16);
    if (intVal != null) return Color(intVal);
  }
  final accentPalette = [
    colorScheme.tertiary,
    colorScheme.secondary,
    colorScheme.primary,
    colorScheme.error,
  ];
  final idx = item.itemId.hashCode.abs();
  return accentPalette[idx % accentPalette.length];
}

Color _itemBackground(Color color, ColorScheme colorScheme) {
  return Color.alphaBlend(
    color.withValues(alpha: 0.12),
    colorScheme.surfaceContainerLow,
  );
}

class _MobileHomeView extends ConsumerWidget {
  const _MobileHomeView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(dashboardItemsProvider);
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

    return Center(
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _MobileBrandHeader(),
              const SizedBox(height: AppSpacing.xl),
              const _MobileGreeting(),
              const SizedBox(height: AppSpacing.xl),
              _MobileSearchBox(onTap: () => context.go('/search')),
              const SizedBox(height: AppSpacing.lg),
              const _MobileQuickCaptureCard(),
              const SizedBox(height: AppSpacing.xxl),
              _MobileSectionTitle(
                title: '今日聚焦',
                trailing: '查看全部',
                onTap: () => context.go('/todos'),
              ),
              const SizedBox(height: AppSpacing.md),
              _MobileFocusCards(thoughtsCount: thoughtsCount),
              const SizedBox(height: AppSpacing.lg),
              LayoutBuilder(
                builder: (context, constraints) {
                  final narrow = constraints.maxWidth < 460;
                  final recent = _MobileRecentThoughts(
                    itemsAsync: itemsAsync,
                    onOpen: () => context.go('/thoughts'),
                  );
                  const todos = _MobileTodayTodos();
                  if (narrow) {
                    return Column(
                      children: [
                        recent,
                        const SizedBox(height: AppSpacing.md),
                        todos,
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: recent),
                      const SizedBox(width: AppSpacing.md),
                      const Expanded(child: todos),
                    ],
                  );
                },
              ),
              const SizedBox(height: AppSpacing.xxl),
              const _MobileSectionTitle(title: '快捷入口'),
              const SizedBox(height: AppSpacing.md),
              _MobileShortcutGrid(
                onThoughtsTap: () => context.go('/thoughts'),
                onTodosTap: () => context.go('/todos'),
                onNotesTap: () => context.go('/notes'),
                onSearchTap: () => context.go('/search'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileBrandHeader extends StatelessWidget {
  const _MobileBrandHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
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
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          'uniHub',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              onPressed: () {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('通知功能暂未实现')));
              },
              icon: const Icon(Icons.notifications_none_rounded),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: SizedBox(width: AppSpacing.xs, height: AppSpacing.xs),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MobileGreeting extends StatelessWidget {
  const _MobileGreeting();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hour = DateTime.now().hour;
    final greeting = hour >= 6 && hour < 12
        ? '早上好，Alex'
        : hour >= 12 && hour < 18
        ? '下午好，Alex'
        : '晚上好，Alex';
    final icon = hour >= 6 && hour < 12
        ? Icons.wb_sunny_rounded
        : hour >= 12 && hour < 18
        ? Icons.wb_cloudy_rounded
        : Icons.nights_stay_rounded;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                greeting,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(icon, color: colorScheme.tertiary, size: 30),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text('快速记录、整理与找回你的信息', style: theme.textTheme.bodyLarge),
      ],
    );
  }
}

class _MobileSearchBox extends StatelessWidget {
  final VoidCallback onTap;

  const _MobileSearchBox({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: onTap,
      child: Container(
        height: AppMobileSizes.searchHeight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: colorScheme.outline),
        ),
        child: Row(
          children: [
            Icon(Icons.search_rounded, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                '搜索想法、待办、笔记、标签...',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: colorScheme.outline),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.crop_free_rounded, color: colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _MobileQuickCaptureCard extends ConsumerStatefulWidget {
  const _MobileQuickCaptureCard();

  @override
  ConsumerState<_MobileQuickCaptureCard> createState() =>
      _MobileQuickCaptureCardState();
}

class _MobileQuickCaptureCardState
    extends ConsumerState<_MobileQuickCaptureCard> {
  late final TextEditingController _controller;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final content = _controller.text.trim();
    if (content.isEmpty || _submitting) return;

    setState(() => _submitting = true);
    try {
      await ref.read(quickCreateProvider((content: content, tags: null)).future);
      ref.invalidate(dashboardItemsProvider);
      ref.invalidate(dashboardPinnedProvider);
      ref.invalidate(dashboardStatsProvider);
      if (!mounted) return;
      _controller.clear();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('想法已记录')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _IconBubble(
                  icon: Icons.edit_outlined,
                  color: colorScheme.onPrimaryContainer,
                  background: colorScheme.primaryContainer,
                ),
                const SizedBox(width: AppSpacing.md),
                Text('快速记录想法', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _controller,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(hintText: '此刻的想法是...'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const _PillButton(icon: Icons.sell_outlined, label: '添加标签'),
                const _PillButton(icon: Icons.image_outlined, label: '图片'),
                const _PillButton(icon: Icons.check_box_outlined, label: '待办'),
                FilledButton.icon(
                  onPressed: _controller.text.trim().isEmpty || _submitting
                      ? null
                      : _submit,
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: Text(_submitting ? '记录中' : '记录'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileSectionTitle extends StatelessWidget {
  final String title;
  final String? trailing;
  final VoidCallback? onTap;

  const _MobileSectionTitle({required this.title, this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        if (trailing != null)
          TextButton.icon(
            onPressed: onTap,
            label: Text(trailing!),
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
          ),
      ],
    );
  }
}

class _MobileFocusCards extends StatelessWidget {
  final int thoughtsCount;

  const _MobileFocusCards({required this.thoughtsCount});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GridView.count(
      crossAxisCount: 3,
      crossAxisSpacing: AppSpacing.md,
      mainAxisSpacing: AppSpacing.md,
      childAspectRatio: 0.62,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _MobileFocusCard(
          title: '今日待办',
          value: '5',
          note: '项待完成',
          icon: Icons.check_box_outlined,
          color: colorScheme.secondary,
          background: colorScheme.secondaryContainer,
        ),
        _MobileFocusCard(
          title: '最近笔记',
          value: '3',
          note: '条新笔记',
          icon: Icons.description_outlined,
          color: colorScheme.primary,
          background: colorScheme.primaryContainer,
        ),
        _MobileFocusCard(
          title: '想法灵感',
          value: '$thoughtsCount',
          note: '条未整理',
          icon: Icons.lightbulb_outline,
          color: colorScheme.tertiary,
          background: colorScheme.tertiaryContainer,
        ),
      ],
    );
  }
}

class _MobileFocusCard extends StatelessWidget {
  final String title;
  final String value;
  final String note;
  final IconData icon;
  final Color color;
  final Color background;

  const _MobileFocusCard({
    required this.title,
    required this.value,
    required this.note,
    required this.icon,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 22),
            Text(title, style: theme.textTheme.labelLarge, maxLines: 1),
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              note,
              style: theme.textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                width: AppSizes.iconButton,
                height: AppSizes.iconButton,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, color: color.withValues(alpha: 0.65)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileRecentThoughts extends StatelessWidget {
  final AsyncValue<List<DashboardItem>> itemsAsync;
  final VoidCallback onOpen;

  const _MobileRecentThoughts({required this.itemsAsync, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MobileSectionTitle(title: '最近想法', trailing: '查看全部', onTap: onOpen),
          const SizedBox(height: AppSpacing.sm),
          itemsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) =>
                Text('加载失败', style: Theme.of(context).textTheme.bodySmall),
            data: (items) {
              final shown = items.take(2).toList();
              if (shown.isEmpty) {
                return Text(
                  '还没有想法，先快速记录一条。',
                  style: Theme.of(context).textTheme.bodyMedium,
                );
              }
              return Column(
                children: [
                  for (final item in shown) ...[
                    _MobileThoughtLine(item: item, onTap: onOpen),
                    if (item != shown.last)
                      const SizedBox(height: AppSpacing.sm),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MobileThoughtLine extends StatelessWidget {
  final DashboardItem item;
  final VoidCallback onTap;

  const _MobileThoughtLine({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _formatTimestamp(item.createdAt),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _firstLine(item.content),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _restLines(item.content),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileTodayTodos extends StatelessWidget {
  const _MobileTodayTodos();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MobileSectionTitle(
            title: '今日待办',
            trailing: '添加',
            onTap: () => context.go('/todos'),
          ),
          const SizedBox(height: AppSpacing.sm),
          const _MobileTodoLine(title: '完成产品原型评审', time: '09:30', done: true),
          const _MobileTodoLine(title: '回复合作伙伴邮件', time: '11:00'),
          const _MobileTodoLine(title: '晨跑 5 公里', time: '07:00', done: true),
          const _MobileTodoLine(title: '阅读《设计心理学》', time: '20:00'),
          const _MobileTodoLine(title: '整理周报数据', time: '21:30'),
        ],
      ),
    );
  }
}

class _MobileTodoLine extends StatelessWidget {
  final String title;
  final String time;
  final bool done;

  const _MobileTodoLine({
    required this.title,
    required this.time,
    this.done = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_box_rounded : Icons.check_box_outline_blank,
            color: done
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(time, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _MobileShortcutGrid extends StatelessWidget {
  final VoidCallback onThoughtsTap;
  final VoidCallback onTodosTap;
  final VoidCallback onNotesTap;
  final VoidCallback onSearchTap;

  const _MobileShortcutGrid({
    required this.onThoughtsTap,
    required this.onTodosTap,
    required this.onNotesTap,
    required this.onSearchTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: AppSpacing.md,
      mainAxisSpacing: AppSpacing.md,
      childAspectRatio: 2.0,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _MobileShortcutCard(
          icon: Icons.lightbulb_outline,
          title: '想法',
          subtitle: '随时记录灵感',
          color: colorScheme.tertiary,
          background: colorScheme.tertiaryContainer,
          onTap: onThoughtsTap,
        ),
        _MobileShortcutCard(
          icon: Icons.check_box_outlined,
          title: '待办',
          subtitle: '管理任务清单',
          color: colorScheme.secondary,
          background: colorScheme.secondaryContainer,
          onTap: onTodosTap,
        ),
        _MobileShortcutCard(
          icon: Icons.description_outlined,
          title: '笔记',
          subtitle: '记录与沉淀知识',
          color: colorScheme.primary,
          background: colorScheme.primaryContainer,
          onTap: onNotesTap,
        ),
        _MobileShortcutCard(
          icon: Icons.search_rounded,
          title: '搜索',
          subtitle: '查找全部内容',
          color: colorScheme.onSurfaceVariant,
          background: colorScheme.surfaceContainerHigh,
          onTap: onSearchTap,
        ),
      ],
    );
  }
}

class _MobileShortcutCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color background;
  final VoidCallback onTap;

  const _MobileShortcutCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.background,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              Container(
                width: AppSizes.inputHeight,
                height: AppSizes.inputHeight,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleSmall),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
