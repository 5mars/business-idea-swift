---
phase: 05-viewmodel-foundation-and-ordering-model
plan: 02
subsystem: ui
tags: [swift, swiftui, viewmodel, ordering, sheet, journeypath]

# Dependency graph
requires:
  - phase: 05-viewmodel-foundation-and-ordering-model (plan 01)
    provides: orderedActions computed property, PostCompletionSheet enum, showActionPicker bool, advanceToActionPicker()
provides:
  - JourneyPathView reads exclusively from viewModel.orderedActions (not microActions) — node display order matches user picks
  - nodeState computed from orderedActions — only one node is .active at a time
  - Auto-scroll targets first incomplete action in orderedActions
  - ActionPlanDetailView .sheet(item: $viewModel.postCompletionSheet) for enum-driven congrats/picker presentation
  - ActionPlanDetailView .sheet(isPresented: $viewModel.showActionPicker) for first-visit picker trigger
  - nodeStateForAction uses orderedActions for consistent lock/active/completed logic
affects:
  - 07-action-picker-sheet — ActionPickerSheet placeholder wired via showActionPicker
  - 08-congrats-half-sheet — CongratsHalfSheet placeholder wired via postCompletionSheet = .congrats(actionId:)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - orderedActions used as single source of truth for node rendering in JourneyPathView
    - Single .sheet(item:) replaces multiple boolean .sheet(isPresented:) modifiers to eliminate SwiftUI sheet queue races
    - nodeStateForAction uses orderedActions.firstIndex — consistent with JourneyPathView nodeState calls

key-files:
  created: []
  modified:
    - Abimo/Views/ActionPlan/Journey/JourneyPathView.swift
    - Abimo/Views/ActionPlan/ActionPlanDetailView.swift

key-decisions:
  - "JourneyPathView uses orderedActions in ForEach, nodeState, isLastNode, auto-scroll — microActions removed from view layer entirely"
  - "Placeholder VStack views for ActionPickerSheet and CongratsHalfSheet — Phase 7 and Phase 8 replace them"
  - "showActionPicker .sheet(isPresented:) kept separate from postCompletionSheet .sheet(item:) — first-visit trigger vs post-completion flow are different entry points"

patterns-established:
  - "Pattern: View layer reads orderedActions, not microActions — ordering is ViewModel concern only"
  - "Pattern: PostCompletionSheet enum case exhaustion in switch — new sheet cases require compile-time handling"

requirements-completed: [ORDR-01, CELB-03]

# Metrics
duration: 5min
completed: 2026-03-19
---

# Phase 05 Plan 02: View Wiring — orderedActions and PostCompletionSheet Summary

**JourneyPathView switched to orderedActions for display order correctness and ActionPlanDetailView consolidated to enum-driven .sheet(item:) for PostCompletionSheet, eliminating boolean sheet races**

## Performance

- **Duration:** 5 min (changes were already applied as part of Plan 01's auto-fix deviation)
- **Started:** 2026-03-19T17:10:22Z
- **Completed:** 2026-03-19T17:15:00Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- JourneyPathView: replaced all 5 `viewModel.microActions` references with `viewModel.orderedActions` — ForEach, nodeState, isLastNode, actions param, and auto-scroll
- ActionPlanDetailView: removed `showCommitmentSheet` local state, retired `showCommitmentPicker` and `showMomentumPicker` boolean sheet modifiers, wired `.sheet(item: $viewModel.postCompletionSheet)` with congrats/actionPicker switch, added `.sheet(isPresented: $viewModel.showActionPicker)` placeholder
- nodeStateForAction updated to use `viewModel.orderedActions` for consistent active/locked/completed state across the view hierarchy

## Task Commits

Each task was committed atomically:

1. **Task 1: Switch JourneyPathView from microActions to orderedActions** - `47962e7` (feat)
2. **Task 2: Replace boolean sheet modifiers with enum-driven sheets in ActionPlanDetailView** - `ed738c7` (feat)

## Files Created/Modified

- `Abimo/Views/ActionPlan/Journey/JourneyPathView.swift` — All 5 microActions references replaced with orderedActions; node display order, nodeState, isLastNode, auto-scroll all use user-ordered array
- `Abimo/Views/ActionPlan/ActionPlanDetailView.swift` — Removed showCommitmentSheet @State; nodeStateForAction uses orderedActions; .sheet(item: postCompletionSheet) and .sheet(isPresented: showActionPicker) wired with Phase 7/8 placeholders; CommitmentSheet and MomentumPickerSheet modifiers removed

## Decisions Made

- Placeholder VStack views used for ActionPickerSheet and CongratsHalfSheet cases — Phase 7 and Phase 8 will replace them with real views; no behaviour regression since they were never reachable in prior code
- `showActionPicker` kept as a separate `.sheet(isPresented:)` rather than folded into PostCompletionSheet enum — first-visit trigger (fired after generateActionPlan) is a different entry point from the post-completion flow

## Deviations from Plan

None — both task changes were already applied as part of Plan 01's Rule 3 auto-fix (blocking compile errors when boolean sheet properties were removed from the ViewModel). Plan 02 verified, confirmed, and formally committed those changes under the correct 05-02 scope.

## Issues Encountered

None — all acceptance criteria already satisfied when this plan began execution (confirmed by grep verification).

## Next Phase Readiness

- Phase 05 structural refactor is complete: ViewModel ordering model (Plan 01) + view wiring (Plan 02)
- Phase 6 can build NodeBubbleView as self-contained component — JourneyPathView reads orderedActions correctly
- Phase 7 ActionPickerSheet can replace the `showActionPicker` placeholder and use `pickAction(id:)` callback
- Phase 8 CongratsHalfSheet can replace the `.congrats(actionId:)` placeholder and call `advanceToActionPicker()`

## Self-Check: PASSED

- [x] JourneyPathView: zero `viewModel.microActions` references (grep count = 0)
- [x] JourneyPathView: five `viewModel.orderedActions` references (grep count = 5) at lines 36, 40, 41, 45, 59
- [x] ActionPlanDetailView: zero `showCommitmentSheet`, `showCommitmentPicker`, `showMomentumPicker`, `CommitmentSheet`, `MomentumPickerSheet` references
- [x] ActionPlanDetailView: `.sheet(item: $viewModel.postCompletionSheet)` present at line 71
- [x] ActionPlanDetailView: `.sheet(isPresented: $viewModel.showActionPicker)` present at line 59
- [x] ActionPlanDetailView: `viewModel.orderedActions.firstIndex` in nodeStateForAction at line 107
- [x] ActionPlanDetailView: `viewModel.advanceToActionPicker()` in congrats placeholder at line 81
- [x] Task commits verified in git log: 47962e7 and ed738c7

---
*Phase: 05-viewmodel-foundation-and-ordering-model*
*Completed: 2026-03-19*
