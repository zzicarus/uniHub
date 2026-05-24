import 'collection_models.dart';
import 'media_type.dart';
import 'source_platform.dart';

class PlatformDetector {
  const PlatformDetector();

  PlatformDetection detect(String url) {
    final uri = Uri.parse(url.contains('://') ? url : 'https://$url');
    final host = uri.host.toLowerCase();

    if (host.contains('github.com')) {
      return const PlatformDetection(
        platform: SourcePlatform.github,
        mediaType: MediaType.repository,
      );
    }
    if (host.contains('bilibili.com') || host.contains('b23.tv')) {
      return const PlatformDetection(
        platform: SourcePlatform.bilibili,
        mediaType: MediaType.video,
      );
    }
    if (host.contains('youtube.com') || host.contains('youtu.be')) {
      return const PlatformDetection(
        platform: SourcePlatform.youtube,
        mediaType: MediaType.video,
      );
    }
    if (host.contains('mp.weixin.qq.com')) {
      return const PlatformDetection(
        platform: SourcePlatform.wechat,
        mediaType: MediaType.article,
      );
    }

    return const PlatformDetection(
      platform: SourcePlatform.web,
      mediaType: MediaType.article,
    );
  }
}
