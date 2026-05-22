import 'package:flutter/material.dart';

abstract final class AppColors {
  static const primary = Color(0xFF4F6BFF);
  static const secondary = Color(0xFF22C55E);
  static const accent = Color(0xFFF59E0B);
  static const purple = Color(0xFF8B5CF6);
  static const error = Color(0xFFF43F5E);

  static const background = Color(0xFFFAFBFE);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFF6F8FC);
  static const border = Color(0xFFE8ECF4);

  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF667085);
  static const textTertiary = Color(0xFF98A2B3);

  static const primarySoft = Color(0xFFEFF3FF);
  static const greenSoft = Color(0xFFEFFAF3);
  static const purpleSoft = Color(0xFFF4F0FF);
  static const yellowSoft = Color(0xFFFFF7E8);
  static const roseSoft = Color(0xFFFFF0F4);
}

abstract final class AppFonts {
  /// Primary Latin / UI font — used as the default for all text.
  static const sansLatin = 'Inter';

  /// CJK fallback font — renders Chinese characters that Inter does not cover.
  static const sansCJK = 'Noto Sans SC';

  /// Monospace font for code, commands, and paths.
  static const mono = 'JetBrains Mono';
}

abstract final class AppSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const section = 40.0;
}

abstract final class AppRadius {
  static const xs = 6.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const full = 999.0;
}

abstract final class AppSizes {
  static const buttonHeight = 48.0;
  static const inputHeight = 48.0;
  static const iconButton = 40.0;
  static const listItem = 56.0;
  static const listItemLarge = 72.0;
  static const statusIcon = 48.0;
  static const cardMinHeight = 148.0;
  static const dashboardCardHeight = 118.0;
}

abstract final class AppDesktopSizes {
  static const sidebarWidth = 286.0;
  static const rightRailWidth = 300.0;
  static const rightRailWideWidth = 320.0;
  static const desktopContentMaxWidth = 1120.0;
  static const topBarHeight = 56.0;
  static const navItemHeight = 48.0;
  static const compactButtonHeight = 36.0;
  static const previewMinWidth = 980.0;
}

abstract final class AppMobileSizes {
  static const maxContentWidth = 560.0;
  static const bottomNavHeight = 88.0;
  static const pageHorizontalPadding = 20.0;
  static const heroLogoSize = 46.0;
  static const iconTile = 48.0;
  static const statCardHeight = 108.0;
  static const compactCardHeight = 128.0;
  static const searchHeight = 58.0;
}

abstract final class AppShadows {
  /// Strong floating shadow used for elevated elements.
  static const card = BoxShadow(
    color: Color(0x080F172A),
    blurRadius: 32,
    offset: Offset(0, 16),
  );

  /// Soft card shadow for dashboard cards — subtle but visible on light gray.
  static const cardSoft = BoxShadow(
    color: Color(0x0A0F172A),
    blurRadius: 24,
    offset: Offset(0, 8),
  );

  /// Elevated card shadow for hovered/interactive state.
  static const cardElevated = BoxShadow(
    color: Color(0x08000000),
    blurRadius: 24,
    offset: Offset(0, 8),
  );
}
