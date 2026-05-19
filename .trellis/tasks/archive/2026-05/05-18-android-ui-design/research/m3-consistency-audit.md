# Research: M3 Consistency Audit

- **Query**: Full audit of Material Design 3 (M3) consistency across the Flutter project
- **Scope**: Mixed (internal code search + M3 spec analysis)
- **Date**: 2026-05-19

## Summary

This audit covers 7 areas of M3 compliance: Theme layer, Color usage, Typography, Component patterns, Plugin UIs, Elevation/Surface, and Spacing. A total of 11 distinct categories of violations were identified, ranging from missing dark theme to hardcoded TextStyles bypassing the theme.

---

## 1. Theme Layer (Critical Issues)

### 1A. Dark Theme Missing [CRITICAL]

M3 requires both light and dark `ColorScheme` definitions. The project only has `AppTheme.light`.

- **File**: `lib/src/core/theme/app_theme.dart`
- The class `AppTheme` defines only a `static ThemeData get light` getter (line 6).
- No `static ThemeData get dark` exists anywhere in the codebase.
- `grep -rn "Brightness.dark\|darkTheme\|dark(" lib/src --include="*.dart"` returns **zero results**.
- The `MaterialApp.router` in `lib/src/core/app/app.dart` line 16 only passes `theme: AppTheme.light` — no `darkTheme` parameter.

### 1B. ColorScheme.fromSeed Overrides Defeat Seed Generation [HIGH]

- **File**: `lib/src/core/theme/app_theme.dart`, lines 8-14
- `ColorScheme.fromSeed()` is called with explicit `primary`, `surface`, and `brightness` overrides. By hardcoding these, the tonal palette generation from the seed color is partially bypassed — the generated `onPrimary`, `primaryContainer`, `onPrimaryContainer`, etc. will be based on the overridden primary rather than the seed.
- The `scaffoldBackgroundColor` (line 15) and `canvasColor` (line 16) are also manually set to `AppColors.background`, overriding whatever the ColorScheme would generate.

### 1C. AppColors Bypasses ColorScheme Entirely [HIGH]

- **File**: `lib/src/core/theme/app_tokens.dart`
- The `AppColors` class defines 34 hardcoded hex `Color(0xFF...)` constants. While centralizing colors is better than scattering raw hex everywhere, these values are completely independent of the M3 `ColorScheme`.
- The theme's `ColorScheme` is created from `ColorScheme.fromSeed(...)` but **never referenced** by any widget — not a single `colorScheme.` usage exists in `lib/src/`:

```
grep -rn "colorScheme\." lib/src --include="*.dart" → No matches found
```

This means the ColorScheme is effectively dead code — all widgets read from `AppColors.*` directly.

---

## 2. Color Usage Violations

### 2A. Colors.white Used as Foreground on Primary Surfaces [MEDIUM]

`Colors.white` is hardcoded in 14 places across the app where `colorScheme.onPrimary` should be used:

| File | Line | Usage |
|---|---|---|
| `app_theme.dart` | 50 | `foregroundColor: Colors.white` (FilledButton) |
| `sidebar.dart` | 183 | `color: Colors.white` (text on primary gradient) |
| `home_page.dart` | 319 | `color: Colors.white` |
| `home_page.dart` | 1431 | `color: Colors.white` (U logo text) |
| `mobile_placeholder_pages.dart` | 313 | `color: Colors.white` |
| `mobile_placeholder_pages.dart` | 362 | `foregroundColor: Colors.white` |
| `mobile_placeholder_pages.dart` | 485 | `color: selected ? Colors.white : ...` |
| `mobile_placeholder_pages.dart` | 1047 | `color: selected ? Colors.white : ...` |
| `thoughts_editor_page.dart` | 488 | `color: Colors.white` |
| `thoughts_desktop_layout.dart` | 309 | `color: Colors.white` |
| `thoughts_mobile_layout.dart` | 333 | `color: Colors.white` |
| `thoughts_shared_widgets.dart` | 192 | `color: selected ? Colors.white : ...` |
| `thoughts_shared_widgets.dart` | 199 | `color: selected ? Colors.white70 : ...` |
| `thought_editor_drawer.dart` | 334 | `color: Colors.white` |

### 2B. Colors.black54 for Overlays [LOW]

Hardcoded `Colors.black54` used for semi-transparent overlay backgrounds instead of using the color scheme's shadow/overlay tokens:

| File | Line |
|---|---|
| `thoughts_editor_page.dart` | 482 |
| `thoughts_desktop_layout.dart` | 302 |
| `thoughts_mobile_layout.dart` | 327 |
| `thought_editor_drawer.dart` | 327 |

### 2C. Colors.transparent for surfaceTintColor [MEDIUM]

