import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

import 'image_picker_service.dart';
import 'picked_image.dart';

/// 使用 [image_picker] 包的平台实现。
class PlatformImagePicker implements ImagePickerService {
  final ImagePicker _picker = ImagePicker();

  @override
  Future<PickedImage?> pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
    );
    if (image == null) return null;

    final bytes = await image.readAsBytes();
    final ext = p.extension(image.path).isNotEmpty
        ? p.extension(image.path)
        : '.jpg';

    return PickedImage(bytes: bytes, extension: ext);
  }
}
