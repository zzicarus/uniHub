import 'package:flutter/material.dart';

class CreateCollectionFolderDialog extends StatefulWidget {
  const CreateCollectionFolderDialog({super.key});

  @override
  State<CreateCollectionFolderDialog> createState() =>
      _CreateCollectionFolderDialogState();
}

class _CreateCollectionFolderDialogState
    extends State<CreateCollectionFolderDialog> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

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
    final name = _controller.text.trim();
    Navigator.of(context).pop(name.isNotEmpty ? name : null);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('新建收藏夹'),
      content: TextField(
        controller: _controller,
        focusNode: _focusNode,
        decoration: const InputDecoration(hintText: '收藏夹名称'),
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('创建'),
        ),
      ],
    );
  }
}
