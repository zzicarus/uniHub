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
