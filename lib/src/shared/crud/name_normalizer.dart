import 'app_failure.dart';

abstract final class NameNormalizer {
  static const int tagMaxLength = 24;
  static const int collectionBoxMaxLength = 30;

  static final RegExp _spaces = RegExp(r'\s+');
  static final RegExp _tagPattern = RegExp(
    r'^[\u4e00-\u9fff\u3400-\u4dbf\uF900-\uFAFFa-zA-Z0-9_-]+$',
  );

  static String normalize(String raw) {
    return raw.trim().replaceAll(_spaces, ' ');
  }

  static String normalizeForKey(String raw) {
    return normalize(raw).toLowerCase();
  }

  static String normalizeTag(String raw) {
    var result = raw.trim();
    if (result.startsWith('#')) {
      result = result.substring(1).trim();
    }
    return result;
  }

  static AppFailure? validateTag(String raw, {String field = 'tag'}) {
    final normalized = normalizeTag(raw);
    if (normalized.isEmpty || normalized == '#') {
      return AppFailure(
        code: AppFailureCode.validation,
        message: '标签不能为空',
        field: field,
      );
    }
    if (normalized.contains(RegExp(r'\s'))) {
      return AppFailure(
        code: AppFailureCode.validation,
        message: '标签不能包含空格或换行',
        field: field,
      );
    }
    if (normalized.length > tagMaxLength) {
      return AppFailure(
        code: AppFailureCode.validation,
        message: '标签长度不能超过 $tagMaxLength 个字符',
        field: field,
      );
    }
    if (!_tagPattern.hasMatch(normalized)) {
      return AppFailure(
        code: AppFailureCode.validation,
        message: '标签只能包含中文、英文、数字、短横线和下划线',
        field: field,
      );
    }
    return null;
  }

  static AppFailure? validateCollectionBoxName(
    String raw, {
    Iterable<String> siblingNames = const <String>[],
    String field = 'name',
  }) {
    final normalized = normalize(raw);
    if (normalized.isEmpty) {
      return AppFailure(
        code: AppFailureCode.validation,
        message: '收藏夹名称不能为空',
        field: field,
      );
    }
    if (normalized.length > collectionBoxMaxLength) {
      return AppFailure(
        code: AppFailureCode.validation,
        message: '收藏夹名称过长，最多 $collectionBoxMaxLength 个字符',
        field: field,
      );
    }
    if (normalized.contains('/')) {
      return AppFailure(
        code: AppFailureCode.validation,
        message: '收藏夹名称不能包含 /',
        field: field,
      );
    }
    final key = normalizeForKey(normalized);
    final duplicate = siblingNames.any((name) => normalizeForKey(name) == key);
    if (duplicate) {
      return AppFailure(
        code: AppFailureCode.duplicate,
        message: '同级收藏夹已存在「$normalized」',
        field: field,
      );
    }
    return null;
  }
}
