import 'package:drift/drift.dart';
import 'package:uni_hub/src/core/database/app_database.dart';
import 'thoughts_dao.dart';

class ThoughtsRepository {
  final ThoughtsDao _dao;

  ThoughtsRepository(this._dao);

  Future<List<ThoughtsTableData>> getThoughts({bool archived = false}) {
    return _dao.getAll(archived: archived);
  }

  /// 活跃想法数量（数据库侧 COUNT）。
  Future<int> countActive() => _dao.countActive();

  /// 最近 N 条未归档想法（数据库侧 LIMIT）。
  Future<List<ThoughtsTableData>> getRecent({required int limit}) =>
      _dao.getRecent(limit: limit);

  /// 最近 N 条置顶想法（数据库侧 LIMIT）。
  Future<List<ThoughtsTableData>> getPinned({required int limit}) =>
      _dao.getPinned(limit: limit);

  Future<ThoughtsTableData?> getThought(int id) {
    return _dao.getById(id);
  }

  Future<ThoughtsTableData> createThought({
    required String content,
    String? color,
    bool isPinned = false,
    String? imagePaths,
  }) async {
    final now = DateTime.now();
    final id = await _dao.insert(
      ThoughtsTableCompanion(
        content: Value(content),
        color: Value(color),
        isPinned: Value(isPinned),
        imagePaths: Value(imagePaths),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );
    final created = await _dao.getById(id);
    return created!;
  }

  Future<void> updateThought(
    int id, {
    String? content,
    String? color,
    bool? isPinned,
    String? imagePaths,
  }) async {
    await _dao.updateById(
      id,
      ThoughtsTableCompanion(
        content: content != null ? Value(content) : const Value.absent(),
        color: color != null ? Value(color) : const Value.absent(),
        isPinned: isPinned != null ? Value(isPinned) : const Value.absent(),
        imagePaths: imagePaths != null
            ? Value(imagePaths)
            : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteThought(int id) {
    return _dao.delete(id);
  }

  Future<void> archiveThought(int id) {
    return _dao.archive(id);
  }

  Future<void> restoreThought(int id) {
    return _dao.restore(id);
  }

  Future<void> togglePin(int id, bool pinned) {
    return _dao.togglePin(id, pinned);
  }
}
