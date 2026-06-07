import 'tag_models.dart';

/// Pure encoding / decoding utilities for tags stored as comma-separated strings.
///
/// Normalization rules:
/// - Trim leading/trailing whitespace.
/// - Strip a leading `#` so that user input `#产品` is stored as `产品`.
/// - Empty tags are rejected.
/// - Maximum tag length is 20 characters.
/// - Allowed characters: Chinese, English letters, digits, short dashes (`-`), underscores (`_`).
/// - Repeated tags are deduplicated.
abstract final class TagCodec {
  /// Normalize a raw tag string.
  ///
  /// Returns the cleaned tag, or an empty string if the input is invalid.
  static String normalize(String raw) {
    var result = raw.trim();
    // Strip a single leading '#' — handles both "#产品" and "产品"
    if (result.startsWith('#')) {
      result = result.substring(1).trim();
    }
    return result;
  }

  /// Return the display form of a tag (e.g. `"产品"` → `"#产品"`).
  static String display(String tag) => '#$tag';

  /// Parse a comma-separated tag string into a list of normalized tags.
  ///
  /// Duplicates are removed while preserving order of first occurrence.
  /// Returns an empty list for `null` or blank input.
  static List<String> parseCommaSeparated(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const [];
    final seen = <String>{};
    return raw
        .split(',')
        .map(normalize)
        .where((tag) => tag.isNotEmpty)
        .where(seen.add)
        .toList();
  }

  /// Encode an iterable of tags into a comma-separated string.
  ///
  /// Each tag is normalized, empty results are skipped, duplicates are removed
  /// (first occurrence wins). Returns `null` when the result would be empty.
  static String? encodeCommaSeparated(Iterable<String> tags) {
    final seen = <String>{};
    final normalized = <String>[];
    for (final tag in tags) {
      final n = normalize(tag);
      if (n.isNotEmpty && seen.add(n)) {
        normalized.add(n);
      }
    }
    if (normalized.isEmpty) return null;
    return normalized.join(',');
  }

  /// Validate a raw tag string.
  ///
  /// Returns [TagValidationResult.valid] when the tag passes all rules,
  /// or [TagValidationResult.invalid] with a descriptive message.
  static TagValidationResult validate(String raw) {
    final normalized = normalize(raw);
    if (normalized.isEmpty) {
      return const TagValidationResult.invalid('标签不能为空');
    }
    if (normalized.length > 20) {
      return const TagValidationResult.invalid('标签长度不能超过 20 个字符');
    }
    final validPattern = RegExp(
      r'^[\u4e00-\u9fff\u3400-\u4dbf\uF900-\uFAFFa-zA-Z0-9_-]+$',
    );
    if (!validPattern.hasMatch(normalized)) {
      return const TagValidationResult.invalid(
        '标签只能包含中文、英文、数字、短横线和下划线',
      );
    }
    return const TagValidationResult.valid();
  }
}
