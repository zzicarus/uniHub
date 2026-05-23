import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:uni_hub/src/core/theme/app_theme_preset.dart';
import 'package:uni_hub/src/core/theme/theme_settings_provider.dart';

void main() {
  group('themeSettingsProvider', () {
    test('default preset is uniBlue', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final settings = container.read(themeSettingsProvider);
      expect(settings.preset, AppThemePreset.uniBlue);
    });

    test('default mode is system', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final settings = container.read(themeSettingsProvider);
      expect(settings.mode, ThemeMode.system);
    });

    test('setPreset changes preset', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(themeSettingsProvider.notifier)
          .setPreset(AppThemePreset.forest);
      expect(
        container.read(themeSettingsProvider).preset,
        AppThemePreset.forest,
      );
    });

    test('setMode changes mode', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(themeSettingsProvider.notifier)
          .setMode(ThemeMode.dark);
      expect(container.read(themeSettingsProvider).mode, ThemeMode.dark);
    });

    test('state remains independent between containers', () {
      final containerA = ProviderContainer();
      final containerB = ProviderContainer();
      addTearDown(containerA.dispose);
      addTearDown(containerB.dispose);

      containerA
          .read(themeSettingsProvider.notifier)
          .setPreset(AppThemePreset.sakura);

      expect(
        containerA.read(themeSettingsProvider).preset,
        AppThemePreset.sakura,
      );
      expect(
        containerB.read(themeSettingsProvider).preset,
        AppThemePreset.uniBlue,
      );
    });
  });
}
