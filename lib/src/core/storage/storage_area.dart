/// 存储区域类型。
enum StorageAreaType {
  /// 核心数据库 — 用户数据，不可缓存清除。
  database,

  /// 用户附件 — 用户主动添加的文件（如图片），不可缓存清除。
  userAttachment,

  /// 可再生缓存 — 可重新生成的数据。
  cache,

  /// 临时文件 — 导入导出等中间文件。
  temporary,

  /// 孤儿文件 — 不再被引用的残留文件。
  orphaned,
}

/// 插件注册的存储区域描述符（不含路径）。
///
/// 由插件在 [UniHubPlugin.storageAreas] 中返回常量实例。
/// [StorageRegistry] 在 Provider 环境中拼接 [AppStoragePaths]
/// 生成完整 [StorageArea]。
class StorageAreaDescriptor {
  final String id;
  final String name;
  final StorageAreaType type;
  final String owner;
  final bool clearable;
  final bool dangerous;
  final String description;

  const StorageAreaDescriptor({
    required this.id,
    required this.name,
    required this.type,
    required this.owner,
    this.clearable = false,
    this.dangerous = false,
    required this.description,
  });
}

/// 完整存储区域（含运行时路径）。
class StorageArea {
  final String id;
  final String name;
  final StorageAreaType type;
  final String owner;
  final String path;
  final bool clearable;
  final bool dangerous;
  final String description;

  const StorageArea({
    required this.id,
    required this.name,
    required this.type,
    required this.owner,
    required this.path,
    required this.clearable,
    required this.dangerous,
    required this.description,
  });

  StorageArea.fromDescriptor(
    StorageAreaDescriptor descriptor, {
    required this.path,
  }) : id = descriptor.id,
       name = descriptor.name,
       type = descriptor.type,
       owner = descriptor.owner,
       clearable = descriptor.clearable,
       dangerous = descriptor.dangerous,
       description = descriptor.description;
}
