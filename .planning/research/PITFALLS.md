# Pitfalls Research

**Domain:** SwiftUI gamified journey path — action picker, node tap bubbles, user-driven ordering, two-step completion sheet
**Researched:** 2026-03-19
**Confidence:** HIGH for SwiftUI/state-management pitfalls (first-hand codebase analysis); MEDIUM for UX pitfalls (research + analogous app patterns)

---

## Critical Pitfalls

### Pitfall 1: User-Chosen Order Corrupts the Node State Machine

**What goes wrong:**
The current `nodeState(at:actions:)` function (in `JourneyNodeView.swift`) derives NodeState from array index position: the first incomplete action at the lowest index is `.active`, everything above it is `.completed`, everything below is `.locked`. When user-driven ordering moves an action to "next" position by changing its array index, any action that previously had a lower index and is now skipped over becomes `.active` — or worse, the ordering logic produces two simultaneous `.active` nodes. The zigzag path and unlock animations fire for the wrong nodes.

**Why it happens:**
The ordering model assumes array index == progression order. That was fine when AI determined order and users only moved forward. User-driven reordering breaks this implicit contract: the function uses `firstIndex(where: !isCompleted)` to find the active node, but if the user has picked an action from position 4 to be next, position 4 is now semantically "active" while positions 1–3 (incomplete, lower index) still satisfy `firstIndex(where: !isCompleted)` and are incorrectly promoted to `.active`.

**How to avoid:**
Introduce an explicit `displayOrder` field (or a separate sorted array on the ViewModel) that carries user-chosen position separate from the `priority` field from the AI. When the user picks action X to be next, swap it to `displayOrder = completedCount + 1`; all other incomplete actions shift their display order up by 1. The `nodeState` function must operate on this display-ordered array, not the raw `microActions` array. Do not mutate `priority` in the database for this — it's AI metadata, not display state.

**Warning signs:**
- Two nodes simultaneously showing `.active` (coral color) in the journey path.
- The unlock animation plays on the wrong node after a user picks a different action.
- `firstIndex(where: !isCompleted)` returns a lower index than the user's chosen action.

**Phase to address:**
Action Picker + User-Driven Ordering phase. Define the display-order model in the ViewModel before building the picker UI or touch handling.

---

### Pitfall 2: Two Sheets Competing on the Same Boolean Cause Undefined Presentation

**What goes wrong:**
`ActionPlanDetailView` currently has three `.sheet()` modifiers driven by separate booleans (`showCommitmentSheet`, `showCommitmentPicker`, `showMomentumPicker`) and one driven by `$selectedAction` (Identifiable). The v1.1 design adds a congrats half-sheet and an action picker that slides in after congrats. If both are driven by independent booleans and they activate in rapid succession (congrats triggers on completion, action picker follows after 1–2 seconds), SwiftUI's sheet presentation queue drops or stacks presentations unpredictably. The user sees the congrats sheet get dismissed and nothing appears, or sees both stacked.

**Why it happens:**
SwiftUI processes `.sheet` presentations one at a time in a queue. When a second `.sheet(isPresented:)` fires while the first is still animating in, the second is silently deferred or ignored. This is a known SwiftUI limitation on iOS 16/17 — documented in multiple community threads and Apple Feedback reports — where presenting two sheets rapidly results in only one showing. The issue is amplified when timers (e.g., auto-advance after 1.5s) drive the second presentation.

**How to avoid:**
Model the two-step flow as a single enum state, not two booleans:
```swift
enum PostCompletionSheet {
    case none
    case congrats(actionId: UUID)
    case actionPicker(actionId: UUID)
}
```
A single `.sheet(item:)` or `.sheet(isPresented:)` reads from this enum. The congrats view contains a "Keep the momentum?" button that calls `viewModel.advancePostCompletionSheet()`, transitioning the enum to `.actionPicker`. No timers, no race — the user controls the transition. This is the same pattern the existing `CelebrationState` enum uses successfully.

**Warning signs:**
- Tapping "Keep the momentum?" sometimes shows nothing.
- Congrats sheet dismisses but action picker never appears.
- In debug: `[Warning] Attempt to present ... whose view is not in the window hierarchy`.

