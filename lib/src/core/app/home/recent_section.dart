part of '../home_page.dart';

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
        return _buildDataGrid(context, items.take(6).toList());
      },
    );
  }

  Widget _buildLoadingGrid(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = AppSpacing.md;
        final columns = constraints.maxWidth >= 760 ? 3 : 1;
        final cardWidth =
            (constraints.maxWidth - (columns - 1) * spacing) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: List.generate(
            columns,
            (_) => SizedBox(
              width: cardWidth,
              height: 108,
              child: AppPanel(
                compact: true,
                child: Center(
                  child: CircularProgressIndicator(
                    color: colorScheme.primary,
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    final colorScheme = Theme.of(context).colorScheme;
    return AppPanel(
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
    return AppPanel(
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
        const cardHeight = 112.0;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: items.take(3).map((item) {
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
  final VoidCallback? onCollectionsTap;

  const _QuickAccessPanel({
    this.onThoughtsTap,
    this.onCollectionsTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(title: '快捷入口', icon: Icons.bolt_outlined),
          const SizedBox(height: AppSpacing.md),
          _ShortcutGrid(
            onThoughtsTap: onThoughtsTap,
            onCollectionsTap: onCollectionsTap,
          ),
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
    return AppPanel(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            title: '最近想法',
            icon: Icons.lightbulb_outline,
            trailingText: '查看全部',
            onTrailingTap: onOpen,
          ),
          const SizedBox(height: AppSpacing.md),
          const _RecentThoughtsGrid(),
        ],
      ),
    );
  }
}

// ─── Shortcut Grid ──────────────────────────────────────────────────

class _ShortcutGrid extends StatelessWidget {
  final VoidCallback? onThoughtsTap;
  final VoidCallback? onCollectionsTap;

  const _ShortcutGrid({
    this.onThoughtsTap,
    this.onCollectionsTap,
  });

  @override
  Widget build(BuildContext context) {
    // Only show shortcuts with real destinations.
    // Entries for unimplemented modules (笔记, 待办, 日程) are omitted
    // per PRD 2.4: placeholder shortcuts should not occupy core positions.
    final items = <Widget>[
      _ShortcutCard(
        icon: Icons.add_rounded,
        title: '新建想法',
        subtitle: '快速记录想法',
        color: AppColors.primary,
        background: AppColors.primarySoft,
        onTap: onThoughtsTap,
      ),
      _ShortcutCard(
        icon: Icons.bookmark_border_rounded,
        title: '收藏内容',
        subtitle: '稍后查看',
        color: AppColors.error,
        background: AppColors.roseSoft,
        onTap: onCollectionsTap,
      ),
    ];

    if (items.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 820 ? 6 : 3;
        final effectiveColumns = columns > items.length
            ? items.length
            : columns;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: effectiveColumns,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: 1.6,
          ),
          itemBuilder: (context, index) => items[index],
        );
      },
    );
  }
}
