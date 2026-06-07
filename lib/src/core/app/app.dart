import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../router/app_router.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../theme/theme_settings_provider.dart';

class UniHubApp extends ConsumerWidget {
  const UniHubApp({super.key, this.startupError, this.startupStackTrace});

  final Object? startupError;
  final StackTrace? startupStackTrace;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeSettings = ref.watch(themeSettingsProvider);
    final localizationsDelegates = const [
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      // TODO(quill-migration): Remove FlutterQuillLocalizations after
      // RichTextEditor is fully replaced by AppFlowyThoughtEditor.
      FlutterQuillLocalizations.delegate,
      AppFlowyEditorLocalizations.delegate,
    ];

    final lightTheme = AppTheme.build(
      preset: themeSettings.preset,
      brightness: Brightness.light,
    );
    final darkTheme = AppTheme.build(
      preset: themeSettings.preset,
      brightness: Brightness.dark,
    );

    if (startupError != null) {
      return MaterialApp(
        title: 'UniHub',
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: themeSettings.mode,
        debugShowCheckedModeBanner: false,
        localizationsDelegates: localizationsDelegates,
        home: StartupErrorPage(
          error: startupError!,
          stackTrace: startupStackTrace,
        ),
      );
    }

    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'UniHub',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeSettings.mode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: localizationsDelegates,
    );
  }
}

@visibleForTesting
class StartupErrorPage extends StatelessWidget {
  const StartupErrorPage({super.key, required this.error, this.stackTrace});

  final Object error;
  final StackTrace? stackTrace;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final details = stackTrace == null ? '$error' : '$error\n\n$stackTrace';

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        color: colorScheme.error,
                        size: AppSizes.statusIcon,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'UniHub 启动失败',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: AppFontTokens.semiBold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        '插件初始化时发生错误。应用已进入安全错误页，详情已写入 Flutter 错误日志。',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: colorScheme.errorContainer.withValues(
                            alpha: 0.32,
                          ),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: SelectableText(
                            details,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
