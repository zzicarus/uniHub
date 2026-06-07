import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../app_storage_paths.dart';
import '../storage_area.dart';
import '../storage_manager.dart';
import '../storage_registry.dart';

/// 提供统一的 [AppStoragePaths] 实例。
///
/// 启动时异步解析系统路径，同时检测并迁移旧的
/// thought_images 目录（仅目录重命名，DB 更新由
/// [runThoughtImageMigrationProvider] 另行处理）。
/// 所有依赖方通过此 Provider 获取目录引用，禁止直接调用
/// path_provider。
final appStoragePathsProvider = FutureProvider<AppStoragePaths>((ref) async {
  final docsDir = await getApplicationDocumentsDirectory();
  final cacheDir = await getApplicationCacheDirectory();

  final paths = AppStoragePaths(
    documentsDir: docsDir,
    cacheDir: cacheDir,
  );

  // Run directory migration (rename only) — DB updates handled separately.
  final migrations = paths.migrateThoughtImagesIfNeeded();

  return AppStoragePaths(
    documentsDir: docsDir,
    cacheDir: cacheDir,
    thoughtImageMigrations: migrations,
  );
});

/// 内建存储区域描述符（由 core 和插件声明，不含路径）。
///
/// 插件通过 [storageRegistryProvider] 的 [StorageRegistry.register]
/// 注册自己的描述符。
final storageRegistryProvider = Provider<StorageRegistry>((ref) {
  final paths = ref.watch(appStoragePathsProvider).requireValue;
  final registry = StorageRegistry(paths);

  // 注册内建区域描述符
  registry.registerAll([
    const StorageAreaDescriptor(
      id: 'core.database',
      name: '主数据库',
      type: StorageAreaType.database,
      owner: 'core',
      dangerous: true,
      description: '保存想法、收藏、标签、状态等核心数据',
    ),
    const StorageAreaDescriptor(
      id: 'thoughts.images',
      name: '想法图片',
      type: StorageAreaType.userAttachment,
      owner: 'thoughts',
      description: '用户插入到想法中的图片附件',
    ),
    const StorageAreaDescriptor(
      id: 'collections.website_logos',
      name: '网站 Logo 缓存',
      type: StorageAreaType.cache,
      owner: 'collections',
      clearable: true,
      description: '从网页自动获取的网站 favicon/logo，可重新生成',
    ),
    const StorageAreaDescriptor(
      id: 'core.temp',
      name: '临时文件',
      type: StorageAreaType.temporary,
      owner: 'core',
      clearable: true,
      description: '导入导出等中间文件',
    ),
  ]);

  return registry;
});

/// 存储扫描与管理服务。
final storageManagerProvider = Provider<StorageManager>((ref) {
  final registry = ref.watch(storageRegistryProvider);
  return StorageManager(registry);
});
