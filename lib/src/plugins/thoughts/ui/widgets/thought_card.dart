import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uni_hub/src/core/theme/app_tokens.dart';
import '../../data/thought_content_codec.dart';
import '../../data/thought_image_service.dart';

class ThoughtCard extends ConsumerStatefulWidget {
  final int id;
  final String content;
  final String? tags;
  final String? color;
  final bool isPinned;
  final DateTime createdAt;
  final String? imagePaths;
  final VoidCallback onTap;
  final void Function(String tag) onTagTap;
  final VoidCallback? onContextMenu;

  const ThoughtCard({
    required this.id,
    required this.content,
    required this.tags,
    required this.color,
    required this.isPinned,
    required this.createdAt,
    this.imagePaths,
    required this.onTap,
    required this.onTagTap,
    this.onContextMenu,
    super.key,
  });

  @override
  ConsumerState<ThoughtCard> createState() => _ThoughtCardState();
}

class _ThoughtCardState extends ConsumerState<ThoughtCard> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tagList = (widget.tags ?? '')
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final accent = widget.color != null
        ? _hexToColor(widget.color!)
        : _cardAccent(widget.id, colorScheme);
    final images = ThoughtImageService.decodeImagePaths(widget.imagePaths);
    final title = ThoughtContentCodec.titleFromStored(widget.content);
    final body = ThoughtContentCodec.plainTextFromStored(widget.content);

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.85),
            ),
            boxShadow: const [AppShadows.cardSoft],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderRow(theme, colorScheme),
              const SizedBox(height: AppSpacing.xs),
              _buildTitle(theme, title),
              const SizedBox(height: AppSpacing.xxs),
              Expanded(child: _buildBody(theme, colorScheme, body)),
              if (tagList.isNotEmpty || images.isNotEmpty)
                _buildTagsSection(theme, colorScheme, tagList, images, accent),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderRow(ThemeData theme, ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          child: Text(
            _formatTimestamp(widget.createdAt),
            style: theme.textTheme.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (widget.isPinned)
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.xxs),
            child: Icon(
              Icons.push_pin_rounded,
              size: 18,
              color: colorScheme.primary,
            ),
          )
        else if (widget.onContextMenu != null)
          GestureDetector(
            onTap: widget.onContextMenu,
            child: Icon(
              Icons.more_horiz_rounded,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }

  Widget _buildTitle(ThemeData theme, String title) {
    return Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.titleSmall?.copyWith(fontWeight: AppFontTokens.bold),
    );
  }

  Widget _buildBody(ThemeData theme, ColorScheme colorScheme, String body) {
    return Text(
      body,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.bodySmall?.copyWith(
        color: colorScheme.onSurfaceVariant,
        height: 1.45,
      ),
    );
  }

  Widget _buildTagsSection(
    ThemeData theme,
    ColorScheme colorScheme,
    List<String> tagList,
    List<String> images,
    Color accent,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Wrap(
            spacing: AppSpacing.xxs,
            runSpacing: AppSpacing.xxs,
            children: _buildTagChips(tagList, theme, accent),
          ),
        ),
        if (images.isNotEmpty) ...[
          const SizedBox(width: AppSpacing.xs),
          Icon(
            Icons.image_outlined,
            size: 16,
            color: colorScheme.onSurfaceVariant,
          ),
        ],
      ],
    );
  }

  List<Widget> _buildTagChips(
    List<String> tagList,
    ThemeData theme,
    Color accent,
  ) {
    const maxVisible = 3;
    final visible = tagList.take(maxVisible).toList();
    final overflow = tagList.length - maxVisible;

    return [
      ...visible.map((tag) {
        return ActionChip(
          label: Text(
            '#$tag',
            style: theme.textTheme.labelMedium?.copyWith(
              color: accent,
              fontWeight: AppFontTokens.extraBold,
              fontSize: AppFontTokens.caption,
            ),
          ),
          onPressed: () => widget.onTagTap(tag),
          backgroundColor: accent.withValues(alpha: 0.10),
          side: BorderSide.none,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs - 2),
        );
      }),
      if (overflow > 0)
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxs,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Text(
            '+$overflow',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: AppFontTokens.semiBold,
              fontSize: AppFontTokens.caption,
            ),
          ),
        ),
    ];
  }

  Color _hexToColor(String hex) {
    final cleaned = hex.replaceFirst('#', '');
    final normalized = cleaned.length == 6 ? 'FF$cleaned' : cleaned;
    final intVal = int.tryParse(normalized, radix: 16);
    return Color(intVal ?? Theme.of(context).colorScheme.primary.toARGB32());
  }

  Color _cardAccent(int index, ColorScheme colorScheme) {
    final accents = [
      colorScheme.tertiary,
      colorScheme.secondary,
      colorScheme.primary,
      colorScheme.error,
    ];
    return accents[index % accents.length];
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final date = DateTime(dt.year, dt.month, dt.day);

    if (date == today) {
      return '今天 ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } else if (date == yesterday) {
      return '昨天 ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } else if (dt.year == now.year) {
      return '${dt.month}月${dt.day}日 ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}
