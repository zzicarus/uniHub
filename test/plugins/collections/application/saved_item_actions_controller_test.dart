import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uni_hub/src/core/database/app_database.dart';
import 'package:uni_hub/src/core/plugin/plugin_registry.dart';
import 'package:uni_hub/src/plugins/collections/collections_plugin.dart';
import 'package:uni_hub/src/plugins/collections/application/saved_item_actions_controller.dart';
import 'package:uni_hub/src/plugins/collections/application/saved_item_action_result.dart';
import 'package:uni_hub/src/plugins/collections/application/saved_item_undo_snapshot.dart';
import 'package:uni_hub/src/plugins/collections/data/collection_boxes_dao.dart';
import 'package:uni_hub/src/plugins/collections/data/collections_repository.dart';
import 'package:uni_hub/src/plugins/collections/data/enrichment_jobs_dao.dart';
import 'package:uni_hub/src/plugins/collections/data/saved_items_dao.dart';
import 'package:uni_hub/src/plugins/collections/domain/collection_models.dart';
import 'package:uni_hub/src/plugins/collections/domain/consumption_status.dart';
import 'package:uni_hub/src/plugins/collections/domain/media_type.dart';
import 'package:uni_hub/src/plugins/collections/domain/saved_items_query.dart';
import 'package:uni_hub/src/plugins/collections/domain/source_platform.dart';
import 'package:uni_hub/src/plugins/collections/services/enrichment_job_service.dart';
import 'package:uni_hub/src/plugins/collections/services/metadata_provider.dart';

/// A stub metadata provider that returns default values without network I/O.
const _urlLauncherChannel = MethodChannel('plugins.flutter.io/url_launcher');

