---
phase: 06-tap-bubbles-on-nodes
plan: 01
subsystem: ui
tags: [swiftui, speech-bubble, gesture, animation, haptics, zstack-overlay]

# Dependency graph
requires:
  - phase: 05-ordering-and-sheets
    provides: JourneyPathView with orderedActions, NodeState enum, JourneyNodeView.onTap closure, selectedAction binding
provides:
  - NodeBubbleView.swift with BubbleShape and three-state content (active/completed/locked)
  - JourneyPathView with activeBubbleId state, bubble overlay, scroll/tap dismissal
affects:
  - phase-07-action-picker (NodeBubbleView "Complete!" flow integrates with postCompletionSheet)
  - phase-08-congrats-sheet (bubble dismissal precedes celebration state transitions)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Single-UUID state (activeBubbleId) for single-selection floating overlay"
    - "Index-based absolute positioning within ZStack overlay (headerHeight + index*stride)"
    - "Synchronous nil-before-async pattern: clear activeBubbleId THEN dispatch async task"
    - "BubbleShape via SwiftUI Path: rounded rect body + downward triangle arrow"

key-files:
  created:
    - Abimo/Views/ActionPlan/Journey/NodeBubbleView.swift
  modified:
    - Abimo/Views/ActionPlan/Journey/JourneyPathView.swift

key-decisions:
  - "activeBubbleId lives at JourneyPathView level (view-local @State) not ViewModel — no persistence needed"
  - "Bubble overlay rendered via .overlay(alignment: .topLeading) on VStack — not inside JourneyNodeView — avoids gesture competition"
  - "Position computed from index arithmetic (162pt header + 136pt*index) rather than GeometryReader/anchorPreference"
  - "Synchronous activeBubbleId=nil before async toggleMicroAction prevents zombie bubble during celebration transitions"

patterns-established:
  - "BubbleShape: Shape uses Path.addRoundedRect for body + addLine triangle for arrow — no ShapeBuilder abstraction needed"
  - "NodeBubbleView: standalone view with closures (onComplete, onSeeMore, onDismiss) — not embedded in parent nodes"
  - "Toggle pattern: activeBubbleId = activeBubbleId == action.id ? nil : action.id"
  - ".simultaneousGesture(DragGesture(minimumDistance: 10)) on ScrollView for scroll-dismiss without blocking scroll"

requirements-completed: [DISC-01, DISC-02, DISC-03]

# Metrics
duration: 18min
completed: 2026-03-19
---

# Phase 6 Plan 1: Tap Bubbles on Nodes Summary

**Speech bubble callouts on every journey node: BubbleShape Path-drawn view with three-state content (Complete!/Done+See more/Coming up) driven by activeBubbleId at JourneyPathView level**

## Performance

- **Duration:** ~18 min
- **Started:** 2026-03-19T18:34:00Z
- **Completed:** 2026-03-19T18:52:00Z
- **Tasks:** 2
- **Files modified:** 2 (1 created, 1 modified)

## Accomplishments

- Created NodeBubbleView.swift with BubbleShape (rounded rect + downward arrow via SwiftUI Path) and three-state content rendering
- Active bubble shows brand-coral "Complete!" button (PlayfulButtonStyle, 44pt min height)
- Completed bubble shows brandGreen "Done" badge + "See more" link that opens ActionDetailSheet
- Locked bubble shows muted "Coming up" label with no interactive elements
- Wired activeBubbleId state into JourneyPathView: toggle on node tap, overlay positioned by index arithmetic, scroll-dismiss via simultaneousGesture
- Spring pop-in animation (AnimationPolicy, 0.3 response, 0.6 damping) + .light haptic on bubble appear

## Task Commits

Each task was committed atomically:

1. **Task 1: Create NodeBubbleView with BubbleShape and state-driven content** - `d6df773` (feat)
2. **Task 2: Wire bubble state, overlay, and dismissal into JourneyPathView** - `48b626b` (feat)

## Files Created/Modified

- `Abimo/Views/ActionPlan/Journey/NodeBubbleView.swift` - Standalone speech bubble view: BubbleShape, three-state content, spring pop-in animation
- `Abimo/Views/ActionPlan/Journey/JourneyPathView.swift` - Added activeBubbleId @State, replaced onTap to toggle bubble, overlay with NodeBubbleView, scroll-dismiss gesture

## Decisions Made

- `activeBubbleId` stays in JourneyPathView as view-local `@State` (not promoted to ViewModel) — bubble visibility is ephemeral UI with no persistence requirement
- Used index-based position arithmetic (`162pt header + CGFloat(index) * 136pt`) instead of GeometryReader/anchorPreference — simpler and sufficient for the fixed-stride zigzag layout
- Rendered bubble overlay via `.overlay(alignment: .topLeading)` on the inner VStack (not inside each JourneyNodeView) — eliminates gesture competition between bubble CTAs and node Button

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- `UIScreen.main` deprecation warning on iOS 26 SDK (used for screen width calculation in bubble positioning). This is a cosmetic warning, not an error. The build succeeds. Deferred: switch to `UIScreen` via window/scene context in a future cleanup pass when a window reference is available in JourneyPathView.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- NodeBubbleView and activeBubbleId wiring complete — Phase 6 tap-bubble feature is fully functional
- "Complete!" button correctly dispatches toggleMicroAction, which triggers existing celebration state transitions (CelebrationState, MilestoneBannerView, PlanCompletionView)
- "See more" correctly opens ActionDetailSheet via selectedAction binding
- Phase 7 (action picker) can proceed — NodeBubbleView does not depend on ActionPickerSheet

---
*Phase: 06-tap-bubbles-on-nodes*
*Completed: 2026-03-19*
