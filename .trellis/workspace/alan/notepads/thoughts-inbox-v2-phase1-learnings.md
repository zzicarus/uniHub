# Learnings for thoughts-inbox-v2-phase1

## [2026-05-22] Wave 1 Starting
- Plan: 10 tasks + 4 final verification
- Wave 1: Tasks 1-4 (parallel)
- Wave 2: Tasks 5-8 (parallel, after Wave 1)
- Wave 3: Tasks 9-10 (sequential, after Wave 2)
- Final: F1-F4 (parallel, after all tasks)

## Key Decisions
- Breakpoint change is GLOBAL (affects all pages)
- Archive nav already exists — no new entry needed
- Composer controller uses ChangeNotifierProvider (matching existing pattern)
- Status filter "归档" chip toggles existing archiveFilterProvider
- Pending review panel shows count badge only in Phase 1
- Random review uses in-memory Set<int> (no persistence)

## [2026-05-22] Wave 1 Task 5 — Desktop Layout Rework
- Created 5 new widget files: `thought_composer.dart`, `thought_filter_bar.dart`, `thought_tag_filter_bar.dart`, `thought_selected_tags_bar.dart`, `thought_more_tags_popover.dart`
- Reworked `thoughts_desktop_layout.dart`: removed pinned/unpinned split, single grid, dynamic title with count badge, local search box
- Simplified `ThoughtsDesktopLayout` constructor from 27 params → 7 params (composer/filter bars read from providers directly)
- Simplified `ThoughtsPage`: removed `_LayoutParams` class, desktop layout receives only essential params
- `ThoughtComposer`: lightweight composer (max 1080px, 96px min height), disabled "转为待办"/"转为笔记" with Tooltip("即将推出")
- `ThoughtFilterBar`: status chips 全部/置顶/有图片/归档, toggles `thoughtStatusFilterProvider` + `archiveFilterProvider`
- `ThoughtTagFilterBar`: top 6 tags from `commonTagsProvider` + "+" button opening popover
- `ThoughtSelectedTagsBar`: shows selected tag with × and "清除" link, hidden when no filter
- `ThoughtMoreTagsPopover`: search field + full tag list in showMenu popover
- `_ThoughtLocalSearchBox`: writes to `thoughtSearchQueryProvider` with clear button
- Verification: `flutter analyze` passes (0 issues), 178/180 tests pass (2 pre-existing failures in `thoughts_providers_test.dart`)

## Guardrails
- NO database migration
- NO new columns
- NO real convert-to-todo/note
- NO multi-tag filter
- NO tag match mode OR/AND
- NO changes to ThoughtEditorDrawer

## [2026-05-22] Wave 1 Task 1 — Shared state template widgets
- Created `lib/src/plugins/thoughts/ui/widgets/thought_state_templates.dart`
- `ThoughtStateTemplate`: shared template widget accepting icon, title, subtitle, optional action label+callback. M3 colors via `Theme.of(context).colorScheme` — zero `AppColors` usage.
- 4 empty state named constructors: `noThoughts()`, `filterNoResults(tagName)`, `searchNoResults(query)`, `archiveEmpty()`
- 6 error state static helpers: `saveError()`, `imageError()`, `deleteError()`, `archiveError()`, `restoreError()`, `filterError()`
- Action button is conditional: only renders when BOTH actionLabel and onAction are non-null; `filterError` always has the label but only renders the button when `onRetry` is provided (consistent with all other helpers)
- 22 widget tests written and passing in `test/plugins/thoughts/ui/widgets/thought_state_templates_test.dart`
- Tests cover: text content for all variants, action button visibility (with/without callback), callback triggering, absence of action when not appropriate

