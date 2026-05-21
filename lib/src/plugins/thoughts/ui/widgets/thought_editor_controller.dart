import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/thought_content_codec.dart';
import '../../data/thought_image_service.dart';
import '../../providers/thoughts_providers.dart';
import 'package:uni_hub/src/shared/ui/rich_text_editor/rich_text_editor.dart';

/// 集中管理想法编辑器的全部业务状态与操作。
///
/// 供 [ThoughtsEditorPage] 与 [ThoughtEditorDrawer] 共用，
/// 避免 save / delete / archive / tag / color / image 逻辑分叉。
class ThoughtEditorController {
  final WidgetRef ref;
  final int thoughtId;

  /// 自动保存间隔；为 `null` 时不启用 debounce 自动保存。
  final Duration? autoSaveInterval;

  /// 状态变化时由 widget 注册的回调（用于触发 `setState`）。
  final VoidCallback? onStateChanged;

  late QuillController contentController;
  final tagTextController = TextEditingController();
  final tagChips = <String>[];
  final images = <String>[];
  String? selectedColor;
  bool isPinned = false;
  bool isArchived = false;
  bool isDirty = false;
  bool isLoaded = false;

  Timer? _autoSaveTimer;

  ThoughtEditorController({
    required this.ref,
    required this.thoughtId,
    this.autoSaveInterval,
    this.onStateChanged,
  });

  /// 初始化 QuillController；应在 widget [initState] 中调用。
  void initialize() {
    contentController = _createController(Document());
  }

  /// 释放资源；应在 widget [dispose] 中调用。
  void dispose() {
    _autoSaveTimer?.cancel();
    contentController.dispose();
    tagTextController.dispose();
  }

  QuillController _createController(Document document) {
    return RichTextEditor.createController(
      document: document,
      onImagePaste: (bytes) async {
        final path = await ref
            .read(thoughtImageServiceProvider)
            .saveImageBytes(bytes);
        final source = ThoughtContentCodec.imageSourceForPath(path);
        final parsedPath = ThoughtContentCodec.imagePathFromSource(source);
        if (parsedPath != null && !images.contains(parsedPath)) {
          images.add(parsedPath);
          _notifyStateChanged();
        }
        markDirty();
        return source;
      },
    );
  }

  void _notifyStateChanged() {
    onStateChanged?.call();
  }

  void _scheduleAutoSave() {
    if (autoSaveInterval == null) return;
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(autoSaveInterval!, save);
  }

  /// 标记为 dirty，并视配置触发 debounce 自动保存。
  void markDirty() {
    if (!isDirty) {
      isDirty = true;
      _notifyStateChanged();
    }
    _scheduleAutoSave();
  }

