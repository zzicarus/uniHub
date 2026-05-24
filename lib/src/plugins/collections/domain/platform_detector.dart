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
    if (host.contains('zhihu.com')) {
      return const PlatformDetection(
        platform: SourcePlatform.zhihu,
        mediaType: MediaType.article,
      );
    }
    if (host.contains('xiaohongshu.com')) {
      return const PlatformDetection(
        platform: SourcePlatform.xiaohongshu,
        mediaType: MediaType.post,
      );
    }
    if (host.contains('twitter.com') || host.contains('x.com')) {
      return const PlatformDetection(
        platform: SourcePlatform.twitter,
        mediaType: MediaType.post,
      );
    }
    if (host.contains('douban.com')) {
      return const PlatformDetection(
        platform: SourcePlatform.douban,
        mediaType: MediaType.post,
      );
    }

    // PDF 文件 — 基于路径后缀，放在平台规则之后避免覆盖平台识别
    if (uri.path.endsWith('.pdf')) {
      return const PlatformDetection(
        platform: SourcePlatform.pdf,
        mediaType: MediaType.pdf,
      );
    }

    return const PlatformDetection(
      platform: SourcePlatform.web,
      mediaType: MediaType.webpage,
    );
  }
}