## [2026-05-22] Wave 1 Task 2 — Global breakpoint update (mobileMax=899, tabletMin=900, wideMin=1280)
- Files changed: `app_breakpoints.dart`, `home/recent_section.dart` (720→AppBreakpoints.tabletMin), `app_breakpoints_test.dart`, `home_page_test.dart`
- Auto-updated via constants: `adaptive_shell.dart`, `adaptive_layout.dart`, `home_page.dart`, `thoughts_desktop_layout.dart`
- Not changed (not breakpoint values): `desktopContentMaxWidth=1120` (app_tokens.dart — content width constraint), `_ThoughtGrid 980/640`, `_ShortcutGrid 820`, `_RecentThoughtsGrid 760` (internal grid thresholds)
- Key discovery: `home_page_test.dart` "today overview" test uses window=1440, but sidebar (286px) reduces content area to 1154px — now < 1280 wideMin. Updated test to 1600px (content area=1314px) for right rail visibility
- Verification: `flutter analyze` passes, all 13 breakpoint tests pass, 2/2 adaptive_layout tests pass
- Pre-existing failures (not from this change): `thoughts_providers_test.dart` — caused by unstaged provider changes

## [2026-05-22] Wave 2 Task 7 — Right Rail Panels
- Created 5 new panel widgets in `lib/src/plugins/thoughts/ui/widgets/`:
  - `thought_pinned_panel.dart`: Top 3 pinned unarchived thoughts via `pinnedThoughtsProvider`, tap opens ThoughtEditorDrawer via `onThoughtTap` callback
  - `thought_pending_review_panel.dart`: Count of untagged unarchived thoughts via `pendingReviewProvider`, Phase 1 shows count badge only
  - `thought_common_tags_panel.dart`: Top 8 tags via `commonTagsProvider`, tappable to set `tagFilterProvider`, syncs with main filter
  - `thought_random_review_panel.dart`: 1 random thought >7 days old via `randomReviewProvider`, "换一个" button invalidates provider for next random, session-based seen ID tracking
  - `thought_quick_actions_panel.dart`: 2 disabled outlined buttons with Tooltip("即将推出")
- Reworked `_ThoughtsRightRail` in `thoughts_desktop_layout.dart`:
  - Removed old `_PinnedThoughtsPanel`, `_StatsPanel`, `_TagsPanel` classes and helper functions
  - New layout order: Pinned → Pending Review → Common Tags → Random Review → Quick Actions → Privacy Notice
  - Right rail uses `ConsumerWidget` panels that watch their own providers (all based on `allThoughtsProvider`, independent of main content filters)
  - Added `onThoughtTap` callback to `_ThoughtsRightRail` for opening ThoughtEditorDrawer from pinned/random panels
- Import path lesson: widgets in `widgets/` need `../../data/` (not `../data/`) to reach `data/` directory
- Verification: `flutter analyze` passes with zero issues on all 6 changed files

## [2026-05-22] Wave 3 Task 9 — ThoughtsPage Orchestrator Simplification
- `thoughts_page.dart` is now only responsible for `Scaffold.endDrawer`, selected drawer thought id, `AdaptiveLayout` switching, `Ctrl+Enter` submission via `composerProvider`, and archive/restore callbacks.
- Confirmed no `_LayoutParams`, `_ThoughtComposer`, `_ThoughtsToolbar`, or `_ThoughtsContent` remain in `thoughts_page.dart`.
- Moved desktop list/filter reads into `ThoughtsDesktopLayout`: it now watches `thoughtsListProvider`, `archiveFilterProvider`, `tagFilterProvider`, and `thoughtsCountProvider` directly.
- Desktop tag taps now write directly to `tagFilterProvider`, keeping right rail/common tag state synced through the same provider.
- Mobile status filter chips now use `ConsumerWidget` + `WidgetRef` directly instead of looking up an ancestor `ConsumerState`.
- Verification: LSP clean on all changed Dart files; `flutter analyze` passes; `dart fix --dry-run` reports nothing to fix; Thoughts UI widget tests pass (29 passed, 1 skipped).
- Known existing provider test failures still reproduce in `thoughts_providers_test.dart`: search returns `[6, 2]` instead of `[2]`, right rail returns `[5, 3]` instead of `[3, 5]`.
