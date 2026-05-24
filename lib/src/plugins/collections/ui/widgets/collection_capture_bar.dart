import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uni_hub/src/core/database/app_database.dart';
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
  int? _selectedBoxId;

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
      final result = await service.captureUrl(url, boxId: _selectedBoxId);
      if (!mounted) return;
      _controller.clear();
      setState(() => _selectedBoxId = null);
      ref.invalidate(savedItemsListProvider);
      if (result.wasCreated) {
        unawaited(_triggerEnrichmentQueue());
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

  Future<void> _triggerEnrichmentQueue() async {
    try {
      await ref.read(enrichmentJobServiceProvider).runPendingJobs();
    } catch (error) {
      debugPrint('Collections enrichment job queue failed: $error');
    } finally {
      if (mounted) {
        ref.invalidate(savedItemsListProvider);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final boxesAsync = ref.watch(collectionBoxesProvider);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: const [AppShadows.cardSoft],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.link_rounded),
                  hintText: '粘贴 URL，按 Enter 收藏',
                  border: InputBorder.none,
                ),
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            _BoxDropdown(
              boxesAsync: boxesAsync,
              selectedBoxId: _selectedBoxId,
              onChanged: (id) => setState(() => _selectedBoxId = id),
            ),
            const SizedBox(width: AppSpacing.xs),
            FilledButton.icon(
              onPressed: _isSubmitting ? null : _submit,
              icon: _isSubmitting
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.bookmark_add_outlined),
              label: const Text('收藏'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BoxDropdown extends StatelessWidget {
  const _BoxDropdown({
    required this.boxesAsync,
    required this.selectedBoxId,
    required this.onChanged,
  });

  final AsyncValue<List<CollectionBoxesTableData>> boxesAsync;
  final int? selectedBoxId;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return boxesAsync.when(
      data: (boxes) {
        if (boxes.isEmpty) return const SizedBox.shrink();
        return DropdownButton<int?>(
          value: selectedBoxId,
          hint: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.folder_outlined, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              const Text('Box'),
            ],
          ),
          underline: const SizedBox.shrink(),
          items: [
            DropdownMenuItem<int?>(
              value: null,
              child: Text('Inbox', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ),
            for (final box in boxes)
              DropdownMenuItem<int?>(
                value: box.id,
                child: Text(box.name),
              ),
          ],
          onChanged: onChanged,
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
