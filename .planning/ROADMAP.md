# Roadmap: Abimo — Actions Flow Revamp

## Overview

Transform the existing flat micro-action task manager into a spatially engaging, gamified journey experience. Foundation utilities come first to guarantee accessibility and haptic infrastructure before any animation is wired. The journey path and card system then replace the flat list as the core spatial metaphor. A two-tier celebration system rewards individual completions inline and full plan completion with a dedicated screen. Polish pass finalizes smooth transitions and integrates momentum context into the journey header.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 1: Foundation** - Build the three utility primitives that every animated view depends on (completed 2026-03-18)
- [ ] **Phase 2: Journey Path and Action Cards** - Replace the flat list with a vertical node path and card-state system
- [ ] **Phase 3: Celebration System** - Add inline and full-screen celebrations for action and plan completions
- [ ] **Phase 4: Polish** - Smooth node-unlock transitions, animated progress rings, and haptic coverage

## Phase Details

### Phase 1: Foundation
**Goal**: The three shared utilities exist and can be used from any view — animations respect reduced-motion, haptics fire at zero latency, and every action type resolves to a consistent icon
**Depends on**: Nothing (first phase)
**Requirements**: FOUN-01, FOUN-02, FOUN-03
**Success Criteria** (what must be TRUE):
  1. Any animation site can call `AnimationPolicy.animate { }` and the block is skipped automatically when the device has Reduce Motion enabled
  2. Any ViewModel can call `HapticEngine.impact()` or `HapticEngine.success()` and get immediate physical feedback with no perceptible delay
  3. Given a `MicroAction` with any action type (email, search, message, post, or unknown), `ActionIconMapper` returns a non-nil emoji and SF Symbol name
**Plans**: 2 plans
Plans:
- [x] 01-01-PLAN.md — Create AnimationPolicy, HapticEngine, and ActionIconMapper utilities
- [x] 01-02-PLAN.md — Create AbimoTests target and unit tests for all three utilities

### Phase 2: Journey Path and Action Cards
**Goal**: Users see and navigate a vertical zigzag node path instead of a flat list — each node renders its locked/active/completed state and expands into a full action card on tap
**Depends on**: Phase 1
**Requirements**: PATH-01, PATH-02, PATH-03, PATH-04, PATH-05, PATH-06, CARD-01, CARD-02, CARD-03, CARD-04, CARD-05
**Success Criteria** (what must be TRUE):
  1. Opening an action plan shows a vertical scrolling path with nodes alternating left and right, connected by a visible line — no flat list visible
  2. The path automatically scrolls to the current active node when the view appears, without user interaction
  3. Each node clearly communicates its state: future nodes appear greyed/locked, the current node is highlighted, and completed nodes show a checked/done state
  4. Tapping a locked/active node opens a bottom sheet showing the action's icon, text, time estimate, and — on secondary tap or scroll within the sheet — done criteria, template text, and deep link buttons
  5. Completing an action from the card causes that node to visually animate into the completed state and the next node plays an unlock animation transitioning from locked to active
**Plans**: 3 plans
Plans:
- [ ] 02-01-PLAN.md — Build JourneyNodeView, JourneyPathView, and ProgressRingView components
- [ ] 02-02-PLAN.md — Build ActionDetailSheet bottom sheet with primary and secondary content
- [ ] 02-03-PLAN.md — Wire journey path into ActionPlanDetailView with completion and unlock animations

### Phase 3: Celebration System
**Goal**: Completing an action produces an immediate, satisfying inline reward; completing all actions in a plan produces a full-screen celebration with summary and a prompt to continue
**Depends on**: Phase 2
**Requirements**: CELB-01, CELB-02, CELB-03, CELB-04, CELB-05
**Success Criteria** (what must be TRUE):
  1. Marking any single micro-action complete triggers a confetti burst and animated checkmark directly on the card within half a second, then clears automatically without requiring user dismissal
  2. Completing the final action in a plan immediately transitions to a full-screen celebration with a Lottie animation and confetti — distinct from the inline per-action celebration
  3. The plan completion screen displays a summary showing how many actions were completed and the total estimated time invested
  4. The plan completion screen has a clearly visible "Record a new voice note" button that navigates back to the recording flow
  5. Completing a 3rd, 5th, or 7th action triggers a visually distinct milestone moment (lighter than plan completion, heavier than a standard inline celebration)
**Plans**: TBD

### Phase 4: Polish
**Goal**: All key interactions feel physically responsive and all transitions between states animate smoothly — the journey path feels alive from first tap to plan completion
**Depends on**: Phase 3
**Requirements**: POLI-01, POLI-02, POLI-03
**Success Criteria** (what must be TRUE):
  1. Completing an action, toggling a commitment, and reaching a milestone each produce a distinct haptic pattern — not the same generic tap feedback
  2. A node that transitions from locked to active animates fluidly; a node that transitions from active to completed animates fluidly — no jarring state jumps
  3. When plan progress advances (e.g., one more action is completed), the progress ring on the plan header visually animates its fill from the old value to the new value
**Plans**: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation | 2/2 | Complete   | 2026-03-18 |
| 2. Journey Path and Action Cards | 0/3 | Not started | - |
| 3. Celebration System | 0/TBD | Not started | - |
| 4. Polish | 0/TBD | Not started | - |
