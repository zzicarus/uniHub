import 'package:drift/drift.dart';

/// Many-to-many relation between saved items and tags.
class SavedItemTagsTable extends Table {
  @override
  String get tableName => 'saved_item_tags';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get savedItemId => integer()();
  IntColumn get tagId => integer()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {savedItemId, tagId},
  ];
}
