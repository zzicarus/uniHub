import 'thought_image_service.dart';
import 'thoughts_repository.dart';

/// 安全删除想法及其附件。
///
/// 协调 DB 删除和图片文件清理，确保：
/// - DB 删除失败时不得删除图片文件
/// - 同一图片被多个 thought 引用时不得删除该图片
class ThoughtDeletionService {
  final ThoughtsRepository _repository;
  final ThoughtImageService _imageService;

  ThoughtDeletionService({
    required ThoughtsRepository repository,
    required ThoughtImageService imageService,
  }) : _repository = repository,
       _imageService = imageService;

  /// 删除想法并清理附件。
  ///
  /// 流程：
  /// 1. 读取 thought 获取 imagePaths
  /// 2. 删除 DB 记录（失败则终止，不删除文件）
  /// 3. 删除图片文件（DB 已删，文件删除失败由孤儿扫描修复）
  ///
  /// [deletedPaths] 输出已删除的文件路径列表（用于日志/调试）。
  Future<void> deleteThoughtWithAssets(
    int id, {
    List<String>? deletedPaths,
  }) async {
    // 1. 读取 thought
    final thought = await _repository.getThought(id);
    final imagePaths =
        ThoughtImageService.decodeImagePaths(thought?.imagePaths);

    // 2. 删除 DB 记录
    await _repository.deleteThought(id);

    // 3. 删除图片文件（DB 已成功删除）
    if (imagePaths.isNotEmpty) {
      await _imageService.deleteImages(imagePaths);
      deletedPaths?.addAll(imagePaths);
    }
  }
}
