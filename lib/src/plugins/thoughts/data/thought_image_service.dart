import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

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

    final ext = p.extension(image.path).isNotEmpty
        ? p.extension(image.path)
        : '.jpg';
    final savedPath = await _newImagePath(ext);
    await File(image.path).copy(savedPath);

    return savedPath;
  }

  Future<String> saveImageBytes(
    Uint8List bytes, {
    String extension = '.png',
  }) async {
    final savedPath = await _newImagePath(extension);
    await File(savedPath).writeAsBytes(bytes, flush: true);
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

  Future<String> _newImagePath(String extension) async {
    final appDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(p.join(appDir.path, 'thought_images'));
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    final ext = extension.startsWith('.') ? extension : '.$extension';
    final fileName =
        '${DateTime.now().microsecondsSinceEpoch}_${_counter++}$ext';
    return p.join(imagesDir.path, fileName);
  }

  static int _counter = 0;
}
