/// Editor Workspace — 可编辑真实 thought 的工作台。
///
/// ### 布局结构
/// ```
/// ThoughtEditorWorkspace
/// ├── 半透明 backdrop（通过 showDialog barrierColor 实现）
/// ├── 居中工作台卡片
/// │   ├── _WorkspaceHeader (h: 64)
/// │   ├── _WorkspaceBody (flex, Row)
/// │   │   ├── _MainEditorColumn (Expanded) — 标题 + AppFlowy Editor
/// │   │   └── _PropertyRail (w: 320) — 标签 / 图片 / 颜色 / 置顶
/// │   └── _WorkspaceFooter (h: 72)
/// ```
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:uni_hub/src/core/theme/app_tokens.dart';
import 'package:uni_hub/src/core/theme/app_theme_tokens.dart';
import 'package:uni_hub/src/shared/editor/appflowy_thought_editor.dart';

import 'package:uni_hub/src/shared/widgets/tags/app_tag_input.dart';

import 'thought_color_picker.dart';
import 'thought_editor_controller.dart';

// ---------------------------------------------------------------------------
// ThoughtEditorWorkspace
// ---------------------------------------------------------------------------

/// 编辑工作台 Modal，在覆盖层中居中显示。
///
/// 使用方式：
/// ```dart
/// ThoughtEditorWorkspace.show(context, thoughtId: id);
/// ```
class ThoughtEditorWorkspace extends ConsumerStatefulWidget {
  const ThoughtEditorWorkspace({
    required this.thoughtId,
    this.onClose,
    super.key,
  });

  /// 当前编辑的想法 ID。
  final int thoughtId;

  /// 关闭回调。
  final VoidCallback? onClose;

  /// 以覆盖层方式打开编辑工作台。
  static void show(BuildContext context, {required int thoughtId}) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withAlpha(100),
      builder: (_) => ThoughtEditorWorkspace(
        thoughtId: thoughtId,
        onClose: () => Navigator.of(context, rootNavigator: true).pop(),
      ),
    );
  }

  @override
  ConsumerState<ThoughtEditorWorkspace> createState() =>
      _ThoughtEditorWorkspaceState();
}

