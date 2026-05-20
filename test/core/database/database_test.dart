import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:uni_hub/src/core/database/app_database.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  group('AppDatabase', () {
    test('creates with schema version 2', () {
      expect(database.schemaVersion, 2);
    });

    test('has ThoughtsTable registered', () {
      expect(database.allTables, isNotEmpty);
    });

    test('can be closed without error', () async {
      expect(() async => await database.close(), returnsNormally);
    });

    test('has migration strategy', () {
      expect(database.migration, isA<MigrationStrategy>());
    });
  });
}
