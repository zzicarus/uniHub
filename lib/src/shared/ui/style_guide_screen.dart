import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

class StyleGuideScreen extends StatelessWidget {
  const StyleGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('UniHub Style Guide')),
      body: ListView(
        key: const Key('styleGuideScroll'),
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text('清爽、可信、年轻、高效', style: textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '用于确认 uniHub 移动端基础视觉语言，后续业务页面统一复用这套 Token 与 Theme。',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xl),
          const _TypographySection(),
          const _FontSection(),
          const _WindowsStyleSection(),
          const _ButtonSection(),
          const _InputSection(),
          const _CardSection(),
          const _ChipSection(),
          const _ListSection(),
          const _EmptyStateSection(),
          const _ErrorStateSection(),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _TypographySection extends StatelessWidget {
  const _TypographySection();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return _Section(
      title: '标题 / 正文 / 辅助文字',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Headline Medium 页面主标题', style: textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.sm),
              Text('Title Large 模块标题', style: textTheme.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              Text('Title Medium 列表主标题', style: textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              Text('Body Large 正文内容适合说明较长的信息。', style: textTheme.bodyLarge),
              const SizedBox(height: AppSpacing.xs),
              Text('Body Medium 用于描述、说明和列表副标题。', style: textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.xs),
              Text('Body Small 用于时间、状态和弱提示。', style: textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _FontSection extends StatelessWidget {
  const _FontSection();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return _Section(
      title: '字体策略',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Material 3 默认字体', style: textTheme.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '课程、活动、想法记录和表单正文继续使用 Flutter Material 平台默认字体。',
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                '霞鹜文楷屏幕阅读版',
                style: textTheme.titleLarge?.copyWith(
                  fontFamily: AppFonts.decorative,
                  fontFamilyFallback: AppFonts.fallback,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '适合品牌短句、空状态标题和轻量情绪化文案，不用于大段正文和密集列表。',
                style: textTheme.bodyMedium?.copyWith(
                  fontFamily: AppFonts.decorative,
                  fontFamilyFallback: AppFonts.fallback,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ButtonSection extends StatelessWidget {
  const _ButtonSection();

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: '按钮',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add_rounded),
            label: const Text('主按钮'),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.calendar_today_outlined),
            label: const Text('次按钮'),
          ),
          const SizedBox(height: AppSpacing.sm),
          const FilledButton(onPressed: null, child: Text('禁用按钮')),
        ],
      ),
    );
  }
}

class _WindowsStyleSection extends StatelessWidget {
  const _WindowsStyleSection();

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Windows 端基础布局',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final preview = SizedBox(
            width: AppDesktopSizes.previewMinWidth,
            child: const _DesktopShellPreview(),
          );

          if (constraints.maxWidth >= AppDesktopSizes.previewMinWidth) {
            return preview;
          }

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: preview,
          );
        },
      ),
    );
  }
}

class _DesktopShellPreview extends StatelessWidget {
  const _DesktopShellPreview();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SizedBox(
        height: 560,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const [
            _DesktopSidebarPreview(),
            VerticalDivider(width: 1),
            Expanded(child: _DesktopContentPreview()),
            VerticalDivider(width: 1),
            _DesktopRightRailPreview(),
          ],
        ),
      ),
    );
  }
}

