import 'dart:convert';
import 'dart:typed_data';

import 'image_picker_service.dart';
import 'image_storage.dart';

/// 管理想法相关图片的协调服务。
///
/// 通过构造器注入 [ImagePickerService] 和 [ImageStorage]，
/// 不直接依赖任何平台 API，方便测试中替换为 fake 实现。
class ThoughtImageService {
  final ImagePickerService _picker;
  final ImageStorage _storage;

  ThoughtImageService({
    required ImagePickerService picker,
    required ImageStorage storage,
  })  : _picker = picker,
        _storage = storage;

  /// 从图库选择图片并保存到应用存储目录。
  ///
  /// 返回保存后的绝对路径；用户取消时返回 `null`。
  Future<String?> pickImage() async {
    final picked = await _picker.pickImage();
    if (picked == null) return null;

    return _storage.saveBytes(picked.bytes, extension: picked.extension);
  }

  /// 将图片字节直接保存到应用存储目录。
  Future<String> saveImageBytes(
    Uint8List bytes, {
    String extension = '.png',
  }) async {
    return _storage.saveBytes(bytes, extension: extension);
  }

  /// 删除指定路径的图片文件。
  Future<void> deleteImage(String path) async {
    await _storage.delete(path);
  }

  /// 批量删除图片文件。
  Future<void> deleteImages(List<String> paths) async {
    await _storage.deleteAll(paths);
  }

  /// 检查指定路径的图片文件是否存在。
  bool existsSync(String path) => _storage.existsSync(path);

  static List<String> decodeImagePaths(String? json) {
    if (json == null || json.isEmpty) return [];
    try {
      final list = jsonDecode(json) as List;
      return list.cast<String>();
    } catch (_) {
      return [];
    }
  }

  static String encodeImagePaths(List<String> paths) {
    return jsonEncode(paths);
  }
}
