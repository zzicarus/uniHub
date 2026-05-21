import 'dart:typed_data';

import 'package:uni_hub/src/plugins/thoughts/data/image_picker_service.dart';
import 'package:uni_hub/src/plugins/thoughts/data/picked_image.dart';

/// 用于测试的模拟图片选择器。
///
/// 预设固定返回值，不依赖平台 [image_picker]。
class FakeImagePicker implements ImagePickerService {
  PickedImage? _nextResult;
  bool _shouldReturnNull = false;

  /// 设置下一次 [pickImage] 返回的结果。
  void setResult(Uint8List bytes, String extension) {
    _nextResult = PickedImage(bytes: bytes, extension: extension);
    _shouldReturnNull = false;
  }

  /// 设置下一次 [pickImage] 返回 `null`（模拟用户取消）。
  void setNull() {
    _nextResult = null;
    _shouldReturnNull = true;
  }

  @override
  Future<PickedImage?> pickImage() async {
    if (_shouldReturnNull) return null;
    return _nextResult;
  }
}