**Phase to address:**
Two-Step Completion Sheet phase. Define the sheet state enum before any sheet view is built.

---

### Pitfall 3: Tap Bubbles Block Node Taps and Break the Existing Sheet Flow

**What goes wrong:**
Duolingo-style bubbles appear on tap (or hover-like press) above each node showing the action name and a CTA. If the bubble is rendered as an `.overlay` or `.popover` inside the `JourneyNodeView`, the bubble's `View` frame captures tap gestures meant for the node itself, or for the `ActionDetailSheet` trigger in `JourneyPathView`. Users tap a bubble CTA but the gesture goes to the node's `onTap` handler instead — or vice versa, the bubble dismisses before they can tap the CTA.

**Why it happens:**
SwiftUI gesture priority is determined by z-order and parent-child relationships. A bubble rendered as an overlay on a `Button` competes with the button's implicit `.onTapGesture`. If the bubble has its own `Button` for the CTA, the parent `Button(action: onTap)` in `JourneyNodeView` may eat the gesture first, depending on whether `.buttonStyle(.plain)` or `.highPriorityGesture` is used.

**How to avoid:**
Render bubbles outside the `JourneyNodeView` entirely — at the `JourneyPathView` level as a ZStack overlay, keyed to the currently-selected node. This separates bubble gesture handling from node gesture handling cleanly. The node's `onTap` sets `selectedBubbleActionId` on the ViewModel; the bubble reads from that. The bubble's CTA calls `viewModel.selectActionForNext(id:)` directly. No gesture competition.

If bubbles must live in `JourneyNodeView`, use `.simultaneousGesture(TapGesture())` on the bubble's container and call `.allowsHitTesting(false)` on purely decorative parts.

**Warning signs:**
- Tapping the bubble CTA sometimes opens the `ActionDetailSheet` instead.
- Bubble appears but CTA button tap does nothing.
- The bubble disappears on the first tap before the CTA can be pressed.

**Phase to address:**
Tap Bubbles on Nodes phase. Decide bubble rendering location (node-level vs. path-level) before implementing bubble gesture handling.

---

### Pitfall 4: CelebrationState Enum Collision — planComplete vs. Congrats Sheet

**What goes wrong:**
The existing `CelebrationState` enum has `.planComplete` which shows the full-screen `PlanCompletionView`. The v1.1 design adds a congrats half-sheet after each individual action completion. If the congrats half-sheet is added to `CelebrationState` as a new case, the `evaluateCelebrationState` logic that currently picks `.planComplete` when all actions are done could produce an ambiguous state: the last action completes → `.planComplete` fires → but the congrats sheet also fires → two celebrations compete. The full-screen completion view and the half-sheet both try to appear.

**Why it happens:**
The existing `evaluateCelebrationState` function is carefully ordered (checks `allDone` first to take priority over milestones). Adding a new case for the congrats half-sheet without updating this priority logic re-introduces the race. The function comment says "allDone FIRST to ensure planComplete takes priority" — that discipline must extend to any new case.

**How to avoid:**
Keep the congrats half-sheet in a separate state machine from `CelebrationState`. The existing enum handles ambient journey celebrations (confetti burst, milestone banner, plan complete overlay). The new congrats half-sheet is post-completion navigation — it belongs in a `PostCompletionSheet` enum (see Pitfall 2). These are different concerns: `CelebrationState` drives visual effects on the journey path; `PostCompletionSheet` drives sheet navigation. When the last action is completed, `CelebrationState` goes to `.planComplete` and `PostCompletionSheet` stays `.none` — the full-screen overlay IS the celebration for plan completion.

**Warning signs:**
- The full-screen `PlanCompletionView` and a congrats half-sheet both appear on the last action.
- `celebrationState` is `.planComplete` but a half-sheet is also presenting.
- Dismissing the congrats sheet kills the `PlanCompletionView` or leaves it orphaned.

**Phase to address:**
Two-Step Completion Sheet phase. Audit `evaluateCelebrationState` before adding any new celebration-adjacent state.

