import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/adaptive_layout.dart';
import 'layouts/thoughts_desktop_layout.dart';
import 'layouts/thoughts_mobile_layout.dart';
import 'widgets/thought_composer_controller.dart';
import 'widgets/thought_editor_drawer.dart';

class ThoughtsPage extends ConsumerStatefulWidget {
  const ThoughtsPage({super.key});

  @override
  ConsumerState<ThoughtsPage> createState() => _ThoughtsPageState();
}

class _ThoughtsPageState extends ConsumerState<ThoughtsPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int? _selectedThoughtId;

  void _openEditor(int id) {
    setState(() => _selectedThoughtId = id);
    _scaffoldKey.currentState?.openEndDrawer();
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
        key: _scaffoldKey,
        backgroundColor: colorScheme.surface,
        endDrawer: _selectedThoughtId != null
            ? Drawer(
                width: MediaQuery.of(context).size.width * 0.55,
                child: ThoughtEditorDrawer(
                  thoughtId: _selectedThoughtId!,
                  onClose: () => _scaffoldKey.currentState?.closeEndDrawer(),
                ),
              )
            : null,
        onEndDrawerChanged: (opened) {
          if (!opened && mounted) {
            setState(() => _selectedThoughtId = null);
          }
        },
        body: SafeArea(
          child: AdaptiveLayout(
            mobile: (_) => ThoughtsMobileLayout(onThoughtTap: _openEditor),
            desktop: (_) => ThoughtsDesktopLayout(
              onThoughtTap: _openEditor,
            ),
          ),
        ),
      ),
    );
  }
}
