import 'package:drift/drift.dart';

class ThoughtsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get content => text()();
  TextColumn get color => text().nullable()();
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn? get archivedAt => dateTime().nullable()();
  TextColumn get imagePaths => text().nullable()();
}