- **File**: `app_theme.dart` lines 27, 40 — `surfaceTintColor: Colors.transparent`
- **File**: `mobile_shell.dart` line 49 — `surfaceTintColor: Colors.transparent`
- Setting `surfaceTintColor` to transparent disables the M3 elevation overlay tint, which is a key part of M3's surface elevation system.

### 2D. AppColors.* Used Instead of ColorScheme [HIGH]

All widget-level color references use `AppColors.*` constants. This is a **systemic pattern** — every file in the project does this. While abstraction through `AppColors` is better than raw hex, it still prevents:
- Dynamic dark theme switching (AppColors are all `const` with fixed values)
- Dynamic color (e.g., user-selectable seed color)
- M3 tonal elevation effects

The following files all reference `AppColors.*` extensively without any fallback to `Theme.of(context).colorScheme`:

- `sidebar.dart`
- `home_page.dart`
- `mobile_placeholder_pages.dart`
- `mobile_shell.dart`
- `desktop_shell.dart`
- `settings_page.dart`
- `thoughts_editor_page.dart`
- `thoughts_desktop_layout.dart`
- `thoughts_mobile_layout.dart`
- `thoughts_shared_widgets.dart`
- `thought_card.dart`
- `thought_editor_drawer.dart`
- `style_guide_screen.dart`

---

## 3. Typography Violations

### 3A. Direct `TextStyle(...)` Bypassing textTheme [HIGH]

Several widgets create inline `TextStyle(...)` with hardcoded font sizes instead of using `Theme.of(context).textTheme.*`:

| File | Line | Issue |
|---|---|---|
| `home_page.dart` | 597 | `TextStyle(color: AppColors.textTertiary, fontSize: 12)` - should be `textTheme.bodySmall` |
| `home_page.dart` | 641-644 | `TextStyle(color: AppColors.textTertiary, fontSize: 13)` - no theme equivalent (odd size) |
| `home_page.dart` | 1430-1435 | `TextStyle(color: Colors.white, fontSize: 28, ...)` - should use the theme |
| `home_page.dart` | 292 | `hintStyle: TextStyle(color: AppColors.textTertiary)` - should use input theme |
| `home_page.dart` | 445 | `TextStyle(color: AppColors.textSecondary)` |
| `home_page.dart` | 476 | `TextStyle(color: AppColors.textTertiary)` |
| `sidebar.dart` | 182-185 | `TextStyle(color: Colors.white, fontSize: 24, ...)` |
| `thoughts_editor_page.dart` | 258 | `TextStyle(color: AppColors.error)` - should use `textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error)` |
| `thoughts_editor_page.dart` | 327 | `labelStyle: const TextStyle(fontSize: 12)` |
| `thoughts_editor_page.dart` | 534 | `TextStyle(fontSize: 12, color: AppColors.textTertiary)` |
| `thought_editor_drawer.dart` | 373 | `labelStyle: const TextStyle(fontSize: 12)` |
| `thought_editor_drawer.dart` | 511-513 | `TextStyle(fontSize: 11, color: AppColors.textTertiary)` |

### 3B. theme.textTheme.*.copyWith with Font-Size Overrides [MEDIUM]

Several places use the correct text style from the theme but then override `fontSize`, indicating the theme's defined sizes don't match the design intent:

| File | Line | Base Style | Overridden fontSize |
|---|---|---|---|
| `home_page.dart` | 123-125 | `headlineMedium` (28) | 30 |
| `home_page.dart` | 1442-1444 | `titleLarge` (22) | 24 |
| `home_page.dart` | 1502-1504 | `headlineMedium` (28) | 34 |
| `home_page.dart` | 1762-1764 | `headlineMedium` (28) | 28 (same as theme, weight changed) |
| `mobile_placeholder_pages.dart` | 240-245 | `headlineMedium` (28) | 34 |
| `mobile_placeholder_pages.dart` | 281-282 | `titleLarge` (22) | 24 |
| `mobile_placeholder_pages.dart` | 314 | Not via textTheme | 28 (direct TextStyle) |
| `settings_page.dart` | 34-35 | `headlineMedium` (28) | 30 |
| `sidebar.dart` | 35 | Not via textTheme | 24 |
| `thoughts_desktop_layout.dart` | 162-163 | `headlineMedium` (28) | 30 |
| `thoughts_mobile_layout.dart` | 158-159 | `headlineMedium` (28) | 34 |

This pattern suggests the theme's `headlineMedium` at `fontSize: 28` is too small for large headings, and numerous pages independently discovered they need 30 or 34.

### 3C. Missing M3 Text Styles in Theme

- **File**: `app_theme.dart` lines 147-201
- The custom `_textTheme` only overrides 8 of 15 M3 text styles: `headlineMedium`, `titleLarge`, `titleMedium`, `titleSmall`, `bodyLarge`, `bodyMedium`, `bodySmall`, `labelLarge`, `labelMedium`.
- Missing overrides: `displayLarge`, `displayMedium`, `displaySmall`, `headlineLarge`, `headlineSmall`, `labelSmall`. These fall through to Flutter defaults, which may not match the visual design.

