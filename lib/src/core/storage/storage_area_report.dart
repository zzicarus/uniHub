import 'storage_area.dart';

/// 单个存储区域扫描报告。
class StorageAreaReport {
  final StorageArea area;
  final int sizeBytes;
  final int fileCount;
  final DateTime? lastModifiedAt;
  final bool exists;
  final String? error;

  const StorageAreaReport({
    required this.area,
    required this.sizeBytes,
    required this.fileCount,
    this.lastModifiedAt,
    this.exists = true,
    this.error,
  });

  const StorageAreaReport.empty(this.area)
      : sizeBytes = 0,
        fileCount = 0,
        lastModifiedAt = null,
        exists = false,
        error = null;

  const StorageAreaReport.error(this.area, this.error)
      : sizeBytes = 0,
        fileCount = 0,
        lastModifiedAt = null,
        exists = false;
}

/// 应用整体存储报告。
class AppStorageReport {
  final int totalBytes;
  final List<StorageAreaReport> areas;

  const AppStorageReport({
    required this.totalBytes,
    required this.areas,
  });

  /// 按类型分组合计。
  int bytesByType(StorageAreaType type) => areas
      .where((a) => a.area.type == type)
      .fold<int>(0, (sum, a) => sum + a.sizeBytes);

  int get databaseBytes => bytesByType(StorageAreaType.database);
  int get userAttachmentBytes => bytesByType(StorageAreaType.userAttachment);
  int get cacheBytes => bytesByType(StorageAreaType.cache);
  int get temporaryBytes => bytesByType(StorageAreaType.temporary);
  int get orphanedBytes => bytesByType(StorageAreaType.orphaned);
}
