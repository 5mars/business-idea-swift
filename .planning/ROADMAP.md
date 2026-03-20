# Roadmap: Abimo — Actions Flow UX

## Milestones

- ✅ **v1.0 Actions Flow Revamp** - Phases 1-4 (shipped 2026-03-19)
- 🚧 **v1.1 Actions Flow UX** - Phases 5-8 (in progress)

## Phases

<details>
<summary>✅ v1.0 Actions Flow Revamp (Phases 1-4) - SHIPPED 2026-03-19</summary>

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
- [x] 02-01-PLAN.md — Build JourneyNodeView, JourneyPathView, and ProgressRingView components
- [x] 02-02-PLAN.md — Build ActionDetailSheet bottom sheet with primary and secondary content
- [x] 02-03-PLAN.md — Wire journey path into ActionPlanDetailView with completion and unlock animations

### Phase 3: Celebration System
**Goal**: Completing an action produces an immediate, satisfying inline reward; completing all actions in a plan produces a full-screen celebration with summary and a prompt to continue
**Depends on**: Phase 2
**Requirements**: CELB-01, CELB-02, CELB-03, CELB-04, CELB-05
**Success Criteria** (what must be TRUE):
  1. Marking any single micro-action complete triggers a confetti burst and animated checkmark directly on the card within half a second, then clears automatically without requiring user dismissal
  2. Completing the final action in a plan immediately transitions to a full-screen celebration with a Lottie animation and confetti — distinct from the inline per-action celebration
  3. The plan completion screen displays a summary showing how many actions were completed and the total estimated time invested
  4. The plan completion screen has a placeholder area for a future "What's next" feature and a "Done" dismiss button
  5. Completing a 3rd, 5th, or 7th action triggers a visually distinct milestone moment (lighter than plan completion, heavier than a standard inline celebration)
**Plans**: 2 plans

Plans:
- [x] 03-01-PLAN.md — Add SPM packages (Vortex + lottie-spm), CelebrationState enum, ViewModel celebration logic, and unit tests
- [x] 03-02-PLAN.md — Build InlineConfettiView, MilestoneBannerView, PlanCompletionView and wire into journey path

### Phase 4: Polish
**Goal**: All key interactions feel physically responsive and all transitions between states animate smoothly — the journey path feels alive from first tap to plan completion
**Depends on**: Phase 3
**Requirements**: POLI-01, POLI-02, POLI-03
**Success Criteria** (what must be TRUE):
  1. Completing an action, toggling a commitment, and reaching a milestone each produce a distinct haptic pattern — not the same generic tap feedback
  2. A node that transitions from locked to active animates fluidly; a node that transitions from active to completed animates fluidly — no jarring state jumps
  3. When plan progress advances (e.g., one more action is completed), the progress ring on the plan header visually animates its fill from the old value to the new value
**Plans**: 1 plan

Plans:
- [x] 04-01-PLAN.md — Add commitment haptic, animate node color transitions, verify progress ring

</details>

### 🚧 v1.1 Actions Flow UX (In Progress)

**Milestone Goal:** Make the journey path intuitive — users understand their actions, choose their own order, and get celebrated properly between completions.

#### Phase 5: ViewModel Foundation and Ordering Model
**Goal**: The ViewModel has a stable, ordered view of actions and a single enum driving all post-completion sheet state — all downstream view work is unblocked with no ordering bugs possible
**Depends on**: Phase 4
**Requirements**: ORDR-01, ORDR-02, ORDR-03, CELB-03
**Success Criteria** (what must be TRUE):
  1. When a user picks an action, `orderedActions` immediately reflects the chosen action first, with remaining actions preserving their relative AI order — no duplicate `.active` nodes appear
  2. User's chosen action order persists across app restarts for the same plan (UserDefaults keyed by plan ID)
  3. Post-completion sheet state is driven by a single `PostCompletionSheet` enum — no boolean flags exist that could race against each other
  4. `JourneyPathView` reads from `orderedActions` (not raw `microActions`) so `nodeState()` always returns the correct state for the user-driven order
**Plans**: 2 plans

