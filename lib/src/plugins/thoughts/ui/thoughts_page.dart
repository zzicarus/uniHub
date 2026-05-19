import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../shared/widgets/adaptive_layout.dart';
import '../data/thought_content_codec.dart';
import '../data/thought_image_service.dart';
import '../providers/thoughts_providers.dart';
import 'layouts/thoughts_desktop_layout.dart';
import 'layouts/thoughts_mobile_layout.dart';
import 'widgets/thought_editor_drawer.dart';
import 'widgets/thought_rich_editor.dart';

class ThoughtsPage extends ConsumerStatefulWidget {
  const ThoughtsPage({super.key});

  @override
  ConsumerState<ThoughtsPage> createState() => _ThoughtsPageState();
}

class _ThoughtsPageState extends ConsumerState<ThoughtsPage> {
  late QuillController _contentController;
  final _tagTextController = TextEditingController();
  final _tagChips = <String>[];
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isSubmitting = false;
  bool _hasContent = false;
  bool _isPinned = false;
  int? _selectedThoughtId;
  final _pendingImages = <String>[];

  @override
  void initState() {
    super.initState();
    _contentController = _createContentController();
  }

  @override
  void dispose() {
    _contentController.dispose();
    _tagTextController.dispose();
    super.dispose();
  }

  QuillController _createContentController() {
    return ThoughtRichEditor.createController(
      document: Document(),
      onImagePaste: (bytes) async {
        final path = await ref
            .read(thoughtImageServiceProvider)
            .saveImageBytes(bytes);
        if (mounted) {
          setState(() => _pendingImages.add(path));
        }
        return ThoughtContentCodec.imageSourceForPath(path);
      },
    );
  }

  void _syncContentState() {
    final encoded = ThoughtContentCodec.encodeDocument(
      _contentController.document,
    );
    final hasContent =
        _contentController.document.toPlainText().trim().isNotEmpty ||
        ThoughtContentCodec.imagePathsFromStored(encoded).isNotEmpty;
    if (hasContent != _hasContent) {
      setState(() => _hasContent = hasContent);
    }
  }

