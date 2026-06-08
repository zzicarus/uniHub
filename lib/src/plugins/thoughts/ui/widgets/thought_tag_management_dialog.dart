import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uni_hub/src/core/theme/app_tokens.dart';
import 'package:uni_hub/src/shared/crud/crud.dart';
import 'package:uni_hub/src/shared/tags/providers/tags_providers.dart';
import 'package:uni_hub/src/shared/tags/tag_codec.dart';
import 'package:uni_hub/src/shared/widgets/app_confirm_dialog.dart';
import 'package:uni_hub/src/shared/widgets/app_toast.dart';

import '../../providers/thoughts_providers.dart';

Future<void> showThoughtTagManagementDialog({
  required BuildContext context,
  required WidgetRef ref,
  String? initialTag,
}) async {
  var entries = ref.read(commonTagsProvider);
  if (initialTag != null && initialTag.trim().isNotEmpty) {
    final tag = initialTag.trim();
    entries = [
      ...entries.where((entry) => entry.key == tag),
      ...entries.where((entry) => entry.key != tag),
    ];
  }

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          Future<void> renameTag(String oldTag) async {
            final newTag = await _askForTagName(
              context,
              oldTag,
              entries.map((entry) => entry.key).where((tag) => tag != oldTag),
            );
            if (newTag == null || newTag.trim() == oldTag) return;
            try {
              final tagsDao = ref.read(tagsDaoProvider);
              final tagToRename = await tagsDao.getTagByNormalizedName(oldTag);
              if (tagToRename != null) {
                final result = await ref
                    .read(tagActionsControllerProvider)
                    .renameTag(tagToRename.id, newTag);
                if (!context.mounted) return;
                ref.read(crudFeedbackCoordinatorProvider).handle(context, result);
              }
              ref
                  .read(selectedTagFiltersProvider.notifier)
                  .state = renameTagInFilter(
                ref.read(selectedTagFiltersProvider),
                oldTag,
                newTag,
              );
              ref.invalidate(allThoughtsProvider);
              setState(() {
                entries =
                    entries
                        .map(
                          (entry) => entry.key == oldTag
                              ? MapEntry(newTag.trim(), entry.value)
                              : entry,
                        )
                        .toList()
                      ..sort((a, b) {
                        final byCount = b.value.compareTo(a.value);
                        return byCount != 0 ? byCount : a.key.compareTo(b.key);
                      });
              });
            } on Exception catch (e) {
              if (context.mounted) {
                AppToast.show(context, message: e.toString());
              }
            }
          }

          Future<void> deleteTag(String tag) async {
            final confirmed = await _confirmDeleteTag(context, tag);
            if (!confirmed) return;
            final tagsDao = ref.read(tagsDaoProvider);
            final tagToDelete = await tagsDao.getTagByNormalizedName(tag);
            if (tagToDelete != null) {
              final result = await ref
                  .read(tagActionsControllerProvider)
                  .deleteTag(tagToDelete.id);
              if (context.mounted) {
                ref.read(crudFeedbackCoordinatorProvider).handle(context, result);
              }
            }
            ref.read(selectedTagFiltersProvider.notifier).state =
                removeTagFromFilter(ref.read(selectedTagFiltersProvider), tag);
            ref.invalidate(allThoughtsProvider);
            setState(() {
              entries = entries.where((entry) => entry.key != tag).toList();
            });
            if (context.mounted) {
              AppToast.show(
                context,
                message: '标签已删除',
                type: AppToastType.success,
              );
            }
          }

          final theme = Theme.of(context);
          final colorScheme = theme.colorScheme;
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '管理标签',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: AppFontTokens.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: 420,
                      child: entries.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(AppSpacing.lg),
                              child: Text('暂无标签'),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              itemCount: entries.length,
                              separatorBuilder: (_, _) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final entry = entries[index];
                                return ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(
                                    Icons.sell_outlined,
                                    size: 18,
                                  ),
                                  title: Text(entry.key),
                                  subtitle: Text('${entry.value} 条想法'),
                                  trailing: Wrap(
                                    spacing: AppSpacing.xxs,
                                    children: [
                                      IconButton(
                                        tooltip: '重命名',
                                        icon: const Icon(
                                          Icons.edit_outlined,
                                          size: 18,
                                        ),
                                        onPressed: () => renameTag(entry.key),
                                      ),
                                      IconButton(
                                        tooltip: '删除',
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          size: 18,
                                        ),
                                        onPressed: () => deleteTag(entry.key),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: const Text('关闭'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

Future<String?> _askForTagName(
  BuildContext context,
  String oldTag,
  Iterable<String> existingTags,
) async {
  final controller = TextEditingController(text: oldTag);
  String? errorText;
  final result = await showDialog<String>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          final theme = Theme.of(context);
          final colorScheme = theme.colorScheme;
          void submit() {
            final next = TagCodec.normalize(controller.text);
            final validation = TagCodec.validate(next);
            if (!validation.isValid) {
              setState(() => errorText = validation.message);
              return;
            }
            final nextKey = next.toLowerCase();
            final duplicated = existingTags.any(
              (tag) => TagCodec.normalize(tag).toLowerCase() == nextKey,
            );
            if (duplicated) {
              setState(() => errorText = '标签已存在');
              return;
            }
            Navigator.of(context).pop(next);
          }

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
                      '重命名标签',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: AppFontTokens.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: controller,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: '标签名称',
                        helperText: '最多 24 个字符，仅支持中文、英文、数字、-、_',
                        errorText: errorText,
                      ),
                      onChanged: (_) {
                        if (errorText != null) setState(() => errorText = null);
                      },
                      onSubmitted: (_) => submit(),
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
                        FilledButton(
                          onPressed: submit,
                          child: const Text('保存'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
  controller.dispose();
  return result;
}

Future<bool> _confirmDeleteTag(BuildContext context, String tag) {
  return AppConfirmDialog.show(
    context: context,
    title: '删除标签',
    message: '确定要从所有想法中删除「$tag」标签吗？',
    confirmLabel: '删除',
    destructive: true,
    icon: Icons.delete_outline_rounded,
  );
}
