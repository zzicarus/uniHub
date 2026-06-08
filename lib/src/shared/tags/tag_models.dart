import 'domain/tag_color_token.dart';

/// A tag entity backed by the [TagsTable] in the database.
class AppTag {
  const AppTag({
    required this.id,
    required this.name,
    required this.normalizedName,
    required this.colorToken,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String name;
  final String normalizedName;
  final TagColorToken colorToken;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AppTag && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Statistics for a single tag.
class AppTagStat {
  final String name;
  final int count;

  const AppTagStat({required this.name, required this.count});
}

/// Whether an item must match any or all selected tags.
enum TagMatchMode {
  any,
  all,
}

/// Result of validating a raw tag string.
class TagValidationResult {
  final bool isValid;
  final String? message;

  const TagValidationResult.valid()
      : isValid = true,
        message = null;

  const TagValidationResult.invalid(this.message) : isValid = false;
}
