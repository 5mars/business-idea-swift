---
phase: 12-path-curves-and-actions-tab-cleanup
plan: 01
subsystem: ui
tags: [swiftui, canvas, bezier, path, journey, momentum-dashboard]

# Dependency graph
requires: []
provides:
  - Bezier S-curve connecting lines between journey nodes (ConnectingLineView)
  - MomentumDashboard with streak-only display (no commitment link)
  - Clean ActionsTabView call site with 3-param MomentumDashboard
affects: [journey-path, actions-tab, momentum-dashboard]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Canvas path.addCurve with vertical control points for organic S-curve between nodes"

key-files:
  created: []
  modified:
    - Abimo/Views/ActionPlan/Journey/JourneyNodeView.swift
    - Abimo/Views/ActionPlan/MomentumDashboard.swift
    - Abimo/Views/ActionPlan/ActionsTabView.swift

key-decisions:
  - "S-curve control points at 0.45*height vertically below/above endpoints — gentle curve within 80pt frame"
  - "MomentumDashboard simplified to 3 props (streak, weekActivity, totalCompletedThisWeek) — commitment section removed entirely"
  - "ActionsTabView visibility condition simplified: show only on !allCompletionDates.isEmpty (activeCommitment check no longer needed)"

patterns-established:
  - "Canvas bezier: control1 directly below from-point, control2 directly above to-point creates S-curve effect"

requirements-completed: [PATH-01, TABS-03]

# Metrics
duration: 2min
completed: 2026-03-21
---

# Phase 12 Plan 01: Path Curves and Actions Tab Cleanup Summary

**Bezier S-curves replace straight connecting lines between journey nodes, and MomentumDashboard drops its commitment NavigationLink section to show only streak data**

## Performance

- **Duration:** ~2 min
- **Started:** 2026-03-21T21:29:16Z
- **Completed:** 2026-03-21T21:30:52Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- ConnectingLineView now draws gentle Bezier S-curves (path.addCurve) instead of straight diagonal lines, making the journey path feel like an organic hiking trail
- MomentumDashboard reduced from 6 props to 3 — removed activeCommitmentText, activeCommitmentPlanId, activeCommitmentAnalysisId and the entire "Your commitment" NavigationLink block
- ActionsTabView call site cleaned up: no commitment params, simplified visibility condition

## Task Commits

Each task was committed atomically:

1. **Task 1: Replace straight lines with Bezier S-curves** - `7d522be` (feat)
2. **Task 2: Remove commitment section from MomentumDashboard and clean up call site** - `7d72da3` (feat)

**Plan metadata:** (docs commit — see below)

## Files Created/Modified
- `Abimo/Views/ActionPlan/Journey/JourneyNodeView.swift` - ConnectingLineView: addLine replaced with addCurve using vertical control points
- `Abimo/Views/ActionPlan/MomentumDashboard.swift` - Removed 3 commitment properties and entire NavigationLink block
- `Abimo/Views/ActionPlan/ActionsTabView.swift` - Simplified MomentumDashboard call site and visibility condition

## Decisions Made
- S-curve control points use 0.45 * height multiplier — keeps the curves gentle and contained within the 80pt frame
- MomentumDashboard visibility condition simplified to only check `!allCompletionDates.isEmpty` since the dashboard no longer surfaces commitment info

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
- xcodebuild failed initially due to 2 .xcodeproj files in root; resolved by passing `-project Abimo.xcodeproj` explicitly.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Journey path now has curved organic lines, ready for visual review
- MomentumDashboard is clean (streak-only), ready for any additional streak polish
- Phase 12 plan 02 can proceed

---
*Phase: 12-path-curves-and-actions-tab-cleanup*
*Completed: 2026-03-21*
