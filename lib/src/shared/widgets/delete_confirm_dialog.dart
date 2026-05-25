import 'package:flutter/material.dart';
import 'package:uni_hub/src/core/theme/app_tokens.dart';
import 'package:uni_hub/src/shared/preferences/delete_confirm_prefs.dart';
import 'package:uni_hub/src/shared/widgets/website_logo.dart';

/// Result of a delete confirmation dialog.
enum DeleteConfirmResult {
  /// User cancelled the dialog.
  cancel,

  /// User confirmed deletion (full delete from all boxes).
  delete,

  /// User chose to only remove from the current box (multi-box scenario).
  removeFromBox,
}

/// A polished destructive confirmation dialog for collection items.
class DeleteConfirmDialog extends StatefulWidget {
  @visibleForTesting
  const DeleteConfirmDialog({
    super.key,
    required this.mode,
    this.itemTitle,
    this.itemSource,
    this.itemTypeLabel,
    this.itemRelativeTime,
    this.localLogoPath,
    this.fallbackIcon,
    this.count,
    required this.prefs,
  });

  final DialogMode mode;
  final String? itemTitle;
  final String? itemSource;
  final String? itemTypeLabel;
  final String? itemRelativeTime;
  final String? localLogoPath;
  final IconData? fallbackIcon;
  final int? count;
  final DeleteConfirmPrefs prefs;

  // ---------------------------------------------------------------
  // Static show methods
  // ---------------------------------------------------------------

  /// Show a single-item delete confirmation dialog.
  ///
  /// Returns [DeleteConfirmResult.delete] immediately if the user has
  /// opted out of confirmations. Returns null if dialog was dismissed.
  static Future<DeleteConfirmResult?> showSingle({
    required BuildContext context,
    required String title,
    required String source,
    required String typeLabel,
    required String relativeTime,
    String? localLogoPath,
    required IconData fallbackIcon,
    required DeleteConfirmPrefs prefs,
  }) async {
    if (!prefs.confirmDeleteSingleItem) {
      return DeleteConfirmResult.delete;
    }

    return showDialog<DeleteConfirmResult>(
      context: context,
      builder: (ctx) => DeleteConfirmDialog(
        mode: DialogMode.single,
        itemTitle: title,
        itemSource: source,
        itemTypeLabel: typeLabel,
        itemRelativeTime: relativeTime,
        localLogoPath: localLogoPath,
        fallbackIcon: fallbackIcon,
        prefs: prefs,
      ),
    );
  }

  /// Show a batch delete confirmation dialog.
  static Future<DeleteConfirmResult?> showBatch({
    required BuildContext context,
    required int count,
    required DeleteConfirmPrefs prefs,
  }) async {
    if (!prefs.confirmDeleteBatchItems) {
      return DeleteConfirmResult.delete;
    }

    return showDialog<DeleteConfirmResult>(
      context: context,
      builder: (ctx) => DeleteConfirmDialog(
        mode: DialogMode.batch,
        count: count,
        prefs: prefs,
      ),
    );
  }

  /// Show a multi-box choice dialog (item belongs to multiple boxes).
  static Future<DeleteConfirmResult?> showMultiBox({
    required BuildContext context,
    required String title,
    required String source,
    required String typeLabel,
    required String relativeTime,
    String? localLogoPath,
    required IconData fallbackIcon,
    required List<String> boxNames, // ignored; kept for API symmetry
    required DeleteConfirmPrefs prefs,
  }) {
    return showDialog<DeleteConfirmResult>(
      context: context,
      builder: (ctx) => DeleteConfirmDialog(
        mode: DialogMode.multiBox,
        itemTitle: title,
        itemSource: source,
        itemTypeLabel: typeLabel,
        itemRelativeTime: relativeTime,
        localLogoPath: localLogoPath,
        fallbackIcon: fallbackIcon,
        prefs: prefs,
      ),
    );
  }

  // ---------------------------------------------------------------
  // State
  // ---------------------------------------------------------------

  @override
  State<DeleteConfirmDialog> createState() => _DeleteConfirmDialogState();
}

class _DeleteConfirmDialogState extends State<DeleteConfirmDialog> {
  bool _dontAskAgain = false;
  _MultiBoxChoice _multiBoxChoice = _MultiBoxChoice.removeFromBox;

