import 'dart:io';

/// 统一应用存储路径管理。
///
/// 所有模块通过此类获取业务目录，禁止直接调用 path_provider。
/// 构造期即确定所有路径（同步），测试可注入临时目录。
class AppStoragePaths {
  final Directory documentsDir;
  final Directory cacheDir;

  /// thought_images 迁移映射（旧路径 → 新路径），无迁移时为空。
  final Map<String, String> thoughtImageMigrations;

  AppStoragePaths({
    required this.documentsDir,
    required this.cacheDir,
    Map<String, String>? thoughtImageMigrations,
  }) : thoughtImageMigrations = thoughtImageMigrations ?? const {};

  const AppStoragePaths.test({
    required this.documentsDir,
    required this.cacheDir,
  }) : thoughtImageMigrations = const {};

  File get databaseFile => File('${documentsDir.path}/unihub.db');

  Directory get thoughtImagesDir =>
      Directory('${documentsDir.path}/media/thought_images');

  Directory get websiteLogosDir =>
      Directory('${cacheDir.path}/website_logos');

  Directory get thumbnailsDir => Directory('${cacheDir.path}/thumbnails');

  Directory get metadataCacheDir => Directory('${cacheDir.path}/metadata');

  Directory get tempDir => Directory('${cacheDir.path}/temp');

  /// 确保所有业务目录存在。
  Future<void> ensureDirectories() async {
    await thoughtImagesDir.create(recursive: true);
    await websiteLogosDir.create(recursive: true);
    await thumbnailsDir.create(recursive: true);
    await metadataCacheDir.create(recursive: true);
    await tempDir.create(recursive: true);
  }

  /// 迁移旧 thought_images 目录。
  ///
  /// 若旧路径 `Documents/thought_images` 存在且新路径
  /// `Documents/media/thought_images` 不存在，则重命名目录。
  /// 同时更新数据库中所有 `thoughts.imagePaths` 旧路径前缀。
  ///
  /// 返回迁移后需要更新的 path 映射（旧路径 → 新路径），
  /// 供调用方更新数据库。
  /// 未迁移时返回空 Map。
  Map<String, String> migrateThoughtImagesIfNeeded() {
    final oldDir = Directory('${documentsDir.path}/thought_images');
    final newDir = thoughtImagesDir;

    if (!oldDir.existsSync()) return {};
    if (newDir.existsSync()) {
      // Both exist — don't migrate; caller should resolve conflicts.
      return {};
    }

    // Ensure parent exists
    newDir.parent.createSync(recursive: true);

    // Build old-to-new path mapping BEFORE rename.
    final oldPrefix = oldDir.path;
    final newPrefix = newDir.path;
    final pathMap = <String, String>{};
    try {
      final entries = oldDir.listSync(recursive: true);
      for (final entry in entries) {
        if (entry is File) {
          final relative = entry.path.substring(oldPrefix.length);
          pathMap[entry.path] = '$newPrefix$relative';
        }
      }
    } catch (_) {
      // If listing fails, we skip path mapping but still attempt rename.
    }

    // Rename directory
    try {
      oldDir.renameSync(newDir.path);
    } catch (_) {
      // Rename failed — return empty map so caller doesn't update DB.
      return {};
    }

    return pathMap;
  }
}
