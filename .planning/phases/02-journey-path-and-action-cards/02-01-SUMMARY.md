---
phase: 02-journey-path-and-action-cards
plan: 01
subsystem: ui
tags: [swiftui, journey-path, scrollview, animation, zigzag, progress-ring]

# Dependency graph
requires:
  - phase: 01-foundation
    provides: AnimationPolicy, ActionIconMapper, HapticEngine utilities

provides:
  - JourneyNodeView: 56pt circle node with locked/active/completed state rendering
  - ProgressRingView: 80pt circular progress indicator with trim animation
  - JourneyPathView: Scrollable zigzag canvas with auto-scroll to active node
  - NodeState enum and nodeState(at:actions:) helper function

affects:
  - 02-02 (ActionCardView will be presented when a JourneyNodeView is tapped)
  - 02-03 (celebration triggers fire after node state transitions to completed)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - PBXFileSystemSynchronizedRootGroup auto-includes new Swift files — no pbxproj edits needed for main target
    - NodeState enum at file scope (not nested) for cross-file reuse
    - Free function nodeState(at:actions:) companion to NodeState for clean call site
    - ScrollViewReader + .task + 50ms sleep pattern for scroll-after-layout-pass

key-files:
  created:
    - Abimo/Views/ActionPlan/Journey/JourneyNodeView.swift
    - Abimo/Views/ActionPlan/Journey/ProgressRingView.swift
    - Abimo/Views/ActionPlan/Journey/JourneyPathView.swift
  modified: []

key-decisions:
  - "PBXFileSystemSynchronizedRootGroup used by Abimo target — creating files in Abimo/ directory is sufficient for compilation, no pbxproj edits needed"
  - "NodeState enum placed at file scope (not nested in JourneyNodeView) so JourneyPathView can call nodeState() without qualification"
  - ".task modifier used instead of .onAppear for auto-scroll to avoid scroll-before-layout-pass race condition (50ms sleep allows first layout pass)"

patterns-established:
  - "Journey group directory pattern: Abimo/Views/ActionPlan/Journey/ for spatial journey components"
  - "StrokeStyle with dash: [] vs [6, 4] for solid/dashed lines based on completion state"

requirements-completed: [PATH-01, PATH-02, PATH-03, PATH-04, PATH-05]

# Metrics
duration: 3min
completed: 2026-03-18
---

# Phase 2 Plan 01: Journey Path UI Components Summary

**Three SwiftUI views implementing a Duolingo-style spatial journey path: 56pt state-aware node circles in a zigzag ScrollView with auto-scroll, plus an animated circular progress ring header**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-03-18T21:40:27Z
- **Completed:** 2026-03-18T21:43:01Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- JourneyNodeView renders 56pt circles in three states: locked (grey with lock emoji), active (brand coral with action emoji + shadow), completed (green with checkmark). Connects to next node with dashed/solid 2pt line segment.
- ProgressRingView renders an 80pt ring using Circle().trim with spring animation and .contentTransition(.numericText()) for the count display.
- JourneyPathView assembles the full scrollable path: zigzag layout (alternating ±60pt horizontal offset), ProgressRingView header, staggered cardEntrance animations, auto-scroll to active node via ScrollViewReader.

## Task Commits

Each task was committed atomically:

1. **Task 1: Create JourneyNodeView and ProgressRingView** - `ed3b44e` (feat)
2. **Task 2: Create JourneyPathView with zigzag layout and auto-scroll** - `81bf31d` (feat)

## Files Created/Modified

- `Abimo/Views/ActionPlan/Journey/JourneyNodeView.swift` - NodeState enum, nodeState helper, and JourneyNodeView with state-aware rendering and connecting line
- `Abimo/Views/ActionPlan/Journey/ProgressRingView.swift` - Circular progress ring with animated trim and numericText transition
- `Abimo/Views/ActionPlan/Journey/JourneyPathView.swift` - ScrollView + ScrollViewReader zigzag canvas with auto-scroll and progress header

## Decisions Made

- The Abimo target uses `PBXFileSystemSynchronizedRootGroup` — any Swift file added to the `Abimo/` directory tree is automatically compiled. No manual pbxproj edits are needed (unlike the AbimoTests target which uses traditional PBXGroup). The plan's instruction to add PBXGroup entries was skipped as it would have been incorrect for this project structure.
- `NodeState` placed at file scope (not nested inside `JourneyNodeView`) so `JourneyPathView` can call `nodeState(at:actions:)` without any qualification.
- Used `.task` modifier with a 50ms `Task.sleep` instead of `.onAppear` for auto-scroll, as `.onAppear` fires before the first layout pass completes, causing the scroll to target unresolved geometry.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Skipped manual pbxproj edits for Abimo target**
- **Found during:** Task 1 (reading project.pbxproj)
- **Issue:** Plan instructed adding PBXFileReference + PBXGroup + PBXBuildFile entries for the Journey group. However, the Abimo target uses `PBXFileSystemSynchronizedRootGroup` which auto-discovers all Swift files in the `Abimo/` directory — manual registration would have been redundant and could corrupt the project.
- **Fix:** Created files in the correct directory; build confirmed they compiled automatically.
- **Files modified:** None (pbxproj unchanged — correct behavior)
- **Verification:** xcodebuild BUILD SUCCEEDED with all three files present
- **Committed in:** ed3b44e, 81bf31d (as part of task commits)

---

**Total deviations:** 1 auto-fixed (Rule 1 — incorrect instruction, skipped harmful action)
**Impact on plan:** Build succeeded; all acceptance criteria met. Skipping the pbxproj edits was the correct decision for this project's structure.

## Issues Encountered

- Build device target: "iPhone 17" simulator used (as specified in plan) but initial invocation failed because two .xcodeproj files exist in the directory. Fixed with `-project Abimo.xcodeproj` flag.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- All three Journey/ views compile and are ready to be integrated into ActionPlanDetailView
- Plan 02: ActionCardView can receive `selectedAction: MicroAction?` binding from JourneyPathView
- Plan 03: Celebration triggers can observe node state transitions from JourneyNodeView taps

---
*Phase: 02-journey-path-and-action-cards*
*Completed: 2026-03-18*
