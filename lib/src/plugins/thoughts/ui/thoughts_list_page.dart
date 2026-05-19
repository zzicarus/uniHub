import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'thoughts_page.dart';

/// Thin wrapper around [ThoughtsPage] which owns all state and layout logic.
/// Kept as a separate class for compatibility with existing plugin routing.
class ThoughtsListPage extends ConsumerWidget {
  const ThoughtsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const ThoughtsPage();
  }
}
