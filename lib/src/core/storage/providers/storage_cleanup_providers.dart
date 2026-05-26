import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:uni_hub/src/plugins/collections/providers/collections_providers.dart';
import '../clear_result.dart';
import 'storage_providers.dart';

/// 一键清除所有可再生缓存（含文件系统内容和数据库索引）。
///
/// 协调 [StorageManager] 的目录清理与 [WebsiteLogoCacheService]
/// 的 DB 索引清理，确保清理后 UI 刷新。
///
/// 返回的函数可在 Widget 或 Controller 中通过 `ref.read(...)()`
/// 直接调用。
final clearRegenerableCacheAction = Provider<Future<ClearResult> Function()>(
  (ref) {
    return () async {
      final manager = ref.read(storageManagerProvider);

      int totalFiles = 0;
      int totalBytes = 0;
      final errors = <String>[];

      // 1. 清除网站 Logo 缓存（文件 + DB 索引）
      try {
        final logoService = await ref.read(websiteLogoCacheServiceProvider.future);
        final logoResult = await logoService.clearCache();
        totalFiles += logoResult.deletedFiles;
        totalBytes += logoResult.freedBytes;
        // 触发 UI 刷新
        ref.read(websiteLogoRefreshProvider.notifier).state++;
      } catch (e) {
        errors.add('网站 Logo 缓存: $e');
      }

      // 2. 清除其他可再生缓存目录（仅文件系统）
      final otherAreaIds = [
        'core.temp',
      ];

      for (final id in otherAreaIds) {
        try {
          final result = await manager.clearStorageArea(id);
          totalFiles += result.deletedFiles;
          totalBytes += result.freedBytes;
          errors.addAll(result.errors);
        } catch (e) {
          errors.add('$id: $e');
        }
      }

      return ClearResult(
        deletedFiles: totalFiles,
        freedBytes: totalBytes,
        errors: errors,
      );
    };
  },
);
