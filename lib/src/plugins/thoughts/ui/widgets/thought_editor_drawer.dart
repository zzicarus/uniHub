import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../data/thought_image_service.dart';
import '../../providers/thoughts_providers.dart';

class ThoughtEditorDrawer extends ConsumerStatefulWidget {
  final int thoughtId;

  const ThoughtEditorDrawer({required this.thoughtId, super.key});

  @override
  ConsumerState<ThoughtEditorDrawer> createState() =>
      _ThoughtEditorDrawerState();
}

class _ThoughtEditorDrawerState extends ConsumerState<ThoughtEditorDrawer> {
  final _contentCtrl = TextEditingController();
  final _tagCtrl = TextEditingController();
  final _tagChips = <String>[];
  String? _color;
  bool _pinned = false;
  bool _archived = false;
  bool _loaded = false;
  bool _dirty = false;
  bool _preview = false;
  List<String> _images = [];
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _contentCtrl.dispose();
    _tagCtrl.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 2), _save);
  }

  void _load() {
    if (_loaded) return;
    ref.read(thoughtProvider(widget.thoughtId)).whenData((t) {
      if (t == null || _loaded) return;
      setState(() {
        _contentCtrl.text = t.content;
        _tagChips.addAll((t.tags ?? '')
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty));
        _color = t.color;
        _pinned = t.isPinned;
        _archived = t.archivedAt != null;
        _images = ThoughtImageService.decodeImagePaths(t.imagePaths);
        _loaded = true;
        _dirty = false;
      });
    });
  }

  Future<void> _save() async {
    if (!_dirty || !_loaded) return;
    await ref.read(thoughtsRepositoryProvider).updateThought(
          widget.thoughtId,
          content: _contentCtrl.text.trim(),
          tags: _tagChips.isNotEmpty ? _tagChips.join(',') : null,
          color: _color,
          isPinned: _pinned,
          imagePaths: ThoughtImageService.encodeImagePaths(_images),
        );
    ref.invalidate(thoughtProvider(widget.thoughtId));
    ref.invalidate(thoughtsListProvider);
    if (mounted) setState(() => _dirty = false);
  }

  Future<void> _close() async {
    await _save();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _addImage() async {
    final svc = ref.read(thoughtImageServiceProvider);
    final path = await svc.pickImage();
    if (path != null) {
      setState(() => _images.add(path));
      // Insert image markdown at cursor position
      final uri = Uri.file(path).toString();
      final t = _contentCtrl.text;
      final st = _contentCtrl.selection.start;
      final prefix = st > 0 && t[st - 1] != '\n' ? '\n' : '';
      final img = '$prefix![](file://$uri)\n';
      final nt = '${t.substring(0, st)}$img${t.substring(st)}';
      _contentCtrl.value = TextEditingValue(
        text: nt,
        selection: TextSelection.collapsed(offset: st + img.length),
      );
      _markDirty();
    }
  }

  Future<void> _removeImage(int i) async {
    await ref.read(thoughtImageServiceProvider).deleteImage(_images[i]);
    setState(() => _images.removeAt(i));
    _markDirty();
  }

  void _fmt(String pre, [String suf = '']) {
    final t = _contentCtrl.text;
    final s = _contentCtrl.selection;
    final st = s.start, en = s.end;
    String nt;
    int cp;
    if (st == en) {
      nt = '${t.substring(0, st)}$pre$suf${t.substring(en)}';
      cp = st + pre.length;
    } else {
      nt = '${t.substring(0, st)}$pre${t.substring(st, en)}$suf${t.substring(en)}';
      cp = en + pre.length + suf.length;
    }
    _contentCtrl.value = TextEditingValue(
      text: nt,
      selection: TextSelection.collapsed(offset: cp),
    );
    _markDirty();
  }

  void _fmtBlock(String pre, [String suf = '']) {
    final t = _contentCtrl.text;
    final s = _contentCtrl.selection;
    final st = s.start;
    final pre2 = st > 0 && t[st - 1] != '\n' ? '\n$pre' : pre;
    final suf2 = suf.isNotEmpty && st >= t.length ? '\n$suf' : suf;
    final nt = '${t.substring(0, st)}$pre2$suf2${t.substring(st)}';
    _contentCtrl.value = TextEditingValue(
      text: nt,
      selection: TextSelection.collapsed(offset: st + pre2.length),
    );
    _markDirty();
  }

  Future<void> _archive() async {
    await ref.read(thoughtsRepositoryProvider).archiveThought(widget.thoughtId);
    ref.invalidate(thoughtsListProvider);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _restore() async {
    await ref.read(thoughtsRepositoryProvider).restoreThought(widget.thoughtId);
    ref.invalidate(thoughtsListProvider);
    if (mounted) setState(() => _archived = false);
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('删除想法'),
        content: const Text('确定要删除吗？此操作不可撤销。'),
        actions: [
          TextButton(onPressed: () => Navigator.of(c).pop(false), child: const Text('取消')),
          FilledButton(
            onPressed: () => Navigator.of(c).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await ref.read(thoughtImageServiceProvider).deleteImages(_images);
    await ref.read(thoughtsRepositoryProvider).deleteThought(widget.thoughtId);
    ref.invalidate(thoughtsListProvider);
    if (mounted) Navigator.of(context).pop();
  }

  /// Pre-process markdown so single newlines render as `<br>` instead of spaces.
  /// Fenced code blocks are preserved as-is.
  String _preprocessMd(String text) {
    final buf = StringBuffer();
    final lines = text.split('\n');
    var inCode = false;
    for (final line in lines) {
      if (line.trimLeft().startsWith('```')) {
        inCode = !inCode;
        buf.writeln(line);
        continue;
      }
      if (inCode || line.isEmpty) {
        buf.writeln(line);
      } else {
        // Two trailing spaces = markdown hard line break
        buf.writeln('$line  ');
      }
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    _load();
    final theme = Theme.of(context);

    return SafeArea(
      child: Column(children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Row(children: [
            Expanded(
              child: Text(
                _archived ? '编辑想法（已归档）' : '编辑想法',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            IconButton(icon: const Icon(Icons.close), tooltip: '关闭（自动保存）', onPressed: _close),
          ]),
        ),
        const Divider(height: 1),

        // Toolbar
        Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
            child: Row(children: [
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('编辑'), icon: Icon(Icons.edit_outlined, size: 16)),
                  ButtonSegment(value: true, label: Text('预览'), icon: Icon(Icons.visibility_outlined, size: 16)),
                ],
                selected: {_preview},
                onSelectionChanged: (v) => setState(() => _preview = v.first),
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ]),
          ),
          if (!_preview)
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                children: [
                  _Tb(icon: Icons.format_bold, tip: '加粗', onTap: () => _fmt('**', '**')),
                  _Tb(icon: Icons.format_italic, tip: '斜体', onTap: () => _fmt('*', '*')),
                  _Td(),
                  _Tb(txt: 'H1', tip: '标题 1', onTap: () => _fmtBlock('# ')),
                  _Tb(txt: 'H2', tip: '标题 2', onTap: () => _fmtBlock('## ')),
                  _Tb(txt: 'H3', tip: '标题 3', onTap: () => _fmtBlock('### ')),
                  _Td(),
                  _Tb(icon: Icons.format_list_bulleted, tip: '无序列表', onTap: () => _fmtBlock('- ')),
                  _Tb(icon: Icons.format_list_numbered, tip: '有序列表', onTap: () => _fmtBlock('1. ')),
                  _Tb(icon: Icons.format_quote, tip: '引用', onTap: () => _fmtBlock('> ')),
                  _Td(),
                  _Tb(icon: Icons.code, tip: '代码块', onTap: () => _fmtBlock('```\n', '\n```')),
                  _Tb(icon: Icons.table_chart_outlined, tip: '表格', onTap: () => _fmtBlock('| 列1 | 列2 |\n|------|------|\n|  |  |')),
                  _Tb(icon: Icons.checklist, tip: '任务列表', onTap: () => _fmtBlock('- [ ] ')),
                  _Tb(icon: Icons.horizontal_rule, tip: '分割线', onTap: () => _fmtBlock('\n---\n')),
                  _Td(),
                  _Tb(icon: Icons.image_outlined, tip: '插入图片', onTap: _addImage),
                ],
              ),
            ),
        ]),
        const Divider(height: 1),

        // Content area
        Expanded(child: _buildContent(theme)),

        // Images
        if (_images.isNotEmpty || _loaded) ...[
          const Divider(height: 1),
          _buildImages(theme),
        ],

        // Footer
        const Divider(height: 1),
        _buildFooter(theme),
      ]),
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (!_loaded) return const Center(child: CircularProgressIndicator());

    if (_preview) {
      return GestureDetector(
        onTap: () => setState(() => _preview = false),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: MarkdownBody(
            data: _preprocessMd(_contentCtrl.text),
            selectable: true,
            styleSheet: MarkdownStyleSheet(
              h1: theme.textTheme.headlineSmall,
              h2: theme.textTheme.titleLarge,
              h3: theme.textTheme.titleMedium,
              p: theme.textTheme.bodyLarge,
              listBullet: theme.textTheme.bodyLarge,
              code: TextStyle(backgroundColor: AppColors.surfaceMuted, fontSize: 13),
              codeblockDecoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              blockquoteDecoration: BoxDecoration(
                border: Border(left: BorderSide(color: AppColors.primary, width: 3)),
                color: AppColors.primarySoft,
              ),
              tableBorder: TableBorder.all(color: AppColors.border),
              tableHead: theme.textTheme.titleSmall,
            ),
            // ignore: deprecated_member_use
            imageBuilder: (uri, title, alt) {
              if (uri.scheme == 'file') {
                final f = File(uri.toFilePath());
                if (f.existsSync()) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: Image.file(f, fit: BoxFit.contain, errorBuilder: (context, error, stackTrace) => const SizedBox.shrink()),
                    ),
                  );
                }
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: TextField(
        controller: _contentCtrl,
        minLines: 8,
        maxLines: null,
        textInputAction: TextInputAction.newline,
        onChanged: (_) => _markDirty(),
        decoration: const InputDecoration(
          hintText: '记录你的想法...支持 Markdown 语法',
          border: InputBorder.none,
          isCollapsed: true,
          contentPadding: EdgeInsets.zero,
        ),
        style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
        keyboardType: TextInputType.multiline,
      ),
    );
  }

  Widget _buildImages(ThemeData theme) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 100),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          Text('图片', style: theme.textTheme.labelMedium),
          const SizedBox(width: AppSpacing.sm),
          Text('${_images.length} 张', style: theme.textTheme.bodySmall),
          const Spacer(),
          TextButton.icon(
            onPressed: _addImage,
            icon: const Icon(Icons.add_photo_alternate_outlined, size: 16),
            label: const Text('添加'),
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ]),
        const SizedBox(height: AppSpacing.xs),
        Expanded(
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _images.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (_, i) {
              final f = File(_images[i]);
              return Stack(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: f.existsSync()
                      ? Image.file(f, width: 80, height: 80, fit: BoxFit.cover)
                      : Container(width: 80, height: 80, color: AppColors.surfaceMuted, child: const Icon(Icons.broken_image_outlined)),
                ),
                Positioned(
                  top: 2, right: 2,
                  child: GestureDetector(
                    onTap: () => _removeImage(i),
                    child: Container(
                      decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                      padding: const EdgeInsets.all(2),
                      child: const Icon(Icons.close, size: 14, color: Colors.white),
                    ),
                  ),
                ),
              ]);
            },
          ),
        ),
      ]),
    );
  }

  Widget _buildFooter(ThemeData theme) {
    if (!_loaded) return const SizedBox.shrink();

    return Container(
      constraints: const BoxConstraints(maxHeight: 260),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
          // Tags
          Text('标签', style: theme.textTheme.labelMedium),
          const SizedBox(height: AppSpacing.xs),
          if (_tagChips.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Wrap(
                spacing: AppSpacing.xxs, runSpacing: AppSpacing.xxs,
                children: _tagChips.map((t) => Chip(
                  label: Text(t), labelStyle: const TextStyle(fontSize: 12),
                  deleteIcon: const Icon(Icons.close, size: 14),
                  onDeleted: () { setState(() => _tagChips.remove(t)); _markDirty(); },
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                )).toList(),
              ),
            ),
          TextField(
            controller: _tagCtrl,
            onChanged: (v) {
              final d = v.contains(',') ? ',' : ' ';
              if (!v.endsWith(d)) return;
              final tag = v.substring(0, v.length - 1).trim();
              if (tag.isNotEmpty && !_tagChips.contains(tag)) {
                setState(() => _tagChips.add(tag));
                _markDirty();
              }
              _tagCtrl.clear();
            },
            decoration: const InputDecoration(hintText: '添加标签（空格/逗号分隔）', isDense: true),
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),

          // Color
          Text('颜色', style: theme.textTheme.labelMedium),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm, runSpacing: AppSpacing.sm,
            children: [
              _Cd(color: null, label: '默认', sel: _color == null, onTap: () { setState(() => _color = null); _markDirty(); }),
              ..._colors.map((c) => _Cd(color: c, sel: _color == _hex(c), onTap: () { setState(() => _color = _hex(c)); _markDirty(); })),
            ],
          ),

          // Pin
          if (!_archived)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('置顶'),
              value: _pinned,
              onChanged: (v) { setState(() => _pinned = v); _markDirty(); },
              activeThumbColor: AppColors.warning,
              dense: true,
            ),
          const SizedBox(height: AppSpacing.sm),

          // Actions
          if (_archived)
            OutlinedButton.icon(onPressed: _restore, icon: const Icon(Icons.unarchive_outlined, size: 18), label: const Text('恢复'))
          else ...[
            OutlinedButton.icon(onPressed: _archive, icon: const Icon(Icons.archive_outlined, size: 18), label: const Text('归档')),
            const SizedBox(height: AppSpacing.xs),
            OutlinedButton.icon(
              onPressed: _delete, icon: const Icon(Icons.delete_outline, size: 18), label: const Text('删除'),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error)),
            ),
          ],
        ]),
      ),
    );
  }
}

// ── Toolbar button ──

class _Tb extends StatelessWidget {
  final IconData? icon;
  final String? txt;
  final String tip;
  final VoidCallback onTap;
  const _Tb({this.icon, this.txt, required this.tip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: IconButton(
        icon: txt != null ? Text(txt!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)) : Icon(icon, size: 20),
        tooltip: tip,
        onPressed: onTap,
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
        padding: EdgeInsets.zero,
      ),
    );
  }
}

class _Td extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 3), color: AppColors.border);
  }
}

// ── Color dot ──

class _Cd extends StatelessWidget {
  final Color? color;
  final String? label;
  final bool sel;
  final VoidCallback onTap;
  const _Cd({this.color, this.label, required this.sel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color ?? AppColors.surfaceMuted,
          border: Border.all(color: sel ? AppColors.primary : AppColors.border, width: sel ? 2.5 : 1.5),
        ),
        child: color == null
            ? Center(child: Text('A', style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)))
            : null,
      ),
    );
  }
}

const _colors = [
  AppColors.primary,
  AppColors.secondary,
  AppColors.accent,
  AppColors.purple,
  AppColors.success,
  AppColors.warning,
  AppColors.error,
];

String _hex(Color c) => '#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
