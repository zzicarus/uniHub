import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uni_hub/src/core/theme/app_tokens.dart';
import 'package:uni_hub/src/plugins/collections/domain/consumption_status.dart';
import 'package:uni_hub/src/plugins/collections/domain/media_type.dart';
import 'package:uni_hub/src/plugins/collections/domain/source_platform.dart';
import 'package:uni_hub/src/plugins/collections/providers/collections_providers.dart';
import 'package:uni_hub/src/shared/widgets/menu/app_select_menu.dart';

/// Platform source filter dropdown, backed by [AppSelectMenu] for
/// consistent visual style with the rest of the app.
class PlatformFilterDropdown extends ConsumerWidget {
  const PlatformFilterDropdown({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(collectionPlatformFilterProvider);

    return AppSelectMenu<SourcePlatform?>(
      value: value,
      label: '来源',
      items: [
        const AppSelectMenuItem<SourcePlatform?>(
          value: null,
          label: '全部',
        ),
        for (final p in SourcePlatform.values)
          AppSelectMenuItem<SourcePlatform?>(
            value: p,
            label: p.label,
            icon: _platformIcon(p),
          ),
      ],
      onChanged: (v) {
        ref.read(collectionPlatformFilterProvider.notifier).state = v;
      },
    );
  }

  static IconData? _platformIcon(SourcePlatform p) => switch (p) {
    SourcePlatform.web => Icons.language_rounded,
    SourcePlatform.wechat => Icons.chat_bubble_outline_rounded,
    SourcePlatform.bilibili => Icons.play_circle_outline_rounded,
    SourcePlatform.youtube => Icons.play_circle_filled_rounded,
    SourcePlatform.github => Icons.code_rounded,
    SourcePlatform.pdf => Icons.picture_as_pdf_rounded,
    SourcePlatform.localFile => Icons.folder_open_rounded,
    SourcePlatform.zhihu => Icons.forum_outlined,
    SourcePlatform.xiaohongshu => Icons.note_alt_outlined,
    SourcePlatform.twitter => Icons.alternate_email_rounded,
    SourcePlatform.douban => Icons.bookmark_border_rounded,
    SourcePlatform.unknown => null,
  };
}

/// Media-type filter dropdown.
class MediaTypeFilterDropdown extends ConsumerWidget {
  const MediaTypeFilterDropdown({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(collectionMediaTypeFilterProvider);

    return AppSelectMenu<MediaType?>(
      value: value,
      label: '类型',
      items: [
        const AppSelectMenuItem<MediaType?>(
          value: null,
          label: '全部',
        ),
        for (final m in MediaType.values)
          AppSelectMenuItem<MediaType?>(
            value: m,
            label: m.label,
            icon: _mediaTypeIcon(m),
          ),
      ],
      onChanged: (v) {
        ref.read(collectionMediaTypeFilterProvider.notifier).state = v;
      },
    );
  }

  static IconData? _mediaTypeIcon(MediaType m) => switch (m) {
    MediaType.article => Icons.article_outlined,
    MediaType.video => Icons.play_circle_outline_rounded,
    MediaType.repository => Icons.code_rounded,
    MediaType.webpage => Icons.language_rounded,
    MediaType.image => Icons.image_outlined,
    MediaType.pdf => Icons.picture_as_pdf_rounded,
    MediaType.audio => Icons.headphones_rounded,
    MediaType.post => Icons.forum_outlined,
    MediaType.document => Icons.description_outlined,
    MediaType.unknown => null,
  };
}

/// Consumption-status filter dropdown.
class StatusFilterDropdown extends ConsumerWidget {
  const StatusFilterDropdown({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(collectionStatusFilterProvider);

    return AppSelectMenu<ConsumptionStatus?>(
      value: value,
      label: '状态',
      items: [
        const AppSelectMenuItem<ConsumptionStatus?>(
          value: null,
          label: '全部',
        ),
        for (final s in ConsumptionStatus.values)
          AppSelectMenuItem<ConsumptionStatus?>(
            value: s,
            label: s.label,
          ),
      ],
      onChanged: (v) {
        ref.read(collectionStatusFilterProvider.notifier).state = v;
      },
    );
  }
}

/// A group of filter chips for source, media type, and consumption status.
///
/// Wraps the three individual [AppSelectMenu]-based dropdowns.
@Deprecated('Use PlatformFilterDropdown / MediaTypeFilterDropdown / StatusFilterDropdown directly.')
class CollectionFilterChipGroup extends ConsumerWidget {
  const CollectionFilterChipGroup({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const PlatformFilterDropdown(),
        const SizedBox(width: AppSpacing.xs),
        const MediaTypeFilterDropdown(),
        const SizedBox(width: AppSpacing.xs),
        const StatusFilterDropdown(),
      ],
    );
  }
}
