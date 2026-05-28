import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:uni_hub/src/core/database/app_database.dart';
import 'package:uni_hub/src/core/database/tables/thoughts_table.dart';
import 'package:uni_hub/src/core/plugin/plugin_interface.dart';
import 'package:uni_hub/src/core/plugin/plugin_registry.dart';

/// A minimal test plugin that declares a table for database tests.
class _TestDbPlugin extends UniHubPlugin {
  @override
  String get id => 'test-db';
  @override
  String get name => 'Test DB Plugin';
  @override
  List<Type> get tables => [ThoughtsTable];
  @override
  int get schemaVersion => 2;
}

void main() {
  late PluginRegistry registry;
  late AppDatabase database;

  setUp(() {
    registry = PluginRegistry();
    registry.register(_TestDbPlugin());
    database = AppDatabase(NativeDatabase.memory(), registry);
  });

  tearDown(() async {
    await database.close();
  });

  group('AppDatabase', () {
    test('uses static currentSchemaVersion (not derived from plugins)', () {
      expect(database.schemaVersion, AppDatabase.currentSchemaVersion);
    });

    test('schema version is always currentSchemaVersion regardless of plugins', () {
      final multiRegistry = PluginRegistry();
      multiRegistry.register(_TestDbPlugin());
      multiRegistry.register(_OtherSchemaPlugin());

      final db = AppDatabase(NativeDatabase.memory(), multiRegistry);
      expect(db.schemaVersion, AppDatabase.currentSchemaVersion);
      addTearDown(() => db.close());
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

    test('asserts when plugin table is missing from annotation', () {
      final badRegistry = PluginRegistry();
      badRegistry.register(_MissingTablePlugin());

      expect(
        () => AppDatabase(NativeDatabase.memory(), badRegistry),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}

class _OtherSchemaPlugin extends UniHubPlugin {
  @override
  String get id => 'other';
  @override
  String get name => 'Other';
  @override
  List<Type> get tables => [];
  @override
  int get schemaVersion => 5;
}

class _MissingTablePlugin extends UniHubPlugin {
  @override
  String get id => 'missing';
  @override
  String get name => 'Missing Table';
  @override
  List<Type> get tables => [String]; // Not a registered table
  @override
  int get schemaVersion => 1;
}
