part of '../home_page.dart';

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
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.tertiaryContainer,
                colorScheme.tertiaryContainer.withValues(alpha: 0.45),
              ],
            ),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: colorScheme.tertiary.withValues(alpha: 0.10),
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.tertiary.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Icon(_greetingIcon(), color: colorScheme.tertiary, size: 30),
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
      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
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
      borderRadius: BorderRadius.circular(AppRadius.xl),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.xl),
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
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.25)),
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
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.25)),
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
