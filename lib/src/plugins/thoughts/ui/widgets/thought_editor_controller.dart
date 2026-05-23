/// 集中管理想法编辑器的全部业务状态与操作。
///
/// 供 [ThoughtsEditorPage]、[ThoughtEditorWorkspace] 共用。
///
/// 状态模型已从 QuillController + Delta 迁移为 AppFlowy documentJson + plainText。
///
/// # 迁移说明
///
/// - `contentController`（QuillController）已废弃，保留仅用于兼容旧 widget。
/// - 新的编辑器状态由 `documentJson` 和 `plainText` 字段管理。
/// - `save()` 使用 `ThoughtContentCodec.encodeAppFlowy()` 持久化。
/// - 标签、颜色、图片路径、置顶、归档等独立字段保持不变。
library;

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' show Document, QuillController;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/thought_content_codec.dart';
import '../../data/thought_image_service.dart';
import '../../providers/thoughts_providers.dart';
import 'package:uni_hub/src/shared/editor/appflowy_document_tools.dart';
import 'package:uni_hub/src/shared/tags/tag_codec.dart';

class ThoughtEditorController {
  final WidgetRef ref;
  final int thoughtId;

  /// 自动保存间隔；为 `null` 时不启用 debounce 自动保存。
  final Duration? autoSaveInterval;

  /// 状态变化时由 widget 注册的回调（用于触发 `setState`）。
  final VoidCallback? onStateChanged;

  /// 已废弃 — 为兼容旧 widget 保留。
  ///
  /// 新代码不应依赖此字段。后续删除旧 widget 后清除。
  @Deprecated('Use documentJson / plainText instead')
  late QuillController contentController;

  // -----------------------------------------------------------------------
  // AppFlowy document 状态（新）
  // -----------------------------------------------------------------------

  /// 当前 AppFlowy 文档 JSON。
  ///
  /// 由 [AppFlowyThoughtEditor] 或 [updateDocument] 更新。
  /// 在 `save()` 中通过 [ThoughtContentCodec.encodeAppFlowy] 持久化。
  Map<String, dynamic>? documentJson;

  /// 当前文档的纯文本。
  ///
  /// 用于列表标题、摘要、搜索，避免每次从 document JSON 解析。
  String plainText = '';

  // -----------------------------------------------------------------------
  // 标签状态（新：Set<String>，由 AppTagInput 管理）
  // -----------------------------------------------------------------------

  Set<String> _tags = {};

  /// 当前标签集合（已 normalize）。
  Set<String> get tags => _tags;

  /// 由 [AppTagInput.onChanged] 回调调用。
  void setTags(Set<String> tags) {
    _tags = tags;
    markDirty();
  }

  // -----------------------------------------------------------------------
  // 标签状态（旧，已废弃 — 为旧 widget 兼容保留）
  // -----------------------------------------------------------------------

  @Deprecated('Use tags / setTags instead')
  final tagTextController = TextEditingController();

  @Deprecated('Use tags / setTags instead')
  List<String> get tagChips => _tags.toList();

  @Deprecated('Use tags / setTags instead')
  String? tagErrorMessage;

  // -----------------------------------------------------------------------
  // 图片、颜色、置顶、归档
  // -----------------------------------------------------------------------

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

  /// 初始化（兼容旧 widget 的 initState 用法）。
  ///
  /// 创建一个空的 QuillController 用于旧 widget 占位。
  /// 新状态通过 [load] 从数据库填充。
  void initialize() {
    contentController = QuillController(
      document: Document(),
      selection: const TextSelection.collapsed(offset: 0),
    );
  }

  /// 释放资源；应在 widget [dispose] 中调用。
  void dispose() {
    _autoSaveTimer?.cancel();
    contentController.dispose();
    tagTextController.dispose();
  }

  /// 通知状态变化。
  void _notifyStateChanged() {
    onStateChanged?.call();
  }

  /// 视配置触发 debounce 自动保存。
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

  // -----------------------------------------------------------------------
  // load / save
  // -----------------------------------------------------------------------

  /// 从数据库加载 thought 数据。
  Future<void> load() async {
    if (isLoaded) return;
    final thought = await ref.read(thoughtProvider(thoughtId).future);
    if (thought == null || isLoaded) return;

    // 加载 AppFlowy document 状态。
    documentJson =
        ThoughtContentCodec.documentJsonFromStored(thought.content);
    plainText = ThoughtContentCodec.plainTextFromStored(thought.content);
    documentJson ??= AppFlowyDocumentTools.emptyDocumentJson();

    // 加载标签。
    _tags = TagCodec.parseCommaSeparated(thought.tags).toSet();

    // 加载图片。
    final storedImagePaths =
        ThoughtImageService.decodeImagePaths(thought.imagePaths);
    images.addAll(storedImagePaths);

    selectedColor = thought.color;
    isPinned = thought.isPinned;
    isArchived = thought.archivedAt != null;
    tagErrorMessage = null;
    isLoaded = true;
    isDirty = false;
    _notifyStateChanged();
  }

