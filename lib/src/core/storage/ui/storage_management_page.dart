import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:uni_hub/src/core/storage/providers/storage_providers.dart';
import 'package:uni_hub/src/core/storage/providers/storage_cleanup_providers.dart';
import 'package:uni_hub/src/core/storage/providers/storage_orphaned_providers.dart';
import 'package:uni_hub/src/core/storage/storage_area.dart';
import 'package:uni_hub/src/core/storage/storage_area_report.dart';
import 'package:uni_hub/src/core/storage/storage_size_utils.dart';
import 'package:uni_hub/src/core/theme/app_tokens.dart';
import 'package:uni_hub/src/core/theme/app_theme_tokens.dart';

class StorageManagementPage extends ConsumerStatefulWidget {
  const StorageManagementPage({super.key});

  @override
  ConsumerState<StorageManagementPage> createState() =>
      _StorageManagementPageState();
}

class _StorageManagementPageState
    extends ConsumerState<StorageManagementPage> {
  bool _scanning = false;
  AppStorageReport? _report;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scan());
  }

  Future<void> _scan() async {
    if (_scanning) return;
    setState(() {
      _scanning = true;
      _error = null;
    });
    try {
      final manager = ref.read(storageManagerProvider);
      final report = await manager.scan();
      if (mounted) {
        setState(() {
          _report = report;
          _scanning = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _scanning = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: AppSpacing.xxl),
                _buildOverviewCard(),
                const SizedBox(height: AppSpacing.xl),
                ..._buildAreaSections(),
                const SizedBox(height: AppSpacing.xl),
                _buildMaintenanceActions(),
                const SizedBox(height: AppSpacing.xl),
                _buildDangerZone(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // Header
  // ------------------------------------------------------------------

  Widget _buildHeader() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(
          Icons.storage_outlined,
          size: 34,
          color: colorScheme.onSurface,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '存储管理',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: AppFontTokens.extraBold,
                ),
              ),
              Text(
                '查看和管理应用存储空间',
                style: theme.textTheme.bodyLarge,
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: _scanning ? null : _scan,
          icon: _scanning
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh_rounded),
          tooltip: '刷新',
        ),
      ],
    );
  }

  // ------------------------------------------------------------------
  // Overview Card
  // ------------------------------------------------------------------

  Widget _buildOverviewCard() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final colors = context.appColors;

    if (_scanning && _report == null) {
      return _buildSkeletonCard();
    }

    if (_error != null && _report == null) {
      return _buildErrorCard();
    }

    if (_report == null) {
      return const SizedBox.shrink();
    }

    final total = _report!.totalBytes;

    return Container(
      decoration: BoxDecoration(
        color: colors.panelBackground,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: colors.border),
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          Text(
            'UniHub 当前占用',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            StorageSizeUtils.format(total),
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: AppFontTokens.extraBold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _CategoryChip(
                label: '核心数据',
                bytes: _report!.databaseBytes,
                color: colorScheme.primary,
              ),
              _CategoryChip(
                label: '用户附件',
                bytes: _report!.userAttachmentBytes,
                color: colorScheme.tertiary,
              ),
              _CategoryChip(
                label: '可再生缓存',
                bytes: _report!.cacheBytes,
                color: colorScheme.secondary,
              ),
              _CategoryChip(
                label: '临时文件',
                bytes: _report!.temporaryBytes,
                color: colorScheme.outline,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonCard() {
    final colors = context.appColors;

    return Container(
      decoration: BoxDecoration(
        color: colors.panelBackground,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: colors.border),
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xxl),
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final colors = context.appColors;

    return Container(
      decoration: BoxDecoration(
        color: colors.panelBackground,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: colors.border),
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: colorScheme.error, size: 32),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '扫描失败',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.error,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _error!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: _scan,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('重试'),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // Area Groups
  // ------------------------------------------------------------------

  List<Widget> _buildAreaSections() {
    if (_report == null) return [];
    final groups = _groupByType(_report!.areas);
    return groups.entries.map((entry) {
      return _buildAreaGroup(
        title: _typeLabel(entry.key),
        areas: entry.value,
      );
    }).toList();
  }

  Map<StorageAreaType, List<StorageAreaReport>> _groupByType(
    List<StorageAreaReport> areas,
  ) {
    final map = <StorageAreaType, List<StorageAreaReport>>{};
    for (final area in areas) {
      map.putIfAbsent(area.area.type, () => []).add(area);
    }
    return map;
  }

  Widget _buildAreaGroup({
    required String title,
    required List<StorageAreaReport> areas,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: AppFontTokens.semiBold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...areas.map(_buildAreaCard),
        ],
      ),
    );
  }

  Widget _buildAreaCard(StorageAreaReport report) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final colors = context.appColors;
    final area = report.area;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.panelBackground,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.border),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: icon + name + size + actions
          Row(
            children: [
              Icon(
                _areaIcon(area.type),
                color: colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  area.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: AppFontTokens.semiBold,
                  ),
                ),
              ),
              if (!report.exists)
                Text(
                  '不存在',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.outline,
                  ),
                )
              else ...[
                Text(
                  StorageSizeUtils.format(report.sizeBytes),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: AppFontTokens.semiBold,
                  ),
                ),
                if (area.clearable) ...[
                  const SizedBox(width: AppSpacing.sm),
                  _buildAreaClearButton(area),
                ],
              ],
              if (_canOpenDirectory && report.exists) ...[
                const SizedBox(width: AppSpacing.xs),
                _buildOpenDirectoryButton(area.path),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          // Row 2: description
          Text(
            area.description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          // Row 3: path + file count
          Row(
            children: [
              Icon(
                Icons.folder_outlined,
                size: 14,
                color: colorScheme.outline,
              ),
              const SizedBox(width: AppSpacing.xxs),
              Expanded(
                child: Text(
                  area.path,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.outline,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (report.exists && report.fileCount > 0) ...[
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '${report.fileCount} 个文件',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.outline,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAreaClearButton(StorageArea area) {
    return SizedBox(
      height: 32,
      child: OutlinedButton(
        onPressed: () => _clearSingleArea(area),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          visualDensity: VisualDensity.compact,
        ),
        child: const Text('清除', style: TextStyle(fontSize: 12)),
      ),
    );
  }

  Widget _buildOpenDirectoryButton(String path) {
    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        onPressed: () => _openDirectory(path),
        icon: const Icon(Icons.open_in_new_rounded, size: 16),
        tooltip: '打开所在目录',
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  // ------------------------------------------------------------------
  // Maintenance Actions
  // ------------------------------------------------------------------

  Widget _buildMaintenanceActions() {
    final theme = Theme.of(context);
    final colors = context.appColors;

    return Container(
      decoration: BoxDecoration(
        color: colors.panelBackground,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.border),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '维护操作',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: AppFontTokens.semiBold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showClearCacheDialog,
                  icon: const Icon(Icons.cleaning_services_outlined, size: 18),
                  label: const Text('清除可再生缓存'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _scanAndCleanOrphans,
                  icon: const Icon(Icons.auto_delete_outlined, size: 18),
                  label: const Text('清理孤儿文件'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // Danger Zone
  // ------------------------------------------------------------------

  Widget _buildDangerZone() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: colorScheme.error,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '危险操作',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colorScheme.error,
                  fontWeight: AppFontTokens.semiBold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '重置将删除全部数据库、想法、收藏、图片附件和缓存。此操作不可恢复。',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onErrorContainer,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: _showResetDialog,
            icon: const Icon(Icons.delete_forever_outlined, size: 18),
            label: const Text('重置应用数据'),
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.error,
              side: BorderSide(color: colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // Dialogs
  // ------------------------------------------------------------------

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清除可再生缓存'),
        content: const Text(
          '将删除网站 Logo、网页缩略图和临时文件。\n'
          '收藏、想法、标签和图片附件不会被删除。\n'
          '需要时应用会重新生成这些缓存。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _clearCache();
            },
            child: const Text('清除缓存'),
          ),
        ],
      ),
    );
  }

  void _showResetDialog() {
    final colorScheme = Theme.of(context).colorScheme;
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('重置应用数据'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '这会删除全部想法、收藏、标签、图片附件和缓存。此操作不可恢复。',
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '输入 RESET 确认重置',
              style: TextStyle(fontWeight: AppFontTokens.semiBold),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'RESET',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim() == 'RESET') {
                Navigator.pop(ctx);
                _performReset();
              }
            },
            child: Text(
              '确认重置',
              style: TextStyle(color: colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // Actions
  // ------------------------------------------------------------------

  Future<void> _clearCache() async {
    setState(() => _scanning = true);
    try {
      final action = ref.read(clearRegenerableCacheAction);
      final result = await action();
      if (mounted) {
        setState(() => _scanning = false);
        _showSnackBar(
          '已清除 ${result.deletedFiles} 个文件，释放 ${StorageSizeUtils.format(result.freedBytes)}',
        );
        await _scan();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _scanning = false);
        _showSnackBar('清除缓存失败：$e');
      }
    }
  }

  Future<void> _clearSingleArea(StorageArea area) async {
    setState(() => _scanning = true);
    try {
      final manager = ref.read(storageManagerProvider);
      final result = await manager.clearStorageArea(area.id);
      if (mounted) {
        setState(() => _scanning = false);
        _showSnackBar(
          '已清除「${area.name}」，释放 ${StorageSizeUtils.format(result.freedBytes)}',
        );
        await _scan();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _scanning = false);
        _showSnackBar('清除失败：$e');
      }
    }
  }

  Future<void> _scanAndCleanOrphans() async {
    setState(() => _scanning = true);
    try {
      final orphaned = await ref.read(orphanedImagesProvider.future);
      if (mounted) setState(() => _scanning = false);

      if (orphaned.isEmpty) {
        if (mounted) _showSnackBar('没有发现孤儿文件');
        return;
      }

      if (!mounted) return;
      final confirmed = await _showOrphanConfirmDialog(orphaned);
      if (confirmed != true) return;

      setState(() => _scanning = true);
      final action = ref.read(cleanOrphanedImagesAction);
      final result = await action();
      if (mounted) {
        setState(() => _scanning = false);
        _showSnackBar(
          '已清理 ${result.deletedFiles} 个孤儿文件，释放 ${StorageSizeUtils.format(result.freedBytes)}',
        );
        await _scan();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _scanning = false);
        _showSnackBar('清理孤儿文件失败：$e');
      }
    }
  }

  Future<bool?> _showOrphanConfirmDialog(
    List<dynamic> orphaned,
  ) {
    final totalBytes = orphaned.fold<int>(
      0,
      (sum, f) => sum + (f.sizeBytes as int),
    );

    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清理孤儿文件'),
        content: Text(
          '发现 ${orphaned.length} 个不再被引用的文件'
          '（${StorageSizeUtils.format(totalBytes)}），'
          '是否删除？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  Future<void> _performReset() async {
    setState(() => _scanning = true);
    try {
      // Clear cache and temp files
      final cacheAction = ref.read(clearRegenerableCacheAction);
      await cacheAction();

      if (mounted) {
        setState(() => _scanning = false);
        _showSnackBar(
          '缓存已清除。数据库和附件需要删除应用数据目录后重启应用。',
        );
        await _scan();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _scanning = false);
        _showSnackBar('重置失败：$e');
      }
    }
  }

  Future<void> _openDirectory(String path) async {
    try {
      if (Platform.isWindows) {
        await Process.run('explorer', [path]);
      } else if (Platform.isMacOS) {
        await Process.run('open', [path]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [path]);
      }
    } catch (_) {
      if (mounted) {
        _showSnackBar('当前平台不支持打开目录');
      }
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ------------------------------------------------------------------
  // Helpers
  // ------------------------------------------------------------------

  /// Whether the current platform supports opening directories.
  bool get _canOpenDirectory =>
      !Platform.isAndroid && !Platform.isIOS;

  String _typeLabel(StorageAreaType type) {
    return switch (type) {
      StorageAreaType.database => '核心数据',
      StorageAreaType.userAttachment => '用户附件',
      StorageAreaType.cache => '可再生缓存',
      StorageAreaType.temporary => '临时文件',
      StorageAreaType.orphaned => '孤儿文件',
    };
  }

  IconData _areaIcon(StorageAreaType type) {
    return switch (type) {
      StorageAreaType.database => Icons.storage_rounded,
      StorageAreaType.userAttachment => Icons.image_outlined,
      StorageAreaType.cache => Icons.cached_outlined,
      StorageAreaType.temporary => Icons.timer_outlined,
      StorageAreaType.orphaned => Icons.auto_delete_outlined,
    };
  }
}

// ------------------------------------------------------------------
// Category Chip (private top-level widget)
// ------------------------------------------------------------------

class _CategoryChip extends StatelessWidget {
  final String label;
  final int bytes;
  final Color color;

  const _CategoryChip({
    required this.label,
    required this.bytes,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: AppFontTokens.medium,
            ),
          ),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            StorageSizeUtils.format(bytes),
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: AppFontTokens.semiBold,
            ),
          ),
        ],
      ),
    );
  }
}
