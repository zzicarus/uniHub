/// A reusable tag input widget for adding and managing tags.
///
/// Features:
/// - Shows existing tags as deletable chips.
/// - TextField accepts tags delimited by Enter, comma, Chinese comma, or space.
/// - Strips `#` prefix via [TagCodec.normalize].
/// - Validates each tag via [TagCodec.validate].
/// - Duplicates are silently ignored.
/// - Exceeds [maxTags] shows an error message.
/// - Blur auto-submits pending input.
///
/// ```dart
/// AppTagInput(
///   key: _tagInputKey,
///   tags: currentTags,
///   onChanged: (updated) => setState(() => currentTags = updated),
/// )
/// ```
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../tags/tag_codec.dart';
import 'app_tag_chip.dart';

class AppTagInput extends StatefulWidget {
  const AppTagInput({
    super.key,
    required this.tags,
    required this.onChanged,
    this.hintText = '输入标签后按 Enter',
    this.label,
    this.autofocus = false,
    this.enabled = true,
    this.maxTags = 12,
  });

  /// Current set of tags (normalized, without `#` prefix).
  final Set<String> tags;

  /// Called whenever the tag set changes.
  final ValueChanged<Set<String>> onChanged;

  /// Placeholder text for the input field.
  final String hintText;

  /// Optional label displayed above the tag chips.
  final String? label;

  /// Whether to auto-focus the input field on mount.
  final bool autofocus;

  /// Whether the input is enabled.
  final bool enabled;

  /// Maximum number of tags allowed.
  final int maxTags;

  @override
  State<AppTagInput> createState() => AppTagInputState();
}

class AppTagInputState extends State<AppTagInput> {
  final _fieldCtrl = TextEditingController();
  final _focusNode = FocusNode();
  String? _errorText;
  bool _isCommitting = false;

  @override
  void initState() {
    super.initState();
    _fieldCtrl.addListener(_onFieldChanged);
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _fieldCtrl.removeListener(_onFieldChanged);
    _fieldCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Public methods
  // ---------------------------------------------------------------------------

  /// Commits any pending text in the input field as a tag.
  ///
  /// Call this from outside (e.g. on a save action) to ensure no
  /// partially typed tag is lost.
  void commitPendingInput() {
    _commitInput(_fieldCtrl.text);
  }

  // ---------------------------------------------------------------------------
  // Event handlers
  // ---------------------------------------------------------------------------

  void _onFieldChanged() {
    // Clear any previous error when the user starts typing.
    if (_errorText != null) {
      setState(() => _errorText = null);
    }
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      commitPendingInput();
    }
  }

  /// Detects delimiter characters in the raw input text.
  ///
  /// Called from both [TextField.onChanged] (via the [TextEditingController]
  /// listener) and [onSubmitted]. Delimiters include: Enter, comma,
  /// Chinese comma, space, and newline.
  void _textFieldValueChanged(String value) {
    if (value.isEmpty) return;
    final lastChar = value[value.length - 1];
    if (lastChar == ',' || lastChar == '，' || lastChar == ' ') {
      _commitInput(value);
    }
  }

  // ---------------------------------------------------------------------------
  // Core logic
  // ---------------------------------------------------------------------------

  void _commitInput(String raw) {
    if (_isCommitting) return;
    _isCommitting = true;

    // Clear the text field synchronously.
    _fieldCtrl.clear();
    _isCommitting = false;

    final trimmed = raw.trim();
    if (trimmed.isEmpty) return;

    // Detect whether the raw input already contains a trailing delimiter.
    // Strip it so we don't get an empty string in the split results.
    final clean = _stripTrailingDelimiter(trimmed);
    if (clean.isEmpty) return;

    // Split by delimiters and process each part.
    final parts = clean.split(RegExp(r'[，,\s\n]+'));
    final newTags = <String>{...widget.tags};
    String? error;

    for (final part in parts) {
      final normalized = TagCodec.normalize(part);
      if (normalized.isEmpty) continue;

      // Check maxTags before adding a new one.
      if (newTags.length >= widget.maxTags) {
        error = '最多支持 ${widget.maxTags} 个标签';
        break;
      }

      final validation = TagCodec.validate(normalized);
      if (!validation.isValid) {
        error = validation.message;
        break;
      }

      newTags.add(normalized);
    }

    if (error != null) {
      setState(() => _errorText = error);
    } else {
      setState(() => _errorText = null);
      if (newTags.length != widget.tags.length) {
        widget.onChanged(newTags);
      }
    }
  }

  /// Strips a trailing delimiter character from [text].
  String _stripTrailingDelimiter(String text) {
    if (text.isEmpty) return text;
    final last = text[text.length - 1];
    if (last == ',' || last == '，' || last == ' ' || last == '\n') {
      return text.substring(0, text.length - 1);
    }
    return text;
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final hasFocusedError = _errorText != null && _focusNode.hasFocus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label
        if (widget.label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Text(
              widget.label!,
              style: TextStyle(
                color: colors.textSecondary,
                fontWeight: AppFontTokens.semiBold,
                fontSize: AppFontTokens.labelMd,
              ),
            ),
          ),

        // Existing tags
        if (widget.tags.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: widget.tags.map((tag) {
                return AppSelectedTagChip(
                  label: tag,
                  onDeleted: widget.enabled ? () => _removeTag(tag) : null,
                );
              }).toList(),
            ),
          ),

        // Input field
        TextField(
          controller: _fieldCtrl,
          focusNode: _focusNode,
          enabled: widget.enabled,
          autofocus: widget.autofocus,
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: TextStyle(
              color: colors.textTertiary,
              fontSize: AppFontTokens.bodyMd,
            ),
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.xs),
              borderSide: BorderSide(color: colors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.xs),
              borderSide: BorderSide(color: colors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.xs),
              borderSide: BorderSide(
                color: hasFocusedError ? colors.danger : colors.primary,
                width: hasFocusedError ? 1.5 : 1.0,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 6,
            ),
          ),
          style: TextStyle(fontSize: AppFontTokens.bodyMd),
          onChanged: _textFieldValueChanged,
          onSubmitted: (value) => _commitInput(value),
        ),

        // Error text
        if (_errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _errorText!,
              style: TextStyle(
                color: colors.danger,
                fontSize: AppFontTokens.caption,
              ),
            ),
          ),

        // Tag count hint
        if (widget.tags.length >= widget.maxTags * 0.8)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${widget.tags.length} / ${widget.maxTags}',
              style: TextStyle(
                color: colors.textTertiary,
                fontSize: AppFontTokens.caption,
              ),
            ),
          ),
      ],
    );
  }

  void _removeTag(String tag) {
    final newTags = Set<String>.from(widget.tags)..remove(tag);
    widget.onChanged(newTags);
  }
}
