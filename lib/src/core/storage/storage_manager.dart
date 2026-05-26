import 'dart:io';
import 'dart:isolate';
import 'clear_result.dart';
import 'orphaned_file.dart';
import 'storage_area.dart';
import 'storage_area_report.dart';
import 'storage_registry.dart';
import 'storage_size_utils.dart';

class _ScanInput {
  final String id;
  final String path;
  final bool isDirectory;

  const _ScanInput({
    required this.id,
    required this.path,
    required this.isDirectory,
  });
}

class _ScanOutput {
  final String id;
  final int sizeBytes;
  final int fileCount;
  final DateTime? lastModifiedAt;
  final bool exists;
  final String? error;

  const _ScanOutput({
    required this.id,
    required this.sizeBytes,
    required this.fileCount,
    this.lastModifiedAt,
    this.exists = true,
    this.error,
  });
}

class StorageManager {
  final StorageRegistry _registry;

  StorageManager(this._registry);

  /// 异步扫描所有注册存储区域，返回完整报告。
  ///
  /// 使用 [Isolate.run] 避免阻塞 UI 线程。
  Future<AppStorageReport> scan() async {
    final areas = _registry.areas;
    final inputs = areas.map((a) {
      final isDir = a.type != StorageAreaType.database;
      return _ScanInput(id: a.id, path: a.path, isDirectory: isDir);
    }).toList();

    final outputs = await Isolate.run(() => _scanSync(inputs));

    final reportMap = <String, _ScanOutput>{};
    for (final o in outputs) {
      reportMap[o.id] = o;
    }

    final areaReports = areas.map((a) {
      final o = reportMap[a.id];
      if (o == null) {
        return StorageAreaReport.empty(a);
      }
      if (o.error != null) {
        return StorageAreaReport.error(a, o.error);
      }
      return StorageAreaReport(
        area: a,
        sizeBytes: o.sizeBytes,
        fileCount: o.fileCount,
        lastModifiedAt: o.lastModifiedAt,
        exists: o.exists,
      );
    }).toList();

    final total = areaReports.fold<int>(0, (sum, r) => sum + r.sizeBytes);

    return AppStorageReport(totalBytes: total, areas: areaReports);
  }

  /// 同步扫描实现（在 Isolate 中运行）。
  static List<_ScanOutput> _scanSync(List<_ScanInput> inputs) {
    return inputs.map((input) {
      try {
        if (input.isDirectory) {
          final dir = Directory(input.path);
          if (!dir.existsSync()) {
            return _ScanOutput(
              id: input.id,
              sizeBytes: 0,
              fileCount: 0,
              exists: false,
            );
          }
          return _ScanOutput(
            id: input.id,
            sizeBytes: StorageSizeUtils.directorySizeSync(dir),
            fileCount: StorageSizeUtils.fileCountSync(dir),
            lastModifiedAt: StorageSizeUtils.lastModifiedSync(dir),
          );
        } else {
          // Database file: include WAL/SHM auxiliary files.
          final file = File(input.path);
          if (!file.existsSync()) {
            return _ScanOutput(
              id: input.id,
              sizeBytes: 0,
              fileCount: 0,
              exists: false,
            );
          }
          var total = file.lengthSync();
          var count = 1;
          var latest = file.lastModifiedSync();

          for (final suffix in ['-wal', '-shm']) {
            final extra = File('${input.path}$suffix');
            if (extra.existsSync()) {
              total += extra.lengthSync();
              count++;
              final mtime = extra.lastModifiedSync();
              if (mtime.isAfter(latest)) latest = mtime;
            }
          }

          return _ScanOutput(
            id: input.id,
            sizeBytes: total,
            fileCount: count,
            lastModifiedAt: latest,
          );
        }
      } catch (e) {
        return _ScanOutput(
          id: input.id,
          sizeBytes: 0,
          fileCount: 0,
          error: e.toString(),
        );
      }
    }).toList();
  }

  // ------------------------------------------------------------------
  // Cache clearing
  // ------------------------------------------------------------------

  /// 清除单个存储区域的文件内容。
  ///
  /// [areaId] 对应的区域必须是 clearable=true，否则抛出 [StateError]。
  /// 只清除文件系统内容；数据库索引类清理需要通过额外的钩子处理。
  Future<ClearResult> clearStorageArea(String areaId) async {
    final area = _registry.areas.firstWhere(
      (a) => a.id == areaId,
      orElse: () => throw ArgumentError('Unknown storage area: $areaId'),
    );

    if (!area.clearable) {
      throw StateError('Storage area "$areaId" is not clearable');
    }

    return _clearPath(area.path, area.type != StorageAreaType.database);
  }

