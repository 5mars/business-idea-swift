---
phase: 11-tooltip-overhaul-and-action-switching
plan: 01
subsystem: ui
tags: [swiftui, journeypath, tooltip, bubble, nodebubble, sfSymbols, GeometryReader]

# Dependency graph
requires:
  - phase: 07-action-picker-sheet
    provides: ActionPickerSheet opened by onSwitch (showActionPicker = true)
provides:
  - NodeBubbleView redesigned with arrowOffset parameter, onSwitch closure, and three-state icon button rows
  - bubbleOverlay in JourneyPathView computes dynamic arrowOffset via GeometryReader containerWidth
  - Locked node tooltip shows Switch (Next) + See More buttons — opens ActionPickerSheet
  - Active node tooltip shows Complete + See More buttons
  - Completed node tooltip shows Done badge + See More button
  - Full action title always visible — no lineLimit or minimumScaleFactor
  - Arrow tip aligned to tapped node center regardless of zigzag position
  - Tap-to-dismiss on overlay background
affects:
  - action-picker-sheet
  - journey-path

# Tech tracking
tech-stack:
  added: []
  patterns:
    - arrowOffset injected from parent (bubbleOverlay) rather than hardcoded in shape
    - GeometryReader containerWidth for overlay layout instead of UIScreen.main.bounds.width
    - nodeCenterX = containerWidth/2 + zigzagOffset, arrowOffset = nodeCenterX - xPos after clamping
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
  - "GeometryReader containerWidth replaces UIScreen.main.bounds.width for correct arrow alignment at all zigzag positions"
  - "onSwitch opens ActionPickerSheet (viewModel.showActionPicker = true) — user wants to choose from list, not silent swap"
  - "Tap-to-dismiss added via onTapGesture on overlay background — missing critical UX"

patterns-established:
  - "arrowOffset = nodeCenterX - xPos: compute after clamping using GeometryReader containerWidth"
  - "GeometryReader in bubbleOverlay for container-relative layout calculations"
  - "onSwitch: sets showActionPicker = true — opens picker sheet rather than direct pickAction call"

requirements-completed: [TIPS-01, TIPS-02, TIPS-03, TIPS-04, SWAP-01]

# Metrics
duration: ~60min
completed: 2026-03-21
---

# Phase 11 Plan 01: Tooltip Overhaul and Action Switching Summary

**NodeBubbleView redesigned with 290pt width, full-title wrapping, Duolingo-style icon buttons per state, and GeometryReader-based arrowOffset that fixes arrow alignment — plus tap-to-dismiss and Switch-opens-picker post-verification fixes**

## Performance

- **Duration:** ~60 min (including human-verify checkpoint and post-fix iteration)
- **Started:** 2026-03-21T19:39:38Z
- **Completed:** 2026-03-21T20:30:00Z
- **Tasks:** 3 (2 auto + 1 human-verify checkpoint)
- **Files modified:** 2

## Accomplishments

- NodeBubbleView rewritten: removed lineLimit/minimumScaleFactor, widened to 290pt, added arrowOffset + onSwitch params (TIPS-01, TIPS-03, SWAP-01)
- Three state-specific button layouts: active (Complete + See More), locked (Switch/Next + See More), completed (Done badge + See More) (D-10, D-11, D-12)
- bubbleOverlay now uses GeometryReader containerWidth to compute `arrowOffset = nodeCenterX - xPos` dynamically — arrow always points to the tapped node center (TIPS-04)
- Switch button opens ActionPickerSheet (viewModel.showActionPicker = true) so user can choose the replacement action from a full list (SWAP-01)
- Tap-to-dismiss added on overlay background via onTapGesture
- Build succeeds, OrderingTests pass, visual verification approved by user

## Task Commits

Each task was committed atomically:

1. **Task 1: Rewrite NodeBubbleView with new layout, icon buttons, and arrowOffset parameter** - `809efcb` (feat)
2. **Task 2: Fix bubbleOverlay arrow alignment and wire onSwitch in JourneyPathView** - `b65a9d9` (feat)
3. **Post-checkpoint fixes: GeometryReader arrow alignment, tap-to-dismiss, switch opens picker** - `82977cf` (fix)

**Plan metadata:** _(this commit)_ (docs: complete plan)

## Files Created/Modified

