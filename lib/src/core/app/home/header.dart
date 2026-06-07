part of '../home_page.dart';

// ─── Header ─────────────────────────────────────────────────────────

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Row(
      children: [
        AppIconBubble(
          icon: _greetingIcon(),
          color: AppColors.accent,
          background: AppColors.yellowSoft,
          size: 62,
          iconSize: 30,
          shape: BoxShape.rectangle,
          radius: AppRadius.xl,
        ),
        const SizedBox(width: AppSpacing.xl),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildGreeting(theme, colorScheme),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                '专注当下，持续进步。把想法、任务与日程收拢到一个中台。',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.xl),
        AppSearchBox(
          width: 380,
          hintText: '搜索想法、笔记、待办...',
          onTap: () {
            AppToast.show(
              context,
              message: '全局搜索即将上线',
            );
          },
        ),
        const SizedBox(width: AppSpacing.md),
        const _NotificationButton(),
      ],
    );
  }

  Widget _buildGreeting(ThemeData theme, ColorScheme colorScheme) {
    final hour = DateTime.now().hour;
    // TODO(profile): Replace neutral greeting with profileProvider when user profile is available.
    final greeting = switch (hour) {
      >= 6 && < 12 => '早上好',
      >= 12 && < 18 => '下午好',
      _ => '晚上好',
    };
    return Text(
      greeting,
      style: theme.textTheme.headlineSmall?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: AppFontTokens.extraBold,
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

class _NotificationButton extends StatelessWidget {
  const _NotificationButton();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AppPanel(
          compact: true,
          padding: EdgeInsets.zero,
          radius: AppRadius.lg,
          child: SizedBox(
            width: AppSizes.inputHeight,
            height: AppSizes.inputHeight,
            child: Icon(
              Icons.notifications_none_rounded,
              color: colorScheme.onSurfaceVariant,
              size: 22,
            ),
          ),
        ),
        Positioned(
          right: 9,
          top: 9,
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
