import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uni_hub/src/core/database/app_database.dart';
import 'package:uni_hub/src/plugins/collections/ui/widgets/saved_item_card.dart';

void main() {
  Future<void> pumpCard(WidgetTester tester, Widget child) {
    return tester.pumpWidget(
      ProviderScope(
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
}
