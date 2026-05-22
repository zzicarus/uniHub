import 'package:flutter/material.dart';

abstract final class AppColors {
  static const primary = Color(0xFF64B5F6);
  static const primaryDark = Color(0xFF42A5F5);
  static const secondary = Color(0xFF14B8A6);
  static const accent = Color(0xFFF59E0B);
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);

  static const background = Color(0xFFF7F9FD);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceElevated = Color(0xFFFCFDFF);
  static const surfaceMuted = Color(0xFFF1F5F9);
  static const surfaceSubtle = Color(0xFFF8FAFC);
  static const border = Color(0xFFE4E9F2);
  static const borderSoft = Color(0xFFF0F3F8);
  static const primarySoft = Color(0xFFE3F2FD);
  static const secondarySoft = Color(0xFFEFFCF9);
  static const accentSoft = Color(0xFFFFF7E6);
  static const purple = Color(0xFF7C3AED);
  static const purpleSoft = Color(0xFFF3E8FF);
  static const blueSoft = Color(0xFFEDF5FF);
  static const greenSoft = Color(0xFFEFF9F2);
  static const yellowSoft = Color(0xFFFFF8E5);
  static const roseSoft = Color(0xFFFFF1F5);
  static const successSoft = Color(0xFFEFF9F2);
  static const errorSoft = Color(0xFFFFF1F2);

  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF475569);
  static const textTertiary = Color(0xFF94A3B8);
}

abstract final class AppFonts {
  static const decorative = 'LXGW WenKai Screen';
  static const fallback = <String>[
    'Roboto',
    'Segoe UI',
    'PingFang SC',
    'Microsoft YaHei',
    'Noto Sans CJK SC',
  ];
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
  static const sidebarWidth = 260.0;
  static const rightRailWidth = 300.0;
  static const rightRailWideWidth = 330.0;
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

  /// Soft card shadow for desktop cards — subtle, close to the surface.
  static const cardSoft = BoxShadow(
    color: Color(0x05000000),
    blurRadius: 16,
    offset: Offset(0, 4),
  );

  /// Elevated card shadow for hovered/interactive state.
  static const cardElevated = BoxShadow(
    color: Color(0x08000000),
    blurRadius: 24,
    offset: Offset(0, 8),
  );
}
