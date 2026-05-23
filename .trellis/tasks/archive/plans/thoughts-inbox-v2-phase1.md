# Thoughts Inbox V2 Phase 1 — Implementation Plan

## TL;DR

> **Quick Summary**: Upgrade the Thoughts module from a simple card list to an "inbox" pattern with lightweight composer, search, status/tag filters, compressed cards with context menu, reworked right rail, and comprehensive empty/error states — all without database changes.

> **Deliverables**:
> - Updated breakpoints (global: mobileMax=899, tabletMin=900, wideMin=1280)
> - New providers: search (debounced), status filter, right rail data providers
> - Extracted ThoughtComposerController from _LayoutParams monolith
> - Reworked desktop layout: lightweight composer, search, status chips, tag filter bar, selected tags bar, compressed cards, context menu, new right rail panels
> - Parallel mobile layout updates: search, status chips, tag filter (horizontal scroll)
> - Empty states (4 types) and error states (6 types) using shared template
> - All existing functionality preserved (archive, edit drawer, compose, pin, image)

> **Estimated Effort**: Large
> **Parallel Execution**: YES - 3 waves
> **Critical Path**: Task 1 (breakpoints) → Task 2 (providers) → Task 4 (desktop layout) → Task 6 (states) → F1-F4

---

## Context

### Original Request
Implement Phase 1 of Thoughts Inbox V2 PRD: search, status filter, tag filter bar, compressed cards, right rail rework, empty/error states. Phase 1 constraints: no DB migration, no new columns, no real convert-to-todo/note, single-tag filter only.

### Interview Summary
**Key Discussions**:
- Phase 1 scope explicitly excludes: DB migration, status/linkedTodoId/linkedNoteId/processedAt columns, real convert-to-todo/note, multi-tag filter, tag match mode
- Breakpoint change (719/720/1120 → 899/900/1280) must be global and tested across all pages
- Archive nav entry already exists as child of "想法" — no new sidebar entry needed
- Right rail panels show global (unarchived-only) data, independent of main content filters
- Status filter "归档" chip toggles existing `archiveFilterProvider`
- Composer extraction requires careful QuillController lifecycle management
- Provider chain: archive → status → tag → search → final list

**Research Findings**:
- `AppBreakpoints` is shared across AdaptiveShell, HomePage, AdaptiveLayout, DesktopShell — global change required
- `_LayoutParams` in ThoughtsPage bundles ~25 parameters including QuillController with lifecycle management
- Archive nav already exists as plugin child entry (`ThoughtsPlugin.navEntries`)
- Provider layer has no search, no status filter — all filtering currently at tag+archive level
- `ThoughtContentCodec.plainTextFromStored()` is needed for search — must call per-thought
- Right rail currently has: Pinned (5), Stats, Tags (10), Privacy — needs complete rework to: Pinned (3), Pending review, Common tags (8), Random review, Quick actions, Privacy
- Card grid uses `childAspectRatio` — changing to max 180px is fundamental layout change
- `ThoughtSearchBox` in shared widgets is a stub (just shows snackbar)

### Metis Review
**Identified Gaps** (addressed):
- Breakpoint change is global breaking change — must test all pages, not just Thoughts
- Archive nav entry already exists — no new sidebar entry needed
- Status filter "归档" must coexist with existing `archiveFilterProvider` — chip toggles it
- Right rail providers must NOT watch `tagFilterProvider` or `thoughtSearchProvider`
- Composer QuillController lifecycle must be preserved during extraction
- Provider filtering order must be explicit: archive → status → tag → search
- Context menu on mobile needs long-press or three-dot fallback
- Card height constraint at 180px needs verification with varied content lengths

---

## Work Objectives

### Core Objective
Rebuild the Thoughts module UI from a simple card list to an inbox-pattern experience with search, filters, compressed cards, and a rich right rail — using only existing database fields and Provider-layer filtering.

### Concrete Deliverables
- Updated `AppBreakpoints` constants (899/900/1280) with all usages updated
- New `ThoughtStatusFilter` enum and providers (search, status filter, right rail data)
- Extracted `ThoughtComposerController` from `_LayoutParams`
- Reworked desktop layout with all new UI components
- Mobile layout with matching filter/search capabilities
- Card context menu (PopupMenuButton) and compressed card layout
- 4 empty state variants and 6 error state variants using shared template
- Widget tests for new providers and key UI interactions

### Definition of Done
- [x] `flutter analyze` passes with 0 errors, 0 warnings
- [x] `flutter test` passes for all existing + new tests
- [x] Desktop: ≥1280px shows 3-column layout (nav + content + right rail)
- [x] Desktop: 900-1279px shows 2-column layout (nav + content, no right rail)
- [x] Mobile: <900px shows single column with horizontal scroll filters
- [x] Search filters thoughts by content plain text and tags with 300ms debounce
- [x] Status filter chips work: 全部/置顶/有图片/归档
- [x] Tag filter bar with "more tags" popover
- [x] Selected tags bar with clear functionality
- [x] Cards max 180px height, max 3 tags +N, context menu with 7 items
- [x] Right rail: Pinned (max 3), Pending review, Common tags (max 8), Random review, Quick actions (disabled), Privacy
- [x] Pinned section removed from main content area
- [x] Right rail tag clicks sync with main tag filter
- [x] Empty states display correctly for all 4 scenarios
- [x] Error snacks display correctly for all 6 failure scenarios
- [x] Convert-to-todo/note buttons disabled with tooltip
- [x] No database schema changes

### Must Have
- Lightweight Composer with max 1080px width and 96-120px default input height
- Search box with 300ms debounce filtering by content plain text and tags
- Status filter chips: 全部/置顶/有图片/归档
- Tag filter bar showing top 6 tags with "more tags" popover
- Selected tags bar with per-tag remove and clear-all
- Compressed thought cards: max 180px height, max 3 tags +N, context menu
- Right rail: Pinned (max 3), Pending review (untagged+unarchived), Common tags (max 8, synced with main filter), Random review, Quick actions (disabled), Privacy notice
- Search and status/tag filters composable (archive → status → tag → search)
- Right rail panels show global data (unarchived only), NOT affected by main content filters
- Pinned section removed from main content area (only in right rail)
- Archive nav entry already exists — verify it works correctly
- Empty states: no thoughts, filter no results, search no results, archive empty
- Error states: save fail, image fail, delete fail, archive fail, restore fail, filter fail
- Global breakpoint update tested across ALL pages

### Must NOT Have (Guardrails)
- NO database migration or schema change
- NO new columns (status, linkedTodoId, linkedNoteId, processedAt)
- NO real convert-to-todo/note functionality (buttons disabled with tooltip only)
- NO multi-tag filter selection (Phase 1 single-tag only)
- NO tag match mode (OR/AND toggle)
- NO sorting feature beyond default (isPinned desc, createdAt desc)
- NO changes to ThoughtEditorDrawer (it's functional, don't touch it)
- NO changes to ThoughtsTable schema
- NO new routes for archive (already exists as query parameter)
- NO changes to AdaptiveShell or DesktopShell without verifying all pages render correctly
- NO AI slop: no excessive comments, no over-abstraction, no generic names

### Spec Framework Integration
- **Detected Framework**: None (no SDD framework detected)
- **Plan references PRD**: `.omo/plans/prd-thoughts-inbox-v2-detailed.md`

---

## Verification Strategy

> **ZERO HUMAN INTERVENTION** — ALL verification is agent-executed. No exceptions.

### Test Decision
- **Infrastructure exists**: YES
- **Automated tests**: YES (tests-after approach)
- **Framework**: Flutter test (existing pattern: ProviderScope overrides + in-memory Drift)
- **Agent-Executed QA**: ALWAYS (mandatory for all tasks)

### QA Policy
Every task MUST include agent-executed QA scenarios.
Evidence saved to `.omo/evidence/task-{N}-{scenario-slug}.{ext}`.

