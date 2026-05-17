import 'package:drift/drift.dart';

class AppDatabase extends GeneratedDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  List<TableInfo<Table, dynamic>> get allTables => [];

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {},
    onUpgrade: (Migrator m, int from, int to) async {},
  );
}
