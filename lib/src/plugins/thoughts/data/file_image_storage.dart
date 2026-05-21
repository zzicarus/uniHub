import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'image_storage.dart';

/// 使用文件系统 + [path_provider] 的存储实现。
///
/// 图片保存在应用的 `thought_images` 子目录下，文件名使用时间戳
/// 避免冲突。
class FileImageStorage implements ImageStorage {
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
    final appDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(p.join(appDir.path, 'thought_images'));
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    final ext = extension.startsWith('.') ? extension : '.$extension';
    final fileName =
        '${DateTime.now().microsecondsSinceEpoch}_${_counter++}$ext';
    return p.join(imagesDir.path, fileName);
  }
}