- **Flutter UI**: Use Playwright or flutter test — Widget tests for UI components, unit tests for providers
- **CLI/Build**: Use Bash — `flutter analyze`, `flutter test`
- **Cross-page verification**: Use Bash — verify no regressions on HomePage, Settings, etc.

---

## Execution Strategy

### Parallel Execution Waves

```
Wave 1 (Start Immediately — foundation + providers):
├── Task 1: Global breakpoint update [quick]
├── Task 2: Provider layer refactoring [deep]
├── Task 3: ThoughtComposerController extraction [deep]
└── Task 4: Shared state template widgets [quick]

Wave 2 (After Wave 1 — core UI rework):
├── Task 5: Desktop layout rework [visual-engineering]
├── Task 6: Thought card compression + context menu [visual-engineering]
├── Task 7: Right rail panels [visual-engineering]
└── Task 8: Mobile layout parallel update [visual-engineering]

Wave 3 (After Wave 2 — integration + polish):
├── Task 9: ThoughtsPage orchestrator simplification [deep]
└── Task 10: Integration verification + edge cases [unspecified-high]

Wave FINAL (After ALL tasks — review):
├── Task F1: Plan compliance audit [oracle]
├── Task F2: Code quality review [unspecified-high]
├── Task F3: Real manual QA [unspecified-high]
└── Task F4: Scope fidelity check [deep]
```

### Dependency Matrix

| Task | Blocked By | Blocks |
|------|-----------|--------|
| 1 | — | 5, 8 |
| 2 | — | 5, 7, 8, 9 |
| 3 | — | 5, 9 |
| 4 | — | 5, 7, 8 |
| 5 | 1, 2, 3, 4 | 9 |
| 6 | 2 | 9 |
| 7 | 2, 4 | 9 |
| 8 | 1, 2, 4 | 9 |
| 9 | 5, 6, 7, 8 | 10 |
| 10 | 9 | F1-F4 |

### Agent Dispatch Summary

- **Wave 1**: Task 1 → `quick`, Task 2 → `deep`, Task 3 → `deep`, Task 4 → `quick`
- **Wave 2**: Task 5 → `visual-engineering`, Task 6 → `visual-engineering`, Task 7 → `visual-engineering`, Task 8 → `visual-engineering`
- **Wave 3**: Task 9 → `deep`, Task 10 → `unspecified-high`
- **FINAL**: F1 → `oracle`, F2 → `unspecified-high`, F3 → `unspecified-high`, F4 → `deep`

---

## TODOs

- [x] 1. Global Breakpoint Update

  **What to do**:
  - Update `AppBreakpoints` constants: `mobileMax=899`, `tabletMin=900`, `wideMin=1280`
  - Update `WindowSize.of()` logic accordingly (compact < 900, medium 900-1279, expanded ≥ 1280)
  - Find ALL usages of `AppBreakpoints.mobileMax`, `AppBreakpoints.tabletMin`, `AppBreakpoints.wideMin` using `lsp_find_references`
  - Update `AdaptiveLayout` if it has hardcoded breakpoint references
  - Update `DesktopShell` sidebar visibility logic if needed
  - Update `HomePage` breakpoint references (uses `tabletMin` and `wideMin`)
  - Verify ALL pages render correctly at new breakpoints (899px, 900px, 1279px, 1280px)
  - Run existing breakpoint tests in `test/core/theme/app_breakpoints_test.dart`
  - Update any responsive column calculations in `_ThoughtGrid` (currently uses 4/2/1 at different widths)

  **Must NOT do**:
  - MUST NOT add Thoughts-specific breakpoint overrides
  - MUST NOT change the semantics of WindowSize enum (compact/medium/expanded)
  - MUST NOT break existing home page layout at new thresholds

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: [`flutter-dev`, `flutter-build-responsive-layout`]
  - **Skills Evaluated but Omitted**: `frontend-ui-ux` (no visual design needed, just constants update)

  **Parallelization**:
  - **Can Run In Parallel**: YES (with Tasks 2, 3, 4)
  - **Parallel Group**: Wave 1
  - **Blocks**: Tasks 5, 8 (layout work depends on new breakpoints)
  - **Blocked By**: None

  **References**:
  - `lib/src/core/theme/app_breakpoints.dart` — Current breakpoint constants to change
  - `lib/src/core/app/home_page.dart:31,35` — Uses `tabletMin`, `wideMin` for layout
  - `lib/src/shared/widgets/adaptive_layout.dart:21` — Uses `tabletMin`
  - `lib/src/plugins/thoughts/ui/layouts/thoughts_desktop_layout.dart:74` — Uses `wideMin`
  - `test/core/theme/app_breakpoints_test.dart` — Existing breakpoint tests to update

  **Acceptance Criteria**:
  - [ ] `AppBreakpoints.mobileMax == 899`
  - [ ] `AppBreakpoints.tabletMin == 900`
  - [ ] `AppBreakpoints.wideMin == 1280`
  - [ ] `flutter analyze` passes with 0 errors
  - [ ] `flutter test test/core/theme/app_breakpoints_test.dart` passes
  - [ ] All pages using breakpoints compile and render at new thresholds

  **QA Scenarios**:

  ```
  Scenario: Breakpoint constants updated
    Tool: Bash (grep)
    Steps:
      1. grep -rn "mobileMax\|tabletMin\|wideMin" lib/src/core/theme/app_breakpoints.dart
      2. Verify output shows: mobileMax = 899, tabletMin = 900, wideMin = 1280
    Expected Result: All three constants updated to new values
    Failure Indicators: Any old value (719, 720, 1120) remaining
    Evidence: .omo/evidence/task-1-breakpoint-constants.txt

  Scenario: All usages found and updated
    Tool: Bash (grep)
    Steps:
      1. grep -rn "mobileMax\|tabletMin\|wideMin" lib/src/
      2. Verify no references to old values in layout logic
    Expected Result: No hardcoded old breakpoint values remain
    Failure Indicators: References to 719, 720, or 1120 in layout code
    Evidence: .omo/evidence/task-1-breakpoint-usages.txt
  ```

  **Commit**: YES (groups with task group)
  - Message: `refactor(breakpoints): update global breakpoints to mobile=899/900/1280`
  - Files: `app_breakpoints.dart`, all usage files
  - Pre-commit: `flutter analyze && flutter test`

