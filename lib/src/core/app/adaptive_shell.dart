import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_breakpoints.dart';
import 'desktop_shell.dart';
import 'mobile_shell.dart';

class AdaptiveShell extends ConsumerWidget {
  final Widget child;

  const AdaptiveShell({required this.child, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < AppBreakpoints.tabletMin) {
          return MobileShell(child: child);
        }
        return DesktopShell(child: child);
      },
    );
  }
}
