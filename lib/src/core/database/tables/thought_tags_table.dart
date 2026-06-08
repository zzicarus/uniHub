import 'package:drift/drift.dart';

/// Many-to-many relation between thoughts and tags.
class ThoughtTagsTable extends Table {
  @override
  String get tableName => 'thought_tags';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get thoughtId => integer()();
  IntColumn get tagId => integer()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {thoughtId, tagId},
  ];
}
