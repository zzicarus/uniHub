import 'package:flutter_test/flutter_test.dart';
import 'package:uni_hub/src/plugins/collections/domain/media_type.dart';
import 'package:uni_hub/src/plugins/collections/domain/platform_detector.dart';
import 'package:uni_hub/src/plugins/collections/domain/source_platform.dart';

void main() {
  group('PlatformDetector', () {
    const detector = PlatformDetector();

    test('GitHub → repository', () {
      final result = detector.detect('https://github.com/flutter/flutter');

      expect(result.platform, SourcePlatform.github);
      expect(result.mediaType, MediaType.repository);
    });

    test('Bilibili → video', () {
      final result = detector.detect('https://www.bilibili.com/video/BV123');

      expect(result.platform, SourcePlatform.bilibili);
      expect(result.mediaType, MediaType.video);
    });

    test('Bilibili short URL (b23.tv) → video', () {
      final result = detector.detect('https://b23.tv/abc123');

      expect(result.platform, SourcePlatform.bilibili);
      expect(result.mediaType, MediaType.video);
    });

    test('YouTube → video', () {
      final result = detector.detect('https://www.youtube.com/watch?v=abc');

      expect(result.platform, SourcePlatform.youtube);
      expect(result.mediaType, MediaType.video);
    });

    test('YouTube short URL (youtu.be) → video', () {
      final result = detector.detect('https://youtu.be/abc123');

      expect(result.platform, SourcePlatform.youtube);
      expect(result.mediaType, MediaType.video);
    });

    test('微信公众号 → article', () {
      final result = detector.detect('https://mp.weixin.qq.com/s/abc123');

      expect(result.platform, SourcePlatform.wechat);
      expect(result.mediaType, MediaType.article);
    });

    test('知乎 → article', () {
      final result = detector.detect('https://www.zhihu.com/question/123');

      expect(result.platform, SourcePlatform.zhihu);
      expect(result.mediaType, MediaType.article);
    });

    test('小红书 → post', () {
      final result = detector.detect('https://www.xiaohongshu.com/explore/123');

      expect(result.platform, SourcePlatform.xiaohongshu);
      expect(result.mediaType, MediaType.post);
    });

    test('Twitter → post', () {
      final result = detector.detect('https://twitter.com/user/status/123');

      expect(result.platform, SourcePlatform.twitter);
      expect(result.mediaType, MediaType.post);
    });

    test('X (Twitter) → post', () {
      final result = detector.detect('https://x.com/user/status/123');

      expect(result.platform, SourcePlatform.twitter);
      expect(result.mediaType, MediaType.post);
    });

    test('豆瓣 → post', () {
      final result = detector.detect('https://www.douban.com/group/topic/123');

      expect(result.platform, SourcePlatform.douban);
      expect(result.mediaType, MediaType.post);
    });

    test('PDF 文件 → pdf / pdf', () {
      final result = detector.detect('https://example.com/paper.pdf');

      expect(result.platform, SourcePlatform.pdf);
      expect(result.mediaType, MediaType.pdf);
    });

    test('PDF 文件带 query → pdf / pdf', () {
      final result = detector.detect('https://example.com/paper.pdf?v=1');

      expect(result.platform, SourcePlatform.pdf);
      expect(result.mediaType, MediaType.pdf);
    });

    test('普通网页 → web / webpage', () {
      final result = detector.detect('https://example.com/some-page');

      expect(result.platform, SourcePlatform.web);
      expect(result.mediaType, MediaType.webpage);
    });

    test('无 scheme 的 URL → web / webpage', () {
      final result = detector.detect('example.com');

      expect(result.platform, SourcePlatform.web);
      expect(result.mediaType, MediaType.webpage);
    });
  });
}
