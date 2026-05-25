// 字体规范检查脚本
//
// 扫描 lib/ 下的 Widget 层代码，检查是否违反字体规范：
// - R1: GoogleFonts.* 禁止调用
// - R2: fontFamily 禁止直接指定
// - R3: 裸数字 fontSize 禁止
// - R4: FontWeight.wXXX 禁止（应使用 AppFontTokens）
//
// 允许例外文件：
// - lib/src/core/theme/app_theme.dart
// - lib/src/core/theme/app_tokens.dart
//
// 用法: dart run tool/check_typography.dart

import 'dart:io';

const allowedFiles = <String>{
  'lib/src/core/theme/app_theme.dart',
  'lib/src/core/theme/app_tokens.dart',
  'lib/src/shared/ui/style_guide_screen.dart',
};

final rules = <RegExp, String>{
  RegExp(r'GoogleFonts\.'): 'Widget 层禁止使用 GoogleFonts.*',
  RegExp(r'fontFamily\s*:'): 'Widget 层禁止直接设置 fontFamily',
  RegExp(r'fontSize\s*:\s*\d+(\.\d+)?'): '禁止裸数字 fontSize，使用 Theme.textTheme 或 AppFontTokens',
  RegExp(r'FontWeight\.w\d{3}'): '禁止直接使用 FontWeight.wXXX，使用 AppFontTokens',
};

void main() {
  final lib = Directory('lib');
  if (!lib.existsSync()) {
    stderr.writeln('错误: lib/ 目录不存在，请从项目根目录运行。');
    exitCode = 1;
    return;
  }

  var hasError = false;
  var checkedCount = 0;

  for (final entity in lib.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;

    final path = entity.path.replaceAll('\\', '/');
    if (allowedFiles.contains(path)) continue;
    if (path.startsWith('lib/vendor/')) continue;

    final content = entity.readAsStringSync();
    var fileHasIssue = false;

    for (final entry in rules.entries) {
      if (entry.key.hasMatch(content)) {
        if (!fileHasIssue) {
          stderr.writeln('\n$path:');
          fileHasIssue = true;
        }
        stderr.writeln('  ⚠  ${entry.value}');
        hasError = true;
      }
    }

    checkedCount++;
  }

  stderr.writeln('\n已扫描 $checkedCount 个文件。');

  if (hasError) {
    stderr.writeln('\n❌ 字体规范检查未通过，请修复上述问题。');
    exitCode = 1;
  } else {
    stderr.writeln('\n✅ 字体规范检查通过。');
  }
}
