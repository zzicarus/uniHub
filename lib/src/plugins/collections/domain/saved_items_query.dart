import 'collection_models.dart';
import 'consumption_status.dart';
import 'media_type.dart';
import 'source_platform.dart';

/// 收藏列表排序方式。
enum SavedItemsSort {
  updatedDesc,
  createdDesc,
  createdAsc,
  titleAsc,
  lastOpenedDesc,
}

/// 统一收藏列表查询参数。
///
/// 所有筛选条件在 DAO 层通过 SQL / Drift 表达式拼装，
/// 避免全量加载后在 Dart 层内存过滤。
class SavedItemsQuery {
  const SavedItemsQuery({
    this.view = CollectionView.inbox,
    this.status,
    this.platform,
    this.mediaType,
    this.selectedBoxIds = const {},
    this.searchQuery = '',
    this.sort = SavedItemsSort.updatedDesc,
    this.limit = 50,
    this.offset = 0,
  });

  final CollectionView view;
  final ConsumptionStatus? status;
  final SourcePlatform? platform;
  final MediaType? mediaType;
  final Set<int> selectedBoxIds;
  final String searchQuery;
  final SavedItemsSort sort;
  final int limit;
  final int offset;

  /// 创建一个新的 [SavedItemsQuery]，仅覆盖指定的字段。
  SavedItemsQuery copyWith({
    CollectionView? view,
    ConsumptionStatus? status,
    SourcePlatform? platform,
    MediaType? mediaType,
    Set<int>? selectedBoxIds,
    String? searchQuery,
    SavedItemsSort? sort,
    int? limit,
    int? offset,
    bool resetStatus = false,
    bool resetPlatform = false,
    bool resetMediaType = false,
    bool resetSearchQuery = false,
  }) {
    return SavedItemsQuery(
      view: view ?? this.view,
      status: resetStatus ? null : (status ?? this.status),
      platform: resetPlatform ? null : (platform ?? this.platform),
      mediaType: resetMediaType ? null : (mediaType ?? this.mediaType),
      selectedBoxIds: selectedBoxIds ?? this.selectedBoxIds,
      searchQuery: resetSearchQuery ? '' : (searchQuery ?? this.searchQuery),
      sort: sort ?? this.sort,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
    );
  }
}