class _StubMetadataProvider implements MetadataProvider {
  @override
  Future<MetadataResult> fetchMetadata(String url) async {
    return const MetadataResult(
      title: 'Stub Title',
      siteName: 'stub.example.com',
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late CollectionsRepository repository;
  late SavedItemActionsController controller;

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_urlLauncherChannel, (call) async {
          if (call.method == 'launch') return true;
          return null;
        });

    final registry = PluginRegistry()..register(CollectionsPlugin());
    db = AppDatabase(NativeDatabase.memory(), registry);

    final savedItemsDao = SavedItemsDao(db);
    final collectionBoxesDao = CollectionBoxesDao(db);
    final enrichmentJobsDao = EnrichmentJobsDao(db);

    repository = CollectionsRepository(
      savedItemsDao: savedItemsDao,
      collectionBoxesDao: collectionBoxesDao,
      enrichmentJobsDao: enrichmentJobsDao,
    );

    final enrichmentJobService = EnrichmentJobService(
      repository: repository,
      jobsDao: enrichmentJobsDao,
      metadataProvider: _StubMetadataProvider(),
    );

    controller = SavedItemActionsController(
      repository: repository,
      enrichmentJobService: enrichmentJobService,
      // ref: null — invalidation callbacks are no-ops in tests
    );
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_urlLauncherChannel, null);
    await db.close();
  });

  group('SavedItemActionsController', () {
    Future<SavedItemsTableData> createTestItem({
      String? title,
      String originalUrl = 'https://example.com/test',
      String normalizedUrl = 'https://example.com/test',
      MediaType mediaType = MediaType.unknown,
      SourcePlatform sourcePlatform = SourcePlatform.unknown,
    }) async {
      return repository.createSavedItem(
        originalUrl: originalUrl,
        normalizedUrl: normalizedUrl,
        title: title,
        mediaType: mediaType,
        sourcePlatform: sourcePlatform,
      );
    }

    Future<int> createBox(String name) async {
      final box = await repository.createBox(name);
      return box.id;
    }

    // ---------------------------------------------------------
    // Action Result / Undo Snapshot basics
    // ---------------------------------------------------------

    test('SavedItemActionResult stores success and message', () {
      const result = SavedItemActionResult(success: true, message: '测试成功');
      expect(result.success, isTrue);
      expect(result.message, '测试成功');
      expect(result.undo, isNull);
      expect(result.error, isNull);
    });

    test('SavedItemUndoSnapshot stores item and boxIds', () async {
      final item = await createTestItem(title: '快照测试');
      final snapshot = SavedItemUndoSnapshot(item: item, boxIds: [1, 2, 3]);
      expect(snapshot.item.id, item.id);
      expect(snapshot.boxIds, [1, 2, 3]);
    });

    test('SavedItemUndoAction can be constructed and executed', () async {
      var executed = false;
      final action = SavedItemUndoAction(
        label: '撤销',
        execute: () async {
          executed = true;
        },
      );
      expect(action.label, '撤销');
      await action.execute();
      expect(executed, isTrue);
    });

    // ---------------------------------------------------------
    // deleteItem — fullDelete
    // ---------------------------------------------------------

    test('deleteItem with fullDelete removes item and returns undo', () async {
      final item = await createTestItem(title: '待删除');

      expect(await repository.getSavedItem(item.id), isNotNull);
      final result = await controller.deleteItem(
        item.id,
        mode: DeleteMode.fullDelete,
      );

      expect(result.success, isTrue);
      expect(result.message, contains('待删除'));
      expect(result.undo, isNotNull);
      expect(await repository.getSavedItem(item.id), isNull);
    });

    test('deleteItem with fullDelete undo restores item', () async {
      final item = await createTestItem(title: '删除后恢复');

      final deleteResult = await controller.deleteItem(
        item.id,
        mode: DeleteMode.fullDelete,
      );
      expect(deleteResult.success, isTrue);

      // Execute the undo action which calls restoreDeletedItem internally
      await deleteResult.undo!.execute();

      // The restored item may have a new ID; find it by normalized URL
      final all = await repository.queryItems(
        const SavedItemsQuery(view: CollectionView.all, limit: 500),
      );
      final restored = all.items.where(
        (i) => i.normalizedUrl == item.normalizedUrl,
      );
      expect(restored, isNotEmpty);
      expect(restored.first.title, '删除后恢复');
    });

    test('deleteItem with fullDelete undo restores box associations', () async {
      final item = await createTestItem(title: '带收藏夹恢复');
      final boxId = await createBox('测试收藏夹');
      await repository.setItemBoxes(item.id, {boxId});

      final deleteResult = await controller.deleteItem(
        item.id,
        mode: DeleteMode.fullDelete,
      );
      expect(deleteResult.success, isTrue);

      // Execute the undo action which calls restoreDeletedItem internally
      await deleteResult.undo!.execute();

      final all = await repository.queryItems(
        const SavedItemsQuery(view: CollectionView.all, limit: 500),
      );
      final restored = all.items.firstWhere(
        (i) => i.normalizedUrl == item.normalizedUrl,
      );
      final restoredBoxIds = await repository.getBoxIdsForItem(restored.id);
      expect(restoredBoxIds, contains(boxId));
    });

    test('deleteItem returns failure for non-existent item', () async {
      final result = await controller.deleteItem(999);
      expect(result.success, isFalse);
      expect(result.message, '收藏项不存在');
    });

    // ---------------------------------------------------------
    // deleteItem — removeFromBox
    // ---------------------------------------------------------

    test('deleteItem with removeFromBox removes box association', () async {
      final item = await createTestItem(title: '移出收藏夹');
      final boxId = await createBox('临时收藏夹');
      await repository.setItemBoxes(item.id, {boxId});

      final result = await controller.deleteItem(
        item.id,
        mode: DeleteMode.removeFromBox,
        boxId: boxId,
        boxName: '临时收藏夹',
      );

      expect(result.success, isTrue);
      expect(result.message, contains('临时收藏夹'));
      expect(result.undo, isNotNull);

      final remainingBoxIds = await repository.getBoxIdsForItem(item.id);
      expect(remainingBoxIds, isEmpty);
    });

    test('deleteItem removeFromBox undo restores box', () async {
      final item = await createTestItem(title: '移出后恢复');
      final boxId = await createBox('撤销盒');
      await repository.setItemBoxes(item.id, {boxId});

      final result = await controller.deleteItem(
        item.id,
        mode: DeleteMode.removeFromBox,
        boxId: boxId,
        boxName: '撤销盒',
      );
      expect(result.success, isTrue);

      await result.undo!.execute();

      final restoredBoxIds = await repository.getBoxIdsForItem(item.id);
      expect(restoredBoxIds, contains(boxId));
    });

    // ---------------------------------------------------------
    // updateStatus / archiveItem
    // ---------------------------------------------------------

    test('updateStatus changes item status', () async {
      final item = await createTestItem();
      expect(
        ConsumptionStatus.fromValue(item.status),
        ConsumptionStatus.unread,
      );

      await controller.updateStatus(item.id, ConsumptionStatus.inProgress);

      final updated = await repository.getSavedItem(item.id);
      expect(updated, isNotNull);
      expect(
        ConsumptionStatus.fromValue(updated!.status),
        ConsumptionStatus.inProgress,
      );
    });

    test('archiveItem changes status to archived', () async {
      final item = await createTestItem();

      await controller.archiveItem(item.id);

      final updated = await repository.getSavedItem(item.id);
      expect(updated, isNotNull);
      expect(
        ConsumptionStatus.fromValue(updated!.status),
        ConsumptionStatus.archived,
      );
    });

    // ---------------------------------------------------------
    // assignBoxes / removeFromBox
    // ---------------------------------------------------------

    test('assignBoxes sets box assignments', () async {
      final item = await createTestItem();
      final boxId = await createBox('收藏夹A');

      await controller.assignBoxes(item.id, {boxId});

      final boxIds = await repository.getBoxIdsForItem(item.id);
      expect(boxIds, contains(boxId));
    });

    test('removeFromBox removes single box', () async {
      final item = await createTestItem();
      final boxId = await createBox('收藏夹B');
      await repository.setItemBoxes(item.id, {boxId});

      await controller.removeFromBox(item.id, boxId);

      final boxIds = await repository.getBoxIdsForItem(item.id);
      expect(boxIds, isEmpty);
    });

    // ---------------------------------------------------------
    // copyUrl / openItem
    // ---------------------------------------------------------

    test('copyUrl returns failure for non-existent item', () async {
      final result = await controller.copyUrl(999);
      expect(result.success, isFalse);
      expect(result.message, '收藏项不存在');
    });

    test('openItem returns failure for non-existent item', () async {
      final result = await controller.openItem(999);
      expect(result.success, isFalse);
      expect(result.message, '收藏项不存在');
    });

    test('openItem does not mark invalid URL as opened', () async {
      final item = await createTestItem(
        originalUrl: 'not a valid url',
        normalizedUrl: 'not-a-valid-url',
      );

      final result = await controller.openItem(item.id);
      final updated = await repository.getSavedItem(item.id);

      expect(result.success, isFalse);
      expect(result.message, '无效的链接');
      expect(updated!.lastOpenedAt, isNull);
    });

    test('openItem does not mark URL as opened when launcher fails', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_urlLauncherChannel, (call) async {
            if (call.method == 'launch') return false;
            return null;
          });
      final item = await createTestItem();

      final result = await controller.openItem(item.id);
      final updated = await repository.getSavedItem(item.id);

      expect(result.success, isFalse);
      expect(result.message, '打开链接失败');
      expect(updated!.lastOpenedAt, isNull);
    });

    // ---------------------------------------------------------
    // retryEnrichment
    // ---------------------------------------------------------

    test('retryEnrichment returns success for existing items', () async {
      final item = await createTestItem();
      final result = await controller.retryEnrichment(item.id);
      expect(result.success, isTrue);
      expect(result.message, contains('重新加入'));
    });

    // ---------------------------------------------------------
    // toggleFavorite — stub
    // ---------------------------------------------------------

    test('toggleFavorite returns not-supported message', () async {
      final item = await createTestItem();
      final result = await controller.toggleFavorite(item.id);
      expect(result.success, isFalse);
      expect(result.message, contains('星标'));
    });
  });
}
