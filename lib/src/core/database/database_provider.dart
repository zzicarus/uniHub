import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../plugin/plugin_registry.dart';
import '../storage/providers/storage_providers.dart';
import 'app_database.dart';

QueryExecutor _createExecutor(Ref ref) {
  return LazyDatabase(() async {
    final storagePaths = await ref.read(appStoragePathsProvider.future);
    return NativeDatabase(storagePaths.databaseFile);
  });
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final registry = ref.read(pluginRegistryProvider);
  final db = AppDatabase(_createExecutor(ref), registry);
  ref.onDispose(db.close);
  return db;
});
