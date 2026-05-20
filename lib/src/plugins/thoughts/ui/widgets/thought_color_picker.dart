import 'package:flutter/material.dart';
import 'package:uni_hub/src/core/theme/app_tokens.dart';

/// A colored circular dot used for selecting thought colors.
class ThoughtColorDot extends StatelessWidget {
  final Color? color;
  final String? label;
  final bool isSelected;
  final VoidCallback onTap;
  final double size;

  const ThoughtColorDot({
    this.color,
    this.label,
    required this.isSelected,
    required this.onTap,
    this.size = 36,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color ?? Theme.of(context).colorScheme.surfaceContainerHigh,
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
            width: isSelected ? 2.5 : 1.5,
          ),
        ),
        child: color == null
            ? Center(
                child: Text(
                  'A',
                  style: TextStyle(
                    fontSize: size * 0.33,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}

/// Returns the standard palette of available thought colors.
List<Color> thoughtAvailableColors(ColorScheme colorScheme) => [
  colorScheme.primary,
  colorScheme.secondary,
  colorScheme.tertiary,
  colorScheme.error,
  colorScheme.primaryContainer,
  colorScheme.secondaryContainer,
  colorScheme.tertiaryContainer,
];

/// Converts a [Color] to a hex string (e.g., `"FF5733"`) without `#` prefix.
String thoughtColorToHex(Color c) {
  return '#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
}
