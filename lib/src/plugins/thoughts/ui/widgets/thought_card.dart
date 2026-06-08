import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uni_hub/src/core/theme/app_tokens.dart';
import 'package:uni_hub/src/shared/tags/tag_models.dart';
import 'package:uni_hub/src/shared/widgets/tags/app_tag_chip.dart';
import '../../data/thought_content_codec.dart';
import '../../data/thought_image_service.dart';
import 'package:uni_hub/src/shared/tags/providers/tags_providers.dart';

/// A thought card in the thoughts list.
///
/// Tags are loaded reactively from [tagsForThoughtProvider] so they always
/// show the correct colours and names regardless of where the tag was
/// created or edited.
class ThoughtCard extends ConsumerStatefulWidget {
  final int id;
  final String content;
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

    // Load tags from the new tag relation table.
    final tagsAsync = ref.watch(tagsForThoughtProvider(widget.id));
    final tagList = tagsAsync.valueOrNull ?? const <AppTag>[];

    final accent = widget.color != null
        ? _hexToColor(widget.color!)
        : _cardAccent(widget.id, colorScheme);
    final images = ThoughtImageService.decodeImagePaths(widget.imagePaths);
    final title = ThoughtContentCodec.titleFromStored(widget.content);
    final body = ThoughtContentCodec.plainTextFromStored(widget.content);

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
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
                _buildTagsSection(theme, tagList, images, accent),
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
      style: theme.textTheme.titleSmall?.copyWith(
        fontWeight: AppFontTokens.bold,
      ),
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

  // ---------------------------------------------------------------
  // Tags section — uses AppTagChip.fromTag for stable colour tokens
  // ---------------------------------------------------------------

  Widget _buildTagsSection(
    ThemeData theme,
    List<AppTag> tagList,
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
            children: _buildTagChips(tagList),
          ),
        ),
        if (images.isNotEmpty) ...[
          const SizedBox(width: AppSpacing.xs),
          Icon(
            Icons.image_outlined,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ],
    );
  }

  List<Widget> _buildTagChips(List<AppTag> tags) {
    const maxVisible = 3;
    final visible = tags.take(maxVisible).toList();
    final overflow = tags.length - maxVisible;

    return [
      ...visible.map(
        (tag) => AppTagChip.fromTag(
          tag: tag,
          compact: true,
          onTap: () => widget.onTagTap(tag.name),
        ),
      ),
      if (overflow > 0)
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxs,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Text(
            '+$overflow',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
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
