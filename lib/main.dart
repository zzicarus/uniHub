import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/core/app/app.dart';
import 'src/core/plugin/plugin_registry.dart';
import 'src/plugins/collections/collections_plugin.dart';
import 'src/plugins/thoughts/thoughts_plugin.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final registry = PluginRegistry();
  registry.register(ThoughtsPlugin());
  registry.register(CollectionsPlugin());

  Object? startupError;
  StackTrace? startupStackTrace;
  try {
    await registry.initAll();
  } catch (error, stackTrace) {
    startupError = error;
    startupStackTrace = stackTrace;
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'unihub startup',
        context: ErrorDescription('while initializing plugins'),
      ),
    );
  }

  runApp(
    ProviderScope(
      overrides: [
        pluginRegistryProvider.overrideWith((ref) {
          ref.onDispose(() => registry.disposeAll());
          return registry;
        }),
      ],
      child: UniHubApp(
        startupError: startupError,
        startupStackTrace: startupStackTrace,
      ),
    ),
  );
}
