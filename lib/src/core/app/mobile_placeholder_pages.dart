import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Placeholder pages for mobile routes not yet implemented.
///
/// Each page shows a simple "coming soon" message. Replace with
/// real implementations when the corresponding plugin is added.

class TodosPage extends StatelessWidget {
  const TodosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _PlaceholderPage(
      title: '待办',
      icon: Icons.check_box_outlined,
    );
  }
}

class NotesPage extends StatelessWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _PlaceholderPage(
      title: '笔记',
      icon: Icons.description_outlined,
    );
  }
}

class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _PlaceholderPage(
      title: '日历',
      icon: Icons.calendar_month_outlined,
    );
  }
}

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _PlaceholderPage(
      title: '收藏',
      icon: Icons.bookmark_outlined,
    );
  }
}

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _PlaceholderPage(
      title: '搜索',
      icon: Icons.search_rounded,
    );
  }
}

class _PlaceholderPage extends StatelessWidget {
  final String title;
  final IconData icon;

  const _PlaceholderPage({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppMobileSizes.maxContentWidth,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppMobileSizes.pageHorizontalPadding,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 64, color: colorScheme.onSurfaceVariant),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: AppFontTokens.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    '即将推出，敬请期待',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