---

### Pitfall 5: Action Picker Stale Data After Picker Is Shown Repeatedly

**What goes wrong:**
The action picker screen lists all incomplete actions for the user to choose from. If the user opens the picker, picks an action, completes it, then another completion triggers the picker again — the picker's `remainingActions` computed property may return stale data. Specifically, the action the user just completed still appears in the list because the `MicroAction` in the ViewModel has not yet been confirmed by the Supabase write (optimistic UI). The user sees a completed action as a selectable option.

**Why it happens:**
`remainingActions` in `MomentumPickerSheet` filters on `!$0.isCompleted`. The ViewModel's `microActions` array is updated optimistically at the start of `confirmCompletion`, so by the time the picker presents, the completed action should be filtered out. However, if the picker pre-selects the first item in `visibleActions` via `onAppear { selectedActionId = visibleActions.first?.id }`, and the list was computed before the optimistic update landed on the MainActor, the pre-selected action could be the one just completed.

**How to avoid:**
Filter actions for the picker using `id != completedActionId` explicitly (already done in `MomentumPickerSheet`), not just `!$0.isCompleted`. Also: compute `remainingActions` lazily after the sheet's `onAppear`, not during body evaluation, so it reads the most current ViewModel state. Add a `.task { }` on the picker that re-evaluates if `viewModel.microActions` changes while the picker is open.

**Warning signs:**
- The action the user just completed appears in the picker list.
- Pre-selected action is one already marked complete (green checkmark state).
- Tapping "I'm on it" on a completed action causes a no-op or an error.

**Phase to address:**
Action Picker phase. Verify the stale data scenario with a unit test for `remainingActions` computed after an optimistic completion.

---

### Pitfall 6: Bubble Persistence After Action Completes (Zombie Bubbles)

**What goes wrong:**
A tap bubble is shown on a node. The user completes that action (e.g., via the action detail sheet). The node transitions from `.active` to `.completed`. The bubble, driven by a local `@State var showBubble: Bool`, is still showing because nothing cleared it. The user now sees a bubble on a green completed node saying "Start this action."

**Why it happens:**
Tap bubbles driven by local `@State` inside `JourneyNodeView` are not automatically dismissed when the node's `state` changes from `.active` to `.completed`. The state change triggers `onChange(of: state)` for color animation, but there's no built-in mechanism to clear `showBubble`. This is guaranteed to happen when the user taps the bubble CTA → opens the detail sheet → marks complete → sheet dismisses → bubble is still up.

**How to avoid:**
If bubbles are driven by local `@State`, add an `onChange(of: state) { if newValue == .completed { showBubble = false } }` modifier. Better: drive bubble visibility from the ViewModel (`activeBubbleActionId: UUID?`), so any state change that calls `viewModel.clearBubble()` removes it from all nodes simultaneously. The ViewModel already has precedent for this with `justCompletedActionId`.

**Warning signs:**
- Bubble saying "Do this action" appears on a green completed node.
- Bubble persists after the ActionDetailSheet marks the action done.
- Multiple nodes show bubbles simultaneously.

**Phase to address:**
Tap Bubbles on Nodes phase. Define bubble lifecycle (what dismisses it) before implementing bubble appearance.

---

### Pitfall 7: User-Chosen Ordering Not Persisted Across App Restarts

**What goes wrong:**
The user picks action B to go next (instead of the AI-ordered action A). The in-memory `displayOrder` reflects this. The user closes the app. On restart, `loadActionPlan` fetches `microActions` from Supabase ordered by the `priority` column (AI order). The user's custom ordering is lost — the journey path reverts to AI order.

**Why it happens:**
`MicroAction` has a `priority` field (used by AI) and no separate `displayOrder` field. If user ordering is only tracked in-memory (e.g., by array re-sorting on the ViewModel), it doesn't survive a reload. The Supabase `fetchMicroActions` query orders by `priority`, so even if items were persisted with updated `priority`, the next fetch reorders by that column.