- [x] 2. Provider Layer Refactoring

  **What to do**:
  - Create `thought_status_filter.dart` with `ThoughtStatusFilter` enum: `all`, `pinned`, `withImages`, `archived`
  - Add to `thoughts_providers.dart`:
    - `thoughtSearchQueryProvider` — StateProvider<String> for raw search input
    - `thoughtSearchDebouncedProvider` — debounced (300ms) search query derived from `thoughtSearchQueryProvider`
    - `thoughtStatusFilterProvider` — StateProvider<ThoughtStatusFilter> defaulting to `.all`
    - `pinnedThoughtsProvider` — top 3 pinned, unarchived thoughts (for right rail)
    - `pendingReviewProvider` — thoughts with empty tags and not archived
    - `commonTagsProvider` — top 8 tags by frequency from unarchived thoughts (for right rail)
    - `randomReviewProvider` — single random thought from unarchived, created >7 days ago, session-based tracking
  - Refactor `thoughtsListProvider` to compose: `allThoughtsProvider` → status filter → tag filter → search filter
  - Add search logic: call `ThoughtContentCodec.plainTextFromStored()` for content search, match tags, case-insensitive
  - The "归档" status filter chip should set `archiveFilterProvider` to true (coexists with existing archive nav)
  - Right rail providers (`pinnedThoughtsProvider`, `pendingReviewProvider`, `commonTagsProvider`, `randomReviewProvider`) watch `allThoughtsProvider` only, NOT `thoughtSearchQueryProvider` or `tagFilterProvider`
  - Add `thoughtsCountProvider` — returns count of current filtered list

  **Must NOT do**:
  - MUST NOT add any new columns to ThoughtsTable
  - MUST NOT create a `status` field or column
  - MUST NOT modify the DAO (all filtering is in Provider layer)
  - MUST NOT implement multi-tag selection (single tag only)

  **Recommended Agent Profile**:
  - **Category**: `deep`
  - **Skills**: [`flutter-dev`]
  - **Skills Evaluated but Omitted**: `frontend-ui-ux` (no UI work in this task)

  **Parallelization**:
  - **Can Run In Parallel**: YES (with Tasks 1, 3, 4)
  - **Parallel Group**: Wave 1
  - **Blocks**: Tasks 5, 7, 8, 9
  - **Blocked By**: None

  **References**:
  - `lib/src/plugins/thoughts/providers/thoughts_providers.dart` — Existing providers to extend
  - `lib/src/plugins/thoughts/data/thoughts_dao.dart` — DAO methods (no changes, reference only)
  - `lib/src/plugins/thoughts/data/thought_content_codec.dart` — `plainTextFromStored()` for search
  - `lib/src/plugins/thoughts/data/thoughts_repository.dart` — Repository interface (no changes)
  - PRD Section 22 (Provider Design) and Section 23 (DAO/Repository)

  **Acceptance Criteria**:
  - [ ] `ThoughtStatusFilter` enum exists with `all`, `pinned`, `withImages`, `archived`
  - [ ] `thoughtSearchQueryProvider` and `thoughtSearchDebouncedProvider` (300ms debounce) exist
  - [ ] `thoughtStatusFilterProvider` exists with default `.all`
  - [ ] `pinnedThoughtsProvider` returns top 3 pinned unarchived thoughts
  - [ ] `pendingReviewProvider` returns untagged + unarchived thoughts
  - [ ] `commonTagsProvider` returns top 8 tags from unarchived thoughts
  - [ ] `randomReviewProvider` returns single random thought with session tracking
  - [ ] `thoughtsListProvider` composes: archive → status → tag → search
  - [ ] Right rail providers do NOT watch tagFilterProvider or thoughtSearchQueryProvider
  - [ ] `flutter analyze` passes
  - [ ] Unit tests pass for provider chain behavior

  **QA Scenarios**:

  ```
  Scenario: Provider chain filter order correct
    Tool: Bash (flutter test)
    Steps:
      1. Write unit test that sets archiveFilter=true, statusFilter=pinned, tagFilter="产品", searchQuery="灵感"
      2. Verify thoughtsListProvider returns only thoughts matching ALL filters
      3. Write test with only archive filter — verify all non-archived thoughts returned
    Expected Result: Filter chain composes correctly in archive → status → tag → search order
    Failure Indicators: Thoughts not matching all active filters appear in result
    Evidence: .omo/evidence/task-2-provider-chain-test.txt

  Scenario: Right rail providers ignore main content filters
    Tool: Bash (flutter test)
    Steps:
      1. Set tagFilterProvider to "产品" and thoughtSearchQueryProvider to "灵感"
      2. Verify pinnedThoughtsProvider returns top 3 pinned thoughts regardless of tag/search
      3. Verify commonTagsProvider returns top 8 tags from ALL unarchived thoughts
    Expected Result: Right rail providers show global unarchived data
    Failure Indicators: Right rail data changes when main content filters change
    Evidence: .omo/evidence/task-2-rail-independence-test.txt

  Scenario: Search debounce works correctly
    Tool: Bash (flutter test)
    Steps:
      1. Set thoughtSearchQueryProvider to "abc" immediately
      2. Verify thoughtSearchDebouncedProvider has not updated yet
      3. Wait 300ms
      4. Verify thoughtSearchDebouncedProvider now equals "abc"
    Expected Result: Search triggers after 300ms debounce, not immediately
    Failure Indicators: Search triggers before 300ms, or never triggers
    Evidence: .omo/evidence/task-2-search-debounce-test.txt
  ```

  **Commit**: YES
  - Message: `feat(thoughts): add search, status filter, and right rail providers`
  - Files: `thought_status_filter.dart`, `thoughts_providers.dart`, test files
  - Pre-commit: `flutter analyze && flutter test`

