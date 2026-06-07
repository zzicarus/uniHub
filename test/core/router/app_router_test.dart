import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:uni_hub/src/core/plugin/plugin_registry.dart';
import 'package:uni_hub/src/core/router/app_router.dart';

void main() {
  test('routerProvider returns a GoRouter instance', () async {
    final registry = PluginRegistry();
    final container = ProviderContainer(
      overrides: [
        pluginRegistryProvider.overrideWithValue(registry),
      ],
    );
    addTearDown(container.dispose);

    final router = container.read(routerProvider);
    expect(router, isA<GoRouter>());
  });
}
