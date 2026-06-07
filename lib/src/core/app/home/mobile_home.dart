part of '../home_page.dart';

// ─── Mobile Home View ───────────────────────────────────────────────

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
                fontSize: AppFontTokens.display,
                height: 1,
                fontWeight: AppFontTokens.black,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          'uniHub',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontSize: AppFontTokens.brand,
            fontWeight: AppFontTokens.extraBold,
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
                child: const SizedBox(width: AppSpacing.xs, height: AppSpacing.xs),
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
    // TODO(profile): Replace neutral greeting with profileProvider when user profile is available.
    final greeting = hour >= 6 && hour < 12
        ? '早上好'
        : hour >= 12 && hour < 18
        ? '下午好'
        : '晚上好';
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
                  fontSize: AppFontTokens.hero,
                  fontWeight: AppFontTokens.extraBold,
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
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.25)),
          boxShadow: const [AppShadows.cardSoft],
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
      final item = await ref.read(
        quickCreateProvider((content: content, tags: null)).future,
      );

      if (!mounted) return;

      if (item == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('无法识别内容')),
        );
        return;
      }

      final message = switch (item.pluginId) {
        'collections' => '已收藏',
        'thoughts' => '想法已记录',
        _ => '已记录',
      };

      _controller.clear();
      ref.invalidate(dashboardItemsProvider);
      ref.invalidate(dashboardPinnedProvider);
      ref.invalidate(dashboardStatsProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.25)),
          boxShadow: const [AppShadows.cardSoft],
        ),
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
          value: '—',
          note: '项待完成',
          icon: Icons.check_box_outlined,
          color: colorScheme.secondary,
          background: colorScheme.secondaryContainer,
        ),
        _MobileFocusCard(
          title: '最近笔记',
          value: '—',
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
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.25)),
          boxShadow: const [AppShadows.cardSoft],
        ),
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
                  fontSize: AppFontTokens.display,
                  fontWeight: AppFontTokens.extraBold,
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
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Icon(icon, color: color.withValues(alpha: 0.65)),
                ),
              ),
            ],
          ),
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
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.25)),
          boxShadow: const [AppShadows.cardSoft],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.xl),
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
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('暂无待办数据', style: TextStyle(color: Colors.grey)),
          ),
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
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.25)),
          boxShadow: const [AppShadows.cardSoft],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.xl),
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
                    borderRadius: BorderRadius.circular(AppRadius.lg),
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
      ),
    );
  }
}