  /// 清除所有可再生缓存区域。
  ///
  /// 遍历所有类型为 [StorageAreaType.cache] 和 [StorageAreaType.temporary]
  /// 的区域，删除其目录内所有文件。单个区域失败不影响其他区域。
  Future<ClearResult> clearRegenerableCache() async {
    final cacheAreas = _registry.areas
        .where((a) => a.type == StorageAreaType.cache ||
                      a.type == StorageAreaType.temporary)
        .toList();

    int totalFiles = 0;
    int totalBytes = 0;
    final allErrors = <String>[];

    for (final area in cacheAreas) {
      try {
        final result = await _clearPath(
          area.path,
          area.type != StorageAreaType.database,
        );
        totalFiles += result.deletedFiles;
        totalBytes += result.freedBytes;
        allErrors.addAll(result.errors);
      } catch (e) {
        allErrors.add('${area.name}: $e');
      }
    }

    return ClearResult(
      deletedFiles: totalFiles,
      freedBytes: totalBytes,
      errors: allErrors,
    );
  }

  /// 删除指定路径的所有文件内容。
  ///
  /// 若 [isDirectory] 为 true，则删除目录下所有文件并重建空目录。
  /// 若为 false，则直接删除单个文件。
  // ------------------------------------------------------------------
  // Orphan file scanning
  // ------------------------------------------------------------------

  /// 同步扫描孤儿文件。
  ///
  /// [dirPath] 是要扫描的目录，[referencedPaths] 是数据库引用的文件路径集合。
  /// 返回不在 [referencedPaths] 中的文件列表。
  static List<OrphanedFile> findOrphanedFilesSync({
    required String dirPath,
    required Set<String> referencedPaths,
  }) {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) return [];

    final orphaned = <OrphanedFile>[];
    try {
      for (final entity in dir.listSync(recursive: true, followLinks: false)) {
        if (entity is File) {
          final normalized = _normalizePath(entity.path);
          if (!referencedPaths.contains(normalized)) {
            orphaned.add(OrphanedFile(
              path: entity.path,
              sizeBytes: entity.lengthSync(),
              lastModifiedAt: entity.lastModifiedSync(),
            ));
          }
        }
      }
    } catch (_) {
      // Permission errors — return partial results
    }
    return orphaned;
  }

  /// 异步扫描孤儿文件（使用 Isolate 避免阻塞 UI）。
  Future<List<OrphanedFile>> findOrphanedFiles({
    required String dirPath,
    required Set<String> referencedPaths,
  }) async {
    return Isolate.run(() => findOrphanedFilesSync(
      dirPath: dirPath,
      referencedPaths: referencedPaths,
    ));
  }

  /// 清理孤儿文件。
  ///
  /// 返回清理结果，包含删除文件数和释放空间。
  /// 单个文件删除失败不阻塞其他文件。
  Future<ClearResult> cleanOrphanedFiles(List<OrphanedFile> files) async {
    int deleted = 0;
    int freed = 0;
    final errors = <String>[];

    for (final file in files) {
      try {
        final f = File(file.path);
        if (f.existsSync()) {
          await f.delete();
          deleted++;
          freed += file.sizeBytes;
        }
      } catch (e) {
        errors.add('${file.path}: $e');
      }
    }

    return ClearResult(
      deletedFiles: deleted,
      freedBytes: freed,
      errors: errors,
    );
  }

  /// 规范化路径用于跨平台比较。
  static String _normalizePath(String path) {
    return path.replaceAll('\\', '/');
  }

  // ------------------------------------------------------------------
  // Internal
  // ------------------------------------------------------------------

  Future<ClearResult> _clearPath(String path, bool isDirectory) async {
    int totalFiles = 0;
    int totalBytes = 0;
    final errors = <String>[];

    try {
      if (isDirectory) {
        final dir = Directory(path);
        if (dir.existsSync()) {
          // 统计大小
          for (final entity in dir.listSync(recursive: true, followLinks: false)) {
            if (entity is File) {
              totalBytes += entity.lengthSync();
              totalFiles++;
            }
          }
          await dir.delete(recursive: true);
          await dir.create(recursive: true);
        }
      } else {
        final file = File(path);
        if (file.existsSync()) {
          totalBytes = file.lengthSync();
          totalFiles = 1;
          await file.delete();
        }
      }
    } catch (e) {
      errors.add('Failed to clear $path: $e');
    }

    return ClearResult(
      deletedFiles: totalFiles,
      freedBytes: totalBytes,
      errors: errors,
    );
  }
}