  DeleteConfirmResult get _primaryResult => widget.mode == DialogMode.multiBox
      ? (_multiBoxChoice == _MultiBoxChoice.removeFromBox
          ? DeleteConfirmResult.removeFromBox
          : DeleteConfirmResult.delete)
      : DeleteConfirmResult.delete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      backgroundColor: colorScheme.surface,
      contentPadding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.sm,
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.lg,
      ),
      content: _buildContent(theme, colorScheme),
      actions: [_buildActions(theme, colorScheme)],
    );
  }

  // ---------------------------------------------------------------
  // Content
  // ---------------------------------------------------------------

  Widget _buildContent(ThemeData theme, ColorScheme colorScheme) {
    return SizedBox(
      width: 400,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Warning icon ---
          _WarningIcon(colorScheme: colorScheme),
          const SizedBox(height: AppSpacing.md),

          // --- Title ---
          Text(
            _titleText,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: AppFontTokens.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),

          // --- Description ---
          Text(
            _descriptionText,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),

          // --- Content preview card (single / multi-box only) ---
          if (widget.mode != DialogMode.batch) ...[
            const SizedBox(height: AppSpacing.md),
            _ContentPreviewCard(
              title: widget.itemTitle!,
              source: widget.itemSource!,
              typeLabel: widget.itemTypeLabel!,
              relativeTime: widget.itemRelativeTime!,
              localLogoPath: widget.localLogoPath,
              fallbackIcon: widget.fallbackIcon!,
              theme: theme,
              colorScheme: colorScheme,
            ),
          ],

          // --- Multi-box radio options ---
          if (widget.mode == DialogMode.multiBox) ...[
            const SizedBox(height: AppSpacing.sm),
            _buildMultiBoxRadio(theme),
          ],

          const SizedBox(height: AppSpacing.md),

          // --- Checkbox ---
          _buildRememberCheckbox(theme, colorScheme),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------

  Widget _buildActions(ThemeData theme, ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Cancel button — white with border
        OutlinedButton(
          onPressed: () => Navigator.pop(context, DeleteConfirmResult.cancel),
          style: OutlinedButton.styleFrom(
            foregroundColor: colorScheme.onSurface,
            side: BorderSide(color: colorScheme.outlineVariant),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
          child: const Text('取消'),
        ),
        const SizedBox(width: AppSpacing.sm),
        // Primary action button — destructive red
        FilledButton(
          onPressed: () async {
            await _maybeSavePreference();
            if (!mounted) return;
            Navigator.pop(context, _primaryResult);
          },
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.error,
            foregroundColor: colorScheme.onError,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
          child: Text(_actionButtonLabel),
        ),
      ],
    );
  }

  Future<void> _maybeSavePreference() async {
    if (!_dontAskAgain) return;
    switch (widget.mode) {
      case DialogMode.single:
        await widget.prefs.setConfirmDeleteSingleItem(false);
      case DialogMode.batch:
        await widget.prefs.setConfirmDeleteBatchItems(false);
      case DialogMode.multiBox:
        break; // No preference for multi-box
    }
  }

  // ---------------------------------------------------------------
  // Multi-box radio
  // ---------------------------------------------------------------

  Widget _buildMultiBoxRadio(ThemeData theme) {
    return RadioGroup<_MultiBoxChoice>(
      groupValue: _multiBoxChoice,
      onChanged: (v) => setState(() => _multiBoxChoice = v!),
      child: Column(
        children: [
          RadioListTile<_MultiBoxChoice>(
            value: _MultiBoxChoice.removeFromBox,
            title: Text(
              '仅从当前收藏夹移除',
              style: theme.textTheme.bodyMedium,
            ),
            subtitle: Text(
              '内容仍会保留在其他收藏夹中',
              style: theme.textTheme.bodySmall,
            ),
            dense: true,
            contentPadding: EdgeInsets.zero,
            toggleable: false,
            visualDensity: VisualDensity.compact,
          ),
          RadioListTile<_MultiBoxChoice>(
            value: _MultiBoxChoice.delete,
            title: Text(
              '删除这条收藏',
              style: theme.textTheme.bodyMedium,
            ),
            subtitle: Text(
              '内容将从所有收藏夹中移除',
              style: theme.textTheme.bodySmall,
            ),
            dense: true,
            contentPadding: EdgeInsets.zero,
            toggleable: false,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------
  // Remember checkbox
  // ---------------------------------------------------------------

  Widget _buildRememberCheckbox(ThemeData theme, ColorScheme colorScheme) {
    // No preference checkbox for multi-box mode
    if (widget.mode == DialogMode.multiBox) return const SizedBox.shrink();

    final isBatch = widget.mode == DialogMode.batch;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _dontAskAgain = !_dontAskAgain),
          borderRadius: BorderRadius.circular(AppRadius.xs),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: _dontAskAgain,
                  onChanged: (v) =>
                      setState(() => _dontAskAgain = v ?? false),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                isBatch
                    ? '以后批量删除收藏时不再提示'
                    : '以后删除单条收藏时不再提示',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Padding(
          padding: const EdgeInsets.only(left: AppSpacing.xl),
          child: Text(
            '可在 设置 > 内容收藏 中重新开启',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------
  // Derived text
  // ---------------------------------------------------------------

  String get _titleText => switch (widget.mode) {
    DialogMode.single => '删除这条收藏？',
    DialogMode.batch => '删除 ${widget.count} 条收藏？',
    DialogMode.multiBox => '处理这条收藏',
  };

  String get _descriptionText => switch (widget.mode) {
    DialogMode.single =>
      '删除后，这条内容将从所有收藏夹中移除。此操作暂时不可恢复。',
    DialogMode.batch =>
      '这些内容将从所有收藏夹中移除。此操作暂时不可恢复。',
    DialogMode.multiBox =>
      '这条内容当前属于多个收藏夹。请选择要执行的操作。',
  };

  String get _actionButtonLabel => switch (widget.mode) {
    DialogMode.single => '删除',
    DialogMode.batch => '删除 ${widget.count} 项',
    DialogMode.multiBox => '确认',
  };
}

// ===============================================================
// Internal types
// ===============================================================

enum DialogMode { single, batch, multiBox }

enum _MultiBoxChoice { removeFromBox, delete }

// ===============================================================
// Warning icon
// ===============================================================

class _WarningIcon extends StatelessWidget {
  const _WarningIcon({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Icon(
        Icons.delete_outline_rounded,
        size: 22,
        color: colorScheme.error,
      ),
    );
  }
}

// ===============================================================
// Content preview card
// ===============================================================

class _ContentPreviewCard extends StatelessWidget {
  const _ContentPreviewCard({
    required this.title,
    required this.source,
    required this.typeLabel,
    required this.relativeTime,
    this.localLogoPath,
    required this.fallbackIcon,
    required this.theme,
    required this.colorScheme,
  });

  final String title;
  final String source;
  final String typeLabel;
  final String relativeTime;
  final String? localLogoPath;
  final IconData fallbackIcon;
  final ThemeData theme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WebsiteLogo(
            localPath: localLogoPath,
            fallbackIcon: fallbackIcon,
            size: 36,
            iconSize: 18,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: AppFontTokens.semiBold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$source · $typeLabel · $relativeTime',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
