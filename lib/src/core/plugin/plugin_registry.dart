import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'plugin_interface.dart';

class PluginRegistry {
  final List<UniHubPlugin> _plugins = [];

  void register(UniHubPlugin plugin) => _plugins.add(plugin);
  List<UniHubPlugin> get plugins => List.unmodifiable(_plugins);
  List<NavEntry> get navEntries => [for (final p in _plugins) ...p.navEntries];
  List<GoRoute> get mergedRoutes => [for (final p in _plugins) ...p.routes];

  Future<void> initAll() async {
    for (final p in _plugins) {
      await p.onInit();
    }
  }

  Future<void> disposeAll() async {
    for (final p in _plugins.reversed) {
      await p.onDispose();
    }
  }
}

final pluginRegistryProvider = Provider<PluginRegistry>(
  (ref) => PluginRegistry(),
);