**How to avoid:**
Two acceptable approaches:
1. Write a `user_display_order` column to the `micro_actions` table when the user re-orders. Cheap write, persists across restarts. Requires a schema migration (acceptable since PROJECT.md says no Supabase schema changes for v1.1 — **flag this as a constraint**).
2. Store the ordering client-side only (UserDefaults keyed by `actionPlanId`). Survives app restart, no schema change. Caveat: lost if user changes device or deletes the app.

Given PROJECT.md constraint "No Supabase schema changes", option 2 is the v1.1 approach. The ViewModel `loadActionPlan` should merge the Supabase-fetched array with the locally-stored display order after loading.

**Warning signs:**
- Restarting the app after a user reorder shows AI order again.
- The journey path "jumps" on first load as it re-orders after the initial render.
- The committed action (from `activeCommitment`) doesn't match the displayed "next" action after a restart.

**Phase to address:**
User-Driven Ordering phase. Decide persistence strategy (UserDefaults vs. schema) before implementing the ordering logic.

---

### Pitfall 8: Locked Node Bubble Misleads Users About Availability

**What goes wrong:**
The design spec says "all nodes show tap bubbles (including locked/future)" to help users understand the full path. If the bubble on a locked node shows the same CTA ("Start this action" or "Pick this next") as an active/unlocked node, users tap it expecting to be able to do something — and nothing happens, or an error state appears. This creates confusion, especially when user-driven ordering means they expect to be able to pick any action.

**Why it happens:**
The bubble CTA is defined once and reused across all node states. The developer assumes "all nodes show bubbles" means identical bubbles, but the UX intent is "preview info bubbles" for locked nodes, not "action bubbles." The distinction is not enforced at the code level.

**How to avoid:**
Parameterise bubble content by `NodeState`. For `.locked` nodes: show a preview bubble with action name and time estimate, no CTA button — or CTA is "Pick this next" which moves it to next position (user-driven ordering entry point). For `.active` nodes: show the action name + "Start now" CTA opening the detail sheet. For `.completed` nodes: show the completion date or a brief outcome. Encode this in a `BubbleContent` value type computed from `NodeState`.

**Warning signs:**
- Tapping the "Start" CTA on a locked node shows an error or does nothing.
- Users report they didn't know they could pick any action (CTA was too generic to imply choice).
- Locked nodes show an identical bubble to active nodes, removing the locked visual metaphor.

**Phase to address:**
Tap Bubbles on Nodes phase. Spec bubble content per NodeState before implementing bubble view.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Driving bubble show/hide from local `@State` per node | Simple, no ViewModel changes | Zombie bubbles on completion; can't clear all bubbles centrally | Only for purely cosmetic states with no external dismissal conditions |
| Sorting `microActions` array in-place for display order | No new data model needed | Supabase reload re-sorts by `priority`, losing user order | Never — use a parallel display-order array or explicit `displayOrder` property |
| Two separate booleans for congrats + action picker | Quick to add | SwiftUI sheet queue race, unpredictable presentation | Never — use a single enum state |
| Adding congrats case to existing `CelebrationState` enum | Reuses existing machinery | Disrupts carefully-ordered `evaluateCelebrationState` priority logic; planComplete vs. congrats collision | Never — congrats sheet is navigation, not a journey path effect |
| Computing `remainingActions` in picker during view body | Simpler code | Stale data if ViewModel updates during presentation | Never — compute in `onAppear` or via `.task` after sheet presents |
| Identical bubble content for all NodeStates | One view to build | Confuses users about locked vs. actionable nodes; breaks user-driven ordering UX | Never — parameterise by state |

