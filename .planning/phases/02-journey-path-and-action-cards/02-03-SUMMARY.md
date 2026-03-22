---
phase: 02-journey-path-and-action-cards
plan: 03
subsystem: ui

tags: [swiftui, journey-path, animation, canvas, zigzag, action-plan]

# Dependency graph
requires:
  - phase: 02-journey-path-and-action-cards
    provides: JourneyPathView, JourneyNodeView, ActionDetailSheet — Phase 2 visual components
  - phase: 01-foundation
    provides: AnimationPolicy, HapticEngine, ActionIconMapper utilities

provides:
  - End-to-end journey path wired into ActionPlanDetailView replacing flat MicroActionRow list
  - justCompletedActionId on ActionPlanViewModel for unlock animation sequencing
  - Scale bounce (1.0->1.2->1.0) on node completion via AnimationPolicy
  - Unlock pulse animation on successor node when predecessor completes
  - ConnectingLineView with diagonal Canvas lines (dashed grey / solid green)
  - Bottom sheet (ActionDetailSheet) on node tap with medium/large detents

affects: [03-celebrations-and-haptics, future-animation-phases]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Canvas for diagonal connecting lines between zigzag nodes
    - zigzagOffset parameter passed from parent to child for geometry-aware line drawing
    - justCompletedActionId ViewModel property drives successor unlock animation
    - DispatchQueue.main.asyncAfter for two-phase bounce animation (up then back)

key-files:
  created: []
  modified:
    - Abimo/Views/ActionPlan/ActionPlanDetailView.swift
    - Abimo/ViewModels/ActionPlanViewModel.swift
    - Abimo/Views/ActionPlan/Journey/JourneyNodeView.swift
    - Abimo/Views/ActionPlan/Journey/JourneyPathView.swift

key-decisions:
  - "ConnectingLineView uses Canvas with horizontalDelta = -zigzagOffset * 2 to draw diagonal from current node center to next node center"
  - "zigzagOffset passed as parameter (not computed) so ConnectingLineView has exact geometry without re-computing parent layout"
  - "justCompletedActionId set immediately on optimistic local update and cleared after 0.6s via DispatchQueue"

patterns-established:
  - "ConnectingLineView pattern: pass zigzagOffset from layout parent, compute delta for Canvas diagonal"
  - "Two-phase bounce: AnimationPolicy.animate up immediately, asyncAfter 0.15s to animate back"

requirements-completed: [PATH-06, CARD-05]

# Metrics
duration: ~20min
completed: 2026-03-18
---

# Phase 2 Plan 03: Wire Journey Path and Add Animations Summary

**End-to-end journey path with zigzag nodes, diagonal connecting lines, scale bounce + unlock animations, and ActionDetailSheet wired into ActionPlanDetailView replacing the flat list**

## Performance

- **Duration:** ~20 min
- **Started:** 2026-03-18T21:50:00Z
- **Completed:** 2026-03-18T22:15:00Z
- **Tasks:** 3 (2 auto + 1 checkpoint:human-verify)
- **Files modified:** 4

## Accomplishments

- ActionPlanDetailView body replaced: JourneyPathView renders zigzag node path instead of flat MicroActionRow ForEach
- ActionPlanViewModel.justCompletedActionId published property enables successor unlock sequencing
- Scale bounce animation (1.0->1.2->1.0) fires on completion via AnimationPolicy; unlock pulse fires on successor node
- ConnectingLineView added using Canvas to draw diagonal lines between alternating zigzag nodes (dashed grey for incomplete, solid green for completed)

## Task Commits

Each task was committed atomically:

1. **Task 1: Add justCompletedActionId to ViewModel and wire ActionPlanDetailView** - `311bae4` (feat)
2. **Task 2: Add scale bounce and unlock animations to JourneyNodeView** - `06432d8` (feat)
3. **Fix: Render diagonal connecting lines between zigzag nodes** - `7eca5b2` (fix)

## Files Created/Modified

- `Abimo/Views/ActionPlan/ActionPlanDetailView.swift` - Replaced body with JourneyPathView + ActionDetailSheet sheet presentation
- `Abimo/ViewModels/ActionPlanViewModel.swift` - Added @Published var justCompletedActionId, set on confirmCompletion
- `Abimo/Views/ActionPlan/Journey/JourneyNodeView.swift` - Added isAnimatingCompletion/unlockAnimating state, onChange handlers, ConnectingLineView with zigzagOffset
- `Abimo/Views/ActionPlan/Journey/JourneyPathView.swift` - Pass justCompletedActionId, index, actions, zigzagOffset to JourneyNodeView

## Decisions Made

- ConnectingLineView uses `horizontalDelta = -zigzagOffset * 2` so a node offset at +60 draws a line going left 120pt to the next node at -60 — the geometry is exact without re-computing the zigzag pattern independently.
- zigzagOffset is passed as a parameter from JourneyPathView rather than derived inside ConnectingLineView, maintaining single source of truth for layout offsets.
- justCompletedActionId cleared after 0.6s (not tied to animation duration) to give a safe buffer for downstream .onChange handlers in all child nodes.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Connecting lines were not rendering after Tasks 1 and 2**
- **Found during:** Task 3 checkpoint (human-verify)
- **Issue:** The original JourneyNodeView had no connecting line implementation; lines were described in the plan's verification steps but not added in Tasks 1 or 2
- **Fix:** Added ConnectingLineView struct using Canvas to draw diagonal lines based on zigzagOffset; added zigzagOffset parameter to JourneyNodeView; updated JourneyPathView to pass the offset
- **Files modified:** Abimo/Views/ActionPlan/Journey/JourneyNodeView.swift, Abimo/Views/ActionPlan/Journey/JourneyPathView.swift
- **Verification:** BUILD SUCCEEDED with iPhone 17 simulator destination
- **Committed in:** 7eca5b2

---

**Total deviations:** 1 auto-fixed (Rule 1 — bug fix for missing rendering)
**Impact on plan:** Fix was necessary for the visual spec (dashed/solid connecting lines between nodes). No scope creep.

## Issues Encountered

- Xcode project directory contained two .xcodeproj files, requiring explicit `-project Abimo.xcodeproj` flag for xcodebuild
- iPhone 16 simulator not available; iPhone 17 used instead (OS 26.2)

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Full journey path experience is wired and building: zigzag nodes, connecting lines, state-driven colors, animations, bottom sheet
- Phase 3 (celebrations and haptics) can now wire HapticEngine and Lottie celebrations into the completion flow
- Lottie .json/.lottie animation assets still need to be sourced from LottieFiles before Phase 3 begins (noted blocker from prior phase)

---
*Phase: 02-journey-path-and-action-cards*
*Completed: 2026-03-18*
