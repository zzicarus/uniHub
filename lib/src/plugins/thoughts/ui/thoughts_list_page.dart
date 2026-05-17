import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_tokens.dart';
import '../providers/thoughts_providers.dart';
import 'widgets/thought_card.dart';

class ThoughtsListPage extends ConsumerStatefulWidget {
  const ThoughtsListPage({super.key});

  @override
  ConsumerState<ThoughtsListPage> createState() => _ThoughtsListPageState();
}

class _ThoughtsListPageState extends ConsumerState<ThoughtsListPage> {
  final _contentController = TextEditingController();
  final _tagTextController = TextEditingController();
  final _tagChips = <String>[];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _contentController.dispose();
    _tagTextController.dispose();
    super.dispose();
  }

  void _handleTagInput(String value) {
    final delimiter = value.contains(',') ? ',' : ' ';
    if (value.endsWith(delimiter)) {
      final tag = value.substring(0, value.length - 1).trim();
      if (tag.isNotEmpty && !_tagChips.contains(tag)) {
        setState(() {
          _tagChips.add(tag);
        });
      }
      _tagTextController.clear();
    }
  }

  void _removeChip(String tag) {
    setState(() {
      _tagChips.remove(tag);
    });
  }

  Future<void> _submit() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      final repo = ref.read(thoughtsRepositoryProvider);
      final tags =
          _tagChips.isNotEmpty ? _tagChips.join(',') : null;
      await repo.createThought(content: content, tags: tags);
      ref.invalidate(thoughtsListProvider);
      _contentController.clear();
      setState(() => _tagChips.clear());
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _navigateToEditor(int id) {
    context.goNamed(
      RouteNames.thoughtEditor,
      pathParameters: {'id': id.toString()},
    );
  }

  void _setTagFilter(String? tag) {
    ref.read(tagFilterProvider.notifier).state = tag;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final thoughtsAsync = ref.watch(thoughtsListProvider);
    final tagFilter = ref.watch(tagFilterProvider);
    final hasContent = _contentController.text.trim().isNotEmpty;

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
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              // Quick input area
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _contentController,
                      minLines: 1,
                      maxLines: 5,
                      textInputAction: TextInputAction.newline,
                      decoration: const InputDecoration(
                        hintText: '记录一个想法...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    // Tag chips
                    if (_tagChips.isNotEmpty)
                      Wrap(
                        spacing: AppSpacing.xxs,
                        runSpacing: AppSpacing.xxs,
                        children: _tagChips.map((tag) {
                          return Chip(
                            label: Text(tag),
                            labelStyle: const TextStyle(fontSize: 12),
                            deleteIcon: const Icon(Icons.close, size: 14),
                            onDeleted: () => _removeChip(tag),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                          );
                        }).toList(),
                      ),
                    if (_tagChips.isNotEmpty)
                      const SizedBox(height: AppSpacing.sm),
                    // Tag input
                    TextField(
                      controller: _tagTextController,
                      onChanged: _handleTagInput,
                      decoration: InputDecoration(
                        hintText: _tagChips.isEmpty ? '添加标签（空格或逗号分隔）' : '',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                        suffixIcon: _tagChips.isNotEmpty
                            ? const Icon(Icons.local_offer_outlined,
                                size: 18)
                            : null,
                      ),
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      height: AppDesktopSizes.compactButtonHeight,
                      child: FilledButton.icon(
                        onPressed: hasContent && !_isSubmitting
                            ? _submit
                            : null,
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(
                          _isSubmitting ? '保存中...' : '记录',
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Tag filter bar
              if (tagFilter != null && tagFilter.isNotEmpty)
                Padding(
                  padding:
                      const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Row(
                    children: [
                      Chip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('#',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600)),
                            Text(tagFilter),
                          ],
                        ),
                        deleteIcon:
                            const Icon(Icons.close, size: 14),
                        onDeleted: () => _setTagFilter(null),
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.12),
                        side: BorderSide.none,
                      ),
                    ],
                  ),
                ),

              // Thoughts list
              thoughtsAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Text('加载失败: $err',
                        style: theme.textTheme.bodyMedium),
                  ),
                ),
                data: (thoughts) {
                  final activeThoughts = thoughts
                      .where((t) => t.archivedAt == null)
                      .toList();
                  final pinned =
                      activeThoughts.where((t) => t.isPinned).toList();
                  final unpinned =
                      activeThoughts.where((t) => !t.isPinned).toList();

                  if (activeThoughts.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xxl),
                        child: Column(
                          children: [
                            Icon(Icons.lightbulb_outline,
                                size: 48,
                                color: AppColors.textTertiary),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              tagFilter != null
                                  ? '没有匹配 "#$tagFilter" 的想法'
                                  : '还没有想法',
                              style: theme.textTheme.bodyLarge,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              tagFilter != null
                                  ? '清除过滤标签'
                                  : '用上方输入框记录第一个想法吧',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Pinned section
                      if (pinned.isNotEmpty) ...[
                        Row(
                          children: [
                            const Icon(Icons.push_pin,
                                size: 16, color: AppColors.warning),
                            const SizedBox(width: AppSpacing.xs),
                            Text('置顶',
                                style: theme.textTheme.labelMedium),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        ...pinned.map(
                          (t) => Padding(
                            padding: const EdgeInsets.only(
                                bottom: AppSpacing.sm),
                            child: ThoughtCard(
                              id: t.id,
                              content: t.content,
                              tags: t.tags,
                              color: t.color,
                              isPinned: t.isPinned,
                              createdAt: t.createdAt,
                              onTap: () => _navigateToEditor(t.id),
                              onTagTap: _setTagFilter,
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(
                              vertical: AppSpacing.xs),
                          child: Divider(),
                        ),
                      ],
                      // Unpinned section
                      ...unpinned.map(
                        (t) => Padding(
                          padding:
                              const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: ThoughtCard(
                            id: t.id,
                            content: t.content,
                            tags: t.tags,
                            color: t.color,
                            isPinned: t.isPinned,
                            createdAt: t.createdAt,
                            onTap: () => _navigateToEditor(t.id),
                            onTagTap: _setTagFilter,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
