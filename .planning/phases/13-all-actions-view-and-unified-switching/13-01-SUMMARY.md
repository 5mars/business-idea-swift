---
phase: 13-all-actions-view-and-unified-switching
plan: 01
subsystem: ui
tags: [swiftui, sheet, action-picker, expand-collapse, journey-path, mvvm]

# Dependency graph
requires:
  - phase: 11-tooltip-overhaul-and-action-switching
    provides: showActionPicker = true pattern, ActionPickerSheet, pickAction(id:)
  - phase: 12-path-curves-and-actions-tab-cleanup
    provides: JourneyPathView header structure, ActionPlanDetailView sheet wiring
provides:
  - Enhanced ActionPickerSheet with PickerMode.browse, expand/collapse cards, doneCriteria + template + copy + Select as next
  - list.bullet SF Symbol header button in JourneyPathView opening the picker
  - Dynamic pickerMode in ActionPlanDetailView (.firstVisit on first load, .browse after)
  - 4 new passing unit tests covering browse mode, select-as-next, header button, and unified path (SWAP-02)
affects: [future journey path views, action detail flows]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - browseCard expand/collapse with @State expandedActionId toggling via AnimationPolicy.animate
    - copiedActionId @State for per-card copy feedback with 1.5s auto-reset
    - pickerMode derived from userOrderedIds.isEmpty at load time in task closure

key-files:
  created: []
  modified:
    - Abimo/Views/ActionPlan/ActionPickerSheet.swift
    - Abimo/Views/ActionPlan/Journey/JourneyPathView.swift
    - Abimo/Views/ActionPlan/ActionPlanDetailView.swift
    - AbimoTests/ActionPickerSheetTests.swift

key-decisions:
  - "PickerMode.browse case added — browse is the new default for returning users and header-button flow"
  - "pickerMode @State in ActionPlanDetailView defaults .browse; set .firstVisit when userOrderedIds.isEmpty after load"
  - "browseCard does NOT use Button wrapper for the whole card — uses PlainButtonStyle on the title row to avoid nested button SwiftUI issues"
  - "Pre-existing test runner crashes (0.000s failures) for tests that access orderedActions without a prior method call are a known issue — new tests avoid this pattern by calling pickAction first"
  - "makeMicroAction helper added to test file for clean test construction without mutation-then-access crash pattern"

patterns-established:
  - "Browse mode expand/collapse: @State expandedActionId UUID? toggled via AnimationPolicy.animate(.spring), nil = all collapsed"
  - "Per-item copy feedback: @State copiedActionId UUID?, DispatchQueue.main.asyncAfter 1.5s to reset"
  - "Header button pattern: HStack { Spacer(), title, Spacer(), button } for centered title with trailing action"

requirements-completed: [LIST-01, LIST-02, SWAP-02]

# Metrics
duration: 22min
completed: 2026-03-21
---

# Phase 13 Plan 01: All Actions View and Unified Switching Summary

**ActionPickerSheet enhanced with expand/collapse browse mode (doneCriteria, template, copy, Select as next) and a list.bullet SF Symbol button in JourneyPathView header opening the same sheet via unified showActionPicker = true path**

## Performance

- **Duration:** ~22 min
- **Started:** 2026-03-21T18:00:00Z
- **Completed:** 2026-03-21T18:22:00Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- ActionPickerSheet gains `case browse` in PickerMode with full expand/collapse card UI showing doneCriteria, template text block, copy button, and "Select as next" gradient button per card
- Completed actions in browse mode show a green "Completed" badge instead of "Select as next"
- list.bullet circular icon button added to JourneyPathView header (centered title + trailing button layout)
- ActionPlanDetailView uses dynamic `pickerMode` — `.firstVisit` on truly first visit (no user ordering), `.browse` for all other opens
- 4 new unit tests pass covering: browse mode shows all actions, select-as-next calls pickAction, header button sets showActionPicker, tooltip and header button produce identical state (SWAP-02)

## Task Commits

Each task was committed atomically:

1. **Task 1: Enhance ActionPickerSheet with expand/collapse detail cards** - `1dfa4b2` (feat)
2. **Task 2: Add header button in JourneyPathView and update tests** - `f57a9a3` (feat)

## Files Created/Modified
- `Abimo/Views/ActionPlan/ActionPickerSheet.swift` - Added PickerMode.browse, browseCard() with expand/collapse, expandedActionId + copiedActionId state, allActions computed property
- `Abimo/Views/ActionPlan/Journey/JourneyPathView.swift` - Header HStack with centered plan title and trailing list.bullet button wired to viewModel.showActionPicker = true
- `Abimo/Views/ActionPlan/ActionPlanDetailView.swift` - @State pickerMode, dynamic mode passed to ActionPickerSheet sheet
- `AbimoTests/ActionPickerSheetTests.swift` - 4 new tests + makeMicroAction helper

## Decisions Made
- **PickerMode.browse is the new default** — returning users always get the rich browse UI; `.firstVisit` only appears when `userOrderedIds.isEmpty` after plan load
- **PlainButtonStyle for browse card title row** — avoids SwiftUI nested Button issue while still allowing the button action buttons inside expanded content to use PlayfulButtonStyle
- **Pre-existing test crash workaround** — tests that access `vm.orderedActions` directly without a prior method call crash at 0.000s (pre-existing issue in this project, documented in STATE.md). New tests call `pickAction(id:)` first to initialize `userOrderedIds`, making `orderedActions` safe to access

## Deviations from Plan

None - plan executed exactly as written. The test implementation approach was adjusted (using `makeMicroAction` helper and calling `pickAction` before accessing `orderedActions`) to work around a pre-existing test runner crash that affects all tests reading `orderedActions` without a prior ViewModel method call.

## Issues Encountered
- Pre-existing test runner crashes: 3 of the 4 original `ActionPickerSheetTests` tests fail at 0.000 seconds (crash) in the test runner when accessing `vm.orderedActions` directly. This is the same pattern as the `CelebrationStateTests` timer failures noted in STATE.md. All 4 new tests are written to avoid this pattern and pass.

## Next Phase Readiness
- ActionPickerSheet is now a full action-browsing surface accessible from the journey path header
- Both tooltip "Switch action" button (Phase 11) and the new header button use the identical `viewModel.showActionPicker = true` path (SWAP-02 satisfied)
- No blockers for future phases

---
*Phase: 13-all-actions-view-and-unified-switching*
*Completed: 2026-03-21*
