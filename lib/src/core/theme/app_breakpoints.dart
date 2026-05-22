import 'package:flutter/material.dart';

enum WindowSize { compact, medium, expanded }

abstract final class AppBreakpoints {
  static const double mobileMax = 899;
  static const double tabletMin = 900;
  static const double wideMin = 1280;

  static bool isCompact(BuildContext context) =>
      MediaQuery.of(context).size.width < tabletMin;

  static bool isMedium(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return w >= tabletMin && w < wideMin;
  }

  static bool isExpanded(BuildContext context) =>
      MediaQuery.of(context).size.width >= wideMin;

  static WindowSize of(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= wideMin) return WindowSize.expanded;
    if (width >= tabletMin) return WindowSize.medium;
    return WindowSize.compact;
  }
}
