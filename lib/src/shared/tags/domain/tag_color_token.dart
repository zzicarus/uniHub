import 'package:flutter/material.dart';

/// Stable colour tokens for tags.
///
/// Assigned at creation time and stored in the database so that the same
/// tag always renders in the same colour.  These map to Material 3 colour
/// roles so they adapt to both light and dark themes.
enum TagColorToken {
  blue(0),
  purple(1),
  rose(2),
  green(3),
  amber(4),
  cyan(5),
  slate(6);

  const TagColorToken(this.value);
  final int value;

  /// Map this token to a [Color] using the given [colorScheme].
  Color resolve(ColorScheme cs) => switch (this) {
    TagColorToken.blue => cs.primary,
    TagColorToken.purple => cs.tertiary,
    TagColorToken.rose => cs.error,
    TagColorToken.green => cs.secondary,
    TagColorToken.amber => Color.lerp(cs.tertiary, cs.error, 0.5) ?? cs.tertiary,
    TagColorToken.cyan => cs.primary.withBlue(200),
    TagColorToken.slate => cs.onSurfaceVariant,
  };

  /// Background tint for the resolved colour.
  Color resolveBackground(ColorScheme cs) => switch (this) {
    TagColorToken.blue => cs.primaryContainer,
    TagColorToken.purple => cs.tertiaryContainer,
    TagColorToken.rose => cs.errorContainer,
    TagColorToken.green => cs.secondaryContainer,
    TagColorToken.amber => cs.tertiaryContainer,
    TagColorToken.cyan => cs.primaryContainer,
    TagColorToken.slate => cs.surfaceContainerLow,
  };

  /// Assign a stable token based on the hash of [name].
  static TagColorToken assign(String name) {
    final hash = name.toLowerCase().hashCode.abs();
    return TagColorToken.values[hash % TagColorToken.values.length];
  }
}
