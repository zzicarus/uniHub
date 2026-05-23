import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../router/app_router.dart';
import '../theme/app_theme.dart';
import '../theme/theme_settings_provider.dart';

class UniHubApp extends ConsumerWidget {
  const UniHubApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeSettings = ref.watch(themeSettingsProvider);
    return MaterialApp.router(
      title: 'UniHub',
      theme: AppTheme.build(
        preset: themeSettings.preset,
        brightness: Brightness.light,
      ),
      darkTheme: AppTheme.build(
        preset: themeSettings.preset,
        brightness: Brightness.dark,
      ),
      themeMode: themeSettings.mode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
        AppFlowyEditorLocalizations.delegate,
      ],
    );
  }
}
