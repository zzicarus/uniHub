import 'package:drift/drift.dart';

class SavedItemsTable extends Table {
  @override
  String get tableName => 'saved_items';

  IntColumn get id => integer().autoIncrement()();

  TextColumn get originalUrl => text()();
  TextColumn get normalizedUrl => text().unique()();

  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get description => text().nullable()();
  TextColumn get author => text().nullable()();
  TextColumn get siteName => text().nullable()();
  TextColumn get coverImage => text().nullable()();
  TextColumn get favicon => text().nullable()();

  TextColumn get mediaType => text().withDefault(const Constant('unknown'))();
  TextColumn get sourcePlatform =>
      text().withDefault(const Constant('unknown'))();

  TextColumn get status => text().withDefault(const Constant('unread'))();
  BoolColumn get isInInbox => boolean().withDefault(const Constant(true))();

  TextColumn get enrichmentStatus =>
      text().withDefault(const Constant('pending'))();

  TextColumn get extractedText => text().nullable()();
  TextColumn get summary => text().nullable()();
  TextColumn get metadataJson => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get lastOpenedAt => dateTime().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get archivedAt => dateTime().nullable()();
}