- `Abimo/Views/ActionPlan/Journey/NodeBubbleView.swift` - Rewritten: 290pt width, no lineLimit, arrowOffset param, onSwitch closure, three-state icon button rows with PlayfulButtonStyle
- `Abimo/Views/ActionPlan/Journey/JourneyPathView.swift` - Updated: GeometryReader containerWidth, dynamic arrowOffset, onSwitch opens ActionPickerSheet, tap-to-dismiss on background, bubbleWidth 290 and bubbleEstimatedHeight 130

## Decisions Made

- Width 290pt selected (discretion range 260-340pt): fits long titles without appearing oversized
- `arrow.triangle.2.circlepath` selected for Switch button (iOS 14+ compatible, safer than `arrow.triangle.swap` which requires iOS 15+)
- `bubbleEstimatedHeight` increased to 130pt from 100pt (Pitfall 3 from research — accommodates taller layout with full title wrapping)
- Divider added between title and button row for Duolingo-style breathing room (D-03)
- **Post-verification:** GeometryReader containerWidth replaces UIScreen.main.bounds.width — gives accurate container-relative width, fixing residual arrow drift
- **Post-verification:** onSwitch opens ActionPickerSheet instead of calling pickAction directly — user confirmed they want to choose from a list
- **Post-verification:** Tap-to-dismiss added on overlay background — universally expected UX

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed arrowOffset drift via GeometryReader**
- **Found during:** Task 3 (visual verification — arrow still drifted at some zigzag positions)
- **Issue:** `UIScreen.main.bounds.width - 120` didn't match actual GeometryReader container width in overlay layout, causing residual arrow offset errors
- **Fix:** Wrapped bubbleOverlay layout in GeometryReader; replaced screen-width-based calculation with `containerWidth` from the geometry proxy
- **Files modified:** `Abimo/Views/ActionPlan/Journey/JourneyPathView.swift`
- **Verification:** Arrow visually aligned to node center at all zigzag positions (user approved)
- **Committed in:** `82977cf`

**2. [Rule 2 - Missing Critical] Added tap-to-dismiss on bubble overlay background**
- **Found during:** Task 3 (visual verification)
- **Issue:** Tapping anywhere outside the tooltip bubble did not dismiss it — essential UX for any overlay/modal
- **Fix:** Added `onTapGesture { activeBubbleId = nil }` on the full-screen overlay background
- **Files modified:** `Abimo/Views/ActionPlan/Journey/JourneyPathView.swift`
- **Verification:** Tapping background outside tooltip dismisses immediately
- **Committed in:** `82977cf`

**3. [Rule 4 - User-clarified] Switch opens ActionPickerSheet instead of calling pickAction directly**
- **Found during:** Task 3 (human-verify checkpoint — user clarified intent)
- **Issue:** Plan specified `viewModel.pickAction(id:)` direct call, silently swapping the action. User confirmed they want to choose the replacement from a full list.
- **Fix:** Changed onSwitch closure to `viewModel.showActionPicker = true; activeBubbleId = nil`
- **Files modified:** `Abimo/Views/ActionPlan/Journey/JourneyPathView.swift`
- **Decision:** User-approved behavioral change during visual checkpoint
- **Committed in:** `82977cf`

---

**Total deviations:** 3 (1 bug fix, 1 missing critical UX, 1 user-clarified behavior)
**Impact on plan:** All three fixes necessary for correct, usable behavior. No scope creep.

## Issues Encountered

- Initial build failed after Task 1 alone (expected — JourneyPathView still used the old NodeBubbleView signature). Normal two-task dependency; both tasks completed before confirming build.
- Pre-existing OrderingTests failures (`testMergeUserOrder*` etc.) confirmed unrelated to this plan's changes.
- Arrow alignment required a second iteration (post-checkpoint) because UIScreen.main.bounds-based layout didn't match GeometryReader container width.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- All 5 requirements verified: TIPS-01 (full title), TIPS-02 (See More opens detail), TIPS-03 (state-appropriate buttons), TIPS-04 (arrow alignment), SWAP-01 (switch opens picker)
- Phase 11 is the only plan in this phase — phase complete
- ActionPickerSheet integration (phase 07) confirmed working via showActionPicker trigger

---
*Phase: 11-tooltip-overhaul-and-action-switching*
*Completed: 2026-03-21*
