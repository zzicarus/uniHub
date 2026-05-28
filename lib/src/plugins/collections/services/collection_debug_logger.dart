import 'package:flutter/foundation.dart';

/// 收藏插件统一调试日志工具。
///
/// 所有日志通过 [debugPrint] 输出，可通过环境变量
/// `UNIHUB_COLLECTION_DEBUG=false` 关闭。
///
/// 使用方式：
/// ```dart
/// CollectionDebugLogger.log('captureUrl input=$input normalized=$normalizedUrl');
/// CollectionDebugLogger.warn('logo candidate failed url=$url error=$e');
/// CollectionDebugLogger.error('Image.file decode failed path=$path', error, stackTrace);
/// ```
class CollectionDebugLogger {
  const CollectionDebugLogger._();

  /// 是否启用调试日志。默认关闭，开发时通过 `--dart-define=UNIHUB_COLLECTION_DEBUG=true` 开启。
  static const bool enabled = bool.fromEnvironment(
    'UNIHUB_COLLECTION_DEBUG',
    defaultValue: false,
  );

  /// 普通信息日志。
  static void log(String message) {
    if (!enabled) return;
    debugPrint('[CollectionDebug] $message');
  }

  /// 警告日志。
  static void warn(String message) {
    if (!enabled) return;
    debugPrint('[CollectionWarn] $message');
  }

  /// 错误日志，可附带异常对象和堆栈。
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (!enabled) return;
    debugPrint('[CollectionError] $message');
    if (error != null) debugPrint('  error=$error');
    if (stackTrace != null) debugPrint('  stack=$stackTrace');
  }
}
