import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:uni_hub/src/core/storage/app_storage_paths.dart';

void main() {
  group('AppStoragePaths', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('storage_paths_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('databaseFile returns correct path', () {
      final paths = AppStoragePaths.test(
        documentsDir: tempDir,
        cacheDir: tempDir,
      );
      expect(paths.databaseFile.path, endsWith('/unihub.db'));
    });

    test('thoughtImagesDir returns media subdirectory', () {
      final paths = AppStoragePaths.test(
        documentsDir: tempDir,
        cacheDir: tempDir,
      );
      expect(
        paths.thoughtImagesDir.path,
        endsWith('/media/thought_images'),
      );
    });

    test('websiteLogosDir returns cache subdirectory', () {
      final cacheDir = Directory('${tempDir.path}/cache');
      final paths = AppStoragePaths.test(
        documentsDir: tempDir,
        cacheDir: cacheDir,
      );
      expect(paths.websiteLogosDir.path, endsWith('/website_logos'));
    });

    test('thumbnailsDir returns thumbnails subdirectory', () {
      final paths = AppStoragePaths.test(
        documentsDir: tempDir,
        cacheDir: tempDir,
      );
      expect(paths.thumbnailsDir.path, endsWith('/thumbnails'));
    });

    test('tempDir returns temp subdirectory', () {
      final paths = AppStoragePaths.test(
        documentsDir: tempDir,
        cacheDir: tempDir,
      );
      expect(paths.tempDir.path, endsWith('/temp'));
    });

    test('migrateThoughtImagesIfNeeded renaming old directory', () {
      final paths = AppStoragePaths.test(
        documentsDir: tempDir,
        cacheDir: tempDir,
      );

      // Create old directory with a file
      final oldDir = Directory('${tempDir.path}/thought_images');
      oldDir.createSync(recursive: true);
      final oldFile = File('${oldDir.path}/test.png');
      oldFile.writeAsStringSync('test');

      final migrations = paths.migrateThoughtImagesIfNeeded();

      expect(migrations, isNotEmpty);
      expect(migrations.values.first, contains('/media/thought_images/'));
      expect(oldDir.existsSync(), isFalse);
      expect(paths.thoughtImagesDir.existsSync(), isTrue);
    });

    test('migrateThoughtImagesIfNeeded no-op when old dir absent', () {
      final paths = AppStoragePaths.test(
        documentsDir: tempDir,
        cacheDir: tempDir,
      );
      final migrations = paths.migrateThoughtImagesIfNeeded();
      expect(migrations, isEmpty);
    });

    test(
      'migrateThoughtImagesIfNeeded no-op when new dir already exists',
      () {
        final paths = AppStoragePaths.test(
          documentsDir: tempDir,
          cacheDir: tempDir,
        );

        // Create both old and new directories
        final oldDir = Directory('${tempDir.path}/thought_images');
        oldDir.createSync(recursive: true);
        File('${oldDir.path}/old_file.png').writeAsStringSync('old');

        paths.thoughtImagesDir.createSync(recursive: true);
        File('${paths.thoughtImagesDir.path}/new_file.png')
            .writeAsStringSync('new');

        final migrations = paths.migrateThoughtImagesIfNeeded();

        // Both exist → no migration
        expect(migrations, isEmpty);
        expect(oldDir.existsSync(), isTrue);
        expect(paths.thoughtImagesDir.existsSync(), isTrue);
      },
    );

    test('ensureDirectories creates all directories', () async {
      final paths = AppStoragePaths.test(
        documentsDir: tempDir,
        cacheDir: tempDir,
      );
      await paths.ensureDirectories();
      expect(paths.thoughtImagesDir.existsSync(), isTrue);
      expect(paths.websiteLogosDir.existsSync(), isTrue);
      expect(paths.thumbnailsDir.existsSync(), isTrue);
      expect(paths.metadataCacheDir.existsSync(), isTrue);
      expect(paths.tempDir.existsSync(), isTrue);
    });
  });
}
