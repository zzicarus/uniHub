import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:uni_hub/src/core/storage/storage_size_utils.dart';

void main() {
  group('StorageSizeUtils.format', () {
    test('bytes less than 1KB', () {
      expect(StorageSizeUtils.format(512), '512 B');
    });

    test('KB range', () {
      expect(StorageSizeUtils.format(1536), '1.5 KB');
    });

    test('MB range', () {
      expect(StorageSizeUtils.format(1048576), '1.0 MB');
    });

    test('GB range', () {
      expect(StorageSizeUtils.format(1073741824), '1.00 GB');
    });

    test('zero bytes', () {
      expect(StorageSizeUtils.format(0), '0 B');
    });

    test('exactly 1024 bytes', () {
      expect(StorageSizeUtils.format(1024), '1.0 KB');
    });
  });

  group('StorageSizeUtils.directorySizeSync', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('size_utils_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('empty directory returns 0', () {
      expect(StorageSizeUtils.directorySizeSync(tempDir), 0);
    });

    test('non-existent directory returns 0', () {
      expect(
        StorageSizeUtils.directorySizeSync(
          Directory('${tempDir.path}/nonexistent'),
        ),
        0,
      );
    });

    test('counts files recursively', () {
      final subDir = Directory('${tempDir.path}/sub');
      subDir.createSync();
      File('${tempDir.path}/a.txt').writeAsStringSync('hello');
      File('${subDir.path}/b.txt').writeAsStringSync('world!');

      final size = StorageSizeUtils.directorySizeSync(tempDir);
      expect(size, greaterThan(0));
      expect(size, 11); // 5 + 6
    });

    test('handles single file', () {
      final file = File('${tempDir.path}/single.txt');
      file.writeAsStringSync('data');
      expect(StorageSizeUtils.directorySizeSync(tempDir), 4);
    });
  });

  group('StorageSizeUtils.fileCountSync', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('file_count_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('counts files', () {
      File('${tempDir.path}/a.txt').writeAsStringSync('hello');
      File('${tempDir.path}/b.txt').writeAsStringSync('world');
      expect(StorageSizeUtils.fileCountSync(tempDir), 2);
    });

    test('empty directory returns 0', () {
      expect(StorageSizeUtils.fileCountSync(tempDir), 0);
    });

    test('non-existent directory returns 0', () {
      expect(
        StorageSizeUtils.fileCountSync(
          Directory('${tempDir.path}/nonexistent'),
        ),
        0,
      );
    });
  });

  group('StorageSizeUtils.lastModifiedSync', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('last_mod_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('empty directory returns null', () {
      expect(StorageSizeUtils.lastModifiedSync(tempDir), isNull);
    });

    test('non-existent directory returns null', () {
      expect(
        StorageSizeUtils.lastModifiedSync(
          Directory('${tempDir.path}/nonexistent'),
        ),
        isNull,
      );
    });

    test('returns file last modified time', () {
      final file = File('${tempDir.path}/data.txt');
      file.writeAsStringSync('content');
      final result = StorageSizeUtils.lastModifiedSync(tempDir);
      expect(result, isNotNull);
      expect(result, isA<DateTime>());
    });
  });
}
