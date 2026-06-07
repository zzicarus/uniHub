part of '../home_page.dart';

/// 解析输入内容，提取 #标签
class ParsedCaptureInput {
  const ParsedCaptureInput({
    required this.content,
    required this.tags,
  });

  final String content;
  final List<String> tags;
}

ParsedCaptureInput parseCaptureInput(String raw) {
  // 标签规则： #标签 中间不能有空格
  final tagPattern = RegExp(r'(^|\s)#([\w\u4e00-\u9fa5-]+)(?=\s|$)');

  final tags = <String>[];

  final content = raw.replaceAllMapped(tagPattern, (match) {
    final tag = match.group(2)?.trim();
    if (tag != null && tag.isNotEmpty) {
      tags.add(tag);
    }
    return match.group(1) ?? '';
  }).replaceAll(RegExp(r'\s+'), ' ').trim();

  return ParsedCaptureInput(
    content: content,
    tags: tags.toSet().toList(),
  );
}

class _DesktopQuickCaptureCard extends ConsumerStatefulWidget {
  const _DesktopQuickCaptureCard();

  @override
  ConsumerState<_DesktopQuickCaptureCard> createState() =>
      _DesktopQuickCaptureCardState();
}

class _DesktopQuickCaptureCardState
    extends ConsumerState<_DesktopQuickCaptureCard> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final raw = _controller.text.trim();
    if (raw.isEmpty || _submitting) return;

    final parsed = parseCaptureInput(raw);

    setState(() => _submitting = true);
    try {
      final item = await ref.read(
        quickCreateProvider((
          content: parsed.content,
          tags: parsed.tags.isEmpty ? null : parsed.tags.join(','),
        )).future,
      );

      if (!mounted) return;

      if (item == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('无法识别内容')),
        );
        return;
      }

      _controller.clear();

      ref.invalidate(dashboardItemsProvider);
      ref.invalidate(dashboardPinnedProvider);
      ref.invalidate(dashboardStatsProvider);

      final message = switch (item.pluginId) {
        'collections' => '已收藏',
        'thoughts' => '想法已记录',
        _ => '已记录',
      };

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final colors = context.appColors;

    return Focus(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.enter &&
            HardwareKeyboard.instance.isControlPressed) {
          unawaited(_submit());
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.25),
          ),
          boxShadow: const [AppShadows.cardSoft],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                AppIconBubble(
                  icon: Icons.edit_outlined,
                  color: colorScheme.onPrimaryContainer,
                  background: colorScheme.primaryContainer,
                  size: 40,
                  iconSize: 20,
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  '快速捕捉',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: AppFontTokens.extraBold,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surfaceMuted,
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                  child: Text(
                    'Ctrl+Enter 保存',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.textTertiary,
                      fontSize: AppFontTokens.caption,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            // Input field
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              minLines: 1,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: '输入想法、粘贴 URL... 支持 #标签',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide(color: colors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide(color: colors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.md),
            // Actions row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surfaceMuted,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.sell_outlined,
                          size: 14, color: colors.textTertiary),
                      const SizedBox(width: AppSpacing.xxs),
                      Text(
                        '#标签',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _controller.text.trim().isEmpty || _submitting
                      ? null
                      : _submit,
                  icon: Icon(
                    Icons.send_rounded,
                    size: 18,
                    color: _controller.text.trim().isEmpty || _submitting
                        ? null
                        : Colors.white,
                  ),
                  label: Text(_submitting ? '记录中' : '记录'),
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
