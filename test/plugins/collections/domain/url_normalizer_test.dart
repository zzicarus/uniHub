import 'package:flutter_test/flutter_test.dart';
import 'package:uni_hub/src/plugins/collections/domain/media_type.dart';
import 'package:uni_hub/src/plugins/collections/domain/platform_detector.dart';
import 'package:uni_hub/src/plugins/collections/domain/source_platform.dart';
import 'package:uni_hub/src/plugins/collections/domain/url_normalizer.dart';

void main() {
  group('UrlNormalizer', () {
    const normalizer = UrlNormalizer();

    test('adds https scheme and lowercases host', () {
      expect(
        normalizer.normalize('Example.COM/Hello/'),
        'https://example.com/Hello',
      );
    });

    test('removes fragment and sorts query parameters', () {
      expect(
        normalizer.normalize('https://example.com/read?b=2&a=1#section'),
        'https://example.com/read?a=1&b=2',
      );
    });

    test('rejects empty URL', () {
      expect(() => normalizer.normalize('  '), throwsArgumentError);
    });

    test('removes tracking parameters but keeps business params', () {
      expect(
        normalizer.normalize(
          'https://example.com/a?utm_source=x&utm_medium=y&id=1#section',
        ),
        'https://example.com/a?id=1',
      );
    });

    test('removes spm, from, share_source tracking params', () {
      expect(
        normalizer.normalize(
          'https://example.com/a?spm=abc&from=share&page=2',
        ),
        'https://example.com/a?page=2',
      );
    });
  });

  group('PlatformDetector', () {
    const detector = PlatformDetector();

    test('detects GitHub repositories', () {
      final result = detector.detect('https://github.com/flutter/flutter');

      expect(result.platform, SourcePlatform.github);
      expect(result.mediaType, MediaType.repository);
    });

    test('detects video platforms', () {
      final result = detector.detect('https://www.bilibili.com/video/BV123');

      expect(result.platform, SourcePlatform.bilibili);
      expect(result.mediaType, MediaType.video);
    });
  });
}
