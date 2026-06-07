import 'package:flutter/material.dart';
import 'package:uni_hub/src/core/theme/app_tokens.dart';
import 'package:uni_hub/src/shared/crud/crud.dart';

class CreateCollectionFolderDialog extends StatefulWidget {
  const CreateCollectionFolderDialog({
    super.key,
    this.existingNames = const <String>[],
  });

  final Iterable<String> existingNames;

  @override
  State<CreateCollectionFolderDialog> createState() =>
      _CreateCollectionFolderDialogState();
}

class _CreateCollectionFolderDialogState
    extends State<CreateCollectionFolderDialog> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  String? _errorText;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final failure = NameNormalizer.validateCollectionBoxName(
      _controller.text,
      siblingNames: widget.existingNames,
    );
    if (failure != null) {
      setState(() => _errorText = failure.message);
      return;
    }
    Navigator.of(context).pop(NameNormalizer.normalize(_controller.text));
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
                '新建收藏夹',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: AppFontTokens.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _controller,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  hintText: '收藏夹名称',
                  helperText: '最多 30 个字符，不允许包含 /',
                  errorText: _errorText,
                ),
                textInputAction: TextInputAction.done,
                onChanged: (_) {
                  if (_errorText != null) setState(() => _errorText = null);
                },
                onSubmitted: (_) => _submit(),
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
                  FilledButton(onPressed: _submit, child: const Text('创建')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
