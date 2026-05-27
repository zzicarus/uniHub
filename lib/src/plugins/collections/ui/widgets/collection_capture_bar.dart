import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uni_hub/src/core/theme/app_tokens.dart';
import 'package:uni_hub/src/plugins/collections/providers/collections_providers.dart';

class CollectionCaptureBar extends ConsumerStatefulWidget {
  const CollectionCaptureBar({super.key});

  @override
  ConsumerState<CollectionCaptureBar> createState() =>
      _CollectionCaptureBarState();
}

class _CollectionCaptureBarState extends ConsumerState<CollectionCaptureBar> {
  final _controller = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    final url = _controller.text.trim();
    if (url.isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      final service = ref.read(collectionCaptureServiceProvider);
      final result = await service.captureUrl(url);
      if (!mounted) return;
      _controller.clear();
      ref.invalidate(savedItemsPageProvider);
      ref.invalidate(collectionFolderCountsProvider);
      if (result.wasCreated) {
        unawaited(ref.read(enrichmentQueueControllerProvider).drainPending(
          batchSize: 5,
          maxBatches: 3,
        ));
      }
      ref.invalidate(collectionBoxesProvider);
      final message = result.wasCreated ? '已添加到收藏' : '已存在，已跳转到该收藏';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('收藏失败：$error')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: const [AppShadows.cardSoft],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.link_rounded),
                  hintText: '粘贴链接、文章地址或内容来源，按 Enter 快速收藏',
                  border: InputBorder.none,
                ),
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            FilledButton.icon(
              onPressed: _isSubmitting ? null : _submit,
              icon: _isSubmitting
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.bookmark_add_outlined),
              label: const Text('快速收藏'),
            ),
          ],
        ),
      ),
    );
  }
}