Plans:
- [ ] 05-01-PLAN.md — TDD: Add ordering model (userOrderedIds, orderedActions, pickAction) and PostCompletionSheet enum to ViewModel with unit tests
- [ ] 05-02-PLAN.md — Wire JourneyPathView to orderedActions and replace boolean sheet modifiers with enum-driven sheets in ActionPlanDetailView

#### Phase 6: Tap Bubbles on Nodes
**Goal**: Every journey node communicates its state on tap — active nodes prompt users to start, locked nodes explain what to finish first, and completed nodes show a read-only recap
**Depends on**: Phase 5
**Requirements**: DISC-01, DISC-02, DISC-03
**Success Criteria** (what must be TRUE):
  1. Tapping any node on the journey path shows a callout bubble with the action name and a contextual CTA — no node is silent on tap
  2. The active node bubble shows a "Complete!" button that opens the action detail sheet; completed node bubbles show a read-only "Done" badge with no CTA
  3. Tapping a second node while a bubble is visible dismisses the first bubble and shows the new one — only one bubble is ever visible at a time
  4. Tapping the journey path background (not a node) dismisses any open bubble
**Plans**: 1 plan

Plans:
- [ ] 06-01-PLAN.md — Build `NodeBubbleView` parameterised by `NodeState`; modify `JourneyNodeView` tap handler to set `activeNodeId`; add background tap dismissal to `JourneyPathView`

#### Phase 7: Action Picker Sheet
**Goal**: Users can see all their actions and choose which one to tackle next — on first visit to a plan and as the second step of the post-completion flow
**Depends on**: Phase 5
**Requirements**: PICK-01, PICK-02, PICK-03
**Success Criteria** (what must be TRUE):
  1. Opening a new action plan for the first time presents a full action list before the user interacts with any node — they pick their first action before the journey path is in focus
  2. Action picker cards clearly show each action's name, type icon (from ActionIconMapper), and time estimate
  3. Confirming a selection in the picker updates the journey path immediately — the chosen action becomes the next active node
  4. The picker shown after completing an action does not include the just-completed action in its list
**Plans**: 1 plan

Plans:
- [ ] 07-01-PLAN.md — Build `ActionPickerSheet` with `LazyVGrid` 2-column layout; wire first-visit trigger in `ActionPlanDetailView.task`; call `viewModel.pickAction(_:)` on confirm

#### Phase 8: Two-Step Completion Sheet and Full Wiring
**Goal**: Completing an action triggers a congrats half-sheet that celebrates the win and flows directly into the action picker — the full v1.1 user journey works end-to-end
**Depends on**: Phase 7
**Requirements**: CELB-01, CELB-02
**Success Criteria** (what must be TRUE):
  1. After marking any action complete (except the final one in a plan), a half-sheet slides up with a Lottie celebration animation and a "Keep the momentum?" CTA — the journey path remains visible behind it
  2. Tapping the CTA on the congrats sheet transitions to the action picker within the same sheet — no sheet dismiss/re-present gap is visible
  3. Completing the final action in a plan shows the full-screen plan completion overlay (not the congrats half-sheet) — the two flows are mutually exclusive
  4. Rapidly completing multiple actions back-to-back (3 in a row) never produces a broken or stuck sheet state
**Plans**: 1 plan

Plans:
- [ ] 08-01-PLAN.md — Build `CongratsHalfSheet` with Lottie star burst animation and "Keep the momentum?" CTA; wire `PostCompletionSheet` enum into `ActionPlanDetailView` via single `.sheet(item:)`; retire `MomentumPickerSheet`

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Foundation | v1.0 | 2/2 | Complete | 2026-03-18 |
| 2. Journey Path and Action Cards | v1.0 | 3/3 | Complete | 2026-03-19 |
| 3. Celebration System | v1.0 | 2/2 | Complete | 2026-03-19 |
| 4. Polish | v1.0 | 1/1 | Complete | 2026-03-19 |
| 5. ViewModel Foundation and Ordering Model | 2/2 | Complete   | 2026-03-19 | - |
| 6. Tap Bubbles on Nodes | 1/1 | Complete   | 2026-03-19 | - |
| 7. Action Picker Sheet | 1/1 | Complete   | 2026-03-19 | - |
| 8. Two-Step Completion Sheet and Full Wiring | 1/1 | Complete   | 2026-03-20 | - |
