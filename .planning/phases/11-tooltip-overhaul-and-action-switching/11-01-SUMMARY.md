---
phase: 11-tooltip-overhaul-and-action-switching
plan: 01
subsystem: ui
tags: [swiftui, journeypath, tooltip, bubble, nodebubble, sfSymbols]

# Dependency graph
requires: []
provides:
  - NodeBubbleView redesigned with arrowOffset parameter, onSwitch closure, and three-state icon button rows
  - bubbleOverlay in JourneyPathView computes dynamic arrowOffset from node zigzag position
  - Locked node tooltip shows Switch (Next) + See More buttons — calls pickAction(id:)
  - Active node tooltip shows Complete + See More buttons
  - Completed node tooltip shows Done badge + See More button
  - Full action title always visible — no lineLimit or minimumScaleFactor
  - Arrow tip aligned to tapped node center regardless of zigzag position
affects:
  - 11-tooltip-overhaul-and-action-switching

# Tech tracking
tech-stack:
  added: []
  patterns:
    - arrowOffset injected from parent (bubbleOverlay) rather than hardcoded in shape
    - nodeCenterX = screenWidth/2 + zigzagOffset, arrowOffset = nodeCenterX - xPos after clamping
    - Three-state stateContent in NodeBubbleView using @ViewBuilder switch

key-files:
  created: []
  modified:
    - Abimo/Views/ActionPlan/Journey/NodeBubbleView.swift
    - Abimo/Views/ActionPlan/Journey/JourneyPathView.swift

key-decisions:
  - "Width 290pt — wide enough for long titles without feeling oversized (D-02)"
  - "arrow.triangle.2.circlepath for Switch button — available iOS 14+ (safer than arrow.triangle.swap)"
  - "bubbleEstimatedHeight 130pt — accommodates full-title wrapping + button row (Pitfall 3)"
  - "Divider added between title and buttons for Duolingo-style visual separation (D-03)"

patterns-established:
  - "arrowOffset = nodeCenterX - xPos: compute after clamping, BubbleShape.path(in:) handles internal clamping"
  - "onSwitch: calls pickAction(id:) + clears activeBubbleId — no HapticEngine call needed (pickAction does it)"

requirements-completed: [TIPS-01, TIPS-02, TIPS-03, TIPS-04, SWAP-01]

# Metrics
duration: 8min
completed: 2026-03-21
---

# Phase 11 Plan 01: Tooltip Overhaul and Action Switching Summary

**NodeBubbleView redesigned with 290pt width, full-title wrapping, Duolingo-style icon buttons per state, and dynamically-computed arrowOffset that fixes the bubble arrow alignment bug**

## Performance

- **Duration:** 8 min
- **Started:** 2026-03-21T19:39:38Z
- **Completed:** 2026-03-21T19:47:00Z
- **Tasks:** 2 of 3 (Task 3 is a human-verify checkpoint — awaiting visual confirmation)
- **Files modified:** 2

## Accomplishments

- NodeBubbleView rewritten: removed lineLimit/minimumScaleFactor, widened to 290pt, added arrowOffset + onSwitch params (TIPS-01, TIPS-03, SWAP-01)
- Three state-specific button layouts: active (Complete + See More), locked (Switch/Next + See More), completed (Done badge + See More) (D-10, D-11, D-12)
- bubbleOverlay now computes `arrowOffset = nodeCenterX - xPos` dynamically instead of hardcoded 110 — arrow always points to the tapped node center (TIPS-04)
- onSwitch wired to `viewModel.pickAction(id:)` + `activeBubbleId = nil` — switch action without completing current (SWAP-01)
- Build succeeds, pickAction-related OrderingTests all pass, pre-existing test failures confirmed unrelated

## Task Commits

Each task was committed atomically:

1. **Task 1: Rewrite NodeBubbleView with new layout, icon buttons, and arrowOffset parameter** - `809efcb` (feat)
2. **Task 2: Fix bubbleOverlay arrow alignment and wire onSwitch in JourneyPathView** - `b65a9d9` (feat)
3. **Task 3: Visual verification checkpoint** - awaiting human approval

## Files Created/Modified

- `Abimo/Views/ActionPlan/Journey/NodeBubbleView.swift` - Rewritten: 290pt width, no lineLimit, arrowOffset param, onSwitch closure, three-state icon button rows with PlayfulButtonStyle
- `Abimo/Views/ActionPlan/Journey/JourneyPathView.swift` - Updated: bubbleWidth 290, bubbleEstimatedHeight 130, dynamic arrowOffset computation, onSwitch wired to pickAction

## Decisions Made

- Width 290pt selected (discretion range 260-340pt): fits long titles without appearing oversized
- `arrow.triangle.2.circlepath` selected for Switch button (iOS 14+ compatible, safer than `arrow.triangle.swap` which requires iOS 15+)
- `bubbleEstimatedHeight` increased to 130pt from 100pt (Pitfall 3 from research — accommodates taller layout with full title wrapping)
- Divider added between title and button row for Duolingo-style breathing room (D-03)

## Deviations from Plan

None - plan executed exactly as written. All implementations match the plan specifications including the exact button layouts, padding values, SF Symbol names, and arrowOffset formula.

## Issues Encountered

- Initial build failed after Task 1 alone (expected — JourneyPathView still used the old NodeBubbleView signature). This is normal two-task dependency; both tasks completed before confirming successful build.
- Pre-existing OrderingTests failures (`testMergeUserOrder*`, `testOrderedActionsReturnsMicroActionsWhenNoUserOrder`, `testUserDefaultsRoundTrip`) confirmed by stash/restore check — not caused by this plan's changes.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- All code changes ready for visual verification (Task 3 checkpoint)
- After visual approval: SUMMARY complete, requirements TIPS-01 through TIPS-04 and SWAP-01 fulfilled
- Next plan in this phase: none (this is the only plan in phase 11)

---
*Phase: 11-tooltip-overhaul-and-action-switching*
*Completed: 2026-03-21*
