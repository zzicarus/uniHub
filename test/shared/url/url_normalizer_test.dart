import 'package:flutter_test/flutter_test.dart';
import 'package:uni_hub/src/shared/url/url_normalizer.dart';

void main() {
  group('UrlNormalizer URL detection', () {
    late UrlNormalizer normalizer;

    setUp(() {
      normalizer = const UrlNormalizer();
    });

    test('detects https://example.com as URL', () {
      final result = normalizer.tryNormalize('https://example.com');
      expect(result, isNotNull);
      expect(result, contains('example.com'));
    });

    test('detects http://example.com as URL', () {
      final result = normalizer.tryNormalize('http://example.com');
      expect(result, isNotNull);
      expect(result, startsWith('http://example.com'));
    });

    test('detects example.com (without scheme) as URL', () {
      final result = normalizer.tryNormalize('example.com');
      expect(result, isNotNull);
      expect(result, startsWith('https://example.com'));
    });

    test('detects www.example.com as URL', () {
      final result = normalizer.tryNormalize('www.example.com');
      expect(result, isNotNull);
      expect(result, startsWith('https://www.example.com'));
    });

    test('detects plain text as NOT a URL', () {
      final result = normalizer.tryNormalize('今天记录一个想法');
      expect(result, isNull);
    });

    test('detects hashtag as NOT a URL', () {
      final result = normalizer.tryNormalize('#Flutter');
      expect(result, isNull);
    });

    test('detects non-URL phrase as NOT a URL', () {
      final result = normalizer.tryNormalize('not a url');
      expect(result, isNull);
    });

    test('detects empty string as NOT a URL', () {
      final result = normalizer.tryNormalize('');
      expect(result, isNull);
    });

    test('detects URL with tracking params stripped', () {
      final result = normalizer.tryNormalize(
        'https://example.com/page?utm_source=test&q=hello',
      );
      expect(result, isNotNull);
      expect(result, contains('q=hello'));
      expect(result, isNot(contains('utm_source')));
    });

    test('detects single word without dot as NOT a URL', () {
      final result = normalizer.tryNormalize('Hello');
      expect(result, isNull);
    });

    test('detects URL with path and trailing slash normalized', () {
      final result = normalizer.tryNormalize('https://example.com/path/');
      expect(result, equals('https://example.com/path'));
    });

    test('detects IP address as URL', () {
      final result = normalizer.tryNormalize('192.168.1.1');
      expect(result, startsWith('https://192.168.1.1'));
    });
  });

  group('UrlNormalizer normalize output', () {
    late UrlNormalizer normalizer;

    setUp(() {
      normalizer = const UrlNormalizer();
    });

    test('normalize adds https scheme when missing', () {
      expect(
        normalizer.tryNormalize('example.com'),
        startsWith('https://'),
      );
    });

    test('normalize lowercases scheme', () {
      final result = normalizer.tryNormalize('HTTP://EXAMPLE.COM');
      expect(result, startsWith('http://example.com'));
    });

    test('normalize lowercases host', () {
      final result = normalizer.tryNormalize('https://Example.COM/Path');
      expect(result, equals('https://example.com/Path'));
    });
  });
}