---

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| SwiftUI `.sheet` (multiple) | Presenting second sheet while first is animating in | Model multi-step sheet flow as a single enum; transition within one sheet presenter |
| `nodeState(at:actions:)` global function | Passing raw `microActions` (API order) to this function when display order has been customised | Always pass the display-ordered array, not the raw ViewModel array |
| `MomentumPickerSheet.remainingActions` | Trusting `!$0.isCompleted` alone to exclude just-completed action | Also filter `$0.id != completedActionId` (already coded; verify it runs after ViewModel optimistic update) |
| `justCompletedActionId` unlock animation | Relying on array index `completedIndex + 1` for the newly unlocked node | After user-driven ordering, the next node is at `displayOrder` position, not `completedIndex + 1` |
| UserDefaults ordering persistence | Storing `[UUID]` for display order keyed by `actionPlanId` | Merge on load: map Supabase array by `id`, then sort by stored display-order array; fall back to `priority` if key missing |
| Lottie + two-step sheet | Playing celebration animation in congrats sheet while route to picker is also queued | Ensure Lottie `playbackMode` is set only after the sheet fully presents (`onAppear`, not `task` with 0 delay) |

---

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Action picker re-rendering all rows on every ViewModel publish | Picker list stutters on selection; CPU spikes | Ensure `MicroAction: Hashable` (it is) and use `ForEach(actions, id: \.id)` — avoid `AnyView` wrappers in picker row | Picker lists with 7+ actions and frequent ViewModel publishes |
| Bubble overlays triggering full node re-layout | Frame drops when bubble appears/disappears | Render bubbles with `.overlay(alignment:)` not `GeometryReader`; use `opacity` transitions not `offset` | Visible path with 5+ nodes |
| Repeated `onChange(of: viewModel.microActions)` inside picker | Picker reconstructed on every action update | Use `.task(id: viewModel.completedCount)` for selective reactivity in picker | Any completion that fires while picker is open |
| Sorting array on every SwiftUI body eval | `microActions.sorted(by:)` called O(n log n) on every render | Sort once in `loadActionPlan` and when user reorders; store sorted result in a `@Published var displayOrderedActions` | Plans with 8+ actions and frequent body re-evaluations |

---

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Action picker shown every time the user navigates to the journey path | Picker fatigue; feels like an interruption to resuming work | Show picker only on first visit to a plan AND after each completion; never on return navigation without completion |
| Two-step sheet auto-advances to action picker without user input | Users who want to rest after completing feel pushed | Congrats sheet has an explicit CTA ("Keep the momentum?") to advance to picker; also a "Later" dismiss |
| Action picker pre-selects first item and "I'm on it" is immediately tappable | Users accidentally commit to the wrong action | Require an explicit tap on an action card to select it before the CTA activates; no pre-selection default |
| User reorders actions but the journey path still shows the old node as "active" | Visual confusion — coral active node doesn't match committed action | After user picks an action, immediately re-sort the display array and re-derive NodeState so the chosen action becomes the active node |
| Bubble appears on tap but stays open while user reads | Second tap to dismiss feels like extra work | Bubble auto-dismisses on scroll, on tap-outside, and when the node's detail sheet opens; do not require a separate dismiss gesture |
| Celebration in congrats sheet conflicts with milestone banner | Two celebrations fire simultaneously (milestone banner slides down + congrats sheet appears) | Milestone banner auto-dismisses after 2.5s (existing); ensure congrats sheet delays its presentation by 300ms to let banner complete |

---

## "Looks Done But Isn't" Checklist

- [ ] **User ordering persisted:** Picked action stays in position after app backgrounding and foreground return — verify by picking action B, backgrounding, reopening, confirming action B is still shown as next node.
- [ ] **Bubble cleared on completion:** No bubble remains on a node after that action is marked complete — verify by opening a bubble, opening the detail sheet, marking complete, checking node has no bubble.
- [ ] **Two-step sheet always reachable:** After every non-final action completion, the congrats sheet appears and the "Keep the momentum?" CTA always transitions to the picker — verify with rapid completions (complete 3 actions in quick succession).
- [ ] **No bubble on completed nodes:** Completed nodes show no bubble or show a read-only recap bubble — verify all 3 NodeState types in the simulator.
- [ ] **Picker excludes completed actions:** The just-completed action never appears in the picker list — verify with a unit test on `remainingActions` computed after `confirmCompletion`.
- [ ] **planComplete does not also show congrats sheet:** When the last action is completed, only the full-screen `PlanCompletionView` appears — verify that `PostCompletionSheet` remains `.none` when `celebrationState == .planComplete`.
- [ ] **Locked node CTA does not trigger ActionDetailSheet completion flow:** Tapping "Pick this next" on a locked node reorders only — it does not open the detail sheet or attempt to mark the action complete.
- [ ] **Display order survives loadActionPlan refresh:** A background refresh (e.g., returning from another tab) does not revert the user's custom order — verify by picking an action, navigating to Notes tab, returning, confirming order preserved.