---

## 4. Component Pattern Violations

### 4A. No Deprecated M2 Widgets [GOOD]

`grep` for `RaisedButton|FlatButton|OutlineButton|ButtonBar` returns **zero matches**. All button usage is already migrated to M3 variants.

### 4B. Plain Chip() Instead of M3-Specific Chips [LOW]

Several places use the generic `Chip()` widget instead of M3-specific variants `FilterChip`, `InputChip`, or `AssistChip`:

| File | Line(s) |
|---|---|
| `style_guide_screen.dart` | 987-990 |
| `mobile_placeholder_pages.dart` | 528 |
| `thoughts_editor_page.dart` | 325 |
| `thoughts_desktop_layout.dart` | 264, 412, 700 |
| `thoughts_mobile_layout.dart` | 288 |
| `thoughts_shared_widgets.dart` | 230, 263 |
| `thought_editor_drawer.dart` | 371 |

### 4C. Custom Filter Chip Implementation [LOW]

- **File**: `thoughts_shared_widgets.dart` lines 158-200
- `ThoughtFilterChip` is a completely custom widget built with `GestureDetector` + `Container` + `Text` instead of using M3's `FilterChip`. This means it misses out on M3 interaction states (hover, press, focus, disabled), elevation, and accessibility features.

### 4D. Custom Button Square Pattern [LOW]

- **File**: `thoughts_shared_widgets.dart` lines 35-58, 61-90, 108-155
- `ThoughtIconBubble`, `ThoughtPillButton`, and `ThoughtIconSquare` are all custom widgets built with `Container` + `BoxDecoration` + `Icon` + `Text` instead of using `IconButton`, `TextButton`, or `FilledButton.tonal`. They miss M3 interaction states.

### 4E. ListTile Usage Without Theme Integration [LOW]

`ListTile` is used in several places and should ideally use the `listTileTheme` defined in `app_theme.dart`:

| File | Line(s) |
|---|---|
| `mobile_placeholder_pages.dart` | 877, 1169, 1446 |
| `style_guide_screen.dart` | 1007, 1014, 1021 |
| `thoughts_editor_page.dart` | 388 (SwitchListTile) |
| `thought_editor_drawer.dart` | 438 (SwitchListTile) |

### 4F. ActionChip with Custom Background [LOW]

- **File**: `thought_card.dart` lines 185-195
- `ActionChip` used but with custom `backgroundColor: accent.withValues(alpha: 0.11)` and `side: BorderSide.none`, and custom `labelStyle`. This bypasses the chip theme.

---

## 5. Plugin UI Consistency

### 5A. Good: Theme.of(context) Called Consistently [GOOD]

All thought plugin UI files call `final theme = Theme.of(context)` at the start of their build methods:
- `thoughts_editor_page.dart` line 204
- `thoughts_desktop_layout.dart` lines 146, 222, 383
- `thoughts_mobile_layout.dart` lines 143, 246
- `thoughts_shared_widgets.dart` lines 77, 117, 174, 223, 256, 286, 339, 366, 398, 417
- `thought_card.dart` line 45
- `thought_editor_drawer.dart` line 199

### 5B. Bad: Plugin Theme Usage Incomplete [HIGH]

Despite calling `Theme.of(context)`, the plugins primarily use it to access `theme.textTheme.*` for text styles — they do **not** use `theme.colorScheme.*` for colors. All colors still come from `AppColors.*`.

This means plugin UIs will not adapt to a dark theme or dynamic color changes.

### 5C. Plugin Files Import from Core Tokens Directly [MEDIUM]

Plugin files import `AppColors`, `AppSpacing`, `AppRadius`, `AppSizes` directly from `../../../../core/theme/app_tokens.dart` (e.g., `thought_editor_drawer.dart` line 8). This creates a direct dependency on the hardcoded token values rather than going through the M3 theme.

---

## 6. Elevation / Surface Violations

### 6A. Card Elevation Hardcoded [MEDIUM]

- **File**: `app_theme.dart` line 37: `elevation: 8`
- M3 uses specific elevation tiers: 0 (surface), 1 (surfaceContainerLowest-5), 2 (surfaceContainerLow-10), 3 (surfaceContainer-25), 4 (surfaceContainerHigh-40), 5 (surfaceContainerHighest-50), and levels 1-5 for shadows. The hardcoded elevation of 8 does not map to any M3 elevation token.

### 6B. AppBar Elevation Hardcoded to 0 [LOW]

- **File**: `app_theme.dart` line 25: `elevation: 0`
- While setting elevation to 0 is valid, the `surfaceTintColor: Colors.transparent` (line 27) additionally suppresses the M3 surface tint that provides elevation context.

