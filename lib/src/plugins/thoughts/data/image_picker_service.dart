import 'picked_image.dart';

/// 负责从平台选择图片的抽象接口。
///
/// 平台实现使用 [image_picker] 包；测试中可注入 [FakeImagePicker]
/// 返回固定数据，避免依赖平台文件系统。
abstract class ImagePickerService {
  /// 从图库选择一张图片。
  ///
  /// 返回 [PickedImage] 包含图片字节和扩展名；
  /// 用户取消选择时返回 `null`。
  Future<PickedImage?> pickImage();
}
