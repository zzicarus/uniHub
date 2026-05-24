# AppFlowy Image Block API

## Overview

AppFlowy Editor has a built-in image block system. We should use it instead of a custom schema.

## Key Files

- `vendor/appflowy_editor/lib/src/editor/block_component/image_block_component/image_block_component.dart`
- Cross-references in `vendor/appflowy_editor/lib/src/editor/block_component/block_component.dart` (exports)

## ImageBlockKeys

```dart
class ImageBlockKeys {
  static const String type = 'image';
  static const String align = 'align';   // left, center, right
  static const String url = 'url';       // URL or base64 string
  static const String width = 'width';   // double
  static const String height = 'height'; // double
}
```

## imageNode() Factory

```dart
Node imageNode({
  required String url,
  String align = 'center',
  double? height,
  double? width,
}) {
  return Node(
    type: ImageBlockKeys.type,
    attributes: {
      ImageBlockKeys.url: url,
      ImageBlockKeys.align: align,
      ImageBlockKeys.height: height,
      ImageBlockKeys.width: width,
    },
  );
}
```

## Inserting into Document

Use `EditorState.transaction` to insert nodes:

```dart
final transaction = editorState.transaction
  ..insertNode([path], imageNode(url: url));
await editorState.apply(transaction);
```

## Image Source (url)

The `url` field accepts:
- A URL string (http/https)
- A base64 string (web)
- For local files, use the absolute path as url

The image block component uses `url` directly to render the image.

## Block Structure

- Type: `image`
- No `delta` (unlike text blocks)
- No children required
- The `validate` check: `node.delta == null && node.children.isEmpty`

## WARNING

When using `EditorState.transaction`, the `insertNode` path must be a valid index path
(e.g., `[0, 2]` for third child of root's first child). The implement sub-agent should
figure out the correct path — for Phase 1, inserting at the end of the document is acceptable.

## Exports

```dart
export 'image_block_component/image_block_component.dart';    // ImageBlockKeys, imageNode
export 'image_block_component/image_upload_widget.dart';      // ImageUploadWidget
export 'image_block_component/resizable_image.dart';          // ResizableImage
```
