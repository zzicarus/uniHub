import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uni_hub/src/core/theme/app_tokens.dart';

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
            final newTag = await _askForTagName(context, oldTag);
            if (newTag == null || newTag.trim() == oldTag) return;
            try {
              final affected = await ref
                  .read(thoughtsRepositoryProvider)
                  .renameTag(oldTag, newTag);
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
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('已重命名 $affected 条想法中的标签')),
                );
              }
            } on StateError catch (error) {
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(error.message)));
              }
            } on ArgumentError catch (error) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(error.message.toString())),
                );
              }
            }
          }

          Future<void> deleteTag(String tag) async {
            final confirmed = await _confirmDeleteTag(context, tag);
            if (!confirmed) return;
            final affected = await ref
                .read(thoughtsRepositoryProvider)
                .deleteTagEverywhere(tag);
            ref.read(selectedTagFiltersProvider.notifier).state =
                removeTagFromFilter(ref.read(selectedTagFiltersProvider), tag);
            ref.invalidate(allThoughtsProvider);
            setState(() {
              entries = entries.where((entry) => entry.key != tag).toList();
            });
            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('已从 $affected 条想法中删除标签')));
            }
          }

          return AlertDialog(
            title: const Text('管理标签'),
            content: SizedBox(
              width: 420,
              child: entries.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: Text('暂无标签'),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: entries.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.sell_outlined, size: 18),
                          title: Text(entry.key),
                          subtitle: Text('${entry.value} 条想法'),
                          trailing: Wrap(
                            spacing: AppSpacing.xxs,
                            children: [
                              IconButton(
                                tooltip: '重命名',
                                icon: const Icon(Icons.edit_outlined, size: 18),
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
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('关闭'),
              ),
            ],
          );
        },
      );
    },
  );
}

Future<String?> _askForTagName(BuildContext context, String oldTag) async {
  final controller = TextEditingController(text: oldTag);
  final result = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('重命名标签'),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(labelText: '标签名称'),
        onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(controller.text.trim()),
          child: const Text('保存'),
        ),
      ],
    ),
  );
  controller.dispose();
  return result;
}

Future<bool> _confirmDeleteTag(BuildContext context, String tag) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('删除标签'),
      content: Text('确定要从所有想法中删除「$tag」标签吗？'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('删除'),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
