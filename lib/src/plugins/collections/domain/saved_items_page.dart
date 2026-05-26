import 'package:uni_hub/src/core/database/app_database.dart';

/// 收藏列表分页返回结构。
///
/// 只包含当前页的 item 数据及其 Box 关系，
/// 避免全量加载后内存过滤。
class SavedItemsPage {
  const SavedItemsPage({
    required this.items,
    required this.boxIdsByItemId,
    required this.hasMore,
    this.totalCount,
  });

  /// 当前页的收藏项列表。
  final List<SavedItemsTableData> items;

  /// 当前页每个 item 所属的 Box ID 列表。
  ///
  /// 只包含 [items] 中出现的 itemId。未出现在 map 中的 item
  /// 表示不属于任何 Box。
  final Map<int, List<int>> boxIdsByItemId;

  /// 是否还有更多数据可加载。
  final bool hasMore;

  /// 总条数（可选，避免额外 count 查询）。
  final int? totalCount;
}
