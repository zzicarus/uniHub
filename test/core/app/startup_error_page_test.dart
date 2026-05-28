import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uni_hub/src/core/app/app.dart';

void main() {
  testWidgets('UniHubApp shows startup error fallback when plugin init fails', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: UniHubApp(
          startupError: StateError('plugin init failed'),
          startupStackTrace: StackTrace.fromString('stack line'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('UniHub 启动失败'), findsOneWidget);
    expect(find.textContaining('插件初始化时发生错误'), findsOneWidget);
    expect(find.textContaining('plugin init failed'), findsOneWidget);
    expect(find.textContaining('stack line'), findsOneWidget);
  });
}
