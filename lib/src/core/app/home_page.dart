import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_breakpoints.dart';
import '../theme/app_tokens.dart';
import 'dashboard_providers.dart';
import '../plugin/plugin_interface.dart';
import '../plugin/plugin_registry.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 920),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _HomeHeader(),
                          const SizedBox(height: AppSpacing.xxl),
                          const _QuickCaptureCard(),
                          const SizedBox(height: AppSpacing.xxl),
                          const _SectionTitle(title: '今日聚焦'),
                          const SizedBox(height: AppSpacing.md),
                          const _FocusGrid(),
                          const SizedBox(height: AppSpacing.xxl),
                          _SectionTitle(
                            title: '最近想法',
                            trailing: '查看全部',
                            onTap: () => context.go('/thoughts'),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          const _RecentThoughtsGrid(),
                          const SizedBox(height: AppSpacing.xxl),
                          const _SectionTitle(title: '快捷入口'),
                          const SizedBox(height: AppSpacing.md),
                          _ShortcutGrid(
                            onThoughtsTap: () => context.go('/thoughts'),
                          ),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGreeting(theme),
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

  Widget _buildGreeting(ThemeData theme) {
    final hour = DateTime.now().hour;
    String greeting;
    IconData greetingIcon;
    Color iconColor;
    if (hour >= 6 && hour < 12) {
      greeting = '早上好，Alex';
      greetingIcon = Icons.wb_sunny_rounded;
      iconColor = AppColors.warning;
    } else if (hour >= 12 && hour < 18) {
      greeting = '下午好，Alex';
      greetingIcon = Icons.wb_cloudy_rounded;
      iconColor = AppColors.textSecondary;
    } else {
      greeting = '晚上好，Alex';
      greetingIcon = Icons.nights_stay_rounded;
      iconColor = AppColors.primary;
    }
    return Row(
      children: [
        Flexible(
          child: Text(
            greeting,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Icon(greetingIcon, color: iconColor, size: 28),
      ],
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: () {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('全局搜索即将上线')));
      },
      child: Container(
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

// ─── Quick Capture Card ─────────────────────────────────────────────

class _QuickCaptureCard extends ConsumerStatefulWidget {
  const _QuickCaptureCard();

  @override
  ConsumerState<_QuickCaptureCard> createState() => _QuickCaptureCardState();
}

class _QuickCaptureCardState extends ConsumerState<_QuickCaptureCard> {
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
      final registry = ref.read(pluginRegistryProvider);
      await registry.quickCreate(ref, content: content);
      if (!mounted) return;
      _controller.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('想法已记录'), duration: Duration(seconds: 2)),
      );
      ref.invalidate(dashboardItemsProvider);
      ref.invalidate(dashboardPinnedProvider);
      ref.invalidate(dashboardStatsProvider);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEmpty = _controller.text.trim().isEmpty;

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
                  constraints: const BoxConstraints(minHeight: 68),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: TextField(
                    controller: _controller,
                    maxLines: null,
                    minLines: 1,
                    textInputAction: TextInputAction.newline,
                    style: theme.textTheme.bodyMedium,
                    decoration: const InputDecoration(
                      hintText: '快速记录你的想法...',
                      hintStyle: TextStyle(color: AppColors.textTertiary),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
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
                      onPressed: (isEmpty || _submitting) ? null : _submit,
                      icon: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded, size: 18),
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

    return Row(
      children: [
        const Expanded(
          child: _MetricCard(
            title: '今日待办',
            // TODO: 待插件实现后替换为真实数据
            value: '5',
            note: '项待完成',
            color: AppColors.success,
            background: AppColors.greenSoft,
            icon: Icons.check_circle_outline_rounded,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        const Expanded(
          child: _MetricCard(
            title: '最近笔记',
            // TODO: 待插件实现后替换为真实数据
            value: '3',
            note: '条新笔记',
            color: AppColors.primary,
            background: AppColors.blueSoft,
            icon: Icons.description_outlined,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _MetricCard(
            title: '灵感想法',
            value: '$thoughtsCount',
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

// ─── Recent Thoughts Grid ───────────────────────────────────────────

class _RecentThoughtsGrid extends ConsumerWidget {
  const _RecentThoughtsGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(dashboardItemsProvider);

    return itemsAsync.when(
      loading: () => _buildLoadingGrid(),
      error: (error, stack) => _buildErrorState(ref, error),
      data: (items) {
        if (items.isEmpty) return _buildEmptyState();
        return _buildDataGrid(context, items);
      },
    );
  }

  Widget _buildLoadingGrid() {
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
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Center(child: CircularProgressIndicator()),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(WidgetRef ref, Object error) {
    return _Panel(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 32),
            const SizedBox(height: AppSpacing.sm),
            Text('加载失败', style: TextStyle(color: AppColors.textSecondary)),
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

  Widget _buildEmptyState() {
    return _Panel(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: AppColors.textTertiary.withValues(alpha: 0.5),
                size: 48,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                '还没有想法，点击上方快速记录第一条吧',
                style: TextStyle(color: AppColors.textTertiary),
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
        const columns = 4;
        final cardWidth =
            (constraints.maxWidth - (columns - 1) * spacing) / columns;
        final cardHeight = cardWidth / 0.82;

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

// ─── Shortcut Grid ──────────────────────────────────────────────────

class _ShortcutGrid extends StatelessWidget {
  final VoidCallback? onThoughtsTap;

  const _ShortcutGrid({this.onThoughtsTap});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      crossAxisSpacing: AppSpacing.md,
      childAspectRatio: 2.55,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _ShortcutCard(
          icon: Icons.lightbulb_outline,
          title: '想法',
          subtitle: '随时记录灵感',
          color: AppColors.purple,
          background: AppColors.purpleSoft,
          onTap: onThoughtsTap,
        ),
        const _ShortcutCard(
          icon: Icons.check_circle_outline_rounded,
          title: '待办',
          subtitle: '管理任务清单',
          color: AppColors.success,
          background: AppColors.greenSoft,
        ),
        const _ShortcutCard(
          icon: Icons.article_outlined,
          title: '笔记',
          subtitle: '沉淀知识',
          color: AppColors.primary,
          background: AppColors.blueSoft,
        ),
        const _ShortcutCard(
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

// ─── Home Right Rail ────────────────────────────────────────────────

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

// ─── Pinned Panel ───────────────────────────────────────────────────

class _PinnedPanel extends ConsumerWidget {
  const _PinnedPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                      color: AppColors.textTertiary,
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
                  final color = _itemColor(item);
                  final background = _itemBackground(color);
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

// ─── Data Panel ─────────────────────────────────────────────────────

class _DataPanel extends ConsumerWidget {
  const _DataPanel();

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
            color: AppColors.purple,
            background: AppColors.purpleSoft,
          ),
          const _DataLine(
            icon: Icons.check_circle_outline,
            label: '待办',
            // TODO: 待插件实现后替换为真实数据
            value: '24',
            change: '—',
            color: AppColors.success,
            background: AppColors.greenSoft,
          ),
          const _DataLine(
            icon: Icons.article_outlined,
            label: '笔记',
            // TODO: 待插件实现后替换为真实数据
            value: '56',
            change: '—',
            color: AppColors.primary,
            background: AppColors.blueSoft,
          ),
        ],
      ),
    );
  }
}

// ─── Reusable Section / Panel Widgets ───────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? trailing;
  final VoidCallback? onTap;

  const _SectionTitle({required this.title, this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
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
                  color: AppColors.primary,
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
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Padding(padding: padding, child: child),
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
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
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
                          padding: const EdgeInsets.only(
                            bottom: AppSpacing.xxs,
                          ),
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
                  color: AppColors.surface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Icon(
                  icon,
                  color: color.withValues(alpha: 0.65),
                  size: 32,
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
    final title = _firstLine(item.content);
    final body = _restLines(item.content);
    final tag = item.tags.isNotEmpty ? item.tags.first : '';
    final time = _formatTimestamp(item.createdAt);
    final color = _itemColor(item);
    final background = _itemBackground(color);

    return Material(
      color: background.withValues(alpha: 0.62),
      borderRadius: BorderRadius.circular(AppRadius.md),
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
                  Expanded(child: Text(time, style: theme.textTheme.bodySmall)),
                  Icon(
                    item.isPinned
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: item.isPinned
                        ? AppColors.warning
                        : AppColors.textTertiary,
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
              if (tag.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: AppSpacing.sm),
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
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              _IconBubble(
                icon: icon,
                color: color,
                background: AppColors.surface.withValues(alpha: 0.5),
              ),
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
            if (onTap != null)
              const Icon(
                Icons.more_vert_rounded,
                color: AppColors.textTertiary,
              ),
          ],
        ),
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
              color: AppColors.textTertiary,
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

const _accentPalette = [
  AppColors.warning,
  AppColors.success,
  AppColors.primary,
  AppColors.purple,
  AppColors.error,
  AppColors.secondary,
];

const _backgroundPalette = [
  AppColors.yellowSoft,
  AppColors.greenSoft,
  AppColors.blueSoft,
  AppColors.purpleSoft,
  AppColors.roseSoft,
  AppColors.secondarySoft,
];

Color _itemColor(DashboardItem item) {
  if (item.colorHex != null && item.colorHex!.isNotEmpty) {
    final cleaned = item.colorHex!.replaceFirst('#', '');
    final normalized = cleaned.length == 6 ? 'FF$cleaned' : cleaned;
    final intVal = int.tryParse(normalized, radix: 16);
    if (intVal != null) return Color(intVal);
  }
  final idx = item.itemId.hashCode.abs();
  return _accentPalette[idx % _accentPalette.length];
}

Color _itemBackground(Color color) {
  final idx = color.toARGB32().abs();
  return _backgroundPalette[idx % _backgroundPalette.length];
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
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFB7C5FF), AppColors.primary],
            ),
          ),
          child: const Center(
            child: Text(
              'U',
              style: TextStyle(
                color: Colors.white,
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
            const Positioned(
              top: 10,
              right: 10,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.primary,
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
            Icon(icon, color: AppColors.warning, size: 30),
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
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: onTap,
      child: Container(
        height: AppMobileSizes.searchHeight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.search_rounded, color: AppColors.textSecondary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                '搜索想法、待办、笔记、标签...',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppColors.textTertiary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.crop_free_rounded, color: AppColors.textSecondary),
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
      final registry = ref.read(pluginRegistryProvider);
      await registry.quickCreate(ref, content: content);
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
    return Material(
      color: AppColors.surfaceSubtle,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const _IconBubble(
                  icon: Icons.edit_outlined,
                  color: AppColors.primary,
                  background: AppColors.primarySoft,
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
    return GridView.count(
      crossAxisCount: 3,
      crossAxisSpacing: AppSpacing.md,
      mainAxisSpacing: AppSpacing.md,
      childAspectRatio: 0.62,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        const _MobileFocusCard(
          title: '今日待办',
          value: '5',
          note: '项待完成',
          icon: Icons.check_box_outlined,
          color: AppColors.success,
          background: AppColors.greenSoft,
        ),
        const _MobileFocusCard(
          title: '最近笔记',
          value: '3',
          note: '条新笔记',
          icon: Icons.description_outlined,
          color: AppColors.primary,
          background: AppColors.blueSoft,
        ),
        _MobileFocusCard(
          title: '想法灵感',
          value: '$thoughtsCount',
          note: '条未整理',
          icon: Icons.lightbulb_outline,
          color: AppColors.warning,
          background: AppColors.yellowSoft,
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
                  color: AppColors.surface.withValues(alpha: 0.5),
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
      color: AppColors.surfaceSubtle,
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
            color: done ? AppColors.primary : AppColors.textTertiary,
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
          color: AppColors.purple,
          background: AppColors.purpleSoft,
          onTap: onThoughtsTap,
        ),
        _MobileShortcutCard(
          icon: Icons.check_box_outlined,
          title: '待办',
          subtitle: '管理任务清单',
          color: AppColors.success,
          background: AppColors.greenSoft,
          onTap: onTodosTap,
        ),
        _MobileShortcutCard(
          icon: Icons.description_outlined,
          title: '笔记',
          subtitle: '记录与沉淀知识',
          color: AppColors.primary,
          background: AppColors.blueSoft,
          onTap: onNotesTap,
        ),
        _MobileShortcutCard(
          icon: Icons.search_rounded,
          title: '搜索',
          subtitle: '查找全部内容',
          color: AppColors.textSecondary,
          background: AppColors.surfaceMuted,
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
                  color: AppColors.surface.withValues(alpha: 0.5),
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
