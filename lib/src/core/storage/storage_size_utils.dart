import 'dart:io';

class StorageSizeUtils {
  /// 将字节数格式化为人类可读字符串。
  static String format(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// 递归计算目录大小（不跟随 symlink）。
  static int directorySizeSync(Directory dir) {
    if (!dir.existsSync()) return 0;
    int total = 0;
    try {
      for (final entity in dir.listSync(recursive: true, followLinks: false)) {
        if (entity is File) {
          total += entity.lengthSync();
        }
      }
    } catch (_) {
      // 权限错误等，返回已统计部分
    }
    return total;
  }

  /// 递归计算文件数量。
  static int fileCountSync(Directory dir) {
    if (!dir.existsSync()) return 0;
    try {
      return dir
          .listSync(recursive: true, followLinks: false)
          .whereType<File>()
          .length;
    } catch (_) {
      return 0;
    }
  }

  /// 获取目录最后修改时间。
  static DateTime? lastModifiedSync(Directory dir) {
    if (!dir.existsSync()) return null;
    try {
      DateTime? latest;
      for (final entity in dir.listSync(recursive: true, followLinks: false)) {
        if (entity is File) {
          final mtime = entity.lastModifiedSync();
          if (latest == null || mtime.isAfter(latest)) latest = mtime;
        }
      }
      return latest;
    } catch (_) {
      return null;
    }
  }
}
