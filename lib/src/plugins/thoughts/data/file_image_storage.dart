import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import 'image_storage.dart';

/// 使用文件系统存储图片。
///
/// 目录由 [AppStoragePaths.thoughtImagesDir] 通过构造器注入，
/// 禁止在实现层直接调用 path_provider。
class FileImageStorage implements ImageStorage {
  FileImageStorage({required Directory imagesDir}) : _imagesDir = imagesDir;

  final Directory _imagesDir;
  static int _counter = 0;

  @override
  Future<String> saveBytes(Uint8List bytes, {String extension = '.png'}) async {
    final savedPath = await _newImagePath(extension);
    await File(savedPath).writeAsBytes(bytes, flush: true);
    return savedPath;
  }

  @override
  Future<void> delete(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Future<void> deleteAll(List<String> paths) async {
    for (final path in paths) {
      await delete(path);
    }
  }

  @override
  bool existsSync(String path) => File(path).existsSync();

  Future<String> _newImagePath(String extension) async {
    if (!await _imagesDir.exists()) {
      await _imagesDir.create(recursive: true);
    }

    final ext = extension.startsWith('.') ? extension : '.$extension';
    final fileName =
        '${DateTime.now().microsecondsSinceEpoch}_${_counter++}$ext';
    return p.join(_imagesDir.path, fileName);
  }
}
