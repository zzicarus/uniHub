import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:uni_hub/src/plugins/thoughts/data/thought_image_service.dart';

import 'fake_image_picker.dart';
import 'fake_image_storage.dart';

void main() {
  group('ThoughtImageService', () {
    late FakeImagePicker fakePicker;
    late FakeImageStorage fakeStorage;
    late ThoughtImageService service;

    setUp(() {
      fakePicker = FakeImagePicker();
      fakeStorage = FakeImageStorage();
      service = ThoughtImageService(
        picker: fakePicker,
        storage: fakeStorage,
      );
    });

    group('pickImage', () {
      test('returns null when user cancels', () async {
        fakePicker.setNull();

        final result = await service.pickImage();

        expect(result, isNull);
        expect(fakeStorage.fileCount, 0);
      });

      test('saves picked image bytes and returns path', () async {
        final bytes = Uint8List.fromList([1, 2, 3, 4]);
        fakePicker.setResult(bytes, '.jpg');

        final result = await service.pickImage();

        expect(result, isNotNull);
        expect(fakeStorage.fileCount, 1);
        expect(fakeStorage.bytesAt(result!), bytes);
      });
    });

    group('saveImageBytes', () {
      test('saves bytes with default extension', () async {
        final bytes = Uint8List.fromList([5, 6, 7]);

        final path = await service.saveImageBytes(bytes);

        expect(path, isNotNull);
        expect(fakeStorage.existsSync(path), true);
        expect(fakeStorage.bytesAt(path), bytes);
      });

      test('saves bytes with custom extension', () async {
        final bytes = Uint8List.fromList([8, 9]);

        final path = await service.saveImageBytes(bytes, extension: '.gif');

        expect(path, endsWith('.gif'));
      });
    });

    group('deleteImage', () {
      test('removes stored file', () async {
        final path = await service.saveImageBytes(
          Uint8List.fromList([1, 2]),
        );
        expect(fakeStorage.existsSync(path), true);

        await service.deleteImage(path);

        expect(fakeStorage.existsSync(path), false);
      });

      test('does not throw when path does not exist', () async {
        await service.deleteImage('/nonexistent/path.png');
        // 不应抛出异常
        expect(fakeStorage.fileCount, 0);
      });
    });

    group('deleteImages', () {
      test('removes multiple files', () async {
        final path1 = await service.saveImageBytes(Uint8List.fromList([1]));
        final path2 = await service.saveImageBytes(Uint8List.fromList([2]));
        final path3 = await service.saveImageBytes(Uint8List.fromList([3]));

        await service.deleteImages([path1, path2]);

        expect(fakeStorage.existsSync(path1), false);
        expect(fakeStorage.existsSync(path2), false);
        expect(fakeStorage.existsSync(path3), true);
      });
    });

    group('existsSync', () {
      test('returns true for existing file', () async {
        final path = await service.saveImageBytes(Uint8List.fromList([1]));

        expect(service.existsSync(path), true);
      });

      test('returns false for missing file', () {
        expect(service.existsSync('/fake/missing.png'), false);
      });
    });

    group('encodeImagePaths / decodeImagePaths', () {
      test('round-trip encoding and decoding', () {
        final paths = ['/a.png', '/b.jpg'];

        final encoded = ThoughtImageService.encodeImagePaths(paths);
        final decoded = ThoughtImageService.decodeImagePaths(encoded);

        expect(decoded, paths);
      });

      test('decode returns empty list for null', () {
        expect(ThoughtImageService.decodeImagePaths(null), isEmpty);
      });

      test('decode returns empty list for empty string', () {
        expect(ThoughtImageService.decodeImagePaths(''), isEmpty);
      });

      test('decode returns empty list for invalid json', () {
        expect(ThoughtImageService.decodeImagePaths('not-json'), isEmpty);
      });
    });
  });
}
