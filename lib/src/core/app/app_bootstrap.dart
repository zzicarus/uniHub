import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database_provider.dart';
import '../plugin/plugin_interface.dart';
import '../plugin/plugin_registry.dart';

class AppBootstrap {
  static Future<void> initialize(
    WidgetRef ref, {
    List<UniHubPlugin> plugins = const [],
  }) async {
    final registry = ref.read(pluginRegistryProvider);
    for (final plugin in plugins) {
      registry.register(plugin);
    }
    await registry.initAll();
    ref.read(appDatabaseProvider);
  }
}
