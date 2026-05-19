import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/sidebar.dart';

class DesktopShell extends ConsumerWidget {
  final Widget child;

  const DesktopShell({required this.child, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Sidebar(),
          Expanded(
            child: ColoredBox(color: colorScheme.surface, child: child),
          ),
        ],
      ),
    );
  }
}
