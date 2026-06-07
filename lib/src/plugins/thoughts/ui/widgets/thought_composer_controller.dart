import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' show Document, QuillController;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uni_hub/src/shared/editor/appflowy_document_tools.dart';
import 'package:uni_hub/src/shared/tags/tag_codec.dart';

import '../../data/picked_image.dart';
import '../../data/thought_content_codec.dart';
import '../../data/thought_image_service.dart';
import '../../providers/thoughts_providers.dart';

final composerProvider = ChangeNotifierProvider<ThoughtComposerController>((
  ref,
) {
  return ThoughtComposerController(ref: ref);
});

/// Manages quick composer state for the capture composer.
///
/// Uses a plain [TextEditingController] for text input and saves
/// content as AppFlowy JSON via [ThoughtContentCodec.encodeAppFlowy].
/// No longer depends on QuillController or RichTextEditor.
class ThoughtComposerController extends ChangeNotifier {
  final Ref ref;

  final textController = TextEditingController();

  // ---------------------------------------------------------------------------
  // 标签（由 AppTagInput 管理）
  // ---------------------------------------------------------------------------

  Set<String> _tags = {};

  Set<String> get tags => _tags;

  void setTags(Set<String> tags) {
    _tags = tags;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // 图片
  // ---------------------------------------------------------------------------

  final _pendingImagePaths = <String>[];

  List<String> get pendingImagePaths => List.unmodifiable(_pendingImagePaths);

  // ---------------------------------------------------------------------------
  // 置顶
  // ---------------------------------------------------------------------------

  bool _isPinned = false;
  bool get isPinned => _isPinned;

  // ---------------------------------------------------------------------------
  // 提交状态
  // ---------------------------------------------------------------------------

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  /// 是否可以提交：文本非空或图片非空。
  bool get canSubmit =>
      textController.text.trim().isNotEmpty || _pendingImagePaths.isNotEmpty;

  ThoughtComposerController({required this.ref});

  @override
  void dispose() {
    textController.dispose();
    contentController.dispose();
    tagTextController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // 图片操作
  // ---------------------------------------------------------------------------

  /// 为 Composer 选择并添加图片（只加入 pending 列表，不插入文档）。
  Future<void> pickImageForComposer() async {
    final picked = await ref.read(imagePickerServiceProvider).pickImage();
    if (picked == null) return;

    final storage = await ref.read(imageStorageProvider.future);
    final path = await storage.saveBytes(
      picked.bytes,
      extension: picked.extension,
    );

    if (!_pendingImagePaths.contains(path)) {
      _pendingImagePaths.add(path);
      _pendingImages.add(picked);
      notifyListeners();
    }
  }

  /// 移除 pending 图片。
  Future<void> removePendingImage(int index) async {
    if (index < 0 || index >= _pendingImagePaths.length) return;
    final path = _pendingImagePaths[index];
    final svc = await ref.read(thoughtImageServiceProvider.future);
    await svc.deleteImage(path);
    _pendingImagePaths.removeAt(index);
    if (index < _pendingImages.length) {
      _pendingImages.removeAt(index);
    }
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // 置顶
  // ---------------------------------------------------------------------------

  void togglePin() {
    _isPinned = !_isPinned;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // 提交
  // ---------------------------------------------------------------------------

  /// 提交想法：保存为 AppFlowy JSON 格式。
  Future<void> submit() async {
    final text = textController.text.trim();
    if (text.isEmpty && _pendingImagePaths.isEmpty) return;
    if (_isSubmitting) return;

    _isSubmitting = true;
    notifyListeners();

    try {
      // Build the AppFlowy document JSON.
      final documentJson =
          AppFlowyDocumentTools.documentJsonFromPlainText(text);
      final encoded = ThoughtContentCodec.encodeAppFlowy(
        document: documentJson,
        plainText: text,
      );

      final repo = ref.read(thoughtsRepositoryProvider);
      final svc = await ref.read(thoughtImageServiceProvider.future);

      // Encode tags.
      final tags = TagCodec.encodeCommaSeparated(_tags);

      // Merge pending image paths.
      final mergedPaths =
          _pendingImagePaths.where(svc.existsSync).toList();
      final imagePaths = ThoughtImageService.encodeImagePaths(mergedPaths);

      await repo.createThought(
        content: encoded,
        tags: tags,
        isPinned: _isPinned,
        imagePaths: imagePaths,
      );

      ref.invalidate(allThoughtsProvider);
      clear();
    } finally {
      if (_isSubmitting) {
        _isSubmitting = false;
        notifyListeners();
      }
    }
  }

  /// 清空 Composer 状态。
  void clear() {
    textController.clear();
    _tags = {};
    _pendingImagePaths.clear();
    _pendingImages.clear();
    _isPinned = false;
    _isSubmitting = false;
    notifyListeners();

    // Sync deprecated state.
    _syncDeprecatedState();
  }

  // ---------------------------------------------------------------------------
  // 已废弃 — 为旧 composer widget 和 mobile layout 兼容保留
  // ---------------------------------------------------------------------------

  @Deprecated('Use textController instead')
  late QuillController contentController = QuillController(
    document: Document(),
    selection: const TextSelection.collapsed(offset: 0),
  );

  @Deprecated('Use tags / setTags instead')
  final tagTextController = TextEditingController();

  @Deprecated('Use tags instead')
  List<String> get tagChips => _tags.toList();

  @Deprecated('Use tags instead')
  String? tagErrorMessage;

  @Deprecated('Use setTags instead')
  final _pendingImages = <PickedImage>[];

  @Deprecated('Use tags / setTags instead')
  List<PickedImage> get pendingImages => List.unmodifiable(_pendingImages);

  @Deprecated('Use setTags instead')
  void handleTagInput(String value) {
    if (value.isEmpty) {
      tagErrorMessage = null;
      notifyListeners();
      return;
    }
    final shouldCommit = value.endsWith(',') || value.endsWith(' ');
    if (!shouldCommit) return;

    final candidates = value
        .split(RegExp('[, ]+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty);

    for (final tag in candidates) {
      final validation = TagCodec.validate(tag);
      if (!validation.isValid) {
        tagErrorMessage = validation.message;
        notifyListeners();
        break;
      }
      if (!_tags.contains(tag)) {
        tagErrorMessage = null;
        _tags = {..._tags, tag};
        notifyListeners();
      }
    }
    tagTextController.clear();
    if (tagErrorMessage != null) notifyListeners();
  }

  @Deprecated('Use setTags instead')
  void removeChip(String tag) {
    _tags = {..._tags}..remove(tag);
    notifyListeners();
  }

  @Deprecated('Use pickImageForComposer instead')
  Future<String?> onPickEditorImage() async {
    final picked = await ref.read(imagePickerServiceProvider).pickImage();
    if (picked == null) return null;
    final storage = await ref.read(imageStorageProvider.future);
    final path = await storage.saveBytes(
      picked.bytes,
      extension: picked.extension,
    );
    return path;
  }

  @Deprecated('Use pickImageForComposer instead')
  Future<String> onPasteImage(Uint8List bytes) async {
    final svc = await ref.read(thoughtImageServiceProvider.future);
    final path = await svc.saveImageBytes(bytes);
    return path;
  }

  @Deprecated('Use pickImageForComposer instead')
  void onEditorImageAdded(String source) {
    // No-op: images are managed via pickImageForComposer.
  }

  @Deprecated('No longer needed')
  void syncContentState() {
    // No-op: content state is real-time via textController.
  }

  /// Syncs deprecated state to match primary state.
  void _syncDeprecatedState() {
    // Clear tagTextController contents.
    tagTextController.clear();
    tagErrorMessage = null;
  }
}
