import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:uni_hub/src/core/theme/app_tokens.dart';
import 'package:uni_hub/src/plugins/collections/services/collection_debug_logger.dart';

/// Displays a website logo (favicon) from a local file path.
///
/// UI never fetches the logo itself — it always reads from a local cache
/// file provided by [WebsiteLogoCacheService] ([localPath]).
///
/// When [localPath] is null or the file doesn't exist, a fallback container
/// with [fallbackIcon] is shown instead.
///
/// All sizing is controlled by [size] (container dimensions) and [iconSize]
/// (fallback icon size). Styling uses [AppRadius] and [colorScheme].
class WebsiteLogo extends StatelessWidget {
  /// Tracks reported missing-file paths to prevent log flood.
  static final Set<String> _reportedMissingFiles = <String>{};

  /// Tracks reported decode-failure paths to prevent log flood.
  static final Set<String> _reportedDecodeFailures = <String>{};

  const WebsiteLogo({
    super.key,
    this.localPath,
    required this.fallbackIcon,
    this.size = 48,
    this.iconSize = 24,
  });

  /// Absolute path to a locally cached logo file.
  ///
  /// Should be obtained from [WebsiteLogoCacheService.getCachedLogo].
  /// When null or the file does not exist, [fallbackIcon] is displayed.
  final String? localPath;

  /// Icon shown when [localPath] is null/empty or the file doesn't exist.
  final IconData fallbackIcon;

  /// Width and height of the icon container / logo image.
  final double size;

  /// Size of the fallback icon inside the container.
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (localPath != null && localPath!.isNotEmpty) {
      final file = File(localPath!);
      if (!file.existsSync()) {
        if (_reportedMissingFiles.add(localPath!)) {
          CollectionDebugLogger.warn(
            'WebsiteLogo local file missing path=$localPath',
          );
        }
        return _fallbackContainer(colorScheme);
      }
      // SVG files use SvgPicture.file (flutter_svg) for rendering.
      if (localPath!.toLowerCase().endsWith('.svg')) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: SvgPicture.file(
            file,
            width: size,
            height: size,
            fit: BoxFit.cover,
            placeholderBuilder: (_) => _fallbackContainer(colorScheme),
            errorBuilder: (_, error, stackTrace) {
              if (_reportedDecodeFailures.add(localPath!)) {
                CollectionDebugLogger.error(
                  'WebsiteLogo SvgPicture.file decode failed path=$localPath',
                  error,
                  stackTrace,
                );
              }
              return _fallbackContainer(colorScheme);
            },
          ),
        );
      }
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Image.file(
          file,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, error, stackTrace) {
            if (_reportedDecodeFailures.add(localPath!)) {
              CollectionDebugLogger.error(
                'WebsiteLogo Image.file decode failed path=$localPath',
                error,
                stackTrace,
              );
            }
            return _fallbackContainer(colorScheme);
          },
        ),
      );
    }

    return _fallbackContainer(colorScheme);
  }

  Widget _fallbackContainer(ColorScheme colorScheme) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Icon(
        fallbackIcon,
        size: iconSize,
        color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
      ),
    );
  }
}
