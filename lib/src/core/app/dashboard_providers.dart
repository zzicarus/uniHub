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
