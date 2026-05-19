import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/sidebar.dart';

class AppLayout extends ConsumerWidget {
  final Widget child;

  const AppLayout({required this.child, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = MediaQuery.of(context).size.width >= 720;
    final colorScheme = Theme.of(context).colorScheme;

    if (isDesktop) {
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

    return Scaffold(
      backgroundColor: colorScheme.surface,
      drawer: const Drawer(child: Sidebar()),
      body: child,
    );
  }
}
