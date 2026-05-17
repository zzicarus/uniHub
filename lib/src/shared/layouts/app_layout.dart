import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/sidebar.dart';

class AppLayout extends ConsumerWidget {
  final Widget child;

  const AppLayout({required this.child, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = MediaQuery.of(context).size.width >= 720;

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Sidebar(),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(child: child),
        ],
      );
    }

    return Scaffold(
      drawer: const Drawer(child: Sidebar()),
      body: child,
    );
  }
}
