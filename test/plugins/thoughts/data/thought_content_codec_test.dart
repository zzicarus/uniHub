import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uni_hub/src/plugins/thoughts/data/thought_content_codec.dart';

void main() {
  group('ThoughtContentCodec', () {
    test('round-trips Quill delta envelope', () {
      final document = Document()..insert(0, '一级标题\n正文');

      final encoded = ThoughtContentCodec.encodeDocument(document);
      final decoded = ThoughtContentCodec.documentFromStored(encoded);

      expect(decoded.toPlainText(), contains('一级标题'));
      expect(decoded.toPlainText(), contains('正文'));
    });

    test('converts legacy markdown to plain text', () {
      const markdown = '# 一级标题\n\n正文内容';

      expect(
        ThoughtContentCodec.plainTextFromStored(markdown),
        contains('一级标题'),
      );
      expect(ThoughtContentCodec.titleFromStored(markdown), '一级标题 正文内容');
    });

    test('extracts image paths from legacy markdown', () {
      const markdown = '正文\n\n![](file:///D:/uniHub/example.png)';

      final paths = ThoughtContentCodec.imagePathsFromStored(markdown);
      expect(paths, hasLength(1));
      expect(paths.first, endsWith('D:/uniHub/example.png'));
    });
  });
}
