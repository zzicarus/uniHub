import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:uni_hub/src/core/theme/app_tokens.dart';
import 'package:uni_hub/src/core/theme/app_theme_tokens.dart';
import 'package:uni_hub/src/shared/widgets/tags/app_tag_input.dart';

import '../widgets/thought_composer_controller.dart';
import 'thoughts_shared_widgets.dart';

/// 轻量 Capture Composer — 首页快速捕捉。
///
/// 不使用完整富文本编辑器或 AppFlowy Editor。
/// 纯文本输入后保存为 AppFlowy JSON 格式。
///
/// 布局：
/// - 白色 ThoughtPanel 卡片
/// - 输入区 TextField（多行，浅灰背景，圆角 16，高度 120–148）
/// - AppTagInput（标签管理）
/// - 图片缩略图 strip（如有）
/// - 操作按钮行：图片 / 置顶 / 转待办 / 转笔记 / Ctrl+Enter 提示 / 记录想法
class ThoughtComposer extends ConsumerWidget {
  const ThoughtComposer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final composer = ref.watch(composerProvider);
    final theme = Theme.of(context);
    final colors = context.appColors;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1080),
      child: ThoughtPanel(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ================================================================
            // Header
            // ================================================================
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Icon(
                    Icons.lightbulb_outline,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '快速记录想法',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: AppFontTokens.extraBold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.sm),

            // ================================================================
            // 输入区 — 多行 TextField
            // ================================================================
            Container(
              constraints: const BoxConstraints(minHeight: 120, maxHeight: 148),
              decoration: BoxDecoration(
                color: colors.surfaceMuted,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: colors.border),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: TextField(
                  controller: composer.textController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: InputDecoration(
                    hintText: '今天有什么新想法？',
                    hintStyle: theme.textTheme.bodyLarge?.copyWith(
                      color: colors.textTertiary,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(AppSpacing.md),
                  ),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colors.textPrimary,
                  ),
                  textInputAction: TextInputAction.newline,
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            // ================================================================
            // 标签 - AppTagInput
            // ================================================================
            AppTagInput(
              tags: composer.tags,
              onChanged: composer.setTags,
              hintText: '添加标签',
            ),

            // ================================================================
            // 图片缩略图 strip
            // ================================================================
            if (composer.pendingImagePaths.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: 56,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: composer.pendingImagePaths.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: AppSpacing.xs),
                  itemBuilder: (_, i) {
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.xs),
                          child: Image.file(
                            File(composer.pendingImagePaths[i]),
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 1,
                          right: 1,
                          child: GestureDetector(
                            onTap: () => composer.removePendingImage(i),
                            child: Container(
                              decoration: BoxDecoration(
                                color: colors.textSecondary.withValues(
                                  alpha: 0.54,
                                ),
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(AppSpacing.xxs),
                              child: Icon(
                                Icons.close,
                                size: 12,
                                color: colors.surface,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.sm),

            // ================================================================
            // 操作按钮行
            // ================================================================
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ThoughtPillButton(
                        icon: Icons.image_outlined,
                        label: composer.pendingImagePaths.isNotEmpty
                            ? '图片 (${composer.pendingImagePaths.length})'
                            : '图片',
                        onTap: composer.pickImageForComposer,
                      ),
                      ThoughtPillButton(
                        icon: composer.isPinned
                            ? Icons.push_pin_rounded
                            : Icons.push_pin_outlined,
                        label: composer.isPinned ? '已置顶' : '置顶',
                        selected: composer.isPinned,
                        onTap: composer.togglePin,
                      ),
                      Tooltip(
                        message: '即将推出',
                        child: ThoughtPillButton(
                          icon: Icons.check_box_outlined,
                          label: '转为待办',
                          onTap: null,
                        ),
                      ),
                      Tooltip(
                        message: '即将推出',
                        child: ThoughtPillButton(
                          icon: Icons.note_alt_outlined,
                          label: '转为笔记',
                          onTap: null,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Ctrl + Enter 快速保存',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.textTertiary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(128, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                  onPressed: composer.canSubmit && !composer.isSubmitting
                      ? composer.submit
                      : null,
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: Text(
                      composer.isSubmitting ? '保存中' : '记录想法'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
