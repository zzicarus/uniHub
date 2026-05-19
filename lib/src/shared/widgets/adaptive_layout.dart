import 'package:flutter/material.dart';

import '../../core/theme/app_breakpoints.dart';

class AdaptiveLayout extends StatelessWidget {
  final WidgetBuilder mobile;
  final WidgetBuilder desktop;

  const AdaptiveLayout({
    required this.mobile,
    required this.desktop,
    super.key,
  });

  static WindowSize windowSizeOf(BuildContext context) =>
      AppBreakpoints.of(context);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= AppBreakpoints.tabletMin) {
      return desktop(context);
    }
    return mobile(context);
  }
}
