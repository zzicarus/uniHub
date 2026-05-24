import 'consumption_status.dart';
import 'enrichment_status.dart';
import 'media_type.dart';
import 'source_platform.dart';

enum CollectionView {
  inbox('inbox', 'Inbox'),
  all('all', '全部'),
  unread('unread', '未看'),
  inProgress('in_progress', '进行中'),
  done('done', '已看'),
  archived('archived', '归档');

  const CollectionView(this.value, this.label);

  final String value;
  final String label;
}

class PlatformDetection {
  const PlatformDetection({required this.platform, required this.mediaType});

  final SourcePlatform platform;
  final MediaType mediaType;
}

class CaptureResult {
  const CaptureResult({required this.itemId, required this.wasCreated});

  final int itemId;
  final bool wasCreated;
}

class MetadataResult {
  const MetadataResult({
    this.title,
    this.description,
    this.author,
    this.siteName,
    this.coverImage,
    this.favicon,
    this.metadataJson,
    this.status = EnrichmentStatus.success,
  });

  final String? title;
  final String? description;
  final String? author;
  final String? siteName;
  final String? coverImage;
  final String? favicon;
  final String? metadataJson;
  final EnrichmentStatus status;
}

class SavedItemQuery {
  const SavedItemQuery({
    this.view = CollectionView.inbox,
    this.status,
    this.platform,
    this.mediaType,
    this.boxIds = const {},
    this.searchQuery = '',
  });

  final CollectionView view;
  final ConsumptionStatus? status;
  final SourcePlatform? platform;
  final MediaType? mediaType;
  final Set<int> boxIds;
  final String searchQuery;
}
