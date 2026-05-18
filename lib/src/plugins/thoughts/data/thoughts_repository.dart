import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';
import 'thoughts_dao.dart';

class ThoughtsRepository {
  final ThoughtsDao _dao;

  ThoughtsRepository(this._dao);

  Future<List<ThoughtsTableData>> getThoughts({bool archived = false}) {
    return _dao.getAll(archived: archived);
  }

  Future<ThoughtsTableData?> getThought(int id) {
    return _dao.getById(id);
  }

  Future<ThoughtsTableData> createThought({
    required String content,
    String? tags,
    String? color,
    bool isPinned = false,
  }) async {
    final now = DateTime.now();
    final id = await _dao.insert(
      ThoughtsTableCompanion(
        content: Value(content),
        tags: Value(tags),
        color: Value(color),
        isPinned: Value(isPinned),
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
    String? tags,
    String? color,
    bool? isPinned,
  }) async {
    await _dao.updateById(
      id,
      ThoughtsTableCompanion(
        content: content != null ? Value(content) : const Value.absent(),
        tags: tags != null ? Value(tags) : const Value.absent(),
        color: color != null ? Value(color) : const Value.absent(),
        isPinned: isPinned != null ? Value(isPinned) : const Value.absent(),
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
