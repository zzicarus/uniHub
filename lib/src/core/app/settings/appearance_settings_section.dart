import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_theme_preset.dart';
import '../../theme/app_theme_registry.dart';
import '../../theme/app_theme_tokens.dart';
import '../../theme/app_tokens.dart';
import '../../theme/theme_settings_provider.dart';

/// 外观设置组件，用于调整主题模式与主题预设。
class AppearanceSettingsSection extends ConsumerWidget {
  const AppearanceSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = context.appColors;
    final settings = ref.watch(themeSettingsProvider);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '外观',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '调整主题模式与主题预设',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          _ThemeModeSelector(settings: settings),
          const Divider(),
          const _ThemePresetGrid(),
        ],
      ),
    );
  }
}

/// 主题模式选择器（跟随系统 / 浅色 / 深色）。
class _ThemeModeSelector extends ConsumerWidget {
  final ThemeSettings settings;

  const _ThemeModeSelector({required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = context.appColors;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '主题模式',
            style: theme.textTheme.titleSmall?.copyWith(
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            '选择跟随系统、浅色或深色显示',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.system,
                label: Text('跟随系统'),
                icon: Icon(Icons.brightness_auto_outlined),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                label: Text('浅色'),
                icon: Icon(Icons.light_mode_outlined),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text('深色'),
                icon: Icon(Icons.dark_mode_outlined),
              ),
            ],
            selected: {settings.mode},
            onSelectionChanged: (values) {
              unawaited(ref.read(themeSettingsProvider.notifier).setMode(values.first));
            },
            showSelectedIcon: false,
          ),
        ],
      ),
    );
  }
}

/// 主题预设选择网格，响应式排列预设卡片。
class _ThemePresetGrid extends ConsumerWidget {
  const _ThemePresetGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = context.appColors;
    final brightness = theme.brightness;
    final settings = ref.watch(themeSettingsProvider);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '主题预设',
            style: theme.textTheme.titleSmall?.copyWith(
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            '选择一套适合当前使用场景的视觉风格',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              double cardWidth;
              if (width >= 760) {
                cardWidth = (width - 2 * AppSpacing.md) / 3;
              } else if (width >= 520) {
                cardWidth = (width - AppSpacing.md) / 2;
              } else {
                cardWidth = width;
              }

              return Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: [
                  for (final preset in AppThemePreset.values)
                    SizedBox(
                      width: cardWidth,
                      child: _ThemePresetCard(
                        preset: preset,
                        isSelected: settings.preset == preset,
                        previewColors:
                            AppThemeRegistry.colorsOf(preset, brightness),
                        onTap: () => unawaited(ref
                            .read(themeSettingsProvider.notifier)
                            .setPreset(preset)),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// 单个主题预设卡片，显示颜色预览和选中态。
class _ThemePresetCard extends StatelessWidget {
  final AppThemePreset preset;
  final bool isSelected;
  final UniHubThemeColors previewColors;
  final VoidCallback onTap;

  const _ThemePresetCard({
    required this.preset,
    required this.isSelected,
    required this.previewColors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appColors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: isSelected ? colors.primary : colors.border,
            ),
            color: isSelected
                ? colors.primarySoft.withValues(alpha: 0.5)
                : colors.panelBackground,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      preset.label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      preset.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        _ColorDot(color: previewColors.primary),
                        const SizedBox(width: AppSpacing.xs),
                        _ColorDot(color: previewColors.primarySoft),
                        const SizedBox(width: AppSpacing.xs),
                        _ColorDot(color: previewColors.surfaceMuted),
                      ],
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle_rounded,
                  color: colors.primary,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 颜色圆点，用于主题预览。
class _ColorDot extends StatelessWidget {
  final Color color;

  const _ColorDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
