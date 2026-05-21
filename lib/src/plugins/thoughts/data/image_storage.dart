import 'dart:typed_data';

/// 负责图片文件系统存储的抽象接口。
///
/// 平台实现使用 [path_provider] + [dart:io File]；
/// 测试中可注入 [FakeImageStorage] 使用内存存储，避免文件系统副作用。
abstract class ImageStorage {
  /// 将图片字节保存到应用存储目录。
  ///
  /// 返回保存后的绝对路径。
  Future<String> saveBytes(Uint8List bytes, {String extension = '.png'});

  /// 删除指定路径的图片文件。
  Future<void> delete(String path);

  /// 批量删除图片文件。
  Future<void> deleteAll(List<String> paths);

  /// 检查指定路径的文件是否存在。
  ///
  /// 使用同步 API 是因为调用方（如 [ThoughtContentCodec.mergeImagePaths]）
  /// 通常在非异步上下文中使用。
  bool existsSync(String path);
}
