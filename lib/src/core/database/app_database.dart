import 'package:drift/drift.dart';
import '../plugin/plugin_registry.dart';
import 'tables/collection_boxes_table.dart';
import 'tables/enrichment_jobs_table.dart';
import 'tables/saved_item_boxes_table.dart';
import 'tables/saved_items_table.dart';
import 'tables/thoughts_table.dart';
import 'tables/saved_item_tags_table.dart';
import 'tables/tags_table.dart';
import 'tables/thought_tags_table.dart';
import 'tables/website_logo_cache_table.dart';

part 'app_database.g.dart';

/// 集中注册所有数据库表。
///
/// 注意：由于 `@DriftDatabase` 注解在编译期由 drift_dev 代码生成器读取，
/// 表列表无法在运行时从 PluginRegistry 动态注入。因此所有表必须在
/// 本文件的 `tables: [...]` 中显式列出，保持为**集中注册点**。
///
/// 新增插件如果需要数据库表：
/// 1. 将表定义放入 `core/database/tables/`
/// 2. 在插件的 `UniHubPlugin.tables` 中返回对应 Type
/// 3. 同步更新本文件 `tables: [...]` 列表
/// 4. 同步更新插件的 `schemaVersion`
///
/// [PluginRegistry] 在运行时被传入，用于：
/// - 动态计算全局 `schemaVersion`（取所有插件版本的最大值）
/// - 在 debug 模式下验证插件声明的表与注解注册表一致
@DriftDatabase(
  tables: [
    ThoughtsTable,
    SavedItemsTable,
    CollectionBoxesTable,
    SavedItemBoxesTable,
    EnrichmentJobsTable,
    SavedItemTagsTable,
    TagsTable,
    ThoughtTagsTable,
    WebsiteLogoCacheTable,
  ],
)
class AppDatabase extends _$AppDatabase {
  final PluginRegistry _registry;

  AppDatabase(super.e, this._registry) {
    assert(
      _validatePluginTables(),
      '插件声明的表与 AppDatabase 集中注册表不一致。'
      '请检查：1) 插件.tables 是否包含新表；'
      '2) app_database.dart 的 @DriftDatabase(tables: [...]) 是否同步更新。',
    );
  }

  /// 显式维护的数据库 schema 版本号。
  ///
  /// 不再由插件最大版本号动态计算。版本迁移统一在此文件中维护。
  /// 插件中的 schemaVersion 仅作声明信息，不驱动 Drift 数据库版本。
  static const int currentSchemaVersion = 7;

  @override
  int get schemaVersion => currentSchemaVersion;


  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      await _createCustomIndexes();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        await m.addColumn(thoughtsTable, thoughtsTable.imagePaths);
      }
      if (from < 3) {
        await m.createTable(savedItemsTable);
        await m.createTable(collectionBoxesTable);
        await m.createTable(savedItemBoxesTable);
        await m.createTable(enrichmentJobsTable);
      }
      if (from < 4) {
        await m.createTable(websiteLogoCacheTable);
      }
      if (from < 7) {
        await m.createTable(tagsTable);
        await m.createTable(thoughtTagsTable);
        await m.createTable(savedItemTagsTable);
        await _migrateTagsFromThoughts();
        await m.dropColumn(thoughtsTable, 'tags');
      }
      // Custom indexes are idempotent via CREATE INDEX IF NOT EXISTS,
      // so a single call at the end handles all upgrade paths.
      await _createCustomIndexes();
    },
  );

  Future<void> _createCustomIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_thoughts_archive_pinned_created '
      'ON thoughts_table(archived_at, is_pinned, created_at DESC)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_thoughts_updated '
      'ON thoughts_table(updated_at DESC)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_saved_items_status_updated '
      'ON saved_items(status, updated_at DESC)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_saved_items_inbox_updated '
      'ON saved_items(is_in_inbox, updated_at DESC)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_saved_items_platform_updated '
      'ON saved_items(source_platform, updated_at DESC)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_saved_items_media_type_updated '
      'ON saved_items(media_type, updated_at DESC)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_saved_items_updated_created '
      'ON saved_items(updated_at DESC, created_at DESC)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_saved_item_boxes_box_item '
      'ON saved_item_boxes(box_id, item_id)',
    );
  }

  /// Migrate tags from the legacy `thoughts.tags` comma-separated column
  /// into the new normalized [tagsTable] + [thoughtTagsTable].
  ///
  /// Reads every thought row, parses its tags string, normalises via
  /// [TagCodec], deduplicates across all thoughts, inserts into
  /// [tagsTable] with a stable color token, and links each thought to
  /// its tags in [thoughtTagsTable].
  ///
  /// This runs synchronously inside the [onUpgrade] callback so the
  /// database lock is held and no concurrent writes can race.
  Future<void> _migrateTagsFromThoughts() async {
    // Read the old tags column via raw SQL (it still exists in the DB
    // during upgrade even though the Drift table definition no longer has it).
    final tagSet = <String>{};
    final thoughtTags = <int, Set<String>>{};

    final rawRows = await customSelect('SELECT id, tags FROM thoughts_table').get();
    for (final row in rawRows) {
      final tagsRaw = row.read<String?>('tags');
      if (tagsRaw == null || tagsRaw.trim().isEmpty) continue;
      final id = row.read<int>('id');
      if (id == null) continue;

      final parsed = <String>{};
      for (final raw in tagsRaw.split(',')) {
        final normalized = raw.trim();
        if (normalized.isEmpty) continue;
        tagSet.add(normalized);
        parsed.add(normalized);
      }
      if (parsed.isNotEmpty) {
        thoughtTags[id] = parsed;
      }
    }

    if (tagSet.isEmpty) return;
    final now = DateTime.now();
    final normalizedList = tagSet.toList()..sort();
    final tagIdMap = <String, int>{};

    for (final tagName in normalizedList) {
      final id = await into(tagsTable).insert(
        TagsTableCompanion(
          name: Value(tagName),
          normalizedName: Value(tagName.toLowerCase()),
          colorToken: Value(_assignColorToken(tagName)),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      tagIdMap[tagName] = id;
    }

    // 3. Link thoughts to tags.
    for (final entry in thoughtTags.entries) {
      for (final tagName in entry.value) {
        final tagId = tagIdMap[tagName];
        if (tagId == null) continue;
        await into(thoughtTagsTable).insert(
          ThoughtTagsTableCompanion(
            thoughtId: Value(entry.key),
            tagId: Value(tagId),
            createdAt: Value(now),
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }
    }
  }

  /// Assign a stable [TagColorToken] based on the hash of [name].
  int _assignColorToken(String name) {
    final int hash = name.toLowerCase().hashCode.abs();
    return hash % 7; // 7 = TagColorToken.values.length
  }

  /// 验证插件声明的表类型与数据库实际注册表一致。
  ///
  /// 由于 Drift 生成器为每张表生成一个包装类（如 `$ThoughtsTableTable`），
  /// 而插件返回的是原始表类型（如 `ThoughtsTable`），验证通过检查
  /// 生成类的名称是否包含原始类型名称来完成匹配。
  bool _validatePluginTables() {
    final pluginTableTypes = _registry.plugins.expand((p) => p.tables).toSet();
    final dbTables = allSchemaEntities.whereType<TableInfo>().toList();

    // 每个插件声明的表都应在 DB 中有对应
    for (final tableType in pluginTableTypes) {
      final typeName = tableType.toString();
      final hasMatch = dbTables.any(
        (t) => t.runtimeType.toString().contains(typeName),
      );
      if (!hasMatch) return false;
    }

    return true;
  }
}
