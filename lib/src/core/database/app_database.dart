import 'package:drift/drift.dart';
import '../../plugins/thoughts/data/thoughts_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [ThoughtsTable])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        await m.addColumn(thoughtsTable, thoughtsTable.imagePaths);
      }
    },
  );
}
