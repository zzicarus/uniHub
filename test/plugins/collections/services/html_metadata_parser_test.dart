import 'package:flutter_test/flutter_test.dart';
import 'package:uni_hub/src/plugins/collections/domain/enrichment_status.dart';
import 'package:uni_hub/src/plugins/collections/services/html_metadata_parser.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Title
  // ---------------------------------------------------------------------------
  group('title parsing', () {
    test('og:title (property=) is top priority', () {
      final parser = HtmlMetadataParser.parse(
        '''<html><head>
          <meta property="og:title" content="OG Title">
          <meta name="twitter:title" content="Twitter Title">
          <title>HTML Title</title>
        </head></html>''',
        baseUrl: 'https://example.com',
      );
      expect(parser.result.title, 'OG Title');
    });

    test('og:title with name= also works', () {
      final parser = HtmlMetadataParser.parse(
        '''<html><head>
          <meta name="og:title" content="OG via name">
          <title>HTML Title</title>
        </head></html>''',
        baseUrl: 'https://example.com',
      );
      expect(parser.result.title, 'OG via name');
    });

    test('twitter:title fallback when no og:title', () {
      final parser = HtmlMetadataParser.parse(
        '''<html><head>
          <meta name="twitter:title" content="Twitter Title">
          <title>HTML Title</title>
        </head></html>''',
        baseUrl: 'https://example.com',
      );
      expect(parser.result.title, 'Twitter Title');
    });

    test('application-name fallback when no og/twitter title', () {
      final parser = HtmlMetadataParser.parse(
        '''<html><head>
          <meta name="application-name" content="My App">
          <title>HTML Title</title>
        </head></html>''',
        baseUrl: 'https://example.com',
      );
      expect(parser.result.title, 'My App');
    });

    test('<title> fallback when no meta titles exist', () {
      final parser = HtmlMetadataParser.parse(
        '<html><head><title>The Page Title</title></head></html>',
        baseUrl: 'https://example.com',
      );
      expect(parser.result.title, 'The Page Title');
    });

    test('returns null when no title source exists', () {
      final parser = HtmlMetadataParser.parse(
        '<html><head></head></html>',
        baseUrl: 'https://example.com',
      );
      expect(parser.result.title, isNull);
    });

    test('empty <title> yields null when no other sources', () {
      final parser = HtmlMetadataParser.parse(
        '<html><head><title>  </title></head></html>',
        baseUrl: 'https://example.com',
      );
      expect(parser.result.title, isNull);
    });

    test('filter "Just a moment" error titles', () {
      final parser = HtmlMetadataParser.parse(
        '<html><head><title>Just a moment...</title></head></html>',
        baseUrl: 'https://example.com',
      );
      expect(parser.result.title, isNull);
    });

    test('filter "Access Denied" error titles', () {
      final parser = HtmlMetadataParser.parse(
        '<html><head><title>Access Denied</title></head></html>',
        baseUrl: 'https://example.com',
      );
      expect(parser.result.title, isNull);
    });

    test('truncate title longer than 160 chars', () {
      final longTitle = 'A' * 200;
      final parser = HtmlMetadataParser.parse(
        '<html><head><title>$longTitle</title></head></html>',
        baseUrl: 'https://example.com',
      );
      expect(parser.result.title!.length, 160);
    });

    test('collapse consecutive whitespace in title', () {
      final parser = HtmlMetadataParser.parse(
        '<html><head><title>Hello    World    Title</title></head></html>',
        baseUrl: 'https://example.com',
      );
      expect(parser.result.title, 'Hello World Title');
    });
  });

  // ---------------------------------------------------------------------------
  // Description
  // ---------------------------------------------------------------------------
  group('description parsing', () {
    test('og:description is top priority', () {
      final parser = HtmlMetadataParser.parse(
        '''<html><head>
          <meta property="og:description" content="OG Description">
          <meta name="twitter:description" content="Twitter Desc">
          <meta name="description" content="Meta Desc">
        </head></html>''',
        baseUrl: 'https://example.com',
      );
      expect(parser.result.description, 'OG Description');
    });

    test('og:description with name= also works', () {
      final parser = HtmlMetadataParser.parse(
        '''<html><head>
          <meta name="og:description" content="OG via name">
          <meta name="description" content="Meta Desc">
        </head></html>''',
        baseUrl: 'https://example.com',
      );
      expect(parser.result.description, 'OG via name');
    });

    test('twitter:description fallback', () {
      final parser = HtmlMetadataParser.parse(
        '''<html><head>
          <meta name="twitter:description" content="Twitter Desc">
          <meta name="description" content="Meta Desc">
        </head></html>''',
        baseUrl: 'https://example.com',
      );
      expect(parser.result.description, 'Twitter Desc');
    });

    test('meta[name=description] fallback', () {
      final parser = HtmlMetadataParser.parse(
        '''<html><head>
          <meta name="description" content="Regular Meta Description">
        </head></html>''',
        baseUrl: 'https://example.com',
      );
      expect(parser.result.description, 'Regular Meta Description');
    });

    test('returns null when no description source exists', () {
      final parser = HtmlMetadataParser.parse(
        '<html><head></head></html>',
        baseUrl: 'https://example.com',
      );
      expect(parser.result.description, isNull);
    });

    test('truncate description longer than 500 chars', () {
      final longDesc = 'X' * 600;
      final parser = HtmlMetadataParser.parse(
        '''<html><head>
          <meta name="description" content="$longDesc">
        </head></html>''',
        baseUrl: 'https://example.com',
      );
      expect(parser.result.description!.length, 500);
    });

    test('collapse consecutive whitespace in description', () {
      final parser = HtmlMetadataParser.parse(
        '''<html><head>
          <meta name="description" content="Hello    World    Desc">
        </head></html>''',
        baseUrl: 'https://example.com',
      );
      expect(parser.result.description, 'Hello World Desc');
    });
  });

  // ---------------------------------------------------------------------------
  // Cover Image
  // ---------------------------------------------------------------------------
  group('cover image parsing', () {
    test('og:image is top priority', () {
      final parser = HtmlMetadataParser.parse(
        '''<html><head>
          <meta property="og:image" content="https://example.com/og.jpg">
          <meta name="twitter:image" content="https://example.com/tw.jpg">
          <link rel="image_src" href="https://example.com/src.jpg">
        </head></html>''',
        baseUrl: 'https://example.com',
      );
      expect(parser.result.coverImage, 'https://example.com/og.jpg');
    });

    test('twitter:image fallback', () {
      final parser = HtmlMetadataParser.parse(
        '''<html><head>
          <meta name="twitter:image" content="https://example.com/tw.jpg">
        </head></html>''',
        baseUrl: 'https://example.com',
      );
      expect(parser.result.coverImage, 'https://example.com/tw.jpg');
    });

    test('twitter:image:src fallback', () {
      final parser = HtmlMetadataParser.parse(
        '''<html><head>
          <meta name="twitter:image:src" content="https://example.com/tw-src.jpg">
        </head></html>''',
        baseUrl: 'https://example.com',
      );
      expect(parser.result.coverImage, 'https://example.com/tw-src.jpg');
    });

    test('link[rel=image_src] fallback', () {
      final parser = HtmlMetadataParser.parse(
        '''<html><head>
          <link rel="image_src" href="https://example.com/img.jpg">
        </head></html>''',
        baseUrl: 'https://example.com',
      );
      expect(parser.result.coverImage, 'https://example.com/img.jpg');
    });

    test('resolve relative og:image URL', () {
      final parser = HtmlMetadataParser.parse(
        '''<html><head>
          <meta property="og:image" content="/images/cover.jpg">
        </head></html>''',
        baseUrl: 'https://example.com/blog/post',
      );
      expect(parser.result.coverImage, 'https://example.com/images/cover.jpg');
    });

    test('resolve relative twitter:image URL', () {
      final parser = HtmlMetadataParser.parse(
        '''<html><head>
          <meta name="twitter:image" content="img/twitter-card.png">
        </head></html>''',
        baseUrl: 'https://example.com/blog/',
      );
      expect(
        parser.result.coverImage,
        'https://example.com/blog/img/twitter-card.png',
      );
    });

    test('returns null when no image source exists', () {
      final parser = HtmlMetadataParser.parse(
        '<html><head></head></html>',
        baseUrl: 'https://example.com',
      );
      expect(parser.result.coverImage, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // Site Name
  // ---------------------------------------------------------------------------
  group('site name parsing', () {
    test('og:site_name is top priority', () {
      final parser = HtmlMetadataParser.parse(
        '''<html><head>
          <meta property="og:site_name" content="Example Site">
          <meta name="application-name" content="My App">
        </head></html>''',
        baseUrl: 'https://example.com',
      );
      expect(parser.result.siteName, 'Example Site');
    });

    test('og:site_name with name= also works', () {
      final parser = HtmlMetadataParser.parse(
        '''<html><head>
          <meta name="og:site_name" content="Example via Name">
        </head></html>''',
        baseUrl: 'https://example.com',
      );
      expect(parser.result.siteName, 'Example via Name');
    });

    test('application-name fallback', () {
      final parser = HtmlMetadataParser.parse(
        '''<html><head>
          <meta name="application-name" content="My Application">
        </head></html>''',
        baseUrl: 'https://example.com',
      );
      expect(parser.result.siteName, 'My Application');
    });

    test('fallback to host when no meta tags', () {
      final parser = HtmlMetadataParser.parse(
        '<html><head></head></html>',
        baseUrl: 'https://blog.example.com/path',
      );
      expect(parser.result.siteName, 'blog.example.com');
    });
  });

  // ---------------------------------------------------------------------------
  // Author
  // ---------------------------------------------------------------------------
  group('author parsing', () {
    test('article:author is top priority', () {
      final parser = HtmlMetadataParser.parse(
        '''<html><head>
          <meta property="article:author" content="Jane Doe">
          <meta name="author" content="John Smith">
          <meta name="byl" content="Byline Person">
        </head></html>''',
        baseUrl: 'https://example.com',
      );
      expect(parser.result.author, 'Jane Doe');
    });

    test('article:author with name= also works', () {
      final parser = HtmlMetadataParser.parse(
        '''<html><head>
          <meta name="article:author" content="Author via Name">
        </head></html>''',
        baseUrl: 'https://example.com',
      );
      expect(parser.result.author, 'Author via Name');
    });

    test('meta[name=author] fallback', () {
      final parser = HtmlMetadataParser.parse(
        '''<html><head>
          <meta name="author" content="John Smith">
        </head></html>''',
        baseUrl: 'https://example.com',
      );
      expect(parser.result.author, 'John Smith');
    });

    test('meta[name=byl] fallback', () {
      final parser = HtmlMetadataParser.parse(
        '''<html><head>
          <meta name="byl" content="Byline Person">
        </head></html>''',
        baseUrl: 'https://example.com',
      );
      expect(parser.result.author, 'Byline Person');
    });

    test('returns null when no author source exists', () {
      final parser = HtmlMetadataParser.parse(
        '<html><head></head></html>',
        baseUrl: 'https://example.com',
      );
      expect(parser.result.author, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // Favicon
  // ---------------------------------------------------------------------------
  group('favicon parsing', () {
    test('apple-touch-icon gets highest priority', () {
      final parser = HtmlMetadataParser.parse(
        '''<html><head>
          <link rel="apple-touch-icon" href="/apple-touch-icon.png">
          <link rel="icon" href="/favicon.ico" type="image/x-icon">
        </head></html>''',
        baseUrl: 'https://example.com',
      );
      expect(
        parser.result.favicon,
        'https://example.com/apple-touch-icon.png',
      );
    });

    test('PNG icon beats ICO', () {
      final parser = HtmlMetadataParser.parse(
        '''<html><head>
          <link rel="icon" href="/favicon.ico">
          <link rel="icon" href="/icon.png">
        </head></html>''',
        baseUrl: 'https://example.com',
      );
      expect(parser.result.favicon, 'https://example.com/icon.png');
    });

    test('resolves relative favicon URL', () {
      final parser = HtmlMetadataParser.parse(
        '<html><head><link rel="icon" href="assets/favicon.ico"></head></html>',
        baseUrl: 'https://example.com/blog/post',
      );
      expect(
        parser.result.favicon,
        'https://example.com/blog/assets/favicon.ico',
      );
    });

    test('root-relative favicon URL', () {
      final parser = HtmlMetadataParser.parse(
        '<html><head><link rel="icon" href="/static/favicon.ico"></head></html>',
        baseUrl: 'https://example.com/blog/post',
      );
      expect(parser.result.favicon, 'https://example.com/static/favicon.ico');
    });

    test('falls back to /favicon.ico when no link tag exists', () {
      final parser = HtmlMetadataParser.parse(
        '<html><head><title>No Favicon</title></head></html>',
        baseUrl: 'https://example.com',
      );
      expect(parser.result.favicon, 'https://example.com/favicon.ico');
    });

    test('shortcut icon is recognised', () {
      final parser = HtmlMetadataParser.parse(
        '<html><head><link rel="shortcut icon" href="/custom.ico"></head></html>',
        baseUrl: 'https://example.com',
      );
      expect(parser.result.favicon, 'https://example.com/custom.ico');
    });

    test('favicon with rel containing "icon" substring works', () {
      final parser = HtmlMetadataParser.parse(
        '<html><head><link rel="mask-icon" href="/safari-pinned-tab.svg"></head></html>',
        baseUrl: 'https://example.com',
      );
      // "mask-icon" contains "icon", so it should be picked up
      expect(
        parser.result.favicon,
        'https://example.com/safari-pinned-tab.svg',
      );
    });

    test('link rel without icon substring falls through to default', () {
      final parser = HtmlMetadataParser.parse(
        '<html><head><link rel="stylesheet" href="/style.css"></head></html>',
        baseUrl: 'https://example.com',
      );
      expect(parser.result.favicon, 'https://example.com/favicon.ico');
    });
  });

  // ---------------------------------------------------------------------------
  // Edge cases
  // ---------------------------------------------------------------------------
  group('edge cases', () {
    test('malformed HTML does not crash parser', () {
      final parser = HtmlMetadataParser.parse(
        '<html><head><meta property="og:title" content="Valid HTML"</head><body><p>Some content</html>',
        baseUrl: 'https://example.com',
      );
      // The html parser is robust — it should extract og:title from
      // partially malformed HTML with unclosed / overlapping tags.
      expect(parser.result.title, 'Valid HTML');
    });

    test('truly broken HTML returns null not crash', () {
      final parser = HtmlMetadataParser.parse(
        'not html at all <<<<>>>> {{bad stuff',
        baseUrl: 'https://example.com',
      );
      // Should not crash, returns null for title
      expect(parser.result.title, isNull);
    });

    test('empty content attribute yields null', () {
      final parser = HtmlMetadataParser.parse(
        '''<html><head>
          <meta property="og:title" content="">
          <title>Real Title</title>
        </head></html>''',
        baseUrl: 'https://example.com',
      );
      expect(parser.result.title, 'Real Title');
    });

    test('all fields correct on complete page', () {
      final parser = HtmlMetadataParser.parse(
        '''<html><head>
          <meta property="og:title" content="Complete Article Title">
          <meta property="og:description" content="A full description of the article.">
          <meta property="og:image" content="https://cdn.example.com/cover.jpg">
          <meta property="og:site_name" content="Example News">
          <meta property="article:author" content="Alice Writer">
          <link rel="apple-touch-icon" href="/apple-touch-icon.png">
          <title>The HTML Title</title>
        </head></html>''',
        baseUrl: 'https://example.com/article/123',
      );

      expect(parser.result.title, 'Complete Article Title');
      expect(parser.result.description, 'A full description of the article.');
      expect(parser.result.coverImage, 'https://cdn.example.com/cover.jpg');
      expect(parser.result.siteName, 'Example News');
      expect(parser.result.author, 'Alice Writer');
      expect(
        parser.result.favicon,
        'https://example.com/apple-touch-icon.png',
      );
    });

    test('status is always success for HtmlMetadataParser', () {
      final parser = HtmlMetadataParser.parse(
        '<html><head></head></html>',
        baseUrl: 'https://example.com',
      );
      expect(parser.result.status, EnrichmentStatus.success);
    });
  });
}