- [x] 3. ThoughtComposerController Extraction

  **What to do**:
  - Create `thought_composer_controller.dart` in `ui/widgets/`
  - Extract composer state from `_ThoughtsPageState` into `ThoughtComposerController`:
    - `QuillController` creation and disposal (lifecycle critical)
    - `tagChips` (List<String>) management
    - `pendingImages` (List<PickedImage>) management
    - `isPinned` toggle
    - `isSubmitting` flag
    - `canSubmit` computed property (has content or has images)
    - `clear()` method to reset after successful submit
  - Controller should follow the pattern of existing `ThoughtEditorController` (see reference) — use `ChangeNotifier` and provide via Riverpod `ChangeNotifierProvider<ThoughtComposerController>` (NOT `StateNotifierProvider` — that pattern requires a separate state class which is unnecessary here since the controller IS the state)
  - Update `thoughts_page.dart` to use `composerProvider` instead of local state
  - Keep `_tagTextController` in controller for tag input management
  - Ensure Ctrl+Enter submit shortcut still works

  **Must NOT do**:
  - MUST NOT break existing composer submit functionality
  - MUST NOT change the QuillEditor widget or RichTextEditor shared component
  - MUST NOT change how ThoughtEditorDrawer works (it's separate from composer)

  **Recommended Agent Profile**:
  - **Category**: `deep`
  - **Skills**: [`flutter-dev`]
  - **Skills Evaluated but Omitted**: `frontend-ui-ux` (no visual changes)

  **Parallelization**:
  - **Can Run In Parallel**: YES (with Tasks 1, 2, 4)
  - **Parallel Group**: Wave 1
  - **Blocks**: Tasks 5, 9
  - **Blocked By**: None

  **References**:
  - `lib/src/plugins/thoughts/ui/thoughts_page.dart` — Current `_ThoughtsPageState` with all composer state
  - `lib/src/plugins/thoughts/ui/widgets/thought_editor_controller.dart` — Existing editor controller pattern to follow
  - `lib/src/shared/ui/rich_text_editor/rich_text_editor.dart` — Shared RichTextEditor used by composer
  - `lib/src/plugins/thoughts/data/picked_image.dart` — PickedImage model for pending images

  **Acceptance Criteria**:
  - [ ] `ThoughtComposerController` class exists with all composer state
  - [ ] `QuillController` lifecycle managed correctly (create in constructor, dispose)
  - [ ] `composerProvider` Riverpod provider exists (as `ChangeNotifierProvider`)
  - [ ] `thoughts_page.dart` no longer holds composer state directly
  - [ ] Existing submit, image pick, tag chip, pin toggle functionality preserved
  - [ ] `flutter analyze` passes
  - [ ] Existing widget tests pass

  **QA Scenarios**:

  ```
  Scenario: Composer controller lifecycle
    Tool: Bash (flutter test)
    Steps:
      1. Create ThoughtComposerController instance
      2. Verify QuillController is initialized
      3. Call dispose()
      4. Verify no memory leaked (controller disposed)
    Expected Result: Controller creates and disposes QuillController correctly
    Failure Indicators: QuillController not disposed, or controller throws on dispose
    Evidence: .omo/evidence/task-3-controller-lifecycle.txt

  Scenario: Composer state preserved on error
    Tool: Bash (flutter test)
    Steps:
      1. Create controller, set content="test content", add tag "产品"
      2. Simulate submit failure (isSubmitting transitions back to false)
      3. Verify content and tags preserved
    Expected Result: Content and tags remain after failed submit
    Failure Indicators: Content cleared after failed submit
    Evidence: .omo/evidence/task-3-error-preservation.txt
  ```

  **Commit**: YES
  - Message: `refactor(thoughts): extract ThoughtComposerController from page state`
  - Files: `thought_composer_controller.dart`, `thoughts_page.dart`
  - Pre-commit: `flutter analyze && flutter test`

- [x] 4. Shared State Template Widgets

  **What to do**:
  - Create `thought_state_templates.dart` in `ui/widgets/`
  - Design a `ThoughtStateTemplate` widget that accepts:
    - `icon` (IconData), `title` (String), `subtitle` (String), `action` (optional: label + callback)
    - Consistent M3 styling with `Theme.of(context).colorScheme`
  - Create 4 empty state variants:
    - `ThoughtEmptyState.noThoughts()` — "还没有想法" + "记录第一个念头..." + "记录想法" button
    - `ThoughtEmptyState.filterNoResults(String tagName)` — "没有找到带有 #xxx 的想法" + "清除筛选" button
    - `ThoughtEmptyState.searchNoResults(String query)` — "没有找到相关想法" + "清除搜索" button
    - `ThoughtEmptyState.archiveEmpty()` — "暂无归档想法" + "归档后的想法会显示在这里"
  - Create 6 error snack bar/message helpers:
    - Save fail: "保存失败，请稍后重试"
    - Image fail: "图片添加失败，请检查文件权限"
    - Delete fail: "删除失败，请稍后重试"
    - Archive fail: "归档失败，请稍后重试"
    - Restore fail: "恢复失败，请稍后重试"
    - Filter fail: "加载失败，请重试" with retry button
  - Use `Theme.of(context).colorScheme` for all colors, not `AppColors` constants
  - Follow existing shared widget patterns from `thoughts_shared_widgets.dart`

  **Must NOT do**:
  - MUST NOT create 10 completely custom widget implementations — use shared template
  - MUST NOT use AppColors constants directly — use `Theme.of(context).colorScheme`

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: [`flutter-dev`, `frontend-ui-ux`]
  - **Skills Evaluated but Omitted**: `flutter-build-responsive-layout` (not layout work)

  **Parallelization**:
  - **Can Run In Parallel**: YES (with Tasks 1, 2, 3)
  - **Parallel Group**: Wave 1
  - **Blocks**: Tasks 5, 7, 8
  - **Blocked By**: None

  **References**:
  - `lib/src/plugins/thoughts/ui/layouts/thoughts_shared_widgets.dart` — Existing shared widget patterns (ThoughtPanel, ThoughtEmptyState, ThoughtErrorState)
  - `lib/src/core/theme/app_tokens.dart` — Design tokens (AppSpacing, AppRadius)
  - PRD Section 25 (Empty States) and Section 26 (Error States)

  **Acceptance Criteria**:
  - [ ] `ThoughtStateTemplate` widget exists with icon, title, subtitle, action parameters
  - [ ] 4 empty state factory constructors exist in `ThoughtEmptyState`
  - [ ] 6 error state helpers exist for save/image/delete/archive/restore/filter failures
  - [ ] All states use `Theme.of(context).colorScheme` for colors
  - [ ] `flutter analyze` passes

  **QA Scenarios**:

  ```
  Scenario: Empty state widgets render correctly
    Tool: Bash (flutter test)
    Steps:
      1. Write widget test for each empty state variant
      2. Verify text content matches PRD specifications
      3. Verify action buttons are present and tappable
    Expected Result: All 4 empty states render with correct text and actions
    Failure Indicators: Missing text, wrong labels, no action buttons
    Evidence: .omo/evidence/task-4-empty-states-test.txt

  Scenario: Error state helpers produce correct messages
    Tool: Bash (flutter test)
    Steps:
      1. Call each error state helper
      2. Verify message text matches PRD specifications
    Expected Result: All 6 error messages match PRD exactly
    Failure Indicators: Wrong message text or missing retry button on filter fail
    Evidence: .omo/evidence/task-4-error-states-test.txt
  ```

  **Commit**: YES
  - Message: `feat(thoughts): add shared empty/error state templates`
  - Files: `thought_state_templates.dart`
  - Pre-commit: `flutter analyze`

- [x] 5. Desktop Layout Rework (post-phase-1: filter area consolidated into compact 3-row ThoughtFilterPanel)

  **What to do**:
  - Create `thought_composer.dart` in `ui/widgets/` — lightweight composer widget:
    - Max width 1080px, default input height 96-120px
    - Uses `ThoughtComposerController` for state (from Task 3)
    - Pending image thumbnails row
    - Tag input field with chip display
    - Image picker button, pin toggle button
    - Submit button with Ctrl+Enter shortcut
  - Create `thought_filter_bar.dart` in `ui/widgets/` — status filter chips:
    - Shows chips: 全部 (default), 置顶, 有图片, 归档
    - 归档 chip toggles `archiveFilterProvider`
    - 置顶 chip filters by `isPinned == true`
    - 有图片 chip filters by `imagePaths != null && imagePaths.isNotEmpty`
    - Active chip highlighted with M3 color scheme
  - Create `thought_tag_filter_bar.dart` in `ui/widgets/` — tag filter bar:
    - Shows top 6 tags sorted by frequency
    - "+" button opens `thought_more_tags_popover.dart`
    - Selected tag highlighted, tap to filter
    - Syncs with `tagFilterProvider`
  - Create `thought_selected_tags_bar.dart` in `ui/widgets/` — selected tags display:
    - Shows currently selected tag chip with × close
    - "清除" link to clear tag filter
    - Only visible when a tag is selected
  - Create `thought_more_tags_popover.dart` in `ui/widgets/` — tag overflow popover:
    - Search field for filtering tags
    - Scrollable list of all tags with counts
    - Tap a tag to select it (closes popover)
  - Rework `thoughts_desktop_layout.dart`:
    - Remove pinned/unpinned split section (`_ThoughtsContent`)
    - Use single `_ThoughtGrid` for all thoughts (sorted by `isPinned desc, createdAt desc`)
    - Dynamic title: "想法" (default), "归档想法" (when archived), shows count badge
    - Replace `_ThoughtComposer` with new `ThoughtComposer` widget
    - Replace `_ThoughtsToolbar` with `ThoughtFilterBar` + `ThoughtTagFilterBar` + `ThoughtSearchBox`
    - Layout: Search → Filters → Selected tags → Composer → Grid
    - Keep right rail section (Task 7 will replace its contents)
  - Add disabled "转为待办" and "转为笔记" buttons with `Tooltip` saying "即将推出"

  **Must NOT do**:
  - MUST NOT change ThoughtEditorDrawer (it's separate and functional)
  - MUST NOT implement real convert-to-todo/note — buttons are disabled stubs only
  - MUST NOT add sorting feature beyond default order
  - MUST NOT remove the endDrawer for ThoughtEditorDrawer

  **Recommended Agent Profile**:
  - **Category**: `visual-engineering`
  - **Skills**: [`flutter-dev`, `frontend-ui-ux`, `flutter-build-responsive-layout`]
  - **Skills Evaluated but Omitted**: `flutter-add-widget-test` (test task is separate)

  **Parallelization**:
  - **Can Run In Parallel**: YES (with Tasks 6, 7, 8)
  - **Parallel Group**: Wave 2
  - **Blocks**: Task 9
  - **Blocked By**: Tasks 1, 2, 3, 4

  **References**:
  - `lib/src/plugins/thoughts/ui/layouts/thoughts_desktop_layout.dart` — Current desktop layout to rework
  - `lib/src/plugins/thoughts/ui/thoughts_page.dart` — Orchestration page, provides _LayoutParams
  - `lib/src/plugins/thoughts/ui/widgets/thought_card.dart` — Card widget (being modified in Task 6)
  - `lib/src/plugins/thoughts/ui/layouts/thoughts_shared_widgets.dart` — Shared widgets: ThoughtSearchBox, ThoughtFilterChip, ThoughtPillButton
  - `lib/src/plugins/thoughts/providers/thoughts_providers.dart` — Providers to consume (Task 2 adds new ones)
  - PRD Sections 3-6 (Composer, Search, Filters, Tags)

  **Acceptance Criteria**:
  - [ ] `ThoughtComposer` widget created with max 1080px width, 96-120px input height
  - [ ] `ThoughtFilterBar` with 4 status chips (全部/置顶/有图片/归档) working
  - [ ] `ThoughtTagFilterBar` showing top 6 tags with "more" popover
  - [ ] `ThoughtSelectedTagsBar` showing selected tag with clear
  - [ ] `ThoughtMoreTagsPopover` with search and full tag list
  - [ ] Desktop layout uses new composer, filter bar, tag filter bar
  - [ ] Pinned/unpinned content split REMOVED — single grid for all thoughts
  - [ ] Dynamic title shows "想法" or "归档想法" with count
  - [ ] Disabled "转为待办" and "转为笔记" buttons with tooltips
  - [ ] `flutter analyze` passes

  **QA Scenarios**:

  ```
  Scenario: Lightweight composer renders with correct constraints
    Tool: Bash (flutter test)
    Steps:
      1. Render ThoughtComposer in test with 1200px width
      2. Verify composer max width is 1080px
      3. Verify input area height between 96-120px
    Expected Result: Composer respects width and height constraints
    Failure Indicators: Composer exceeds 1080px width or input area outside 96-120px
    Evidence: .omo/evidence/task-5-composer-constraints.txt

  Scenario: Status filter chips work correctly
    Tool: Bash (flutter test)
    Steps:
      1. Tap "置顶" chip → verify thoughtStatusFilterProvider is ThoughtStatusFilter.pinned
      2. Tap "归档" chip → verify archiveFilterProvider is true
      3. Tap "全部" chip → verify status filter is .all and archive filter is false
    Expected Result: Each chip activates correct filter
    Failure Indicators: Wrong provider state after chip tap
    Evidence: .omo/evidence/task-5-status-filters.txt

  Scenario: Tag filter bar with overflow
    Tool: Bash (flutter test)
    Steps:
      1. Render tag filter bar with 10 tags (top 6 visible)
      2. Verify only 6 tag chips displayed
      3. Tap "+" button → popover opens with all 10 tags
      4. Search for tag → filtered list shows matching tags
      5. Tap a tag → popover closes, tag selected in main filter
    Expected Result: Tag bar shows top 6, popover shows all, selection syncs
    Failure Indicators: More than 6 chips shown, popover doesn't open, selection doesn't sync
    Evidence: .omo/evidence/task-5-tag-filter-bar.txt
  ```

  **Commit**: YES
  - Message: `feat(thoughts): redesign desktop layout with inbox pattern`
  - Files: `thought_composer.dart`, `thought_filter_bar.dart`, `thought_tag_filter_bar.dart`, `thought_selected_tags_bar.dart`, `thought_more_tags_popover.dart`, `thoughts_desktop_layout.dart`
  - Pre-commit: `flutter analyze`

- [x] 6. Thought Card Compression + Context Menu

  **What to do**:
  - Modify `thought_card.dart`:
    - Add `maxHeight` constraint of 180px
    - Limit title to 1 line with `maxLines: 1`, `overflow: TextOverflow.ellipsis`
    - Limit summary/body to 2 lines with `maxLines: 2`, `overflow: TextOverflow.ellipsis`
    - Show max 3 tags, with "+N" overflow indicator (e.g., "+2" if 5 tags total)
    - Show image badge icon if `imagePaths` is not empty
    - Show pin icon if `isPinned`
    - Add `onContextMenu` callback for popup menu trigger
    - On desktop: right-click → context menu; on mobile: long-press → context menu
  - Create `thought_context_menu.dart` in `ui/widgets/`:
    - `ThoughtContextMenu` function/widget returning `PopupMenuButton` or `PopupMenuEntry` list
    - Items: 编辑, 置顶/取消置顶, 加标签, 转为待办 (DISABLED), 转为笔记 (DISABLED), 归档/取消归档, 删除
    - "转为待办" and "转为笔记" show `Tooltip("即将推出")` and are `enabled: false`
    - "编辑" calls `onEdit` → opens ThoughtEditorDrawer
    - "置顶/取消置顶" calls `onTogglePin`
    - "加标签" opens tag input (or shows tag picker)
    - "归档/取消归档" calls `onArchive` or `onRestore`
    - "删除" shows confirmation dialog → calls `onDelete`
  - Add delete confirmation dialog (AlertDialog with "确认删除?" message)
  - Add archive/restore snackbar feedback using `ScaffoldMessenger`
  - Remove hover archive/restore icons from card (replaced by context menu)

  **Must NOT do**:
  - MUST NOT change ThoughtEditorDrawer
  - MUST NOT implement real convert-to-todo/note logic
  - MUST NOT add new fields to ThoughtsTable
  - MUST NOT make context menu items functional for "转为待办" and "转为笔记"

  **Recommended Agent Profile**:
  - **Category**: `visual-engineering`
  - **Skills**: [`flutter-dev`, `frontend-ui-ux`]
  - **Skills Evaluated but Omitted**: `flutter-build-responsive-layout` (card is same on all sizes)

  **Parallelization**:
  - **Can Run In Parallel**: YES (with Tasks 5, 7, 8)
  - **Parallel Group**: Wave 2
  - **Blocks**: Task 9
  - **Blocked By**: Task 2

  **References**:
  - `lib/src/plugins/thoughts/ui/widgets/thought_card.dart` — Current card to modify
  - `lib/src/plugins/thoughts/data/thoughts_table.dart` or data model — Thought fields (isPinned, imagePaths, tags, archivedAt)
  - PRD Sections 7-8 (Compressed Cards, Context Menu)

  **Acceptance Criteria**:
  - [ ] Card maxHeight constrained to 180px
  - [ ] Title shows 1 line with ellipsis overflow
  - [ ] Summary shows 2 lines with ellipsis overflow
  - [ ] Max 3 tags shown with "+N" overflow indicator
  - [ ] Image badge icon shown when imagePaths not empty
  - [ ] Pin icon shown when isPinned
  - [ ] Context menu has 7 items (2 disabled: 转为待办, 转为笔记)
  - [ ] Delete shows confirmation dialog
  - [ ] Archive/restore shows snackbar feedback
  - [ ] Hover archive/restore icons removed from card
  - [ ] `flutter analyze` passes

  **QA Scenarios**:

  ```
  Scenario: Card displays correctly with varied content lengths
    Tool: Bash (flutter test)
    Steps:
      1. Render ThoughtCard with long title (>50 chars), 2-line body, 5 tags, 2 images
      2. Verify: title shows 1 line with ellipsis, body shows 2 lines, only 3 tags + "+2" shown, image badge present
      3. Render ThoughtCard with short title, no tags, no images
      4. Verify: card still within 180px max, no overflow, no image badge
    Expected Result: Cards respect max 180px, content truncation works
    Failure Indicators: Card exceeds 180px, tags overflow, missing ellipsis
    Evidence: .omo/evidence/task-6-card-compression.txt

  Scenario: Context menu shows all items with correct enabled/disabled states
    Tool: Bash (flutter test)
    Steps:
      1. Show context menu on a thought
      2. Verify 7 menu items appear
      3. Verify "转为待办" and "转为笔记" are disabled with tooltip "即将推出"
      4. Tap "删除" → verify confirmation dialog appears
      5. Tap "归档" on unarchived thought → verify snackbar shown
    Expected Result: Context menu works with correct states and callbacks
    Failure Indicators: Missing items, wrong enabled state, no confirmation on delete
    Evidence: .omo/evidence/task-6-context-menu.txt

  Scenario: Card height constraint with edge cases
    Tool: Bash (flutter test)
    Steps:
      1. Render card with empty content (just whitespace)
      2. Render card with 10 tags and 3 images
      3. Verify both cards stay within 180px max height
    Expected Result: Cards never exceed 180px regardless of content
    Failure Indicators: Card height exceeds 180px
    Evidence: .omo/evidence/task-6-card-height-edge.txt
  ```

  **Commit**: YES
  - Message: `feat(thoughts): compress cards to 180px and add context menu`
  - Files: `thought_card.dart`, `thought_context_menu.dart`
  - Pre-commit: `flutter analyze`

- [x] 7. Right Rail Panels

  **What to do**:
  - Rework `_ThoughtsRightRail` in `thoughts_desktop_layout.dart` (or extract to separate file):
    - Remove existing `_PinnedThoughtsPanel` (max 5), `_StatsPanel`, `_TagsPanel`
    - Build entirely new right rail structure
  - Create `thought_pinned_panel.dart` in `ui/widgets/`:
    - Shows top 3 pinned, unarchived thoughts
    - Header: "置顶" with count badge (e.g., "3")
    - Each item shows title (1 line, ellipsis) + timestamp
    - Tap item opens ThoughtEditorDrawer
    - Data source: `pinnedThoughtsProvider` (NOT filtered by main tag/search)
  - Create `thought_pending_review_panel.dart` in `ui/widgets/`:
    - Shows count of untagged + unarchived thoughts
    - Header: "待整理" with count badge
    - For Phase 1: show count badge only — tapping does NOT set any status filter (there is no "pending" status filter in Phase 1), but could set tagFilterProvider to null and archiveFilterProvider to false to show all unfiltered thoughts as a future enhancement
  - Create `thought_common_tags_panel.dart` in `ui/widgets/`:
    - Shows top 8 tags sorted by frequency from unarchived thoughts
    - Each tag shows name + count, tappable to set `tagFilterProvider`
    - Tapping a tag in right rail syncs with main tag filter (sets `tagFilterProvider`)
    - Data source: `commonTagsProvider` (global, NOT filtered by main content)
  - Create `thought_random_review_panel.dart` in `ui/widgets/`:
    - Shows 1 random thought that was created >7 days ago
    - "换一个" button to get another random thought
    - Session-based tracking: `Set<int>` of seen IDs, reset when all seen
    - Data source: `randomReviewProvider`
  - Create `thought_quick_actions_panel.dart` in `ui/widgets/`:
    - 2 disabled buttons: "转为待办", "转为笔记"
    - Each has `Tooltip("即将推出")`
    - Visual style: outlined buttons, M3 color scheme
  - Right rail layout (top to bottom): Pinned → Pending Review → Common Tags → Random Review → Quick Actions → Privacy Notice
  - Right rail panels use `allThoughtsProvider` (unarchived-only), NOT `thoughtsListProvider`
  - Right rail visible at `width >= 1280px` (using new `AppBreakpoints.wideMin`)

  **Must NOT do**:
  - MUST NOT filter right rail data by main content tag or search
  - MUST NOT persist random review state to SharedPreferences (in-memory Set<int> only)
  - MUST NOT implement real convert-to-todo/note in Quick Actions

  **Recommended Agent Profile**:
  - **Category**: `visual-engineering`
  - **Skills**: [`flutter-dev`, `frontend-ui-ux`]
  - **Skills Evaluated but Omitted**: `flutter-build-responsive-layout` (right rail is desktop-only)

  **Parallelization**:
  - **Can Run In Parallel**: YES (with Tasks 5, 6, 8)
  - **Parallel Group**: Wave 2
  - **Blocks**: Task 9
  - **Blocked By**: Tasks 2, 4

  **References**:
  - `lib/src/plugins/thoughts/ui/layouts/thoughts_desktop_layout.dart` — Current right rail (`_ThoughtsRightRail`, `_PinnedThoughtsPanel`, `_StatsPanel`, `_TagsPanel`)
  - `lib/src/plugins/thoughts/providers/thoughts_providers.dart` — New right rail providers (from Task 2)
  - `lib/src/plugins/thoughts/ui/layouts/thoughts_shared_widgets.dart` — ThoughtPanel, ThoughtPanelHeader, ThoughtSectionLabel patterns
  - PRD Sections 9-13 (Right Rail: Pinned, Pending, Tags, Random, Quick Actions, Privacy)

  **Acceptance Criteria**:
  - [ ] Pinned panel shows max 3 items, not affected by main content filters
  - [ ] Pending review panel shows untagged + unarchived count (Phase 1: count badge only, no status filter action)
  - [ ] Common tags panel shows max 8 tags, tapping syncs with main `tagFilterProvider`
  - [ ] Random review panel shows 1 random old thought with "换一个" button
  - [ ] Quick actions panel has 2 disabled buttons with "即将推出" tooltip
  - [ ] Right rail visible at ≥1280px width
  - [ ] Old panels (max 5 pinned, stats, max 10 tags) REMOVED
  - [ ] `flutter analyze` passes

  **QA Scenarios**:

  ```
  Scenario: Right rail shows global data independent of main filters
    Tool: Bash (flutter test)
    Steps:
      1. Set tagFilterProvider to "产品" and thoughtSearchQueryProvider to "灵感"
      2. Verify pinnedThoughtsProvider returns top 3 pinned globally
      3. Verify commonTagsProvider returns top 8 tags globally
      4. Verify pendingReviewProvider returns all untagged+unarchived globally
    Expected Result: Right rail data doesn't change when main filters change
    Failure Indicators: Right rail data changes when tag/search filters change
    Evidence: .omo/evidence/task-7-rail-independence.txt

  Scenario: Pinned panel shows max 3 items
    Tool: Bash (flutter test)
    Steps:
      1. Create 5 pinned thoughts
      2. Verify pinnedThoughtsProvider returns only 3
    Expected Result: Only top 3 pinned items shown
    Failure Indicators: More than 3 items shown
    Evidence: .omo/evidence/task-7-pinned-max3.txt

  Scenario: Random review no-repeat in session
    Tool: Bash (flutter test)
    Steps:
      1. Create 5 thoughts older than 7 days
      2. Request random 5 times via "换一个"
      3. Verify no duplicate in the first 5 requests (until all seen)
      4. After all seen, verify reset and can show previous thoughts again
    Expected Result: No duplicates until all thoughts have been shown
    Failure Indicators: Same thought appears twice before all are shown
    Evidence: .omo/evidence/task-7-random-review.txt
  ```

  **Commit**: YES
  - Message: `feat(thoughts): add right rail panels (pinned, pending, tags, random, quick actions)`
  - Files: `thought_pinned_panel.dart`, `thought_pending_review_panel.dart`, `thought_common_tags_panel.dart`, `thought_random_review_panel.dart`, `thought_quick_actions_panel.dart`, `thoughts_desktop_layout.dart`
  - Pre-commit: `flutter analyze`

- [x] 8. Mobile Layout Parallel Update

  **What to do**:
  - Rework `thoughts_mobile_layout.dart`:
    - Add search bar at top using `ThoughtSearchBox` (updated provider)
    - Add horizontal scrolling status filter chips: 全部/置顶/有图片/归档
    - Add horizontal scrolling tag filter chips (top 4 tags)
    - Add "more tags" button that opens bottom sheet with full tag list
    - Update composer to use `ThoughtComposerController` (from Task 3)
    - Keep 2-column grid layout for cards
    - No right rail on mobile (all panels are mobile-inaccessible)
    - Show selected tag with clear button above grid
    - Dynamic title: "想法" or "归档想法" based on archive filter
  - Connect mobile layout to same providers as desktop (`thoughtStatusFilterProvider`, `thoughtSearchQueryProvider`, etc.)
  - Remove mobile pinned/unpinned split (match desktop behavior)
  - Cards use compressed layout from Task 6
  - Context menu on mobile: long-press triggers same `ThoughtContextMenu`

  **Must NOT do**:
  - MUST NOT add right rail panels to mobile
  - MUST NOT create mobile-specific providers (use same ones as desktop)
  - MUST NOT change mobile navigation structure

  **Recommended Agent Profile**:
  - **Category**: `visual-engineering`
  - **Skills**: [`flutter-dev`, `frontend-ui-ux`, `flutter-build-responsive-layout`]
  - **Skills Evaluated but Omitted**: `flutter-add-widget-test` (test task is separate)

  **Parallelization**:
  - **Can Run In Parallel**: YES (with Tasks 5, 6, 7)
  - **Parallel Group**: Wave 2
  - **Blocks**: Task 9
  - **Blocked By**: Tasks 1, 2, 4

  **References**:
  - `lib/src/plugins/thoughts/ui/layouts/thoughts_mobile_layout.dart` — Current mobile layout
  - `lib/src/plugins/thoughts/ui/layouts/thoughts_desktop_layout.dart` — Desktop layout (parallel task, reference pattern)
  - `lib/src/plugins/thoughts/providers/thoughts_providers.dart` — Shared providers
  - PRD Sections 14 (Mobile Layout)

  **Acceptance Criteria**:
  - [ ] Mobile layout has search bar at top
  - [ ] Horizontal scrolling status filter chips
  - [ ] Horizontal scrolling tag filter chips (top 4 tags)
  - [ ] "More tags" opens bottom sheet
  - [ ] Uses same providers as desktop (no mobile-specific providers)
  - [ ] Pinned/unpinned split removed (single list)
  - [ ] Long-press context menu works
  - [ ] `flutter analyze` passes

  **QA Scenarios**:

  ```
  Scenario: Mobile filters work with same providers as desktop
    Tool: Bash (flutter test)
    Steps:
      1. Set statusFilterProvider to ThoughtStatusFilter.pinned
      2. Verify thoughtsListProvider returns pinned thoughts only
      3. Set tagFilterProvider to "产品"
      4. Verify thoughtsListProvider filters by both status and tag
    Expected Result: Mobile and desktop use same provider chain
    Failure Indicators: Different filter results on mobile vs desktop
    Evidence: .omo/evidence/task-8-mobile-filters.txt

  Scenario: Mobile tag overflow opens bottom sheet
    Tool: Bash (flutter test)
    Steps:
      1. Render mobile layout with 10 tags
      2. Verify only 4 tag chips visible in horizontal scroll
      3. Tap "more" button → verify bottom sheet opens with all 10 tags
      4. Tap a tag → verify tag filter set and bottom sheet closes
    Expected Result: Overflow tags accessible via bottom sheet
    Failure Indicators: More than 4 tags shown, bottom sheet doesn't open
    Evidence: .omo/evidence/task-8-mobile-tag-overflow.txt
  ```

  **Commit**: YES
  - Message: `feat(thoughts): update mobile layout with search and filters`
  - Files: `thoughts_mobile_layout.dart`
  - Pre-commit: `flutter analyze`

- [x] 9. ThoughtsPage Orchestrator Simplification

  **What to do**:
  - Refactor `thoughts_page.dart`:
    - Remove `_LayoutParams` monolith — decompose into individual parameters or smaller props
    - Replace composer state references with `ThoughtComposerController` (from Task 3)
    - Replace filter state references with Riverpod providers (from Task 2)
    - Keep the `Scaffold` with `endDrawer` for `ThoughtEditorDrawer`
    - Keep `AdaptiveLayout` switching between mobile and desktop
    - Simplify `_ThoughtsPageState` to only orchestrate layout transitions
    - Ensure `Ctrl+Enter` submit shortcut still works (handled by composer controller)
    - Verify `_openEditor`, `_quickArchive`, `_quickRestore` still work
  - Connect new filter widgets to providers:
    - Status filter changes → `thoughtStatusFilterProvider`
    - Search input → `thoughtSearchQueryProvider`
    - Tags in right rail → `tagFilterProvider` sync
  - Remove old `_ThoughtComposer`, `_ThoughtsToolbar`, `_ThoughtsContent` private widgets from page (now in separate files from Task 5)
  - Ensure the page title is dynamic: "想法" (unarchived) or "归档想法" (archived)

  **Must NOT do**:
  - MUST NOT remove ThoughtEditorDrawer functionality
  - MUST NOT break existing archive/restore/pin flows
  - MUST NOT remove Ctrl+Enter submit shortcut
  - MUST NOT remove AdaptiveLayout mobile/desktop switching

  **Recommended Agent Profile**:
  - **Category**: `deep`
  - **Skills**: [`flutter-dev`]
  - **Skills Evaluated but Omitted**: `frontend-ui-ux` (no visual changes, just refactoring)

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Wave 3 (sequential, depends on Tasks 5-8)
  - **Blocks**: Task 10
  - **Blocked By**: Tasks 5, 6, 7, 8

  **References**:
  - `lib/src/plugins/thoughts/ui/thoughts_page.dart` — Current orchestrator with `_LayoutParams` (lines 349-402)
  - `lib/src/plugins/thoughts/ui/widgets/thought_composer_controller.dart` — Extracted controller (from Task 3)
  - `lib/src/plugins/thoughts/providers/thoughts_providers.dart` — New providers (from Task 2)

  **Acceptance Criteria**:
  - [ ] `_LayoutParams` class removed from `thoughts_page.dart`
  - [ ] Composer state managed by `ThoughtComposerController`
  - [ ] Filter state managed by Riverpod providers
  - [ ] `ThoughtsPage` only orchestrates layout — no inline composer/filter logic
  - [ ] ThoughtEditorDrawer still opens on card tap
  - [ ] Ctrl+Enter submit still works
  - [ ] Archive/restore/pin flows still work
  - [ ] `flutter analyze` passes
  - [ ] Existing widget tests pass

  **QA Scenarios**:

  ```
  Scenario: Orchestrator delegates to controllers and providers
    Tool: Bash (grep)
    Steps:
      1. grep -rn "_LayoutParams" lib/src/plugins/thoughts/ui/thoughts_page.dart
      2. Verify zero results (class completely removed)
      3. Verify ThoughtComposerController is used for composer state
      4. Verify Riverpod providers handle all filter state
    Expected Result: No _LayoutParams class, state managed by controller + providers
    Failure Indicators: _LayoutParams still exists, state still in page
    Evidence: .omo/evidence/task-9-orchestrator-simplified.txt

  Scenario: Existing flows still work after refactoring
    Tool: Bash (flutter test)
    Steps:
      1. Run existing widget tests for thoughts page
      2. Test: tap thought → drawer opens
      3. Test: Ctrl+Enter → submits thought
      4. Test: archive thought → snackbar shown
    Expected Result: All existing flows work without regression
    Failure Indicators: Any existing test fails
    Evidence: .omo/evidence/task-9-existing-flows.txt
  ```

  **Commit**: YES
  - Message: `refactor(thoughts): simplify ThoughtsPage orchestrator, remove _LayoutParams`
  - Files: `thoughts_page.dart`
  - Pre-commit: `flutter analyze && flutter test`

- [x] 10. Integration Verification + Edge Cases

  **What to do**:
  - Verify all filter combinations work correctly:
    - Archive on + Status "pinned" → only pinned archived thoughts
    - Archive off + Status "withImages" + Tag "产品" + Search "灵感" → intersection
    - Clear all filters → returns all unarchived thoughts
  - Verify right rail independence:
    - Set tag filter → right rail panels unaffected
    - Set search query → right rail panels unaffected
    - Set status filter → right rail panels unaffected
  - Verify all 4 empty states render correctly:
    - No thoughts at all → "还没有想法" with action button
    - Filter returns empty → "没有找到带有 #xxx 的想法" with clear button
    - Search returns empty → "没有找到相关想法" with clear button
    - Archive empty → "暂无归档想法"
  - Verify all 6 error state messages display:
    - Save fail snackbar, image fail snackbar, delete fail snackbar
    - Archive fail snackbar, restore fail snackbar, filter fail with retry button
  - Verify card context menu at breakpoints:
    - Desktop: right-click context menu
    - Mobile: long-press context menu
  - Write widget tests for:
    - Provider chain: `allThoughtsProvider` → `thoughtStatusFilterProvider` → `tagFilterProvider` → `thoughtSearchDebouncedProvider` → `thoughtsListProvider`
    - Right rail independence from main content filters
    - Empty state rendering for each variant
    - Error state message text matching PRD
  - Run full test suite: `flutter test`
  - Run static analysis: `flutter analyze`

  **Must NOT do**:
  - MUST NOT add new features beyond what's tested
  - MUST NOT fix bugs silently — document and create follow-up tasks if found
  - MUST NOT skip any verification scenario

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
  - **Skills**: [`flutter-dev`, `flutter-add-widget-test`]
  - **Skills Evaluated but Omitted**: `frontend-ui-ux` (no visual changes)

  **Parallelization**:
  - **Can Run In Parallel**: NO (depends on all previous tasks)
  - **Parallel Group**: Wave 3 (sequential, after Task 9)
  - **Blocks**: F1-F4
  - **Blocked By**: Task 9

  **References**:
  - All files created/modified in Tasks 1-9
  - `test/` — Existing test patterns
  - `lib/src/plugins/thoughts/providers/thoughts_providers.dart` — Provider chain to test
  - PRD Sections 22-28 (providers, empty states, error states)

  **Acceptance Criteria**:
  - [ ] All filter combinations produce correct results
  - [ ] Right rail panels show global unarchived data regardless of main filters
  - [ ] All 4 empty states render with correct text and actions
  - [ ] All 6 error state messages match PRD specifications
  - [ ] Context menu works on desktop (right-click) and mobile (long-press)
  - [ ] `flutter analyze` passes with 0 errors, 0 warnings
  - [ ] `flutter test` passes for all existing + new tests

  **QA Scenarios**:

  ```
  Scenario: Filter combinations produce correct results
    Tool: Bash (flutter test)
    Steps:
      1. Create thoughts: pinned+tagged, unpinned+withImage, archived+tagged, untagged+unarchived
      2. Test: archive=true + status=pinned → only pinned archived thoughts
      3. Test: archive=false + status=withImages + tag="产品" → intersection
      4. Test: archive=false + status=all + search="keyword" → filtered by content
    Expected Result: Each filter combination returns correct intersection
    Failure Indicators: Wrong thoughts in result, missing thoughts, extra thoughts
    Evidence: .omo/evidence/task-10-filter-combinations.txt

  Scenario: Empty states render correctly
    Tool: Bash (flutter test)
    Steps:
      1. No thoughts in DB → verify "还没有想法" empty state
      2. Thoughts exist but tag filter matches none → verify "没有找到带有 #xxx 的想法"
      3. Thoughts exist but search matches none → verify "没有找到相关想法"
      4. Archive filter on but no archived thoughts → verify "暂无归档想法"
    Expected Result: Each empty state shows correct text and action
    Failure Indicators: Wrong text, missing action button, wrong state shown
    Evidence: .omo/evidence/task-10-empty-states.txt

  Scenario: Error state messages match PRD
    Tool: Bash (flutter test)
    Steps:
      1. Trigger each of 6 error conditions
      2. Verify snackbar text matches PRD exactly:
         - 保存失败: "保存失败，请稍后重试"
         - 图片失败: "图片添加失败，请检查文件权限"
         - 删除失败: "删除失败，请稍后重试"
         - 归档失败: "归档失败，请稍后重试"
         - 恢复失败: "恢复失败，请稍后重试"
         - 筛选失败: "加载失败，请重试" (with retry button)
    Expected Result: All 6 error messages match PRD specifications
    Failure Indicators: Wrong message text, missing retry button on filter error
    Evidence: .omo/evidence/task-10-error-states.txt

  Scenario: Right rail independence verified
    Tool: Bash (flutter test)
    Steps:
      1. Set tag filter, search query, and status filter on main content
      2. Verify pinnedThoughtsProvider returns top 3 from ALL unarchived
      3. Verify pendingReviewProvider returns all untagged+unarchived
      4. Verify commonTagsProvider returns top 8 tags from ALL unarchived
    Expected Result: Right rail data is global, independent of main filters
    Failure Indicators: Right rail data changes when main filters change
    Evidence: .omo/evidence/task-10-rail-independence.txt

  Scenario: Full test suite passes
    Tool: Bash
    Steps:
      1. flutter analyze
      2. flutter test
    Expected Result: 0 errors, 0 warnings, all tests pass
    Failure Indicators: Any analysis error, any test failure
    Evidence: .omo/evidence/task-10-full-test-suite.txt
  ```

  **Commit**: YES
  - Message: `test(thoughts): integration verification and edge case coverage`
  - Files: test files
  - Pre-commit: `flutter analyze && flutter test`

---

## Final Verification Wave (after ALL implementation tasks)

- [x] F1. **Plan Compliance Audit** — `oracle`
  Read the plan end-to-end. For each "Must Have": verify implementation exists (read file, run command). For each "Must NOT Have": search codebase for forbidden patterns — reject with file:line if found. Check evidence files exist in .omo/evidence/. Compare deliverables against plan.
  Output: `Must Have [N/N] | Must NOT Have [N/N] | Tasks [N/N] | VERDICT: APPROVE/REJECT`

- [x] F2. **Code Quality Review** — `unspecified-high`
  Run `flutter analyze` + `flutter test`. Review all changed files for: `as any`/`@ts-ignore` equivalents, empty catches, print statements in prod, commented-out code, unused imports. Check AI slop: excessive comments, over-abstraction, generic names. Check all new widgets follow existing patterns (ThoughtPanel, ThoughtFilterChip, etc.).
  Output: `Analyze [PASS/FAIL] | Tests [N pass/N fail] | Files [N clean/N issues] | VERDICT`

- [x] F3. **Real Manual QA** — `unspecified-high`
  Start from clean state. Execute EVERY QA scenario from EVERY task. Test cross-page integration: verify HomePage, Thoughts, Settings render at 899px, 900px, 1279px, 1280px. Test filter combinations. Test right rail independence. Capture screenshots.
  Output: `Scenarios [N/N pass] | Integration [N/N] | Edge Cases [N tested] | VERDICT`

- [x] F4. **Scope Fidelity Check** — `deep`
  For each task: read "What to do", read actual diff. Verify 1:1 — everything in spec was built (no missing), nothing beyond spec was built (no creep). Check "Must NOT do" compliance. Verify no database schema changes. Verify no new columns. Verify convert-to-todo/note buttons are disabled. Detect cross-task contamination.
  Output: `Tasks [N/N compliant] | Contamination [CLEAN/N issues] | Unaccounted [CLEAN/N files] | VERDICT`

---

## Commit Strategy

- **Task 1**: `refactor(breakpoints): update global breakpoints to mobile=899/900/1280` - app_breakpoints.dart, all usage files, flutter test
- **Task 2**: `feat(thoughts): add search, status filter, and right rail providers` - thoughts_providers.dart, thought_status_filter.dart, flutter test
- **Task 3**: `refactor(thoughts): extract ThoughtComposerController from page state` - thought_composer_controller.dart, thoughts_page.dart, flutter test
- **Task 4**: `feat(thoughts): add shared empty/error state templates` - thought_state_template.dart, flutter test
- **Task 5**: `feat(thoughts): redesign desktop layout with inbox pattern` - thoughts_desktop_layout.dart, thought_composer.dart, flutter analyze
- **Task 6**: `feat(thoughts): compress thought cards and add context menu` - thought_card.dart, thought_context_menu.dart, flutter analyze
- **Task 7**: `feat(thoughts): add right rail panels` - thought_pinned_panel.dart, thought_pending_review_panel.dart, thought_common_tags_panel.dart, thought_random_review_panel.dart, thought_quick_actions_panel.dart, flutter analyze
- **Task 8**: `feat(thoughts): update mobile layout with search and filters` - thoughts_mobile_layout.dart, flutter analyze
- **Task 9**: `refactor(thoughts): simplify ThoughtsPage orchestrator` - thoughts_page.dart, flutter analyze
- **Task 10**: `test(thoughts): integration verification and edge cases` - test files, flutter test, flutter analyze

---

## Success Criteria

### Verification Commands
```bash
flutter analyze  # Expected: 0 errors, 0 warnings
flutter test     # Expected: all tests pass
```

### Final Checklist
- [x] All "Must Have" present and functional
- [x] All "Must NOT Have" absent (no DB migration, no new columns, no real convert, no multi-tag)
- [x] All tests pass
- [x] Desktop layout correct at 1280px+, 900-1279px
- [x] Mobile layout correct at <900px
- [x] Search with debounce working
- [x] Status filter chips working
- [x] Tag filter with popover working
- [x] Right rail panels showing global data
- [x] Pinned section removed from main content
- [x] Card max 180px height enforced
- [x] Context menu with 7 items (2 disabled)
- [x] Empty states for all 4 scenarios
- [x] Error handling for all 6 failure types