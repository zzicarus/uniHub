import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_tokens.dart';
import '../widgets/sidebar.dart';

class AppLayout extends ConsumerWidget {
  final Widget child;

  const AppLayout({required this.child, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = MediaQuery.of(context).size.width >= 720;

    if (isDesktop) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Sidebar(),
            Expanded(
              child: ColoredBox(color: AppColors.background, child: child),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const Drawer(child: Sidebar()),
      body: child,
    );
  }
}