  /// 保存当前编辑内容到数据库。
  Future<void> save() async {
    if (!isDirty || !isLoaded) return;

    final repo = ref.read(thoughtsRepositoryProvider);
    final tags = TagCodec.encodeCommaSeparated(_tags);

    await repo.updateThought(
      thoughtId,
      content: ThoughtContentCodec.encodeAppFlowy(
        document: documentJson ?? AppFlowyDocumentTools.emptyDocumentJson(),
        plainText: plainText,
      ),
      tags: tags,
      color: selectedColor,
      isPinned: isPinned,
      imagePaths: ThoughtImageService.encodeImagePaths(images),
    );

    ref.invalidate(thoughtProvider(thoughtId));
    ref.invalidate(allThoughtsProvider);
    isDirty = false;
    _notifyStateChanged();
  }

  // -----------------------------------------------------------------------
  // 更新 document（由 AppFlowyThoughtEditor 的 onChanged 调用）
  // -----------------------------------------------------------------------

  /// 由 [AppFlowyThoughtEditor.onChanged] 回调调用。
  ///
  /// 更新 [documentJson] 和 [plainText] 后自动标记 dirty。
  void updateDocument({
    required Map<String, dynamic> documentJson,
    required String plainText,
  }) {
    this.documentJson = documentJson;
    this.plainText = plainText;
    markDirty();
  }

  // -----------------------------------------------------------------------
  // 删除 / 归档 / 恢复 / 置顶
  // -----------------------------------------------------------------------

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
      ref.invalidate(allThoughtsProvider);
    }
  }

  /// 归档当前 thought。
  Future<void> archive() async {
    final repo = ref.read(thoughtsRepositoryProvider);
    await repo.archiveThought(thoughtId);
    ref.invalidate(allThoughtsProvider);
  }

  /// 恢复当前 thought。
  Future<void> restore() async {
    final repo = ref.read(thoughtsRepositoryProvider);
    await repo.restoreThought(thoughtId);
    ref.invalidate(allThoughtsProvider);
    isArchived = false;
    isDirty = false;
    _notifyStateChanged();
  }

  /// 切换置顶状态。
  void togglePin(bool value) {
    isPinned = value;
    markDirty();
  }

  // -----------------------------------------------------------------------
  // 标签操作
  // -----------------------------------------------------------------------

  @Deprecated('Use setTags instead')
  void handleTagInput(String value) {
    // Delegate to TagCodec-based logic via tagTextController.
    if (value.isEmpty) {
      tagErrorMessage = null;
      _notifyStateChanged();
      return;
    }
    final delimiter = value.contains(',') ? ',' : ' ';
    if (value.endsWith(delimiter)) {
      final tag = value.substring(0, value.length - 1).trim();
      if (tag.isNotEmpty) {
        final validation = TagCodec.validate(tag);
        if (!validation.isValid) {
          tagErrorMessage = validation.message;
          _notifyStateChanged();
        } else if (!_tags.contains(tag)) {
          _tags = {..._tags, tag};
          tagErrorMessage = null;
          isDirty = true;
          _notifyStateChanged();
        }
      }
      tagTextController.clear();
      _scheduleAutoSave();
    }
  }

  @Deprecated('Use setTags instead')
  void removeChip(String tag) {
    _tags = {..._tags}..remove(tag);
    markDirty();
  }

  // -----------------------------------------------------------------------
  // 颜色操作
  // -----------------------------------------------------------------------

  /// 设置想法颜色。
  void setColor(String? color) {
    selectedColor = color;
    markDirty();
  }

  // -----------------------------------------------------------------------
  // 图片操作（AppFlowy image block 暂不实现）
  // -----------------------------------------------------------------------

  /// 已废弃 — 供旧 [RichTextEditor] 回调使用。
  ///
  /// 新编辑器不依赖此方法。
  @Deprecated('Use addImage instead')
  Future<String?> onPickImage() async {
    final path = await ref.read(thoughtImageServiceProvider).pickImage();
    return path;
  }

  /// 已废弃 — 供旧 [RichTextEditor] 回调使用。
  @Deprecated('Use addImage instead')
  Future<String?> onPasteImage(Uint8List bytes) async {
    final path = await ref
        .read(thoughtImageServiceProvider)
        .saveImageBytes(bytes);
    return path;
  }

  /// 已废弃 — 供旧 [RichTextEditor] 回调使用。
  @Deprecated('Use addImage instead')
  void onEditorImageAdded(String source) {
    // 不再处理 Quill image embed。
  }

  /// 显式添加图片到 images 列表。
  ///
  /// 第一阶段只保存到 imagePaths 独立字段，不插入 AppFlowy image block。
  Future<void> addImage() async {
    final svc = ref.read(thoughtImageServiceProvider);
    final path = await svc.pickImage();
    if (path != null) {
      images.add(path);
      markDirty();
    }
  }

  /// 从 images 列表中移除指定索引的图片。
  ///
  /// 只删除图片文件和 images 列表，不操作 document block。
  Future<void> removeImage(int index) async {
    if (index < 0 || index >= images.length) return;
    final path = images[index];
    await ref.read(thoughtImageServiceProvider).deleteImage(path);
    images.removeAt(index);
    isDirty = true;
    _notifyStateChanged();
    _scheduleAutoSave();
  }
}
