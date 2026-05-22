import 'dart:typed_data';

/// 从图库选择的图片数据。
class PickedImage {
  final Uint8List bytes;
  final String extension;

  const PickedImage({required this.bytes, required this.extension});
}
