import 'package:drift/drift.dart';
import '../plugin/plugin_registry.dart';
import 'tables/collection_boxes_table.dart';
import 'tables/enrichment_jobs_table.dart';
import 'tables/saved_item_boxes_table.dart';
import 'tables/saved_items_table.dart';
import 'tables/thoughts_table.dart';
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

  @override
  int get schemaVersion {
    final versions = _registry.plugins.map((p) => p.schemaVersion);
    if (versions.isEmpty) return 1;
    return versions.reduce((a, b) => a > b ? a : b);
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
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
      if (from < 5) {
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
    },
  );

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
