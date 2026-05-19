import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/sidebar.dart';
import '../theme/app_tokens.dart';

class DesktopShell extends ConsumerWidget {
  final Widget child;

  const DesktopShell({required this.child, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
}
