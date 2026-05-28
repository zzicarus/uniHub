import 'package:flutter/material.dart';
import 'package:uni_hub/src/shared/widgets/adaptive_layout.dart';

import 'layouts/collections_desktop_layout.dart';
import 'layouts/collections_mobile_layout.dart';

/// 收藏页面入口，根据屏幕宽度自适应选择布局。
class CollectionsPage extends StatelessWidget {
  const CollectionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      mobile: (_) => const CollectionsMobileLayout(),
      desktop: (_) => const CollectionsDesktopLayout(),
    );
  }
}