---

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Node state machine broken by ordering | MEDIUM | Add explicit `displayOrder` sort to ViewModel; refactor `nodeState` to take display-ordered array — no data model changes needed |
| Two sheets racing (congrats + picker) | LOW | Merge into `PostCompletionSheet` enum; replace two `.sheet` modifiers with one; congrats view gets an explicit advance CTA |
| Zombie bubbles on completed nodes | LOW | Add `onChange(of: state)` clearing bubble flag; or move bubble state to ViewModel with `clearBubble()` on completion |
| Stale data in action picker | LOW | Ensure picker computes `remainingActions` in `onAppear`/`.task`; add explicit `id != completedActionId` guard |
| User ordering not persisting | LOW-MEDIUM | Add UserDefaults persistence layer in `loadActionPlan` and `selectActionForNext`; no schema change needed |
| CelebrationState collision (planComplete + congrats) | LOW | Move congrats out of `CelebrationState`; use separate `PostCompletionSheet` enum; audit `evaluateCelebrationState` to guard against `.none`-ing `PostCompletionSheet` on planComplete |

---

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| User ordering breaks node state machine | User-Driven Ordering phase | Two `.active` nodes never appear simultaneously; picked action becomes the active node |
| Two sheets racing | Two-Step Completion Sheet phase | Rapid completion x3: congrats sheet + picker appear reliably every time |
| Bubble tap conflicts with node tap | Tap Bubbles phase | CTA in bubble always fires correct action; node tap only triggers when bubble is not showing |
| CelebrationState enum collision | Two-Step Completion Sheet phase | Last action completion shows only `PlanCompletionView`, never a congrats half-sheet simultaneously |
| Action picker stale data | Action Picker phase | Unit test: `remainingActions` excludes just-completed action immediately after `confirmCompletion` |
| Zombie bubbles | Tap Bubbles phase | Complete an action via bubble CTA: no bubble remains on the completed node |
| Order not persisted | User-Driven Ordering phase | Background + foreground the app after picking: custom order preserved |
| Locked bubble misleads user | Tap Bubbles phase | Locked node bubble shows no "complete" CTA; tapping it offers "pick this next" or info only |

---

## Sources

- Codebase analysis: `ActionPlanViewModel.swift` — `evaluateCelebrationState`, `nodeState(at:actions:)`, `MomentumPickerSheet.remainingActions` (2026-03-19)
- Codebase analysis: `ActionPlanDetailView.swift` — three concurrent `.sheet()` presenters and their boolean conditions (2026-03-19)
- Codebase analysis: `JourneyNodeView.swift` — `nodeState` global function relying on `firstIndex(where: !isCompleted)` (2026-03-19)
- PROJECT.md decision log: "No Supabase schema changes" constraint for v1.1; "user-chosen action slots into next node position" ordering spec (2026-03-19)
- SwiftUI sheet presentation queue limitations — known iOS 16/17 issue with multiple sheet modifiers presenting in rapid succession: community threads (SwiftUI Forum, Hacking with Swift issues tracker)
- Duolingo UX pattern analysis: bubble tooltips on nodes (Duolingo app, 2025) — bubbles are non-blocking, state-dependent, dismissed on any interaction outside the bubble
- SwiftUI gesture priority documentation — `.highPriorityGesture`, `.simultaneousGesture` interaction with `Button` (Apple Developer Documentation, SwiftUI gestures)
- UserDefaults persistence for transient ordering — precedent in iOS task management apps (Things 3, OmniFocus) for local ordering that does not require server sync

---
*Pitfalls research for: SwiftUI gamified journey app — v1.1 action picker, tap bubbles, user-driven ordering, two-step completion sheet (Abimo)*
*Researched: 2026-03-19*
