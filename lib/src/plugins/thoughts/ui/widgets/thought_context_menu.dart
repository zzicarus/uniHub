import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uni_hub/src/core/theme/app_tokens.dart';
import 'package:uni_hub/src/shared/crud/crud.dart';
import 'package:uni_hub/src/shared/tags/tag_models.dart';
import 'package:uni_hub/src/shared/tags/providers/tags_providers.dart';
import 'package:uni_hub/src/shared/widgets/app_confirm_dialog.dart';
import 'package:uni_hub/src/shared/widgets/entity_picker/app_entity_picker.dart';
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

/// Shows a tag picker dialog for adding/removing tags on a thought.
///
/// Uses [AppEntityPicker] for a consistent search-and-tap experience.
/// Each toggle immediately adds or removes the tag via [TagActionsController].
Future<void> showThoughtTagDialog({
  required BuildContext context,
  required WidgetRef ref,
  required int thoughtId,
}) async {
  if (!context.mounted) return;

  final tagsDao = ref.read(tagsDaoProvider);
  final controller = ref.read(tagActionsControllerProvider);
  final coordinator = ref.read(crudFeedbackCoordinatorProvider);

  final allTags = await tagsDao.getAllTags();
  final currentTags = await tagsDao.getTagsForThought(thoughtId);
  final currentIds = currentTags.map((t) => t.id as Object).toSet();
  if (!context.mounted) return;

  await showDialog<void>(
    context: context,
    builder: (_) => AppEntityPicker<AppTag>(
      title: '添加标签',
      searchHint: '搜索标签或创建新标签',
      items: allTags,
      selectedIds: currentIds,
      itemLabel: (tag) => tag.name,
      itemId: (tag) => tag.id,
      allowCreate: true,
      createLabelBuilder: (input) => '创建标签「$input」',
      onToggle: (tag, selected) async {
        final result = selected
            ? await controller.addTagToThought(
                thoughtId: thoughtId,
                tagName: tag.name,
              )
            : await controller.removeTagFromThought(
                thoughtId: thoughtId,
                tagId: tag.id,
              );
        if (context.mounted) {
          coordinator.handle(context, result);
        }
        if (result.success) {
          ref.invalidate(allThoughtsProvider);
          ref.invalidate(tagsForThoughtProvider(thoughtId));
        }
      },
      onCreate: (name) async {
        final result = await controller.createTag(name);
        if (context.mounted) {
          coordinator.handle(context, result);
        }
        if (result.success) {
          return result.data;
        }
        return null;
      },
    ),
  );
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
