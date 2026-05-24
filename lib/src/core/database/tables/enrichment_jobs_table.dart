import 'package:drift/drift.dart';

class EnrichmentJobsTable extends Table {
  @override
  String get tableName => 'enrichment_jobs';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get itemId => integer()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  TextColumn get errorMessage => text().nullable()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get startedAt => dateTime().nullable()();
  DateTimeColumn get finishedAt => dateTime().nullable()();
}
