// ignore_for_file: experimental_member_use

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../data/thought_content_codec.dart';
import '../../data/thought_image_service.dart';

class ThoughtRichEditor extends StatefulWidget {
  final QuillController controller;
  final ThoughtImageService imageService;
  final ValueChanged<Document>? onChanged;
  final ValueChanged<String>? onImageAdded;
  final double minHeight;
  final String placeholder;
  final bool showToolbar;
  final EdgeInsetsGeometry padding;
  final bool expands;

  const ThoughtRichEditor({
    required this.controller,
    required this.imageService,
    this.onChanged,
    this.onImageAdded,
    this.minHeight = 180,
    this.placeholder = '记录你的想法...',
    this.showToolbar = true,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.expands = false,
    super.key,
  });

  static QuillController createController({
    required Document document,
    required Future<String?> Function(Uint8List imageBytes) onImagePaste,
  }) {
    return QuillController(
      document: document,
      selection: const TextSelection.collapsed(offset: 0),
      config: QuillControllerConfig(
        clipboardConfig: QuillClipboardConfig(onImagePaste: onImagePaste),
      ),
    );
  }

  @override
  State<ThoughtRichEditor> createState() => _ThoughtRichEditorState();
}

class _ThoughtRichEditorState extends State<ThoughtRichEditor> {
  StreamSubscription<DocChange>? _changes;
  int? _lastMarkdownShortcutHash;

  @override
  void initState() {
    super.initState();
    _listenToController();
  }

  @override
  void didUpdateWidget(covariant ThoughtRichEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _changes?.cancel();
      _listenToController();
    }
  }

  @override
  void dispose() {
    _changes?.cancel();
    super.dispose();
  }

  void _listenToController() {
    _changes = widget.controller.document.changes.listen((_) {
      widget.onChanged?.call(widget.controller.document);
      _applyMarkdownShortcut();
    });
  }

  Future<void> _insertPickedImage() async {
    final path = await widget.imageService.pickImage();
    if (path == null) return;
    _insertImage(path);
  }

  void _insertImage(String path) {
    final index = widget.controller.selection.baseOffset;
    final length = widget.controller.selection.extentOffset - index;
    final safeIndex = index < 0 ? widget.controller.document.length - 1 : index;
    widget.controller
      ..skipRequestKeyboard = true
      ..replaceText(
        safeIndex,
        length < 0 ? 0 : length,
        BlockEmbed.image(ThoughtContentCodec.imageSourceForPath(path)),
        null,
      )
      ..moveCursorToPosition(safeIndex + 1);
    widget.onImageAdded?.call(path);
    widget.onChanged?.call(widget.controller.document);
  }

  void _applyMarkdownShortcut() {
    final selection = widget.controller.selection;
    if (!selection.isCollapsed || selection.baseOffset < 1) return;

    final text = widget.controller.document.toPlainText();
    final offset = selection.baseOffset;
    if (offset > text.length || text[offset - 1] != ' ') return;

    final lineStart = text.lastIndexOf('\n', offset - 2) + 1;
    final marker = text.substring(lineStart, offset);
    final markerHash = Object.hash(lineStart, marker, offset);
    if (_lastMarkdownShortcutHash == markerHash) return;

    Attribute<dynamic>? attribute;
    var removeLength = 0;
    switch (marker) {
      case '# ':
        attribute = Attribute.h1;
        removeLength = 2;
        break;
      case '## ':
        attribute = Attribute.h2;
        removeLength = 3;
        break;
      case '### ':
        attribute = Attribute.h3;
        removeLength = 4;
        break;
      case '- ':
        attribute = Attribute.ul;
        removeLength = 2;
        break;
      case '1. ':
        attribute = Attribute.ol;
        removeLength = 3;
        break;
      case '> ':
        attribute = Attribute.blockQuote;
        removeLength = 2;
        break;
    }
    if (attribute == null) return;

    _lastMarkdownShortcutHash = markerHash;
    widget.controller
      ..replaceText(lineStart, removeLength, '', null)
      ..formatSelection(attribute)
      ..moveCursorToPosition(lineStart);
    widget.onChanged?.call(widget.controller.document);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final toolbar = QuillSimpleToolbar(
      controller: widget.controller,
      config: QuillSimpleToolbarConfig(
        multiRowsDisplay: false,
        showFontFamily: false,
        showFontSize: false,
        showSmallButton: false,
        showUnderLineButton: false,
        showStrikeThrough: false,
        showInlineCode: false,
        showColorButton: false,
        showBackgroundColorButton: false,
        showAlignmentButtons: false,
        showSubscript: false,
        showSuperscript: false,
        showDirection: false,
        showSearchButton: false,
        showLink: false,
        showIndent: false,
        embedButtons: [
          (context, embedContext) => IconButton(
            icon: const Icon(Icons.image_outlined, size: 20),
            tooltip: '插入图片',
            onPressed: _insertPickedImage,
          ),
        ],
      ),
    );

    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyV):
            const PasteTextIntent(SelectionChangedCause.keyboard),
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.showToolbar) ...[
            Container(
              height: 42,
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                border: Border(
                  bottom: BorderSide(color: colorScheme.outlineVariant),
                ),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: toolbar,
              ),
            ),
          ],
          if (widget.expands)
            Expanded(
              child: Container(
                padding: widget.padding,
                child: QuillEditor.basic(
                  controller: widget.controller,
                  config: QuillEditorConfig(
                    placeholder: widget.placeholder,
                    autoFocus: false,
                    expands: true,
                    padding: EdgeInsets.zero,
                    embedBuilders: FlutterQuillEmbeds.editorBuilders(
                      videoEmbedConfig: null,
                    ),
                  ),
                ),
              ),
            )
          else
            Container(
              constraints: BoxConstraints(minHeight: widget.minHeight),
              padding: widget.padding,
              child: QuillEditor.basic(
                controller: widget.controller,
                config: QuillEditorConfig(
                  placeholder: widget.placeholder,
                  autoFocus: false,
                  expands: false,
                  padding: EdgeInsets.zero,
                  embedBuilders: FlutterQuillEmbeds.editorBuilders(
                    videoEmbedConfig: null,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
