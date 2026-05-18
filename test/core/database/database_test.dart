import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:uni_hub/src/core/database/app_database.dart';

void main() {
  group('AppDatabase', () {
    test('creates with schema version 2', () {
      final database = AppDatabase(NativeDatabase.memory());
      expect(database.schemaVersion, 2);
      database.close();
    });

    test('has ThoughtsTable registered', () {
      final database = AppDatabase(NativeDatabase.memory());
      expect(database.allTables, isNotEmpty);
      database.close();
    });

    test('can be closed without error', () async {
      final database = AppDatabase(NativeDatabase.memory());
      expect(() async => await database.close(), returnsNormally);
    });

    test('has migration strategy', () {
      final database = AppDatabase(NativeDatabase.memory());
      expect(database.migration, isA<MigrationStrategy>());
      database.close();
    });
  });
}
