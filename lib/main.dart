import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/core/app/app.dart';
import 'src/core/plugin/plugin_registry.dart';
import 'src/plugins/thoughts/thoughts_plugin.dart';

void main() {
  runApp(
    ProviderScope(
      overrides: [
        pluginRegistryProvider.overrideWith((ref) {
          final registry = PluginRegistry();
          registry.register(ThoughtsPlugin());
          return registry;
        }),
      ],
      child: const UniHubApp(),
    ),
  );
}
