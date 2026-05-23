import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/adaptive_layout.dart';
import 'layouts/thoughts_desktop_layout.dart';
import 'layouts/thoughts_mobile_layout.dart';
import 'widgets/thought_composer_controller.dart';
import 'widgets/thought_editor_workspace.dart';

class ThoughtsPage extends ConsumerStatefulWidget {
  const ThoughtsPage({super.key});

  @override
  ConsumerState<ThoughtsPage> createState() => _ThoughtsPageState();
}

class _ThoughtsPageState extends ConsumerState<ThoughtsPage> {
  void _openEditor(int id) {
    ThoughtEditorWorkspace.show(context, thoughtId: id);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Focus(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.enter &&
            HardwareKeyboard.instance.isControlPressed) {
          ref.read(composerProvider).submit();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        body: SafeArea(
          child: AdaptiveLayout(
            mobile: (_) => ThoughtsMobileLayout(onThoughtTap: _openEditor),
            desktop: (_) => ThoughtsDesktopLayout(onThoughtTap: _openEditor),
          ),
        ),
      ),
    );
  }
}