  /// 从数据库加载 thought 数据。
  Future<void> load() async {
    if (isLoaded) return;
    final thought = await ref.read(thoughtProvider(thoughtId).future);
    if (thought == null || isLoaded) return;
    final controller = _createController(
      ThoughtContentCodec.documentFromStored(thought.content),
    );
    contentController.dispose();
    contentController = controller;
    tagChips.addAll(
      (thought.tags ?? '')
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty),
    );
    final svc = ref.read(thoughtImageServiceProvider);
    images.addAll(
      ThoughtContentCodec.mergeImagePaths(
        thought.imagePaths,
        thought.content,
        existsChecker: svc.existsSync,
      ),
    );
    selectedColor = thought.color;
    isPinned = thought.isPinned;
    isArchived = thought.archivedAt != null;
    isLoaded = true;
    isDirty = false;
    _notifyStateChanged();
  }

  /// 保存当前编辑内容到数据库。
  Future<void> save() async {
    if (!isDirty || !isLoaded) return;
    final repo = ref.read(thoughtsRepositoryProvider);
    final tags = tagChips.isNotEmpty ? tagChips.join(',') : null;
    await repo.updateThought(
      thoughtId,
      content: ThoughtContentCodec.encodeDocument(contentController.document),
      tags: tags,
      color: selectedColor,
      isPinned: isPinned,
      imagePaths: ThoughtImageService.encodeImagePaths(images),
    );
    ref.invalidate(thoughtProvider(thoughtId));
    ref.invalidate(thoughtsListProvider);
    isDirty = false;
    _notifyStateChanged();
  }

  /// 删除当前 thought（含确认弹窗）。
  Future<void> delete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除想法'),
        content: const Text('确定要删除这条想法吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(thoughtImageServiceProvider).deleteImages(images);
      await ref.read(thoughtsRepositoryProvider).deleteThought(thoughtId);
      ref.invalidate(thoughtsListProvider);
    }
  }

  /// 归档当前 thought。
  Future<void> archive() async {
    final repo = ref.read(thoughtsRepositoryProvider);
    await repo.archiveThought(thoughtId);
    ref.invalidate(thoughtsListProvider);
  }

  /// 恢复当前 thought。
  Future<void> restore() async {
    final repo = ref.read(thoughtsRepositoryProvider);
    await repo.restoreThought(thoughtId);
    ref.invalidate(thoughtsListProvider);
    isArchived = false;
    isDirty = false;
    _notifyStateChanged();
  }

  /// 切换置顶状态。
  void togglePin(bool value) {
    isPinned = value;
    isDirty = true;
    _notifyStateChanged();
    _scheduleAutoSave();
  }

  /// 处理标签输入（空格或逗号分隔）。
  void handleTagInput(String value) {
    final delimiter = value.contains(',') ? ',' : ' ';
    if (value.endsWith(delimiter)) {
      final tag = value.substring(0, value.length - 1).trim();
      if (tag.isNotEmpty && !tagChips.contains(tag)) {
        tagChips.add(tag);
        isDirty = true;
        _notifyStateChanged();
      }
      tagTextController.clear();
      _scheduleAutoSave();
    }
  }

  /// 移除一个标签 chip。
  void removeChip(String tag) {
    tagChips.remove(tag);
    isDirty = true;
    _notifyStateChanged();
    _scheduleAutoSave();
  }

  /// 设置想法颜色。
  void setColor(String? color) {
    selectedColor = color;
    isDirty = true;
    _notifyStateChanged();
    _scheduleAutoSave();
  }

  /// 供 [RichTextEditor.onPickImage] 回调使用。
  Future<String?> onPickImage() async {
    final path = await ref.read(thoughtImageServiceProvider).pickImage();
    return path != null
        ? ThoughtContentCodec.imageSourceForPath(path)
        : null;
  }

  /// 供 [RichTextEditor.onPasteImage] 回调使用。
  Future<String?> onPasteImage(Uint8List bytes) async {
    final path = await ref.read(thoughtImageServiceProvider).saveImageBytes(bytes);
    return ThoughtContentCodec.imageSourceForPath(path);
  }

  /// 供 [RichTextEditor.onImageAdded] 回调使用。
  void onEditorImageAdded(String source) {
    final path = ThoughtContentCodec.imagePathFromSource(source);
    if (path != null && !images.contains(path)) {
      images.add(path);
      _notifyStateChanged();
    }
  }

  /// 显式添加图片（供抽屉编辑器的 "添加" 按钮使用）。
  Future<void> addImage() async {
    final svc = ref.read(thoughtImageServiceProvider);
    final path = await svc.pickImage();
    if (path != null) {
      images.add(path);
      _insertImage(path);
      markDirty();
    }
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
  }

  /// 移除指定索引的图片。
  Future<void> removeImage(int index) async {
    final path = images[index];
    await ref.read(thoughtImageServiceProvider).deleteImage(path);
    final updatedDocument = ThoughtContentCodec.removeImage(
      contentController.document,
      path,
    );
    contentController.dispose();
    contentController = _createController(updatedDocument);
    images.removeAt(index);
    isDirty = true;
    _notifyStateChanged();
  }
}
