import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'app_database.dart';
import '../plugin/plugin_registry.dart';

QueryExecutor _createExecutor() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'unihub.db'));
    return NativeDatabase(file);
  });
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final registry = ref.read(pluginRegistryProvider);
  final db = AppDatabase(_createExecutor(), registry);
  ref.onDispose(() => db.close());
  return db;
});
