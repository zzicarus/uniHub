import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uni_hub/src/core/database/app_database.dart';
import 'package:uni_hub/src/core/database/database_provider.dart';
import 'package:uni_hub/src/core/plugin/plugin_registry.dart';
import 'package:uni_hub/src/plugins/collections/collections_plugin.dart';
import 'package:uni_hub/src/plugins/collections/ui/widgets/saved_item_card.dart';

void main() {
  Future<void> pumpCard(WidgetTester tester, Widget child) {
    final registry = PluginRegistry()..register(CollectionsPlugin());
    final db = AppDatabase(NativeDatabase.memory(), registry);
    addTearDown(() => db.close());

    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          pluginRegistryProvider.overrideWithValue(registry),
        ],
        child: MaterialApp(
          home: Scaffold(body: Center(child: child)),
        ),
      ),
    );
  }

  bool hasLocalMaterialAncestor({
    required WidgetTester tester,
    required Finder component,
    required Finder target,
  }) {
    final componentElement = tester.element(component);
    final targetElement = tester.element(target);
    var found = false;

    targetElement.visitAncestorElements((ancestor) {
      if (ancestor == componentElement) return false;
      if (ancestor.widget is Material) {
        found = true;
        return false;
      }
      return true;
    });

    return found;
  }

  testWidgets('SavedItemCard owns a local Material host for ink decoration', (
    tester,
  ) async {
    var tapped = false;
    final now = DateTime(2026, 5, 24, 9);

    await pumpCard(
      tester,
      SavedItemCard(
        item: SavedItemsTableData(
          id: 1,
          originalUrl: 'https://example.com/article',
          normalizedUrl: 'https://example.com/article',
          title: 'Flutter Ink host note',
          description: 'Local Material prevents Scaffold-level ink features',
          mediaType: 'article',
          sourcePlatform: 'web',
          status: 'unread',
          isInInbox: true,
          enrichmentStatus: 'pending',
          createdAt: now,
          updatedAt: now,
        ),
        onTap: () => tapped = true,
      ),
    );

    expect(
      hasLocalMaterialAncestor(
        tester: tester,
        component: find.byType(SavedItemCard),
        target: find
            .descendant(
              of: find.byType(SavedItemCard),
              matching: find.byType(Ink),
            )
            .first,
      ),
      isTrue,
    );

    await tester.tap(find.text('Flutter Ink host note'));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('SavedItemCard renders with favicon URL without crashing', (
    tester,
  ) async {
    final now = DateTime(2026, 5, 24, 9);

    await pumpCard(
      tester,
      SavedItemCard(
        item: SavedItemsTableData(
          id: 2,
          originalUrl: 'https://example.com/article',
          normalizedUrl: 'https://example.com/article',
          title: 'With Favicon',
          description: 'Article with favicon',
          mediaType: 'article',
          sourcePlatform: 'web',
          status: 'unread',
          isInInbox: true,
          enrichmentStatus: 'pending',
          favicon: 'https://example.com/favicon.ico',
          createdAt: now,
          updatedAt: now,
        ),
        onTap: () {},
      ),
    );

    // The card renders without crashing.
    // The WalletLogo fallback shows the article icon when the image fails
    // to load in the test environment (no real HTTP).
    expect(find.text('With Favicon'), findsOneWidget);
  });

  testWidgets('SavedItemCard enrichment failed red dot shows with favicon', (
    tester,
  ) async {
    final now = DateTime(2026, 5, 24, 9);

    await pumpCard(
      tester,
      SavedItemCard(
        item: SavedItemsTableData(
          id: 3,
          originalUrl: 'https://example.com/failed',
          normalizedUrl: 'https://example.com/failed',
          title: 'Failed Enrichment',
          mediaType: 'article',
          sourcePlatform: 'web',
          status: 'unread',
          isInInbox: true,
          enrichmentStatus: 'failed',
          favicon: 'https://example.com/favicon.ico',
          createdAt: now,
          updatedAt: now,
        ),
        onTap: () {},
      ),
    );

    // The card still renders and '抓取失败' chip is shown
    expect(find.text('Failed Enrichment'), findsOneWidget);
    expect(find.text('抓取失败'), findsOneWidget);
  });
}
