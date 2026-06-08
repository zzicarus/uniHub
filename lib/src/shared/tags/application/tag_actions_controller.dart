import 'dart:async';

import 'package:uni_hub/src/shared/crud/crud.dart';
import 'package:uni_hub/src/shared/tags/data/tags_dao.dart';
import 'package:uni_hub/src/shared/tags/tag_models.dart';

import 'tag_mutation_event.dart';

/// Unified controller for all tag write operations.
///
/// Every method returns [CrudResult] so the UI can display status
/// messages consistently without catching raw exceptions.
class TagActionsController {
  TagActionsController({
    required TagsDao tagsDao,
  }) : _tagsDao = tagsDao;

  final TagsDao _tagsDao;

  /// In-memory stream controller for broadcasting mutation events.
  final _eventController = StreamController<TagMutationEvent>.broadcast();

  /// Stream of tag mutation events.  UI components should listen to this
  /// to patch local state.
  Stream<TagMutationEvent> get events => _eventController.stream;

  // ---------------------------------------------------------------------------
  // Tag CRUD
  // ---------------------------------------------------------------------------

  Future<CrudResult<AppTag>> createTag(String name) async {
    try {
      final validation = _validateTagName(name);
      if (validation != null) {
        return CrudResult<AppTag>.failure(
          failure: validation,
          fieldErrorHandled: true,
        );
      }

      final existing = await _tagsDao.getTagByNormalizedName(name);
      if (existing != null) {
        return CrudResult<AppTag>.success(
          data: existing,
          message: '标签已存在',
          suppressFeedback: true,
        );
      }

      final tag = await _tagsDao.createTag(name);
      _eventController.add(TagCreated(tag.id));
      return CrudResult<AppTag>.success(
        data: tag,
        message: '已创建标签「${tag.name}」',
      );
    } catch (error, stackTrace) {
      return CrudResult<AppTag>.failure(
        failure: AppFailure(
          code: AppFailureCode.database,
          message: '创建标签失败',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  Future<CrudResult<AppTag>> getOrCreateTag(String name) async {
    try {
      final existing = await _tagsDao.getTagByNormalizedName(name);
      if (existing != null) {
        return CrudResult<AppTag>.success(
          data: existing,
          message: '标签已存在',
          suppressFeedback: true,
        );
      }
      return createTag(name);
    } catch (error, stackTrace) {
      return CrudResult<AppTag>.failure(
        failure: AppFailure(
          code: AppFailureCode.database,
          message: '获取或创建标签失败',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  Future<CrudResult<void>> renameTag(
    int tagId,
    String newName,
  ) async {
    try {
      final validation = _validateTagName(newName);
      if (validation != null) {
        return CrudResult<void>.failure(
          failure: validation,
          fieldErrorHandled: true,
        );
      }

      final existing = await _tagsDao.getTagByNormalizedName(newName);
      if (existing != null && existing.id != tagId) {
        return CrudResult<void>.failure(
          failure: AppFailure(
            code: AppFailureCode.duplicate,
            message: '标签「$newName」已存在',
          ),
          fieldErrorHandled: true,
        );
      }

      await _tagsDao.renameTag(tagId, newName);
      _eventController.add(TagUpdated(tagId));
      return const CrudResult<void>.success(message: '标签已重命名');
    } catch (error, stackTrace) {
      return CrudResult<void>.failure(
        failure: AppFailure(
          code: AppFailureCode.database,
          message: '重命名标签失败',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  Future<CrudResult<void>> deleteTag(int tagId) async {
    try {
      await _tagsDao.deleteTag(tagId);
      _eventController.add(TagDeleted(tagId));
      return const CrudResult<void>.success(message: '标签已删除');
    } catch (error, stackTrace) {
      return CrudResult<void>.failure(
        failure: AppFailure(
          code: AppFailureCode.database,
          message: '删除标签失败',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Thought tags
  // ---------------------------------------------------------------------------

  Future<CrudResult<void>> addTagToThought({
    required int thoughtId,
    required String tagName,
  }) async {
    try {
      final tag = await _tagsDao.getOrCreateTag(tagName);
      await _tagsDao.addTagToThought(thoughtId, tag.id);
      _eventController.add(TagAddedToThought(thoughtId: thoughtId, tagId: tag.id));
      return CrudResult<void>.success(
        message: '已添加标签「${tag.name}」',
        suppressFeedback: true,
      );
    } catch (error, stackTrace) {
      return CrudResult<void>.failure(
        failure: AppFailure(
          code: AppFailureCode.database,
          message: '添加标签失败',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  Future<CrudResult<void>> removeTagFromThought({
    required int thoughtId,
    required int tagId,
  }) async {
    try {
      await _tagsDao.removeTagFromThought(thoughtId, tagId);
      _eventController.add(TagRemovedFromThought(
        thoughtId: thoughtId,
        tagId: tagId,
      ));
      return const CrudResult<void>.success(
        message: '标签已移除',
        suppressFeedback: true,
      );
    } catch (error, stackTrace) {
      return CrudResult<void>.failure(
        failure: AppFailure(
          code: AppFailureCode.database,
          message: '移除标签失败',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // SavedItem tags
  // ---------------------------------------------------------------------------

  Future<CrudResult<void>> addTagToSavedItem({
    required int savedItemId,
    required String tagName,
  }) async {
    try {
      final tag = await _tagsDao.getOrCreateTag(tagName);
      await _tagsDao.addTagToSavedItem(savedItemId, tag.id);
      _eventController.add(
        TagAddedToSavedItem(savedItemId: savedItemId, tagId: tag.id),
      );
      return CrudResult<void>.success(
        message: '已添加标签「${tag.name}」',
        suppressFeedback: true,
      );
    } catch (error, stackTrace) {
      return CrudResult<void>.failure(
        failure: AppFailure(
          code: AppFailureCode.database,
          message: '添加标签失败',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  Future<CrudResult<void>> removeTagFromSavedItem({
    required int savedItemId,
    required int tagId,
  }) async {
    try {
      await _tagsDao.removeTagFromSavedItem(savedItemId, tagId);
      _eventController.add(
        TagRemovedFromSavedItem(savedItemId: savedItemId, tagId: tagId),
      );
      return const CrudResult<void>.success(
        message: '标签已移除',
        suppressFeedback: true,
      );
    } catch (error, stackTrace) {
      return CrudResult<void>.failure(
        failure: AppFailure(
          code: AppFailureCode.database,
          message: '移除标签失败',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Tag merge
  // ---------------------------------------------------------------------------

  Future<CrudResult<void>> mergeTags({
    required int sourceTagId,
    required int targetTagId,
  }) async {
    try {
      if (sourceTagId == targetTagId) {
        return const CrudResult<void>.failure(
          failure: AppFailure(
            code: AppFailureCode.validation,
            message: '不能合并同一标签',
          ),
          fieldErrorHandled: true,
        );
      }
      // Migrate thought relationships.
      final thoughtTags = await _tagsDao.getTagsForThought(sourceTagId);
      for (final tag in thoughtTags) {
        await _tagsDao.addTagToThought(tag.id, targetTagId);
      }
      // Migrate saved item relationships.
      final itemTags = await _tagsDao.getTagsForSavedItem(sourceTagId);
      for (final tag in itemTags) {
        await _tagsDao.addTagToSavedItem(tag.id, targetTagId);
      }
      // Delete the source tag.
      await _tagsDao.deleteTag(sourceTagId);
      _eventController.add(TagMerged(
        sourceTagId: sourceTagId,
        targetTagId: targetTagId,
      ));
      return const CrudResult<void>.success(message: '标签已合并');
    } catch (error, stackTrace) {
      return CrudResult<void>.failure(
        failure: AppFailure(
          code: AppFailureCode.database,
          message: '合并标签失败',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Dispose
  // ---------------------------------------------------------------------------

  void dispose() {
    _eventController.close();
  }

  // ---------------------------------------------------------------------------
  // Validation
  // ---------------------------------------------------------------------------

  /// Returns an [AppFailure] if [name] is invalid, null otherwise.
  AppFailure? _validateTagName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return const AppFailure(
        code: AppFailureCode.validation,
        message: '标签不能为空',
        field: 'name',
      );
    }
    if (trimmed.length > 24) {
      return const AppFailure(
        code: AppFailureCode.validation,
        message: '标签长度不能超过 24 个字符',
        field: 'name',
      );
    }
    if (trimmed.contains(RegExp(r'\s'))) {
      return const AppFailure(
        code: AppFailureCode.validation,
        message: '标签不能包含空格',
        field: 'name',
      );
    }
    if (!RegExp(r'^[\u4e00-\u9fff\u3400-\u4dbf\uF900-\uFAFFa-zA-Z0-9_-]+$')
        .hasMatch(trimmed)) {
      return const AppFailure(
        code: AppFailureCode.validation,
        message: '标签只能包含中文、英文、数字、短横线和下划线',
        field: 'name',
      );
    }
    return null;
  }
}
