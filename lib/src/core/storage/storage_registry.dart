import 'app_storage_paths.dart';
import 'storage_area.dart';

/// 两级注册：收集所有插件的 [StorageAreaDescriptor]，
/// 在 Provider 环境中结合 [AppStoragePaths] 生成完整 [StorageArea] 列表。
class StorageRegistry {
  final AppStoragePaths _paths;
  final List<StorageAreaDescriptor> _descriptors = [];
  List<StorageArea>? _areas;

  StorageRegistry(this._paths);

  /// 注册单个存储区域描述符。
  void register(StorageAreaDescriptor descriptor) {
    _descriptors.add(descriptor);
    _areas = null; // invalidate cache
  }

  /// 注册一组存储区域描述符。
  void registerAll(Iterable<StorageAreaDescriptor> descriptors) {
    _descriptors.addAll(descriptors);
    _areas = null; // invalidate cache
  }

  /// 获取所有已注册的完整存储区域（含运行时路径）。
  List<StorageArea> get areas {
    if (_areas != null) return _areas!;
    _areas = _descriptors.map(_buildArea).toList();
    return _areas!;
  }

  StorageArea _buildArea(StorageAreaDescriptor descriptor) {
    return StorageArea.fromDescriptor(
      descriptor,
      path: _resolvePath(descriptor),
    );
  }

  /// 将描述符 ID 解析为运行时路径。
  String _resolvePath(StorageAreaDescriptor descriptor) {
    return switch (descriptor.id) {
      'core.database' => _paths.databaseFile.path,
      'thoughts.images' => _paths.thoughtImagesDir.path,
      'collections.website_logos' => _paths.websiteLogosDir.path,
      'core.temp' => _paths.tempDir.path,
      _ => throw ArgumentError('Unknown storage area: ${descriptor.id}'),
    };
  }
}
