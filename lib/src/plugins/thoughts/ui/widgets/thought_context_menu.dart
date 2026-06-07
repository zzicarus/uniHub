import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uni_hub/src/core/theme/app_tokens.dart';
import 'package:uni_hub/src/shared/tags/tag_codec.dart';
import 'package:uni_hub/src/shared/widgets/app_confirm_dialog.dart';
import 'package:uni_hub/src/shared/widgets/app_toast.dart';
import '../../providers/thoughts_providers.dart';

enum ThoughtContextAction {
  edit,
  togglePin,
  addTag,
  convertToTodo,
  convertToNote,
  toggleArchive,
  delete,
}

/// Shows a context menu for a thought at the given position.
///
/// Returns the selected action, or null if dismissed.
Future<ThoughtContextAction?> showThoughtContextMenu({
  required BuildContext context,
  required Offset position,
  required bool isPinned,
  required bool isArchived,
}) async {
  final colorScheme = Theme.of(context).colorScheme;

  return showMenu<ThoughtContextAction>(
    context: context,
    position: RelativeRect.fromSize(
      position & const Size(200, 400),
      MediaQuery.of(context).size,
    ),
    items: [
      const PopupMenuItem(
        value: ThoughtContextAction.edit,
        child: _MenuItem(icon: Icons.edit_outlined, label: '编辑'),
      ),
      PopupMenuItem(
        value: ThoughtContextAction.togglePin,
        child: _MenuItem(
          icon: isPinned ? Icons.push_pin : Icons.push_pin_outlined,
          label: isPinned ? '取消置顶' : '置顶',
        ),
      ),
      const PopupMenuItem(
        value: ThoughtContextAction.addTag,
        child: _MenuItem(icon: Icons.sell_outlined, label: '加标签'),
      ),
      const PopupMenuItem(
        enabled: false,
        child: _MenuItem(icon: Icons.check_box_outlined, label: '转为待办'),
      ),
      const PopupMenuItem(
        enabled: false,
        child: _MenuItem(icon: Icons.note_outlined, label: '转为笔记'),
      ),
      PopupMenuItem(
        value: ThoughtContextAction.toggleArchive,
        child: _MenuItem(
          icon: isArchived ? Icons.unarchive_outlined : Icons.archive_outlined,
          label: isArchived ? '取消归档' : '归档',
          highlightColor: isArchived ? colorScheme.primary : null,
        ),
      ),
      const PopupMenuItem(
        value: ThoughtContextAction.delete,
        child: _MenuItem(
          icon: Icons.delete_outline,
          label: '删除',
          isError: true,
        ),
      ),
    ],
    elevation: 8,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
    ),
  );
}

/// Shows a tag editing dialog for the given thought.
Future<void> showThoughtTagDialog({
  required BuildContext context,
  required WidgetRef ref,
  required int thoughtId,
}) async {
  if (!context.mounted) return;

  final thought = await ref.read(thoughtProvider(thoughtId).future);
  if (!context.mounted) return;

  final currentTags = (thought?.tags ?? '')
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  final controller = TextEditingController(text: '');

  final newTags = await showDialog<List<String>>(
    context: context,
    builder: (ctx) =>
        _TagDialog(currentTags: currentTags, controller: controller),
  );

  if (newTags != null && context.mounted) {
    final tagsString = newTags.isEmpty ? null : newTags.join(',');
    await ref
        .read(thoughtsRepositoryProvider)
        .updateTags(thoughtId, tagsString);
    ref.invalidate(allThoughtsProvider);
    if (context.mounted) {
      AppToast.show(context, message: '标签已更新', type: AppToastType.success);
    }
  }
}

/// Shows a delete confirmation dialog. Returns true if confirmed.
Future<bool> showThoughtDeleteDialog(BuildContext context) {
  return AppConfirmDialog.show(
    context: context,
    title: '删除想法',
    message: '确定要删除这个想法吗？此操作不可撤销。',
    confirmLabel: '删除',
    destructive: true,
    icon: Icons.delete_outline_rounded,
  );
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? highlightColor;
  final bool isError;

  const _MenuItem({
    required this.icon,
    required this.label,
    this.highlightColor,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: isError
              ? colorScheme.error
              : highlightColor ?? colorScheme.onSurface,
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isError ? colorScheme.error : colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _TagDialog extends StatefulWidget {
  final List<String> currentTags;
  final TextEditingController controller;

  const _TagDialog({required this.currentTags, required this.controller});

  @override
  State<_TagDialog> createState() => _TagDialogState();
}

class _TagDialogState extends State<_TagDialog> {
  late List<String> _tags;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _tags = List.from(widget.currentTags);
  }

  void _removeTag(String tag) {
    setState(() => _tags.remove(tag));
  }

  void _save() {
    final input = widget.controller.text.trim();
    if (input.isNotEmpty) {
      final added = input
          .split(RegExp(r'[,\s]+'))
          .map(TagCodec.normalize)
          .where((s) => s.isNotEmpty)
          .toList();
      for (final tag in added) {
        final validation = TagCodec.validate(tag);
        if (!validation.isValid) {
          setState(() => _errorText = validation.message);
          return;
        }
        if (!_tags.contains(tag)) {
          _tags.add(tag);
        }
      }
    }
    Navigator.of(context).pop(_tags);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '添加标签',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: AppFontTokens.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (_tags.isNotEmpty) ...[
                Text('当前标签', style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xxs,
                  runSpacing: AppSpacing.xxs,
                  children: _tags.map((tag) {
                    return Chip(
                      label: Text(tag),
                      deleteIcon: const Icon(Icons.close, size: 14),
                      onDeleted: () => _removeTag(tag),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              TextField(
                controller: widget.controller,
                decoration: InputDecoration(
                  hintText: '输入新标签（空格/逗号分隔）',
                  helperText: '最多 24 个字符，仅支持中文、英文、数字、-、_',
                  errorText: _errorText,
                  isDense: true,
                ),
                autofocus: true,
                onChanged: (_) {
                  if (_errorText != null) setState(() => _errorText = null);
                },
                onSubmitted: (_) => _save(),
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  FilledButton(onPressed: _save, child: const Text('保存')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
