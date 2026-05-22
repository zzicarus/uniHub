import 'package:drift/drift.dart';
import 'package:uni_hub/src/core/database/app_database.dart';
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
    String? imagePaths,
  }) async {
    final now = DateTime.now();
    final id = await _dao.insert(
      ThoughtsTableCompanion(
        content: Value(content),
        tags: Value(tags),
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
    String? tags,
    String? color,
    bool? isPinned,
    String? imagePaths,
  }) async {
    await _dao.updateById(
      id,
      ThoughtsTableCompanion(
        content: content != null ? Value(content) : const Value.absent(),
        tags: tags != null ? Value(tags) : const Value.absent(),
        color: color != null ? Value(color) : const Value.absent(),
        isPinned: isPinned != null ? Value(isPinned) : const Value.absent(),
        imagePaths: imagePaths != null
            ? Value(imagePaths)
            : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> updateTags(int id, String? tags) {
    return _dao.updateById(
      id,
      ThoughtsTableCompanion(
        tags: Value(_encodeTags(_parseTags(tags))),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> renameTag(String oldTag, String newTag) async {
    final from = oldTag.trim();
    final to = newTag.trim();
    if (from.isEmpty || to.isEmpty) {
      throw ArgumentError('标签名称不能为空');
    }
    if (from == to) return 0;

    final thoughts = [
      ...await getThoughts(),
      ...await getThoughts(archived: true),
    ];
    final allTags = <String>{
      for (final thought in thoughts) ..._parseTags(thought.tags),
    };
    if (allTags.contains(to)) {
      throw StateError('标签「$to」已存在');
    }

    var affected = 0;
    for (final thought in thoughts) {
      final tags = _parseTags(thought.tags);
      if (!tags.contains(from)) continue;
      final renamed = tags.map((tag) => tag == from ? to : tag).toList();
      await updateTags(thought.id, _encodeTags(renamed));
      affected++;
    }
    return affected;
  }

  Future<int> deleteTagEverywhere(String tag) async {
    final target = tag.trim();
    if (target.isEmpty) return 0;
    final thoughts = [
      ...await getThoughts(),
      ...await getThoughts(archived: true),
    ];

    var affected = 0;
    for (final thought in thoughts) {
      final tags = _parseTags(thought.tags);
      if (!tags.contains(target)) continue;
      tags.removeWhere((item) => item == target);
      await updateTags(thought.id, _encodeTags(tags));
      affected++;
    }
    return affected;
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

  List<String> _parseTags(String? tags) {
    if (tags == null || tags.trim().isEmpty) return const [];
    final seen = <String>{};
    return tags
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .where(seen.add)
        .toList();
  }

  String? _encodeTags(List<String> tags) {
    final normalized = _parseTags(tags.join(','));
    return normalized.isEmpty ? null : normalized.join(',');
  }
}
