/// 存储清理操作结果。
class ClearResult {
  final int deletedFiles;
  final int freedBytes;
  final List<String> errors;

  const ClearResult({
    required this.deletedFiles,
    required this.freedBytes,
    this.errors = const [],
  });

  bool get hasErrors => errors.isNotEmpty;
}
