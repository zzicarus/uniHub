import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uni_hub/src/plugins/collections/domain/saved_items_query.dart';
import 'package:uni_hub/src/plugins/collections/providers/collections_providers.dart';
import 'package:uni_hub/src/shared/widgets/menu/app_select_menu.dart';

/// Sort dropdown menu for the Collection Command Bar.
///
/// Uses [AppSelectMenu] so the visual style is consistent with the
/// platform / media-type / status filter menus across the app.
class CollectionSortMenu extends ConsumerWidget {
  const CollectionSortMenu({super.key});

  static const _items = <AppSelectMenuItem<SavedItemsSort>>[
    AppSelectMenuItem(
      value: SavedItemsSort.createdDesc,
      label: '最新收藏',
      icon: Icons.access_time_rounded,
    ),
    AppSelectMenuItem(
      value: SavedItemsSort.updatedDesc,
      label: '最近更新',
      icon: Icons.update_rounded,
    ),
    AppSelectMenuItem(
      value: SavedItemsSort.lastOpenedDesc,
      label: '最近打开',
      icon: Icons.history_rounded,
    ),
    AppSelectMenuItem(
      value: SavedItemsSort.titleAsc,
      label: '标题 A-Z',
      icon: Icons.sort_by_alpha_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSort = ref.watch(collectionSortProvider);

    return AppSelectMenu<SavedItemsSort>(
      value: currentSort,
      items: _items,
      onChanged: (sort) {
        ref.read(collectionSortProvider.notifier).state = sort;
      },
      leadingIcon: Icons.swap_vert_rounded,
    );
  }
}
