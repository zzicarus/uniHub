import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:uni_hub/src/core/database/app_database.dart';
import 'package:uni_hub/src/core/database/database_provider.dart';
import 'package:uni_hub/src/core/database/tables/thoughts_table.dart';
import 'package:uni_hub/src/core/plugin/plugin_interface.dart';
import 'package:uni_hub/src/core/plugin/plugin_registry.dart';
import 'package:uni_hub/src/core/theme/app_theme.dart';
import 'package:uni_hub/src/core/theme/app_theme_preset.dart';
import 'package:uni_hub/src/plugins/thoughts/ui/widgets/thought_editor_workspace.dart';

/// Minimal plugin registration so AppDatabase knows about ThoughtsTable.
class _ThoughtsTablePlugin extends UniHubPlugin {
  @override
  String get id => 'thoughts-workspace-test';
  @override
  String get name => 'Thoughts Workspace Test';
  @override
  List<Type> get tables => [ThoughtsTable];
  @override
  int get schemaVersion => 2;
}

/// Builds a minimal AppFlowy JSON content string for a single paragraph.
String _makeAppFlowyContent(String text) {
  return jsonEncode({
    'format': 'unihub.appflowy_json.v1',
    'document': {
      'type': 'page',
      'children': [
        {
          'type': 'paragraph',
          'data': {
            'delta': [
              {'insert': text},
            ],
          },
        },
      ],
    },
    'plainText': text,
  });
}

void main() {
  group('ThoughtEditorWorkspace', () {
    late AppDatabase db;
    late PluginRegistry registry;

    setUp(() async {
      registry = PluginRegistry()..register(_ThoughtsTablePlugin());
      db = AppDatabase(NativeDatabase.memory(), registry);

      // Insert one thought so the workspace can load it.
      await db.into(db.thoughtsTable).insertReturning(
        ThoughtsTableCompanion.insert(
          content: _makeAppFlowyContent('Test thought content'),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    });

    tearDown(() async {
      await db.close();
    });

    /// Wraps the workspace in a MaterialApp + ProviderScope with overrides.
    Widget buildTestApp({
      required int thoughtId,
      VoidCallback? onClose,
    }) {
      return ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          pluginRegistryProvider.overrideWithValue(registry),
        ],
        child: MaterialApp(
          theme: AppTheme.build(
            preset: AppThemePreset.uniBlue,
            brightness: Brightness.light,
          ),
          home: Scaffold(
            body: ThoughtEditorWorkspace(
              thoughtId: thoughtId,
              onClose: onClose,
            ),
          ),
        ),
      );
    }

    testWidgets('header shows "编辑想法"', (tester) async {
      await tester.pumpWidget(buildTestApp(thoughtId: 1));
      await tester.pump();

      expect(find.text('编辑想法'), findsOneWidget);
    });

    testWidgets('header shows save status after loaded', (tester) async {
      await tester.pumpWidget(buildTestApp(thoughtId: 1));
      // Let the async load complete. In-memory DB is fast, so a single
      // pump (processing microtasks + frame) is sufficient.
      await tester.pump();

      expect(find.text('草稿已自动保存'), findsOneWidget);
    });

    testWidgets('displays property cards: 标签, 图片, 外观, 状态',
        (tester) async {
      await tester.pumpWidget(buildTestApp(thoughtId: 1));
      await tester.pump();

      // The property cards are rendered in the right rail.
      expect(find.text('标签'), findsOneWidget);
      expect(find.text('图片'), findsOneWidget);
      expect(find.text('外观'), findsOneWidget);
      expect(find.text('状态'), findsOneWidget);
    });

    testWidgets('footer shows buttons: 删除想法, 关闭, 保存想法',
        (tester) async {
      await tester.pumpWidget(buildTestApp(thoughtId: 1));
      await tester.pump();

      expect(find.text('删除想法'), findsOneWidget);
      expect(find.text('关闭'), findsOneWidget);
      expect(find.text('保存想法'), findsOneWidget);
    });

    testWidgets('footer shows Ctrl+Enter hint', (tester) async {
      await tester.pumpWidget(buildTestApp(thoughtId: 1));
      await tester.pump();

      expect(find.text('Ctrl+Enter 快速保存'), findsOneWidget);
    });

    testWidgets('tapping close button triggers onClose', (tester) async {
      var closed = false;

      await tester.pumpWidget(buildTestApp(
        thoughtId: 1,
        onClose: () => closed = true,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      // load completes → "草稿已自动保存"

      // Tap the close icon button.
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(closed, isTrue);
    });
  });
}
