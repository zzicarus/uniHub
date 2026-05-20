import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../plugin/plugin_interface.dart';
import '../plugin/plugin_registry.dart';

final dashboardItemsProvider = FutureProvider<List<DashboardItem>>((ref) async {
  final registry = ref.watch(pluginRegistryProvider);
  return registry.getDashboardItems(ref);
});

final dashboardPinnedProvider = FutureProvider<List<DashboardItem>>((
  ref,
) async {
  final registry = ref.watch(pluginRegistryProvider);
  return registry.getDashboardPinned(ref);
});

final dashboardStatsProvider = FutureProvider<List<PluginStat>>((ref) async {
  final registry = ref.watch(pluginRegistryProvider);
  return registry.getDashboardStats(ref);
});

/// Quick-create a dashboard item (e.g. a thought) via the plugin registry.
///
/// Used from widgets (ConsumerState) where [WidgetRef] is available but
/// [Ref] is not — this provider bridges the gap.
final quickCreateProvider = FutureProvider.autoDispose
    .family<DashboardItem?, ({String content, String? tags})>(
  (ref, params) async {
    final registry = ref.read(pluginRegistryProvider);
    return registry.quickCreate(ref, content: params.content, tags: params.tags);
  },
);
