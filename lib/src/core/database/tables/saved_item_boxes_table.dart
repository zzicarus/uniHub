import 'package:drift/drift.dart';

class SavedItemBoxesTable extends Table {
  @override
  String get tableName => 'saved_item_boxes';

  IntColumn get itemId => integer()();
  IntColumn get boxId => integer()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {itemId, boxId};
}
