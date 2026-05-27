import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uni_hub/src/core/theme/app_tokens.dart';
import 'package:uni_hub/src/plugins/collections/providers/collections_providers.dart';

/// Dual-mode input field: search or URL capture.
///
/// When the input looks like a URL, switches to capture mode with a
/// "收藏" button. Otherwise, debounced search mode.
class CollectionSearchCaptureField extends ConsumerStatefulWidget {
  const CollectionSearchCaptureField({super.key});

  @override
  ConsumerState<CollectionSearchCaptureField> createState() =>
      _CollectionSearchCaptureFieldState();
}

class _CollectionSearchCaptureFieldState
    extends ConsumerState<CollectionSearchCaptureField> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;

  bool _isUrl = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    // Sync initial value from provider
    final initialQuery = ref.read(collectionSearchQueryProvider);
    if (initialQuery.isNotEmpty) {
      _controller.text = initialQuery;
    }

    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      // On blur, if the input looks URL-like, don't submit automatically
    }
  }

  void _onChanged(String value) {
    final trimmed = value.trim();
    final isUrl = _detectUrl(trimmed);

    setState(() {
      _isUrl = isUrl;
    });

    if (isUrl) {
      // URL mode: don't update search query
      _debounce?.cancel();
      return;
    }

    // Search mode: debounce before writing to provider
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) {
        ref.read(collectionSearchQueryProvider.notifier).state = trimmed;
      }
    });
  }

  bool _detectUrl(String text) {
    if (text.isEmpty) return false;

    if (text.startsWith('http://') || text.startsWith('https://')) {
      return true;
    }

    if (text.contains(' ') || !text.contains('.')) {
      return false;
    }

    return RegExp(r'^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}').hasMatch(text);
  }

  Future<void> _onSubmitted() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    if (_detectUrl(text)) {
      await _captureUrl(text);
    } else {
      ref.read(collectionSearchQueryProvider.notifier).state = text;
    }
  }

  Future<void> _captureUrl(String url) async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final selectedBoxIds = ref.read(selectedCollectionBoxIdsProvider);
      final boxId = selectedBoxIds.length == 1 ? selectedBoxIds.first : null;

      final result = await ref
          .read(collectionCaptureServiceProvider)
          .captureUrl(url, boxId: boxId);

      if (!mounted) return;

      ref.invalidate(savedItemsListProvider);
      ref.invalidate(collectionFolderCountsProvider);

      if (result.wasCreated) {
        unawaited(ref.read(enrichmentQueueControllerProvider).drainPending(
          batchSize: 5,
          maxBatches: 3,
        ));
      }

      ref.read(selectedSavedItemIdProvider.notifier).state = result.itemId;

      _controller.clear();
      setState(() => _isUrl = false);

      ref.read(collectionSearchQueryProvider.notifier).state = '';

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.wasCreated ? '已收藏' : '已存在，已定位到该收藏'),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('收藏失败，请检查链接')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _onClear() {
    _controller.clear();
    setState(() => _isUrl = false);
    ref.read(collectionSearchQueryProvider.notifier).state = '';
    _focusNode.unfocus();
  }

  /// Compute the capture button label based on the selected box context.
  String _captureButtonLabel(Set<int> selectedBoxIds) {
    if (selectedBoxIds.length == 1) {
      // We need the box name — fetch synchronously from the provider cache.
      final boxes = ref.read(collectionBoxesProvider).valueOrNull ?? [];
      final box = boxes.where((b) => b.id == selectedBoxIds.first).firstOrNull;
      if (box != null) return '收藏到「${box.name}」';
    }
    return '收藏';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentQuery = ref.watch(collectionSearchQueryProvider);
    final hasQuery = currentQuery.isNotEmpty && !_isUrl;
    final selectedBoxIds = ref.watch(selectedCollectionBoxIdsProvider);

    // Focus state
    final isFocused = _focusNode.hasFocus;

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: isFocused ? colorScheme.surface : const Color(0xFFF6F8FC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFocused ? const Color(0xFF93C5FD) : Colors.transparent,
        ),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: const Color(0xFF4F6BFF).withValues(alpha: 0.08),
                  blurRadius: 6,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          // Icon: link or search
          Icon(
            _isUrl ? Icons.link_rounded : Icons.search_rounded,
            size: 20,
            color: _isUrl
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 10),
          // Text field
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              onChanged: _onChanged,
              onSubmitted: (_) => _onSubmitted(),
              textInputAction: _isUrl
                  ? TextInputAction.done
                  : TextInputAction.search,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                hintText: '搜索或粘贴链接收藏',
                hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF94A3B8),
                  fontWeight: AppFontTokens.normal,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF0F172A),
                fontWeight: AppFontTokens.normal,
              ),
            ),
          ),
          // Right-side actions
          if (_isUrl)
            // Capture button
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: Padding(
                        padding: EdgeInsets.all(4),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : Material(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: _onSubmitted,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          child: Text(
                            _captureButtonLabel(selectedBoxIds),
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: colorScheme.onPrimary,
                                  fontWeight: AppFontTokens.semiBold,
                                  letterSpacing: 0,
                                ),
                          ),
                        ),
                      ),
                    ),
            )
          else if (hasQuery)
            // Clear button
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 18),
              onPressed: _onClear,
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              tooltip: '清空',
              color: colorScheme.onSurfaceVariant,
            ),
          const SizedBox(width: 6),
        ],
      ),
    );
  }
}