class _DesktopSidebarPreview extends StatelessWidget {
  const _DesktopSidebarPreview();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: AppDesktopSizes.sidebarWidth,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const _AppMark(),
                const SizedBox(width: AppSpacing.sm),
                Text('uniHub', style: textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            const _DesktopNavItem(
              icon: Icons.home_rounded,
              label: '首页',
              selected: true,
            ),
            const _DesktopNavItem(icon: Icons.lightbulb_outline, label: '想法'),
            const _DesktopNavItem(icon: Icons.check_box_outlined, label: '待办'),
            const _DesktopNavItem(
              icon: Icons.description_outlined,
              label: '笔记',
            ),
            const _DesktopNavItem(
              icon: Icons.calendar_today_outlined,
              label: '日历',
            ),
            const _DesktopNavItem(icon: Icons.star_border_rounded, label: '收藏'),
            const Spacer(),
            const Divider(),
            const _DesktopNavItem(icon: Icons.settings_outlined, label: '设置'),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: colorScheme.primaryContainer,
                  child: Icon(
                    Icons.person_outline,
                    size: 20,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Alex', style: textTheme.titleSmall),
                      Text('专注记录', style: textTheme.bodySmall),
                    ],
                  ),
                ),
                const Icon(Icons.expand_more_rounded, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DesktopNavItem extends StatelessWidget {
  const _DesktopNavItem({
    required this.icon,
    required this.label,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = selected
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected ? colorScheme.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: SizedBox(
          height: AppDesktopSizes.navItemHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                Icon(icon, color: foreground, size: 22),
                const SizedBox(width: AppSpacing.md),
                Text(
                  label,
                  style: textTheme.titleSmall?.copyWith(color: foreground),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DesktopContentPreview extends StatelessWidget {
  const _DesktopContentPreview();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: SingleChildScrollView(
        primary: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('早上好，Alex ☀', style: textTheme.headlineMedium),
                      const SizedBox(height: AppSpacing.xs),
                      Text('快速记录、整理与找回你的信息', style: textTheme.bodyMedium),
                    ],
                  ),
                ),
                const _DesktopSearchField(),
                const SizedBox(width: AppSpacing.sm),
                const _IconButtonPreview(
                  icon: Icons.notifications_none_rounded,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            const _QuickCapturePreview(),
            const SizedBox(height: AppSpacing.xl),
            Text('桌面端信息卡片', style: textTheme.titleLarge),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    icon: Icons.check_box_outlined,
                    title: '今日待办',
                    value: '5',
                    color: colorScheme.secondary,
                    tint: colorScheme.secondaryContainer,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _MetricCard(
                    icon: Icons.description_outlined,
                    title: '最近笔记',
                    value: '3',
                    color: colorScheme.primary,
                    tint: colorScheme.primaryContainer,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _MetricCard(
                    icon: Icons.lightbulb_outline,
                    title: '灵感想法',
                    value: '8',
                    color: colorScheme.tertiary,
                    tint: colorScheme.tertiaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            const _DesktopListPreview(),
          ],
        ),
      ),
    );
  }
}

class _DesktopSearchField extends StatelessWidget {
  const _DesktopSearchField();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: SizedBox(
        width: 240,
        height: AppDesktopSizes.compactButtonHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Row(
            children: [
              const Icon(Icons.search_rounded, size: 18),
              const SizedBox(width: AppSpacing.xs),
              Text('Ctrl + K 全局搜索', style: textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickCapturePreview extends StatelessWidget {
  const _QuickCapturePreview();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return _DesktopPanel(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IconBadge(icon: Icons.edit_outlined, color: colorScheme.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('快速记录想法', style: textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                const TextField(
                  decoration: InputDecoration(hintText: '快速记录你的想法...'),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    const _MiniActionChip(
                      icon: Icons.sell_outlined,
                      label: '标签',
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    const _MiniActionChip(
                      icon: Icons.image_outlined,
                      label: '图片',
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.send_outlined, size: 18),
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

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    required this.tint,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tint,
        border: Border.all(color: color.withValues(alpha: 0.22)),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: AppSpacing.sm),
            Text(title, style: textTheme.bodySmall),
            Text(value, style: textTheme.headlineMedium),
            Text(
              '查看全部 →',
              style: textTheme.labelMedium?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _DesktopListPreview extends StatelessWidget {
  const _DesktopListPreview();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return _DesktopPanel(
      child: Column(
        children: [
          _CompactListRow(
            icon: Icons.star_rounded,
            title: '产品想法：轻量级个人信息中心',
            tag: '产品想法',
            color: colorScheme.tertiary,
            tint: colorScheme.tertiaryContainer,
          ),
          const Divider(),
          _CompactListRow(
            icon: Icons.menu_book_outlined,
            title: '读书笔记：《原子习惯》',
            tag: '阅读笔记',
            color: colorScheme.secondary,
            tint: colorScheme.secondaryContainer,
          ),
          const Divider(),
          _CompactListRow(
            icon: Icons.shopping_cart_outlined,
            title: '采购清单',
            tag: '生活',
            color: colorScheme.primary,
            tint: colorScheme.primaryContainer,
          ),
        ],
      ),
    );
  }
}

class _CompactListRow extends StatelessWidget {
  const _CompactListRow({
    required this.icon,
    required this.title,
    required this.tag,
    required this.color,
    required this.tint,
  });

  final IconData icon;
  final String title;
  final String tag;
  final Color color;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      height: 56,
      child: Row(
        children: [
          _SmallIconTile(icon: icon, color: color, tint: tint),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(title, style: textTheme.titleSmall)),
          _PillLabel(label: tag, color: color, tint: tint),
          const SizedBox(width: AppSpacing.xs),
          const Icon(Icons.more_horiz_rounded, size: 18),
        ],
      ),
    );
  }
}

class _DesktopRightRailPreview extends StatelessWidget {
  const _DesktopRightRailPreview();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: AppDesktopSizes.rightRailWidth,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: SingleChildScrollView(
          primary: false,
          child: Column(
            children: [
              _DesktopPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('右侧信息栏', style: textTheme.titleMedium),
                        const Spacer(),
                        const Icon(Icons.add_rounded, size: 18),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _CompactListRow(
                      icon: Icons.bookmark_rounded,
                      title: '人生愿景清单',
                      tag: '长期',
                      color: colorScheme.tertiary,
                      tint: colorScheme.tertiaryContainer,
                    ),
                    const Divider(),
                    _CompactListRow(
                      icon: Icons.folder_rounded,
                      title: '旅行计划',
                      tag: '计划',
                      color: colorScheme.primary,
                      tint: colorScheme.primaryContainer,
                    ),
                    const Divider(),
                    _CompactListRow(
                      icon: Icons.task_alt_rounded,
                      title: '今日待办',
                      tag: '5',
                      color: colorScheme.secondary,
                      tint: colorScheme.secondaryContainer,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _DesktopPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('桌面端规则', style: textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.md),
                    const _RuleLine(text: '左侧导航固定宽度，选中态使用浅蓝底。'),
                    const _RuleLine(text: '内容卡片白底、细边框、低阴影。'),
                    const _RuleLine(text: '右侧栏只承载摘要和快捷入口。'),
                    const _RuleLine(text: '桌面端信息密度高于移动端，但间距仍基于 8pt。'),
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

class _DesktopPanel extends StatelessWidget {
  const _DesktopPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: child,
      ),
    );
  }
}

class _MiniActionChip extends StatelessWidget {
  const _MiniActionChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: AppSpacing.xs),
            Text(label, style: textTheme.labelMedium),
          ],
        ),
      ),
    );
  }
}

class _SmallIconTile extends StatelessWidget {
  const _SmallIconTile({
    required this.icon,
    required this.color,
    required this.tint,
  });

  final IconData icon;
  final Color color;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: SizedBox.square(
        dimension: 36,
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}

class _PillLabel extends StatelessWidget {
  const _PillLabel({
    required this.label,
    required this.color,
    required this.tint,
  });

  final String label;
  final Color color;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xxs,
        ),
        child: Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: color),
        ),
      ),
    );
  }
}

