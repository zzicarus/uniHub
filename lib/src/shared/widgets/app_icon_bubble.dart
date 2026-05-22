import 'package:flutter/material.dart';
import 'package:uni_hub/src/core/theme/app_tokens.dart';

class AppIconBubble extends StatelessWidget {
  final IconData icon;
  final double size;
  final double? iconSize;
  final Color color;
  final Color background;
  final BoxShape shape;
  final double? radius;

  const AppIconBubble({
    required this.icon,
    required this.color,
    required this.background,
    this.size = 44,
    this.iconSize,
    this.shape = BoxShape.circle,
    this.radius,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        shape: shape,
        borderRadius: shape == BoxShape.rectangle
            ? BorderRadius.circular(radius ?? AppRadius.md)
            : null,
      ),
      child: Icon(icon, color: color, size: iconSize ?? size * 0.48),
    );
  }
}
