import 'dart:typed_data';

import 'package:uni_hub/src/plugins/thoughts/data/image_storage.dart';

/// 用于测试的内存图片存储实现。
///
/// 不触及真实文件系统，所有操作在内存中完成。
class FakeImageStorage implements ImageStorage {
  final Map<String, Uint8List> _files = {};
  int _counter = 0;

  @override
  Future<String> saveBytes(Uint8List bytes, {String extension = '.png'}) async {
    final path = '/fake/image_${_counter++}$extension';
    _files[path] = bytes;
    return path;
  }

  @override
  Future<void> delete(String path) async {
    _files.remove(path);
  }

  @override
  Future<void> deleteAll(List<String> paths) async {
    for (final path in paths) {
      _files.remove(path);
    }
  }

  @override
  bool existsSync(String path) => _files.containsKey(path);

  /// 获取指定路径保存的字节数据（测试断言用）。
  Uint8List? bytesAt(String path) => _files[path];

  /// 当前存储的文件数量。
  int get fileCount => _files.length;
}
