import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:uni_hub/src/core/storage/app_storage_paths.dart';
import 'package:uni_hub/src/core/storage/orphaned_file.dart';
import 'package:uni_hub/src/core/storage/storage_area.dart';
import 'package:uni_hub/src/core/storage/storage_manager.dart';
import 'package:uni_hub/src/core/storage/storage_registry.dart';

void main() {
  group('StorageManager', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('storage_mgr_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    StorageManager createManager({Map<String, String>? files}) {
      final paths = AppStoragePaths.test(
        documentsDir: tempDir,
        cacheDir: tempDir,
      );

      // Create test files
      if (files != null) {
        for (final entry in files.entries) {
          final file = File(entry.key);
          file.parent.createSync(recursive: true);
          file.writeAsStringSync(entry.value);
        }
      }

      final registry = StorageRegistry(paths);
      registry.registerAll([
        const StorageAreaDescriptor(
          id: 'core.database',
          name: '\u4e3b\u6570\u636e\u5e93',
          type: StorageAreaType.database,
          owner: 'core',
          description: '\u6d4b\u8bd5\u6570\u636e\u5e93',
        ),
        const StorageAreaDescriptor(
          id: 'thoughts.images',
          name: '\u60f3\u6cd5\u56fe\u7247',
          type: StorageAreaType.userAttachment,
          owner: 'thoughts',
          description: '\u6d4b\u8bd5\u56fe\u7247',
        ),
        const StorageAreaDescriptor(
          id: 'core.temp',
          name: '\u4e34\u65f6\u6587\u4ef6',
          type: StorageAreaType.temporary,
          owner: 'core',
          clearable: true,
          description: '\u4e34\u65f6\u6587\u4ef6',
        ),
      ]);

      return StorageManager(registry);
    }

    test('scan returns report with zero sizes for empty dirs', () async {
      final manager = createManager();
      final report = await manager.scan();
      expect(report.totalBytes, 0);
      expect(report.areas.length, 3);
    });

    test('scan counts database file size', () async {
      final dbPath = '${tempDir.path}/unihub.db';
      final manager = createManager(files: {dbPath: 'test data'});
      final report = await manager.scan();
      final dbReport = report.areas
          .firstWhere((a) => a.area.id == 'core.database');
      expect(dbReport.sizeBytes, greaterThan(0));
      expect(dbReport.fileCount, 1);
    });

    test('scan includes WAL/SHM files in database size', () async {
      final dbPath = '${tempDir.path}/unihub.db';
      File('$dbPath-wal').writeAsStringSync('wal data');
      File('$dbPath-shm').writeAsStringSync('shm data');
      final manager = createManager(files: {dbPath: 'test data'});
      final report = await manager.scan();
      final dbReport = report.areas
          .firstWhere((a) => a.area.id == 'core.database');
      // db + wal + shm
      expect(dbReport.fileCount, 3);
    });

    test('scan missing directory returns exists=false', () async {
      final manager = createManager();
      final report = await manager.scan();
      final imgReport = report.areas
          .firstWhere((a) => a.area.id == 'thoughts.images');
      expect(imgReport.exists, isFalse);
      expect(imgReport.sizeBytes, 0);
    });

    test('AppStorageReport groups by type', () async {
      final dbPath = '${tempDir.path}/unihub.db';
      final manager = createManager(files: {dbPath: 'db content'});
      final report = await manager.scan();
      expect(report.databaseBytes, greaterThan(0));
      expect(report.cacheBytes, 0);
      expect(report.userAttachmentBytes, 0);
      expect(report.temporaryBytes, 0);
    });

    test('clearStorageArea deletes files', () async {
      final tempFilePath = '${tempDir.path}/temp/test.txt';
      final manager = createManager(files: {tempFilePath: 'temp content'});

      final result = await manager.clearStorageArea('core.temp');
      expect(result.deletedFiles, 1);
      expect(result.freedBytes, greaterThan(0));
      expect(File(tempFilePath).existsSync(), isFalse);
    });

    test('clearStorageArea throws on non-clearable area', () async {
      final manager = createManager();
      expect(
        () => manager.clearStorageArea('core.database'),
        throwsA(isA<StateError>()),
      );
    });

    test('clearStorageArea throws on unknown area', () async {
      final manager = createManager();
      expect(
        () => manager.clearStorageArea('nonexistent'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('clearRegenerableCache only clears cache/temporary', () async {
      final dbPath = '${tempDir.path}/unihub.db';
      final tempFilePath = '${tempDir.path}/temp/test.txt';
      final manager = createManager(files: {
        dbPath: 'db',
        tempFilePath: 'temp',
      });

      await manager.clearRegenerableCache();

      // temp file deleted
      expect(File(tempFilePath).existsSync(), isFalse);
      // db file preserved
      expect(File(dbPath).existsSync(), isTrue);
    });

    test('clearRegenerableCache handles empty directories', () async {
      final manager = createManager();
      final result = await manager.clearRegenerableCache();
      expect(result.deletedFiles, 0);
      expect(result.freedBytes, 0);
      expect(result.hasErrors, isFalse);
    });

    test('findOrphanedFilesSync returns unreferenced files', () {
      final imagesDir = Directory('${tempDir.path}/media/thought_images');
      imagesDir.createSync(recursive: true);
      final refPath = '${imagesDir.path}/ref.png';
      final orphanPath = '${imagesDir.path}/orphan.png';
      File(refPath).writeAsStringSync('ref');
      File(orphanPath).writeAsStringSync('orphan');

      final orphaned = StorageManager.findOrphanedFilesSync(
        dirPath: imagesDir.path,
        referencedPaths: {refPath},
      );

      expect(orphaned.length, 1);
      expect(orphaned.first.path, endsWith('orphan.png'));
      expect(orphaned.first.sizeBytes, 6); // 'orphan'
    });

    test('findOrphanedFilesSync with subdirectory structure', () {
      final imagesDir = Directory('${tempDir.path}/media/thought_images');
      final subDir = Directory('${imagesDir.path}/sub');
      subDir.createSync(recursive: true);
      final refFile = File('${imagesDir.path}/keep.png');
      final orphanFile = File('${subDir.path}/orphan.png');
      refFile.writeAsStringSync('keep');
      orphanFile.writeAsStringSync('orphan');

      // referencedPaths uses normalized (forward-slash) paths
      final orphaned = StorageManager.findOrphanedFilesSync(
        dirPath: imagesDir.path,
        referencedPaths: {refFile.path},
      );

      // Only orphan.png (not in referencedPaths) should be returned
      expect(orphaned.length, 1);
      expect(orphaned.first.path, endsWith('orphan.png'));
    });

    test('findOrphanedFilesSync returns empty for non-existent dir', () {
      final orphaned = StorageManager.findOrphanedFilesSync(
        dirPath: '${tempDir.path}/nonexistent',
        referencedPaths: const <String>{},
      );
      expect(orphaned, isEmpty);
    });

    test('cleanOrphanedFiles deletes files', () async {
      final imagesDir = Directory('${tempDir.path}/media/thought_images');
      imagesDir.createSync(recursive: true);
      final filePath = '${imagesDir.path}/to_delete.png';
      final file = File(filePath);
      file.writeAsStringSync('delete me');

      final result = await StorageManager(StorageRegistry(
        AppStoragePaths.test(documentsDir: tempDir, cacheDir: tempDir),
      )).cleanOrphanedFiles([
        OrphanedFile(
          path: filePath,
          sizeBytes: file.lengthSync(),
          lastModifiedAt: file.lastModifiedSync(),
        ),
      ]);

      expect(result.deletedFiles, 1);
      expect(result.freedBytes, 9); // 'delete me'
      expect(file.existsSync(), isFalse);
    });

    test('cleanOrphanedFiles skips already deleted files', () async {
      final result = await StorageManager(StorageRegistry(
        AppStoragePaths.test(documentsDir: tempDir, cacheDir: tempDir),
      )).cleanOrphanedFiles([
        OrphanedFile(
          path: '${tempDir.path}/nonexistent.png',
          sizeBytes: 100,
          lastModifiedAt: DateTime.now(),
        ),
      ]);

      // File doesn't exist → skipped silently
      expect(result.deletedFiles, 0);
      expect(result.freedBytes, 0);
    });

    test('scan reports area for directory with files', () async {
      final imagesDir = Directory('${tempDir.path}/media/thought_images');
      imagesDir.createSync(recursive: true);
      File('${imagesDir.path}/img1.png').writeAsStringSync('image data 1');
      File('${imagesDir.path}/img2.png').writeAsStringSync('image data 2');

      final manager = createManager();
      final report = await manager.scan();
      final imgReport = report.areas
          .firstWhere((a) => a.area.id == 'thoughts.images');

      expect(imgReport.exists, isTrue);
      expect(imgReport.fileCount, 2);
      expect(imgReport.sizeBytes, 24); // 12 + 12
      expect(imgReport.lastModifiedAt, isNotNull);
    });
  });
}
