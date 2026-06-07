import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uni_hub/src/core/storage/clear_result.dart';
import 'package:uni_hub/src/core/storage/orphaned_file.dart';
import 'package:uni_hub/src/plugins/thoughts/data/thought_image_service.dart';

import '../../../plugins/thoughts/providers/thoughts_providers.dart';
import '../providers/storage_providers.dart';

/// 获取所有被引用的图片路径集合（规范化后）。
///
/// 直接通过 Repository 查询，避免在 FutureProvider 中 await 另一个
/// FutureProvider（allThoughtsProvider）。
Future<Set<String>> _resolveReferencedImagePaths(Ref ref) async {
  final repo = ref.read(thoughtsRepositoryProvider);
  final active = await repo.getThoughts();
  final archived = await repo.getThoughts(archived: true);

  final paths = <String>{};
  for (final thought in [...active, ...archived]) {
    final imagePaths = ThoughtImageService.decodeImagePaths(thought.imagePaths);
    for (final p in imagePaths) {
      paths.add(p.replaceAll('\\', '/'));
    }
  }
  return paths;
}

/// 扫描孤儿图片。
///
/// 孤儿图片定义：存储在 thoughtImagesDir 中，但不被任何
/// thoughts.imagePaths 引用的文件。
final orphanedImagesProvider = FutureProvider<List<OrphanedFile>>((ref) async {
  final storagePaths = ref.watch(appStoragePathsProvider).requireValue;
  final manager = ref.watch(storageManagerProvider);

  final referenced = await _resolveReferencedImagePaths(ref);

  return manager.findOrphanedFiles(
    dirPath: storagePaths.thoughtImagesDir.path,
    referencedPaths: referenced,
  );
});

/// 清理孤儿图片 action。
final cleanOrphanedImagesAction =
    Provider<Future<ClearResult> Function()>((ref) {
  return () async {
    final orphaned = await ref.read(orphanedImagesProvider.future);
    final manager = ref.read(storageManagerProvider);
    return manager.cleanOrphanedFiles(orphaned);
  };
});