  void _handleTagInput(String value) {
    if (value.isEmpty) return;
    final shouldCommit = value.endsWith(',') || value.endsWith(' ');
    if (!shouldCommit) return;

    final candidates = value
        .split(RegExp('[, ]+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty);

    setState(() {
      for (final tag in candidates) {
        if (!_tagChips.contains(tag)) {
          _tagChips.add(tag);
        }
      }
    });
    _tagTextController.clear();
  }

  void _removeChip(String tag) {
    setState(() {
      _tagChips.remove(tag);
    });
  }

  Future<void> _pickImageForComposer() async {
    final svc = ref.read(thoughtImageServiceProvider);
    final path = await svc.pickImage();
    if (path != null) {
      setState(() => _pendingImages.add(path));
      _insertImage(_contentController, path);
    }
  }

  void _removePendingImage(int index) {
    final path = _pendingImages[index];
    ref.read(thoughtImageServiceProvider).deleteImage(path);
    final updatedDocument = ThoughtContentCodec.removeImage(
      _contentController.document,
      path,
    );
    _contentController.dispose();
    _contentController = _createContentController();
    _contentController.document = updatedDocument;
    setState(() => _pendingImages.removeAt(index));
    _syncContentState();
  }

  Future<void> _submit() async {
    final content = ThoughtContentCodec.encodeDocument(
      _contentController.document,
    );
    final hasContent =
        _contentController.document.toPlainText().trim().isNotEmpty ||
        ThoughtContentCodec.imagePathsFromStored(content).isNotEmpty;
    if (!hasContent || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      final repo = ref.read(thoughtsRepositoryProvider);
      final tags = _tagChips.isNotEmpty ? _tagChips.join(',') : null;
      await repo.createThought(
        content: content,
        tags: tags,
        isPinned: _isPinned,
        imagePaths: ThoughtImageService.encodeImagePaths(
          ThoughtContentCodec.mergeImagePaths(
            ThoughtImageService.encodeImagePaths(_pendingImages),
            content,
          ),
        ),
      );
      ref.invalidate(thoughtsListProvider);
      _contentController.dispose();
      _contentController = _createContentController();
      if (mounted) {
        setState(() {
          _tagChips.clear();
          _hasContent = false;
          _isPinned = false;
          _pendingImages.clear();
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _insertImage(QuillController controller, String path) {
    final index = controller.selection.baseOffset;
    final length = controller.selection.extentOffset - index;
    final safeIndex = index < 0 ? controller.document.length - 1 : index;
    controller
      ..skipRequestKeyboard = true
      ..replaceText(
        safeIndex,
        length < 0 ? 0 : length,
        BlockEmbed.image(ThoughtContentCodec.imageSourceForPath(path)),
        null,
      )
      ..moveCursorToPosition(safeIndex + 1);
    _syncContentState();
  }

  void _openEditor(int id) {
    setState(() => _selectedThoughtId = id);
    _scaffoldKey.currentState?.openEndDrawer();
  }

  Future<void> _quickArchive(int id) async {
    final repo = ref.read(thoughtsRepositoryProvider);
    await repo.archiveThought(id);
    ref.invalidate(thoughtsListProvider);
  }

  Future<void> _quickRestore(int id) async {
    final repo = ref.read(thoughtsRepositoryProvider);
    await repo.restoreThought(id);
    ref.invalidate(thoughtsListProvider);
  }

  void _setTagFilter(String? tag) {
    ref.read(tagFilterProvider.notifier).state = tag;
  }

  @override
  Widget build(BuildContext context) {
    final thoughtsAsync = ref.watch(thoughtsListProvider);
    final isArchived = ref.watch(archiveFilterProvider);
    final tagStats = ref.watch(tagStatsProvider);
    final selectedTag = ref.watch(tagFilterProvider);
    final colorScheme = Theme.of(context).colorScheme;

    final layoutParams = _LayoutParams(
      thoughtsAsync: thoughtsAsync,
      isArchived: isArchived,
      contentController: _contentController,
      tagTextController: _tagTextController,
      tagChips: _tagChips,
      isSubmitting: _isSubmitting,
      canSubmit: _hasContent,
      isPinned: _isPinned,
      pendingImages: _pendingImages,
      onSubmit: _submit,
      onTagInput: _handleTagInput,
      onRemoveChip: _removeChip,
      onTogglePin: () => setState(() => _isPinned = !_isPinned),
      onPickImage: _pickImageForComposer,
      onRemoveImage: _removePendingImage,
      imageService: ref.read(thoughtImageServiceProvider),
      onContentChanged: _syncContentState,
      onImageAdded: (path) {
        if (!_pendingImages.contains(path)) {
          setState(() => _pendingImages.add(path));
        }
      },
      onThoughtTap: _openEditor,
      onArchive: _quickArchive,
      onRestore: _quickRestore,
      tagStats: tagStats,
      selectedTag: selectedTag,
      onTagFilterChanged: _setTagFilter,
    );

    return Focus(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.enter &&
            HardwareKeyboard.instance.isControlPressed) {
          _submit();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: colorScheme.surface,
        endDrawer: _selectedThoughtId != null
            ? Drawer(
                width: MediaQuery.of(context).size.width * 0.55,
                child: ThoughtEditorDrawer(
                  thoughtId: _selectedThoughtId!,
                  onClose: () => _scaffoldKey.currentState?.closeEndDrawer(),
                ),
              )
            : null,
        onEndDrawerChanged: (opened) {
          if (!opened && mounted) {
            setState(() => _selectedThoughtId = null);
          }
        },
        body: SafeArea(
          child: AdaptiveLayout(
            mobile: (_) => ThoughtsMobileLayout(
              thoughtsAsync: layoutParams.thoughtsAsync,
              isArchived: layoutParams.isArchived,
              contentController: layoutParams.contentController,
              tagTextController: layoutParams.tagTextController,
              tagChips: layoutParams.tagChips,
              isSubmitting: layoutParams.isSubmitting,
              canSubmit: layoutParams.canSubmit,
              isPinned: layoutParams.isPinned,
              pendingImages: layoutParams.pendingImages,
              onSubmit: layoutParams.onSubmit,
              onTagInput: layoutParams.onTagInput,
              onRemoveChip: layoutParams.onRemoveChip,
              onTogglePin: layoutParams.onTogglePin,
              onPickImage: layoutParams.onPickImage,
              onRemoveImage: layoutParams.onRemoveImage,
              imageService: layoutParams.imageService,
              onContentChanged: layoutParams.onContentChanged,
              onImageAdded: layoutParams.onImageAdded,
              onThoughtTap: layoutParams.onThoughtTap,
              onArchive: layoutParams.onArchive,
              onRestore: layoutParams.onRestore,
              tagStats: layoutParams.tagStats,
              selectedTag: layoutParams.selectedTag,
              onTagFilterChanged: layoutParams.onTagFilterChanged,
            ),
            desktop: (_) => ThoughtsDesktopLayout(
              thoughtsAsync: layoutParams.thoughtsAsync,
              isArchived: layoutParams.isArchived,
              contentController: layoutParams.contentController,
              tagTextController: layoutParams.tagTextController,
              tagChips: layoutParams.tagChips,
              isSubmitting: layoutParams.isSubmitting,
              canSubmit: layoutParams.canSubmit,
              isPinned: layoutParams.isPinned,
              pendingImages: layoutParams.pendingImages,
              onSubmit: layoutParams.onSubmit,
              onTagInput: layoutParams.onTagInput,
              onRemoveChip: layoutParams.onRemoveChip,
              onTogglePin: layoutParams.onTogglePin,
              onPickImage: layoutParams.onPickImage,
              onRemoveImage: layoutParams.onRemoveImage,
              imageService: layoutParams.imageService,
              onContentChanged: layoutParams.onContentChanged,
              onImageAdded: layoutParams.onImageAdded,
              onThoughtTap: layoutParams.onThoughtTap,
              onArchive: layoutParams.onArchive,
              onRestore: layoutParams.onRestore,
              tagStats: layoutParams.tagStats,
              selectedTag: layoutParams.selectedTag,
              onTagFilterChanged: layoutParams.onTagFilterChanged,
            ),
          ),
        ),
      ),
    );
  }
}

/// Bundle of parameters passed to both mobile and desktop layouts.
class _LayoutParams {
  final AsyncValue<List<ThoughtsTableData>> thoughtsAsync;
  final bool isArchived;
  final QuillController contentController;
  final TextEditingController tagTextController;
  final List<String> tagChips;
  final bool isSubmitting;
  final bool canSubmit;
  final bool isPinned;
  final List<String> pendingImages;
  final VoidCallback onSubmit;
  final ValueChanged<String> onTagInput;
  final ValueChanged<String> onRemoveChip;
  final VoidCallback onTogglePin;
  final VoidCallback onPickImage;
  final void Function(int) onRemoveImage;
  final ThoughtImageService imageService;
  final VoidCallback onContentChanged;
  final ValueChanged<String> onImageAdded;
  final void Function(int) onThoughtTap;
  final Future<void> Function(int) onArchive;
  final Future<void> Function(int) onRestore;
  final Map<String, int> tagStats;
  final String? selectedTag;
  final ValueChanged<String?> onTagFilterChanged;

  const _LayoutParams({
    required this.thoughtsAsync,
    required this.isArchived,
    required this.contentController,
    required this.tagTextController,
    required this.tagChips,
    required this.isSubmitting,
    required this.canSubmit,
    required this.isPinned,
    required this.pendingImages,
    required this.onSubmit,
    required this.onTagInput,
    required this.onRemoveChip,
    required this.onTogglePin,
    required this.onPickImage,
    required this.onRemoveImage,
    required this.imageService,
    required this.onContentChanged,
    required this.onImageAdded,
    required this.onThoughtTap,
    required this.onArchive,
    required this.onRestore,
    required this.tagStats,
    required this.selectedTag,
    required this.onTagFilterChanged,
  });
}