class _RuleLine extends StatelessWidget {
  const _RuleLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_rounded,
            color: Theme.of(context).colorScheme.secondary,
            size: 16,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

class _IconButtonPreview extends StatelessWidget {
  const _IconButtonPreview({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: SizedBox.square(
        dimension: AppDesktopSizes.compactButtonHeight,
        child: Icon(icon, size: 18),
      ),
    );
  }
}

class _AppMark extends StatelessWidget {
  const _AppMark();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.tertiary],
        ),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: SizedBox.square(
        dimension: 32,
        child: Center(
          child: Text(
            'U',
            style: TextStyle(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _InputSection extends StatelessWidget {
  const _InputSection();

  @override
  Widget build(BuildContext context) {
    return const _Section(
      title: '输入框',
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              labelText: '课程名称',
              hintText: '例如：高等数学',
              prefixIcon: Icon(Icons.school_outlined),
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          TextField(
            minLines: 3,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: '备注',
              hintText: '记录地点、作业或灵感',
              prefixIcon: Icon(Icons.edit_note_outlined),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardSection extends StatelessWidget {
  const _CardSection();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return _Section(
      title: '卡片',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _IconBadge(
                    icon: Icons.task_alt_rounded,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('今日重点', style: textTheme.titleMedium),
                        const SizedBox(height: AppSpacing.xxs),
                        Text('14:00 · 教学楼 B204', style: textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text('线性代数讨论课前完成例题整理，课后同步到想法记录。', style: textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChipSection extends StatelessWidget {
  const _ChipSection();

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: '标签',
      child: Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        children: const [
          Chip(label: Text('课程')),
          Chip(label: Text('社团活动')),
          Chip(label: Text('待处理')),
          Chip(avatar: Icon(Icons.bolt_rounded, size: 16), label: Text('高优先级')),
        ],
      ),
    );
  }
}

class _ListSection extends StatelessWidget {
  const _ListSection();

  @override
  Widget build(BuildContext context) {
    return const _Section(
      title: '列表项',
      child: Card(
        child: Column(
          children: [
            ListTile(
              leading: Icon(Icons.school_outlined),
              title: Text('课程表'),
              subtitle: Text('查看今天和本周课程安排'),
              trailing: Icon(Icons.chevron_right_rounded),
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.event_available_outlined),
              title: Text('校园活动'),
              subtitle: Text('2 个活动即将开始'),
              trailing: Icon(Icons.chevron_right_rounded),
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.lightbulb_outline_rounded),
              title: Text('想法记录'),
              subtitle: Text('快速保存学习和生活灵感'),
              trailing: Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyStateSection extends StatelessWidget {
  const _EmptyStateSection();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return _Section(
      title: '空状态',
      child: _StatusPanel(
        icon: Icons.inbox_outlined,
        iconColor: colorScheme.secondary,
        title: '今天还没有安排',
        message: '添加课程、活动或待办后，这里会展示接下来要处理的事项。',
        actionLabel: '添加事项',
      ),
    );
  }
}

class _ErrorStateSection extends StatelessWidget {
  const _ErrorStateSection();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return _Section(
      title: '错误状态',
      child: _StatusPanel(
        icon: Icons.error_outline_rounded,
        iconColor: colorScheme.error,
        title: '同步失败',
        message: '当前网络不稳定，部分数据可能不是最新状态。',
        actionLabel: '重试',
        isOutlinedAction: true,
      ),
    );
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    required this.actionLabel,
    this.isOutlinedAction = false,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final String actionLabel;
  final bool isOutlinedAction;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _IconBadge(icon: icon, color: iconColor),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              style: textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: isOutlinedAction
                  ? OutlinedButton(onPressed: () {}, child: Text(actionLabel))
                  : FilledButton(onPressed: () {}, child: Text(actionLabel)),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: SizedBox.square(
        dimension: AppSizes.statusIcon,
        child: Icon(icon, color: color),
      ),
    );
  }
}
