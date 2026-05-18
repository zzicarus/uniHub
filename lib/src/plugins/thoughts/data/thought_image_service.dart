import 'dart:convert';
import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ThoughtImageService {
  final ImagePicker _picker = ImagePicker();

  Future<String?> pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
    );
    if (image == null) return null;

    final appDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(p.join(appDir.path, 'thought_images'));
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    final ext = p.extension(image.path).isNotEmpty
        ? p.extension(image.path)
        : '.jpg';
    final fileName = '${DateTime.now().millisecondsSinceEpoch}$ext';
    final savedPath = p.join(imagesDir.path, fileName);
    await File(image.path).copy(savedPath);

    return savedPath;
  }

  Future<void> deleteImage(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<void> deleteImages(List<String> paths) async {
    for (final path in paths) {
      await deleteImage(path);
    }
  }

  static List<String> decodeImagePaths(String? json) {
    if (json == null || json.isEmpty) return [];
    try {
      final list = jsonDecode(json) as List;
      return list.cast<String>();
    } catch (_) {
      return [];
    }
  }

  static String encodeImagePaths(List<String> paths) {
    return jsonEncode(paths);
  }
}