class _ThoughtEditorWorkspaceState
    extends ConsumerState<ThoughtEditorWorkspace> {
  late final ThoughtEditorController _ctrl;
  late final AppFlowyThoughtEditorController _editorController;

  @override
  void initState() {
    super.initState();
    _editorController = AppFlowyThoughtEditorController();
    _ctrl = ThoughtEditorController(
      ref: ref,
      thoughtId: widget.thoughtId,
      autoSaveInterval: const Duration(seconds: 2),
      editorController: _editorController,
      onStateChanged: () {
        if (mounted) setState(() {});
      },
    )..initialize();
    unawaited(_ctrl.load());
  }

  @override
  void dispose() {
    _editorController.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    await _ctrl.save();
    widget.onClose?.call();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth.clamp(1040.0, 1180.0);
        final availHeight = constraints.maxHeight;
        final cardHeight = (availHeight * 0.90)
            .clamp(availHeight * 0.86, availHeight * 0.92);

        return Center(
          child: SizedBox(
            width: cardWidth,
            height: cardHeight,
            child: Material(
              color: colors.surface,
              borderRadius: BorderRadius.circular(22),
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              shadowColor: Colors.black26,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Column(
                  children: [
                    _WorkspaceHeader(
                      isLoaded: _ctrl.isLoaded,
                      isDirty: _ctrl.isDirty,
                      onClose: _close,
                    ),
                    Expanded(
                      child: _WorkspaceBody(ctrl: _ctrl),
                    ),
                    _WorkspaceFooter(
                      onDelete: _onDelete,
                      onClose: _close,
                      onSave: _onSave,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _onDelete() async {
    await _ctrl.delete(context);
    if (mounted) widget.onClose?.call();
  }

  Future<void> _onSave() async {
    await _ctrl.save();
  }
}

// ===========================================================================
// _WorkspaceHeader
// ===========================================================================

class _WorkspaceHeader extends StatelessWidget {
  const _WorkspaceHeader({
    required this.isLoaded,
    required this.isDirty,
    required this.onClose,
  });

  final bool isLoaded;
  final bool isDirty;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appColors;

    // Determine save status label and color.
    final (String statusText, Color statusBg, Color statusFg) = switch ((
      isLoaded,
      isDirty,
    )) {
      (false, _) => ('加载中...', colors.surfaceMuted, colors.textTertiary),
      (true, true) => ('有未保存修改', colors.warningSoft, colors.warning),
      (true, false) => ('草稿已自动保存', colors.primarySoft, colors.primary),
    };

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          bottom: BorderSide(color: colors.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Title
          Text(
            '编辑想法',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),

          const SizedBox(width: AppSpacing.sm),

          // Save status badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(AppRadius.xs),
            ),
            child: Text(
              statusText,
              style: theme.textTheme.labelSmall?.copyWith(
                color: statusFg,
                fontSize: 11,
              ),
            ),
          ),

          const Spacer(),

          // Close button
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            tooltip: '关闭（自动保存）',
            onPressed: onClose,
            style: IconButton.styleFrom(
              minimumSize: const Size(AppSizes.iconButton, AppSizes.iconButton),
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// _WorkspaceBody
// ===========================================================================

class _WorkspaceBody extends StatelessWidget {
  const _WorkspaceBody({required this.ctrl});

  final ThoughtEditorController ctrl;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: _MainEditorColumn(ctrl: ctrl)),
        _PropertyRail(ctrl: ctrl),
      ],
    );
  }
}

// ===========================================================================
// _MainEditorColumn
// ===========================================================================

class _MainEditorColumn extends StatefulWidget {
  const _MainEditorColumn({required this.ctrl});

  final ThoughtEditorController ctrl;

  @override
  State<_MainEditorColumn> createState() => _MainEditorColumnState();
}

class _MainEditorColumnState extends State<_MainEditorColumn> {
  late TextEditingController _titleCtrl;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: _firstLine);
  }

  @override
  void didUpdateWidget(_MainEditorColumn oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync title when plainText changes externally.
    final newFirstLine = _firstLine;
    if (_titleCtrl.text != newFirstLine) {
      _titleCtrl.text = newFirstLine;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  /// Returns the first non-empty line of [ctrl.plainText].
  String get _firstLine {
    final text = widget.ctrl.plainText.trim();
    if (text.isEmpty) return '';
    return text.split('\n').first.trim();
  }

  void _onTitleChanged(String value) {
    // Update the first line of plainText.  The document JSON is managed
    // by AppFlowyThoughtEditor below; updating plainText here keeps the
    // title in sync for save / display purposes.
    final lines = widget.ctrl.plainText.split('\n');
    if (lines.isNotEmpty) {
      lines[0] = value;
      widget.ctrl.plainText = lines.join('\n');
      widget.ctrl.markDirty();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: colors.border, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title input
          Container(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: TextField(
              controller: _titleCtrl,
              onChanged: _onTitleChanged,
              decoration: InputDecoration(
                hintText: '输入标题...',
                hintStyle: theme.textTheme.headlineSmall?.copyWith(
                  color: colors.textTertiary,
                  fontWeight: FontWeight.w700,
                ),
                border: InputBorder.none,
                isCollapsed: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
          ),

          // Toolbar hint
          Container(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.xs,
            ),
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: colors.surfaceMuted,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(
                children: [
                  const SizedBox(width: AppSpacing.xs),
                  _toolbarHint(theme, Icons.format_bold),
                  _toolbarHint(theme, Icons.format_italic),
                  _toolbarHint(theme, Icons.format_underlined),
                  _toolbarHint(theme, Icons.format_list_bulleted),
                  _toolbarHint(theme, Icons.format_list_numbered),
                  _toolbarHint(theme, Icons.title),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      '/ 命令',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.textTertiary,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // AppFlowy Thought Editor
          Expanded(
            child: widget.ctrl.isLoaded
                ? AppFlowyThoughtEditor(
                    key: ValueKey('thought-editor-${widget.ctrl.thoughtId}'),
                    initialJson: widget.ctrl.documentJson,
                    initialText: widget.ctrl.plainText,
                    placeholder: '开始书写你的想法...',
                    autofocus: false,
                    controller: widget.ctrl.editorController,
                    onChanged: (value) {
                      widget.ctrl.updateDocument(
                        documentJson: value.documentJson,
                        plainText: value.plainText,
                      );
                    },
                  )
                : Center(
                    child: Text(
                      '加载中...',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.textTertiary,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _toolbarHint(ThemeData theme, IconData icon) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Container(
        width: 30,
        height: 28,
        alignment: Alignment.center,
        child: Icon(icon, size: 16, color: colors.textSecondary),
      ),
    );
  }
}

// ===========================================================================
// _PropertyRail
// ===========================================================================

class _PropertyRail extends StatelessWidget {
  const _PropertyRail({required this.ctrl});

  final ThoughtEditorController ctrl;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return SizedBox(
      width: 320,
      child: Container(
        color: colors.surfaceMuted,
        child: Column(
          children: [
            _TagsCard(ctrl: ctrl),
            _ImagesCard(ctrl: ctrl),
            _AppearanceCard(ctrl: ctrl),
            _StatusCard(ctrl: ctrl),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _TagsCard
// ---------------------------------------------------------------------------

class _TagsCard extends StatelessWidget {
  const _TagsCard({required this.ctrl});

  final ThoughtEditorController ctrl;

  @override
  Widget build(BuildContext context) {
    return _PropertyCard(
      title: '标签',
      child: AppTagInput(
        tags: ctrl.tags,
        onChanged: ctrl.setTags,
        label: null,
        hintText: '添加标签',
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _ImagesCard
// ---------------------------------------------------------------------------

class _ImagesCard extends StatelessWidget {
  const _ImagesCard({required this.ctrl});

  final ThoughtEditorController ctrl;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final refs = ctrl.imageRefs;

    return _PropertyCard(
      title: '图片',
      subtitle: '正文图片',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (refs.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: refs.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: AppSpacing.xxs),
                  itemBuilder: (context, index) {
                    final ref = refs[index];
                    return Chip(
                      label: Text(
                        '图片 ${index + 1}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      deleteIcon: const Icon(Icons.close, size: 14),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      onDeleted: () => ctrl.removeImageFromDocument(ref.id),
                    );
                  },
                ),
              ),
            ),

          TextButton.icon(
            onPressed: () => ctrl.insertImageIntoDocument(),
            icon: const Icon(Icons.add_photo_alternate_outlined, size: 16),
            label: Text(
              refs.isEmpty ? '添加图片' : '继续添加',
              style: const TextStyle(fontSize: 13),
            ),
            style: TextButton.styleFrom(
              foregroundColor: colors.primary,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 28),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _AppearanceCard
// ---------------------------------------------------------------------------

class _AppearanceCard extends StatelessWidget {
  const _AppearanceCard({required this.ctrl});

  final ThoughtEditorController ctrl;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final availableColors = thoughtAvailableColors(colorScheme);

    return _PropertyCard(
      title: '外观',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // "默认" color dot (null color)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              // No-color option
              ThoughtColorDot(
                color: null,
                label: '默认',
                isSelected: ctrl.selectedColor == null,
                size: 32,
                onTap: () => ctrl.setColor(null),
              ),

              // Palette
              ...availableColors.map((c) {
                final hex = thoughtColorToHex(c);
                return ThoughtColorDot(
                  color: c,
                  isSelected: ctrl.selectedColor == hex,
                  size: 32,
                  onTap: () => ctrl.setColor(hex),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _StatusCard
// ---------------------------------------------------------------------------

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.ctrl});

  final ThoughtEditorController ctrl;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return _PropertyCard(
      title: '状态',
      child: Row(
        children: [
          Text(
            '置顶',
            style: TextStyle(
              fontSize: 13,
              color: colors.textSecondary,
            ),
          ),
          const Spacer(),
          Switch(
            value: ctrl.isPinned,
            onChanged: ctrl.togglePin,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _PropertyCard (通用属性卡片容器)
// ---------------------------------------------------------------------------

class _PropertyCard extends StatelessWidget {
  const _PropertyCard({
    required this.title,
    this.subtitle,
    required this.child,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: colors.border, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Row(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(width: AppSpacing.xxs),
                  Text(
                    '· $subtitle',
                    style: TextStyle(
                      color: colors.textTertiary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          DefaultTextStyle(
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 13,
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// _WorkspaceFooter
// ===========================================================================

class _WorkspaceFooter extends StatelessWidget {
  const _WorkspaceFooter({
    required this.onDelete,
    required this.onClose,
    required this.onSave,
  });

  final VoidCallback onDelete;
  final VoidCallback onClose;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appColors;

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          top: BorderSide(color: colors.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Delete thought
          TextButton.icon(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('删除想法'),
            style: TextButton.styleFrom(
              foregroundColor: colors.textTertiary,
              visualDensity: VisualDensity.compact,
            ),
          ),

          const SizedBox(width: AppSpacing.sm),

          // Ctrl + Enter hint
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
              'Ctrl+Enter 快速保存',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.textTertiary,
                fontSize: 11,
              ),
            ),
          ),

          const Spacer(),

          // Close
          OutlinedButton(
            onPressed: onClose,
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.textSecondary,
              side: BorderSide(color: colors.border),
              visualDensity: VisualDensity.compact,
            ),
            child: const Text('关闭'),
          ),

          const SizedBox(width: AppSpacing.sm),

          // Save
          FilledButton(
            onPressed: onSave,
            style: FilledButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: Colors.white,
              visualDensity: VisualDensity.compact,
            ),
            child: const Text('保存想法'),
          ),
        ],
      ),
    );
  }
}
