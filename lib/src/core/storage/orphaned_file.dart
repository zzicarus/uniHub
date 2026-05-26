/// 孤儿文件 — 保存在应用目录中但不再被数据库引用的文件。
class OrphanedFile {
  final String path;
  final int sizeBytes;
  final DateTime lastModifiedAt;

  const OrphanedFile({
    required this.path,
    required this.sizeBytes,
    required this.lastModifiedAt,
  });

  @override
  String toString() =>
      'OrphanedFile(path: $path, sizeBytes: $sizeBytes, lastModifiedAt: $lastModifiedAt)';
}
