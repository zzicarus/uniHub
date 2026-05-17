import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_tokens.dart';
import '../providers/thoughts_providers.dart';

class ThoughtsEditorPage extends ConsumerStatefulWidget {
  final int thoughtId;

  const ThoughtsEditorPage({required this.thoughtId, super.key});

  @override
  ConsumerState<ThoughtsEditorPage> createState() =>
      _ThoughtsEditorPageState();
}

class _ThoughtsEditorPageState extends ConsumerState<ThoughtsEditorPage> {
  final _contentController = TextEditingController();
  final _tagTextController = TextEditingController();
  final _tagChips = <String>[];
  String? _selectedColor;
  bool _isPinned = false;
  bool _isArchived = false;
  bool _isDirty = false;
  bool _isLoaded = false;

  @override
  void dispose() {
    _contentController.dispose();
    _tagTextController.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!_isDirty) {
      setState(() => _isDirty = true);
    }
  }

  void _loadThought() {
    if (_isLoaded) return;
    final thoughtAsync = ref.read(thoughtProvider(widget.thoughtId));
    thoughtAsync.whenData((thought) {
      if (thought != null && !_isLoaded) {
        setState(() {
          _contentController.text = thought.content;
          _tagChips.addAll(
            (thought.tags ?? '')
                .split(',')
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty),
          );
          _selectedColor = thought.color;
          _isPinned = thought.isPinned;
          _isArchived = thought.archivedAt != null;
          _isLoaded = true;
          _isDirty = false;
        });
      }
    });
  }

  Future<void> _save() async {
    if (!_isDirty) return;
    final repo = ref.read(thoughtsRepositoryProvider);
    final tags = _tagChips.isNotEmpty ? _tagChips.join(',') : null;
    await repo.updateThought(
      widget.thoughtId,
      content: _contentController.text.trim(),
      tags: tags,
      color: _selectedColor,
      isPinned: _isPinned,
    );
    ref.invalidate(thoughtProvider(widget.thoughtId));
    ref.invalidate(thoughtsListProvider);
    setState(() => _isDirty = false);
  }

  Future<void> _goBack() async {
    await _save();
    if (mounted) {
      context.pop();
    }
  }

  Future<void> _delete() async {
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
              backgroundColor: AppColors.error,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final repo = ref.read(thoughtsRepositoryProvider);
      await repo.deleteThought(widget.thoughtId);
      ref.invalidate(thoughtsListProvider);
      if (mounted) {
        context.pop();
      }
    }
  }

  Future<void> _archive() async {
    final repo = ref.read(thoughtsRepositoryProvider);
    await repo.archiveThought(widget.thoughtId);
    ref.invalidate(thoughtsListProvider);
    if (mounted) {
      context.pop();
    }
  }

  Future<void> _restore() async {
    final repo = ref.read(thoughtsRepositoryProvider);
    await repo.restoreThought(widget.thoughtId);
    ref.invalidate(thoughtsListProvider);
    setState(() {
      _isArchived = false;
      _isDirty = false;
    });
  }

  void _togglePin(bool value) {
    setState(() {
      _isPinned = value;
      _isDirty = true;
    });
  }

  void _handleTagInput(String value) {
    final delimiter = value.contains(',') ? ',' : ' ';
    if (value.endsWith(delimiter)) {
      final tag = value.substring(0, value.length - 1).trim();
      if (tag.isNotEmpty && !_tagChips.contains(tag)) {
        setState(() {
          _tagChips.add(tag);
          _isDirty = true;
        });
      }
      _tagTextController.clear();
    }
  }

  void _removeChip(String tag) {
    setState(() {
      _tagChips.remove(tag);
      _isDirty = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    _loadThought();

    if (!_isLoaded) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          unawaited(_goBack());
        }
      },
      child: Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: '返回（自动保存）',
          onPressed: _goBack,
        ),
        title: Text(
          _isArchived ? '编辑想法（已归档）' : '编辑想法',
          style: theme.textTheme.titleMedium,
        ),
        actions: [
          if (!_isArchived)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                switch (value) {
                  case 'delete':
                    _delete();
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(Icons.delete_outline,
                          size: 20, color: AppColors.error),
                      const SizedBox(width: AppSpacing.sm),
                      Text('删除',
                          style: TextStyle(color: AppColors.error)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            // Content editor
            TextField(
              controller: _contentController,
              minLines: 5,
              maxLines: null,
              textInputAction: TextInputAction.newline,
              onChanged: (_) => _markDirty(),
              decoration: const InputDecoration(
                hintText: '记录你的想法...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              style: theme.textTheme.bodyLarge,
            ),

            const SizedBox(height: AppSpacing.lg),

            // Tags section
            Text('标签', style: theme.textTheme.labelMedium),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xxs,
              runSpacing: AppSpacing.xxs,
              children: [
                ..._tagChips.map((tag) {
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
                }),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: _tagTextController,
              onChanged: _handleTagInput,
              decoration: const InputDecoration(
                hintText: '添加标签（空格或逗号分隔）',
                isDense: true,
              ),
              style: theme.textTheme.bodySmall,
            ),

            const SizedBox(height: AppSpacing.lg),

            // Color selector
            Text('颜色', style: theme.textTheme.labelMedium),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _ColorDot(
                  color: null,
                  label: '默认',
                  isSelected: _selectedColor == null,
                  onTap: () {
                    setState(() {
                      _selectedColor = null;
                      _isDirty = true;
                    });
                  },
                ),
                ..._availableColors.map((c) {
                  return _ColorDot(
                    color: c,
                    label: null,
                    isSelected: _selectedColor == _colorToHex(c),
                    onTap: () {
                      setState(() {
                        _selectedColor = _colorToHex(c);
                        _isDirty = true;
                      });
                    },
                  );
                }),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),

            // Pin toggle
            if (!_isArchived)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('置顶'),
                value: _isPinned,
                onChanged: _togglePin,
                activeThumbColor: AppColors.warning,
                secondary: const Icon(Icons.push_pin_outlined),
              ),

            const Divider(height: AppSpacing.xl),

            // Actions
            if (_isArchived) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _restore,
                  icon: const Icon(Icons.unarchive_outlined, size: 18),
                  label: const Text('恢复'),
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _archive,
                  icon: const Icon(Icons.archive_outlined, size: 18),
                  label: const Text('归档'),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _delete,
                  icon: const Icon(Icons.delete_outline,
                      size: 18, color: AppColors.error),
                  label: const Text('删除'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  final Color? color;
  final String? label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorDot({
    this.color,
    this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color ?? AppColors.surfaceMuted,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2.5 : 1.5,
          ),
        ),
        child: color == null
            ? const Center(
                child: Text('A',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textTertiary)),
              )
            : null,
      ),
    );
  }
}

const _availableColors = [
  AppColors.primary,
  AppColors.secondary,
  AppColors.accent,
  AppColors.purple,
  AppColors.success,
  AppColors.warning,
  AppColors.error,
];

String _colorToHex(Color c) {
  return '#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
}
