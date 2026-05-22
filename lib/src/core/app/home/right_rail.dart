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
        color: colorScheme.surfaceContainerLowest,
        border: Border(left: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5))),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
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
          const _PanelHeader(title: '重要内容', icon: Icons.push_pin_outlined),
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
    final colorScheme = Theme.of(context).colorScheme;
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelHeader(title: '今日待办', icon: Icons.check_box_outlined),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text('暂无待办数据', style: TextStyle(color: colorScheme.outline)),
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
            value: '—',
            change: '—',
            color: colorScheme.secondary,
            background: colorScheme.secondaryContainer,
          ),
          _DataLine(
            icon: Icons.article_outlined,
            label: '笔记',
            value: '—',
            change: '—',
            color: colorScheme.primary,
            background: colorScheme.primaryContainer,
          ),
        ],
      ),
    );
  }
}
