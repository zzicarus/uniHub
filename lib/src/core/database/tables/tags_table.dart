import 'package:drift/drift.dart';

/// Normalized tags table.
///
/// Each tag has a stable [colorToken] assigned at creation time so that
/// the same tag always renders in the same colour regardless of page.
class TagsTable extends Table {
  @override
  String get tableName => 'tags';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get normalizedName => text().unique()();
  IntColumn get colorToken => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}