### 6C. Custom BoxShadow Duplicated in Multiple Places [MEDIUM]

Four separate locations define equivalent custom `BoxShadow` values instead of using a shared token:

| File | Line | blurRadius | offset | alpha |
|---|---|---|---|---|
| `app_theme.dart` (cardTheme.shadowColor) | 38 | N/A (card shadow) | N/A | 0.04 |
| `style_guide_screen.dart` | 210-214 | 18 | (0, 8) | 0.04 |
| `style_guide_screen.dart` | 714-718 | 16 | (0, 6) | 0.035 |
| `mobile_placeholder_pages.dart` | 387-391 | 24 | (0, 12) | 0.04 |
| `thoughts_shared_widgets.dart` | 23-27 | 24 | (0, 12) | 0.04 |

The duplication between `mobile_placeholder_pages.dart:387` and `thoughts_shared_widgets.dart:23` is an exact copy. These should be consolidated into an elevation token system.

---

## 7. Spacing Violations

### 7A. Hardcoded padding Values [LOW]

Four instances of hardcoded `EdgeInsets.all(2)` instead of using `AppSpacing.xxs` (4.0):

| File | Line |
|---|---|
| `thoughts_editor_page.dart` | 480 |
| `thoughts_desktop_layout.dart` | 305 |
| `thoughts_mobile_layout.dart` | 325 |
| `thought_editor_drawer.dart` | 330 |

### 7B. Overall Spacing Pattern: Good [GOOD]

The overwhelming majority of `EdgeInsets.*` and `SizedBox` usages reference `AppSpacing.*` constants. The `AppSpacing` class (app_tokens.dart lines 47-56) defines a good spacing scale from `xxs` (4) through `section` (40). This is well-adhered to across the codebase.

---

## 8. Additional Observations

### 8A. No DefaultTabController / TabBar / Tab Usage

The project does not use any Material Tab widgets, so no issues there.

### 8B. NavigationBar Uses M3 Correctly [GOOD]

- **File**: `mobile_shell.dart` lines 46-99
- Uses M3 `NavigationBar` with proper M3 `NavigationDestination` widgets. `surfaceTintColor` is set to transparent (see 2C) but otherwise correct.

### 8C. Divider Usage: Mix of Themed and Direct [LOW]

The `DividerThemeData` is set in `app_theme.dart` (lines 137-140) with thickness 1 and space 1. Most Divider usage is `const Divider()` or `Divider()` at the default. The themed divider will apply to all of these, so this is consistent.

### 8D. withValues() Usage: Modern API [GOOD]

The codebase uses `withValues(alpha: ...)` (the modern Flutter API) rather than the deprecated `withOpacity()`. This is correct.

---

## 9. Severity Summary

| Severity | Count | Key Areas |
|---|---|---|
| CRITICAL | 1 | Missing dark theme entirely |
| HIGH | 4 | ColorScheme unused, TextStyles bypassing theme, AppColors hardcoded, plugin color bypass |
| MEDIUM | 6 | Colors.white hardcoded, surfaceTint disabled, elevation hardcoded, fontSize overrides, BoxShadow duplication, plugin file coupling |
| LOW | 5 | Chip variants, custom filter chip, hardcoded padding(2), Colors.black54, ActionChip customization |
| GOOD | 4 | No M2 deprecated widgets, NavigationBar correct, withValues API, AppSpacing adherence |

---

## Files Audit Was Based On

| File | Role |
|---|---|
| `lib/src/core/theme/app_theme.dart` | ThemeData definition |
| `lib/src/core/theme/app_tokens.dart` | Color, spacing, radius, size tokens |
| `lib/src/core/theme/app_breakpoints.dart` | Breakpoint definitions |
| `lib/src/core/app/app.dart` | MaterialApp.router setup |
| `lib/src/core/app/home_page.dart` | Main desktop dashboard |
| `lib/src/core/app/mobile_placeholder_pages.dart` | Mobile pages (todos, notes) |
| `lib/src/core/app/mobile_shell.dart` | Mobile shell with NavigationBar |
| `lib/src/core/app/desktop_shell.dart` | Desktop shell with sidebar |
| `lib/src/core/app/settings_page.dart` | Settings page |
| `lib/src/shared/widgets/sidebar.dart` | Desktop sidebar |
| `lib/src/shared/ui/style_guide_screen.dart` | UI component showcase |
| `lib/src/plugins/thoughts/ui/thoughts_page.dart` | Plugin main entry |
| `lib/src/plugins/thoughts/ui/thoughts_editor_page.dart` | Plugin editor |
| `lib/src/plugins/thoughts/ui/layouts/*.dart` | Plugin layouts |
| `lib/src/plugins/thoughts/ui/widgets/*.dart` | Plugin widgets |
