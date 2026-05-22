import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/picked_image.dart';
import '../../data/thought_content_codec.dart';
import '../../data/thought_image_service.dart';
import '../../providers/thoughts_providers.dart';
import 'package:uni_hub/src/shared/ui/rich_text_editor/rich_text_editor.dart';

final composerProvider = ChangeNotifierProvider<ThoughtComposerController>((ref) {
  return ThoughtComposerController(ref: ref);
});

/// Manages quick composer state and controller lifecycles.
class ThoughtComposerController extends ChangeNotifier {
  final Ref ref;

  late QuillController contentController;
  final tagTextController = TextEditingController();

  final _tagChips = <String>[];
  final _pendingImages = <PickedImage>[];
  final _pendingImagePaths = <String>[];
  bool _hasContent = false;
  bool _isPinned = false;
  bool _isSubmitting = false;

  ThoughtComposerController({required this.ref}) {
    contentController = _createContentController();
  }

  List<String> get tagChips => List.unmodifiable(_tagChips);
  List<PickedImage> get pendingImages => List.unmodifiable(_pendingImages);
  List<String> get pendingImagePaths => List.unmodifiable(_pendingImagePaths);
  bool get isPinned => _isPinned;
  bool get isSubmitting => _isSubmitting;
  bool get canSubmit => _hasContent || _pendingImagePaths.isNotEmpty;

  @override
  void dispose() {
    contentController.dispose();
    tagTextController.dispose();
    super.dispose();
  }

  QuillController _createContentController() {
    return RichTextEditor.createController(
      document: Document(),
      onImagePaste: onPasteImage,
    );
  }

  Future<String> onPasteImage(Uint8List bytes) async {
    final path = await ref.read(thoughtImageServiceProvider).saveImageBytes(bytes);
    _addPendingImage(
      path: path,
      image: PickedImage(bytes: bytes, extension: '.png'),
    );
    return ThoughtContentCodec.imageSourceForPath(path);
  }

  Future<String?> onPickEditorImage() async {
    final result = await _pickAndSaveImage();
    if (result == null) return null;
    return ThoughtContentCodec.imageSourceForPath(result.path);
  }

  Future<void> pickImageForComposer() async {
    final result = await _pickAndSaveImage();
    if (result == null) return;
    _insertImage(result.path);
  }

  Future<_SavedPickedImage?> _pickAndSaveImage() async {
    final picked = await ref.read(imagePickerServiceProvider).pickImage();
    if (picked == null) return null;

    final path = await ref
        .read(imageStorageProvider)
        .saveBytes(picked.bytes, extension: picked.extension);
    _addPendingImage(path: path, image: picked);
    return _SavedPickedImage(path: path, image: picked);
  }

  void _addPendingImage({required String path, PickedImage? image}) {
    if (!_pendingImagePaths.contains(path)) {
      _pendingImagePaths.add(path);
      if (image != null) {
        _pendingImages.add(image);
      }
      syncContentState();
      notifyListeners();
    }
  }

  void onEditorImageAdded(String source) {
    final path = ThoughtContentCodec.imagePathFromSource(source);
    if (path != null) {
      _addPendingImage(path: path);
    }
  }

  void syncContentState() {
    final encoded = ThoughtContentCodec.encodeDocument(contentController.document);
    final hasContent =
        contentController.document.toPlainText().trim().isNotEmpty ||
        ThoughtContentCodec.imagePathsFromStored(encoded).isNotEmpty;
    if (hasContent != _hasContent) {
      _hasContent = hasContent;
      notifyListeners();
    }
  }

  void handleTagInput(String value) {
    if (value.isEmpty) return;
    final shouldCommit = value.endsWith(',') || value.endsWith(' ');
    if (!shouldCommit) return;

    final candidates = value
        .split(RegExp('[, ]+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty);

    var changed = false;
    for (final tag in candidates) {
      if (!_tagChips.contains(tag)) {
        _tagChips.add(tag);
        changed = true;
      }
    }
    tagTextController.clear();
    if (changed) notifyListeners();
  }

  void removeChip(String tag) {
    if (_tagChips.remove(tag)) {
      notifyListeners();
    }
  }

  void togglePin() {
    _isPinned = !_isPinned;
    notifyListeners();
  }

  Future<void> removePendingImage(int index) async {
    final path = _pendingImagePaths[index];
    await ref.read(thoughtImageServiceProvider).deleteImage(path);
    final updatedDocument = ThoughtContentCodec.removeImage(
      contentController.document,
      path,
    );
    contentController.dispose();
    contentController = _createContentController();
    contentController.document = updatedDocument;
    _pendingImagePaths.removeAt(index);
    if (index < _pendingImages.length) {
      _pendingImages.removeAt(index);
    }
    syncContentState();
    notifyListeners();
  }

  Future<void> submit() async {
    final content = ThoughtContentCodec.encodeDocument(contentController.document);
    final hasContent =
        contentController.document.toPlainText().trim().isNotEmpty ||
        ThoughtContentCodec.imagePathsFromStored(content).isNotEmpty;
    if ((!hasContent && _pendingImagePaths.isEmpty) || _isSubmitting) return;

    _isSubmitting = true;
    notifyListeners();
    try {
      final repo = ref.read(thoughtsRepositoryProvider);
      final svc = ref.read(thoughtImageServiceProvider);
      final tags = _tagChips.isNotEmpty ? _tagChips.join(',') : null;
      await repo.createThought(
        content: content,
        tags: tags,
        isPinned: _isPinned,
        imagePaths: ThoughtImageService.encodeImagePaths(
          ThoughtContentCodec.mergeImagePaths(
            ThoughtImageService.encodeImagePaths(_pendingImagePaths),
            content,
            existsChecker: svc.existsSync,
          ),
        ),
      );
      ref.invalidate(thoughtsListProvider);
      clear();
    } finally {
      if (_isSubmitting) {
        _isSubmitting = false;
        notifyListeners();
      }
    }
  }

  void clear() {
    contentController.dispose();
    contentController = _createContentController();
    tagTextController.clear();
    _tagChips.clear();
    _pendingImages.clear();
    _pendingImagePaths.clear();
    _hasContent = false;
    _isPinned = false;
    _isSubmitting = false;
    notifyListeners();
  }

  void _insertImage(String path) {
    final index = contentController.selection.baseOffset;
    final length = contentController.selection.extentOffset - index;
    final safeIndex = index < 0 ? contentController.document.length - 1 : index;
    contentController
      ..skipRequestKeyboard = true
      ..replaceText(
        safeIndex,
        length < 0 ? 0 : length,
        BlockEmbed.image(ThoughtContentCodec.imageSourceForPath(path)),
        null,
      )
      ..moveCursorToPosition(safeIndex + 1);
    syncContentState();
  }
}

class _SavedPickedImage {
  final String path;
  final PickedImage image;

  const _SavedPickedImage({required this.path, required this.image});
}
