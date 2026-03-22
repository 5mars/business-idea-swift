# Architecture Research

**Domain:** Gamified task completion UX — v1.1 integration: action picker, tap bubbles, user-driven ordering, two-step completion sheet
**Researched:** 2026-03-19
**Confidence:** HIGH (all conclusions drawn from reading actual source files, not inferred)

---

## Context: What Already Exists

This research covers v1.1 integration only. The v1.0 architecture (JourneyPathView, JourneyNodeView, CelebrationState machine, HapticEngine, AnimationPolicy) is fully shipped. The findings below describe exactly how each new feature grafts onto existing components.

Existing component inventory relevant to v1.1:

| Existing File | Role |
|---|---|
| `ActionPlanViewModel.swift` | Single source of truth. `@Published microActions: [MicroAction]`, `celebrationState: CelebrationState`, `justCompletedActionId: UUID?`, `showMomentumPicker: Bool`, `completingActionId: UUID?` |
| `JourneyPathView.swift` | Renders scrollable node list. Passes `selectedAction` binding up to `ActionPlanDetailView` via `@Binding`. Calls `nodeState(at:actions:)` free function for each node. |
| `JourneyNodeView.swift` | Renders one node circle + connecting line. Currently: tap fires `onTap` closure which sets `selectedAction`. Has `celebrationState` param for inline confetti. |
| `ActionPlanDetailView.swift` | Root view. Owns `@State var selectedAction: MicroAction?`. Drives three `.sheet` modifiers: `ActionDetailSheet` (item binding), `CommitmentSheet` (showCommitmentPicker), and `MomentumPickerSheet` (showMomentumPicker). |
| `ActionDetailSheet.swift` | Bottom sheet showing action detail + "Mark Complete" button. Calls `viewModel.toggleMicroAction` then dismisses. |
| `CommitmentSheet.swift` | Picker showing up to 3 incomplete actions. User picks one and commits. Driven by `viewModel.showCommitmentPicker`. |
| `CelebrationState` enum | `.idle`, `.inlineConfetti(actionId:)`, `.milestone(count:)`, `.planComplete`. Lives in `ActionPlanViewModel.swift`. |
| `PlanCompletionView.swift` | Full-screen overlay for `.planComplete`. Has a placeholder `Color.clear.frame(height: 48)` marked "future 'What's next' feature (CELB-04 deferred)". |
| `nodeState(at:actions:)` free function | In `JourneyNodeView.swift`. Returns `.locked`, `.active`, or `.completed`. Currently: only the first incomplete action is `.active`; all others are `.locked`. |

---

## System Overview: v1.1 Layer Changes

```
┌──────────────────────────────────────────────────────────────────────┐
│                          View Layer                                   │
│                                                                       │
│  ┌────────────────────────┐    ┌───────────────────────────────────┐ │
│  │   JourneyPathView      │    │  ActionPlanDetailView              │ │
│  │   (MODIFIED)           │    │  (MODIFIED — additional sheets)    │ │
│  │                        │    │                                   │ │
│  │  ForEach node          │    │  .sheet(item: $selectedAction)    │ │
│  │    JourneyNodeView     │    │  .sheet(isPresented: showCommit)  │ │
│  │    + NodeBubbleView    │    │  .sheet(isPresented: showMomentum)│ │
│  │      (NEW)             │    │  .sheet(isPresented: showCongrats)│ │
│  └───────────┬────────────┘    │  .sheet(isPresented: showPicker)  │ │
│              │                 └───────────┬───────────────────────┘ │
│              │                             │                          │
│  ┌───────────▼────────────┐   ┌────────────▼──────────────────────┐ │
│  │   JourneyNodeView      │   │  ActionPickerSheet (NEW)           │ │
│  │   (MODIFIED)           │   │  CongratsHalfSheet (NEW)           │ │
│  │                        │   │  MomentumPickerSheet (NEW?)        │ │
│  │   onTap → show bubble  │   │  PlanCompletionView (MODIFIED)     │ │
│  │   bubble onCTA → sheet │   └───────────────────────────────────┘ │
│  └────────────────────────┘                                          │
└──────────────────────────────────────────────────────────────────────┘
                          │ @ObservedObject
┌─────────────────────────▼────────────────────────────────────────────┐
│                       ViewModel Layer                                 │
│                                                                       │
│  ActionPlanViewModel (MODIFIED)                                       │
│                                                                       │
│  EXISTING (keep as-is):                                               │
│    @Published microActions: [MicroAction]                             │
│    @Published celebrationState: CelebrationState                      │
│    @Published justCompletedActionId: UUID?                            │
│    @Published showCommitmentPicker: Bool                              │
│    @Published showMomentumPicker: Bool                                │
│    @Published completingActionId: UUID?                               │
│                                                                       │
│  NEW:                                                                 │
│    @Published activeNodeId: UUID?   ← which node has bubble open     │
│    @Published showCongratsSheet: Bool                                 │
│    @Published showActionPicker: Bool                                  │
│    var orderedActions: [MicroAction]  ← reordered by user choice     │
│    func pickAction(_ action: MicroAction)                             │
│    func dismissCongrats()                                             │
│                                                                       │
└──────────────────────────────────────────────────────────────────────┘
```

---

## Component Boundaries: New vs Modified

### New Components

#### `NodeBubbleView`
**What it is:** A callout bubble that appears above (or below) a node when tapped, showing the action name and a CTA button ("Start" / "Do this next").

**Where it lives:** `Views/ActionPlan/Journey/NodeBubbleView.swift`

**Integration:** Rendered as an `.overlay` on `JourneyNodeView`, similar to how `InlineConfettiView` is overlaid today. Visibility is controlled by comparing `action.id` against `viewModel.activeNodeId`.

**Communicates with:**
- Parent (`JourneyPathView`) reads `viewModel.activeNodeId` and passes it down to each node via a binding or direct param
- Tapping the CTA sets `selectedAction` (opens `ActionDetailSheet`) or calls `viewModel.pickAction(_:)` depending on context

#### `ActionPickerSheet`
**What it is:** A full-height sheet showing all incomplete actions so the user can choose what to do next. Shows after first load and after each completion.

**Where it lives:** `Views/ActionPlan/ActionPickerSheet.swift`

**Integration:** Presented from `ActionPlanDetailView` via `.sheet(isPresented: $viewModel.showActionPicker)`. Replaces or supplements `CommitmentSheet` — these two are structurally similar but serve different moments (commitment = time-scheduled promise; picker = immediate ordering choice).

**Communicates with:**
- `ActionPlanViewModel.pickAction(_:)` — reorders `microActions` array
- Dismisses via `viewModel.showActionPicker = false`

#### `CongratsHalfSheet`
**What it is:** A half-sheet shown immediately after an action is marked complete. Shows a celebration animation and a "Keep the momentum?" prompt that transitions to `ActionPickerSheet`.

**Where it lives:** `Views/ActionPlan/Celebration/CongratsHalfSheet.swift`

**Integration:** Presented from `ActionPlanDetailView` via `.sheet(isPresented: $viewModel.showCongratsSheet)`. Replaces the current `showMomentumPicker` → `MomentumPickerSheet` flow. After the user taps "Keep going", `CongratsHalfSheet` dismisses and `viewModel.showActionPicker` is set to `true`.

**Communicates with:**
- `ActionPlanViewModel.dismissCongrats()` — dismisses and optionally chains to picker
- Reads `viewModel.completingActionId` to show the completed action's name/emoji

### Modified Components

#### `JourneyNodeView` (modified)
**Current behavior:** Tap fires `onTap` closure which sets `selectedAction` in `JourneyPathView`. `ActionDetailSheet` appears immediately.

**New behavior:** Tap reveals `NodeBubbleView` instead of immediately opening the sheet. The bubble shows the action name and a "Start" / "Do this" CTA. Tapping the CTA opens `ActionDetailSheet`. Tapping elsewhere dismisses the bubble.

**Change required:** Replace the direct `onTap: { selectedAction = action }` pattern with a two-step: `onTap: { viewModel.activeNodeId = action.id }`. The CTA inside `NodeBubbleView` then sets `selectedAction`.

**NodeState impact:** Currently `nodeState(at:actions:)` returns `.locked` for all nodes except the first incomplete one. User-driven ordering requires ALL incomplete actions to be `.active` (tappable and showing their emoji). The `.locked` state should be reserved for truly locked mechanics — v1.1 has none, so this free function changes to return `.active` for all incomplete nodes.

#### `ActionPlanDetailView` (modified)
**Current sheet drivers:**

```swift
.sheet(item: $selectedAction)       // ActionDetailSheet
.sheet(isPresented: $showCommitmentSheet)  // CommitmentSheet (local state)
.sheet(isPresented: $viewModel.showCommitmentPicker)  // CommitmentSheet (VM driven)
.sheet(isPresented: $viewModel.showMomentumPicker)    // MomentumPickerSheet
```

**New sheet drivers to add:**

```swift
.sheet(isPresented: $viewModel.showCongratsSheet)  // CongratsHalfSheet
.sheet(isPresented: $viewModel.showActionPicker)   // ActionPickerSheet
```

The existing `showMomentumPicker` sheet may be retired or replaced by the new `showCongratsSheet` → `showActionPicker` two-step flow. Decision at build time based on whether `MomentumPickerSheet` content is reused.

#### `ActionPlanViewModel` (modified)
**Current completion flow:**

```
toggleMicroAction(isCompleted: true)
  → confirmCompletion()
  → evaluateCelebrationState()   [sets celebrationState]
  → completingActionId = id
  → showMomentumPicker = true    [if remaining actions exist]
```

**New completion flow:**

```
toggleMicroAction(isCompleted: true)
  → confirmCompletion()
  → evaluateCelebrationState()   [unchanged — inline confetti + milestone still fire]
  → completingActionId = id
  → showCongratsSheet = true     [replaces showMomentumPicker]
```

`showMomentumPicker` and `MomentumPickerSheet` can be removed once `CongratsHalfSheet` + `ActionPickerSheet` replace the flow.

**User-driven ordering:**

`microActions` is currently the authoritative ordered array. Its order is used to determine `NodeState` (first incomplete = `.active`). For user-driven ordering, the ViewModel needs a way to move a chosen action to the "next" position.

Recommended approach: add `var displayOrder: [UUID]` (an array of action IDs in display order) and derive display ordering from it. Alternatively, add a `displayIndex` field to a local wrapper — but that requires a wrapper type.

Simplest correct approach: keep `microActions` as the Supabase-fetched source of truth (ordered by `priority`). Add a separate `@Published var userOrderedIds: [UUID]` that starts empty (meaning "use default order") and is updated when the user picks an action. `orderedActions` becomes a computed property that applies `userOrderedIds` when set, otherwise falls back to `microActions` order.

```swift
// In ActionPlanViewModel:
@Published var userOrderedIds: [UUID] = []

var orderedActions: [MicroAction] {
    guard !userOrderedIds.isEmpty else { return microActions }
    let idOrder = userOrderedIds.enumerated().reduce(into: [UUID: Int]()) { $0[$1.element] = $1.offset }
    return microActions.sorted { (idOrder[$0.id] ?? Int.max) < (idOrder[$1.id] ?? Int.max) }
}

func pickAction(_ action: MicroAction) {
    // Move chosen action to first incomplete slot
    var ids = userOrderedIds.isEmpty
        ? microActions.map(\.id)
        : userOrderedIds
    ids.removeAll { $0 == action.id }
    let firstIncompleteIdx = ids.firstIndex(where: { id in
        microActions.first(where: { $0.id == id })?.isCompleted == false
    }) ?? ids.endIndex
    ids.insert(action.id, at: firstIncompleteIdx)
    userOrderedIds = ids
    showActionPicker = false
    HapticEngine.selection()
}
```

`JourneyPathView` and `nodeState(at:actions:)` must be updated to use `viewModel.orderedActions` instead of `viewModel.microActions`.

#### `PlanCompletionView` (modified)
**Current state:** Has a `Color.clear.frame(height: 48)` placeholder for "What's next" (CELB-04 deferred). The "Done" button dismisses the view.

**v1.1 change:** The two-step completion sheet (`CongratsHalfSheet` → `ActionPickerSheet`) applies to *per-action* completions, not plan completion. `PlanCompletionView` is the end state when all actions are done — it stays full-screen, no picker needed. The placeholder can remain deferred.

No functional change to `PlanCompletionView` is required for v1.1.

---

## Data Flow

### First Visit Flow (Action Picker on Load)

```
ActionPlanDetailView.task { await viewModel.loadActionPlan() }
    ↓
loadActionPlan() completes, microActions populated
    ↓
ViewModel checks: activeCommitment == nil && completedCount == 0
    → showActionPicker = true    [first visit trigger]
    ↓
ActionPickerSheet appears
User taps an action → viewModel.pickAction(action)
    → userOrderedIds updated (chosen action moves to slot 0)
    → showActionPicker = false
    ↓
JourneyPathView re-renders using orderedActions
    → chosen action is now at top node, shows .active state
    → ScrollView auto-scrolls to it (existing .task scroll logic)
```

### Node Tap → Bubble → CTA Flow

```
User taps node circle
    ↓
JourneyNodeView.onTap fires
    → viewModel.activeNodeId = action.id
    ↓
NodeBubbleView appears over that node (overlay driven by activeNodeId == action.id)
    → Shows: action.text + CTA button ("Start" / "Do this")
    ↓
User taps CTA
    → selectedAction = action    [sets ActionDetailSheet binding]
    → viewModel.activeNodeId = nil    [dismisses bubble]
    ↓
ActionDetailSheet appears (existing sheet flow, unchanged)
    ↓
User taps "Mark Complete"
    → dismiss() + viewModel.toggleMicroAction(id:, isCompleted: true)
    [existing completion flow continues from here]

User taps outside bubble
    → viewModel.activeNodeId = nil    [dismiss on background tap]
```

### Completion → Two-Step Sheet Flow

```
toggleMicroAction(id:, isCompleted: true)
    ↓
confirmCompletion() [optimistic update, Supabase persist]
evaluateCelebrationState() [inlineConfetti or milestone fires as before]
    ↓
completingActionId = id
showCongratsSheet = true
    ↓
CongratsHalfSheet appears (.medium detent)
    → Lottie/confetti animation plays
    → Shows completed action name + "Keep the momentum?" prompt
    ↓
User taps "Keep going"
    → viewModel.dismissCongrats()
      → showCongratsSheet = false
      → showActionPicker = true (if remaining actions exist)
    ↓
ActionPickerSheet appears (.large detent)
    → Shows all incomplete actions
    → User picks next → viewModel.pickAction(action)
    → showActionPicker = false
    ↓
JourneyPathView: chosen action is now in next node slot
```

### State Management Summary

```
ActionPlanViewModel @Published state → driven views:

  microActions          → JourneyPathView (all nodes)
  orderedActions        → JourneyPathView (display order) [NEW computed]
  celebrationState      → ActionPlanDetailView ZStack overlays [unchanged]
  justCompletedActionId → JourneyNodeView unlock animation [unchanged]
  activeNodeId          → JourneyNodeView bubble visibility [NEW]
  showCongratsSheet     → ActionPlanDetailView sheet [NEW, replaces showMomentumPicker]
  showActionPicker      → ActionPlanDetailView sheet [NEW]
  completingActionId    → CongratsHalfSheet (completed action display) [unchanged field]
  showCommitmentPicker  → CommitmentSheet [unchanged]
```

---

## Recommended Project Structure (v1.1 additions)

```
Abimo/
├── ViewModels/
│   └── ActionPlanViewModel.swift       # MODIFIED: add activeNodeId, showCongratsSheet,
│                                       #   showActionPicker, userOrderedIds, orderedActions,
│                                       #   pickAction(), dismissCongrats()
├── Views/
│   ├── ActionPlan/
│   │   ├── ActionPlanDetailView.swift  # MODIFIED: add 2 new .sheet modifiers
│   │   ├── Journey/
│   │   │   ├── JourneyPathView.swift   # MODIFIED: use orderedActions, pass activeNodeId
│   │   │   ├── JourneyNodeView.swift   # MODIFIED: tap → bubble instead of direct sheet
│   │   │   └── NodeBubbleView.swift    # NEW: callout bubble with action name + CTA
│   │   ├── ActionPickerSheet.swift     # NEW: full list of incomplete actions for user choice
│   │   └── Celebration/
│   │       ├── CongratsHalfSheet.swift # NEW: post-completion half-sheet (replaces MomentumPickerSheet)
│   │       └── PlanCompletionView.swift # unchanged
```

### What Does NOT Change

- `ActionDetailSheet.swift` — no changes needed; still opens from `selectedAction` binding
- `CommitmentSheet.swift` — no changes; still driven by `showCommitmentPicker`
- `InlineConfettiView.swift`, `MilestoneBannerView.swift` — no changes
- `HapticEngine.swift`, `AnimationPolicy.swift`, `ActionIconMapper.swift` — no changes
- All Models, Services, Utilities — no changes
- Supabase schema — no changes; `userOrderedIds` is client-only state, not persisted

---

## Architectural Patterns

### Pattern 1: Bubble Visibility via Shared `activeNodeId`

**What:** A single `@Published var activeNodeId: UUID?` on the ViewModel controls which node (if any) shows its bubble. Only one bubble can be visible at a time — setting a new ID implicitly dismisses the previous one.

**When to use:** Any "one-at-a-time" popover-style UI where SwiftUI's built-in popover is too heavy. Avoids managing multiple `@State var showBubble` per node.

**Trade-offs:** The ViewModel holds a UI-selection concept. Acceptable because "which node is tapped" is shared across views (JourneyPathView needs to close it on background tap; ActionDetailSheet CTA needs to clear it).

**Example:**
```swift
// JourneyNodeView tap:
Button { viewModel.activeNodeId = action.id } label: { ... }
    .overlay {
        if viewModel.activeNodeId == action.id {
            NodeBubbleView(action: action, onCTA: {
                viewModel.activeNodeId = nil
                selectedAction = action
            })
        }
    }

// JourneyPathView background tap to dismiss:
.onTapGesture { viewModel.activeNodeId = nil }
```

### Pattern 2: User Ordering via Client-Side `userOrderedIds`

**What:** The Supabase `microActions` array (ordered by `priority`) is never mutated by user ordering. Instead, `userOrderedIds: [UUID]` is a client-only array that overrides display order. `orderedActions` is a computed property that applies the override.

**When to use:** When persistence of user ordering is not required (or deferred). The ordering choice resets on app restart, which is acceptable given actions are typically completed in a single session.

**Trade-offs:** User ordering is lost on restart. If persistence is later required, `userOrderedIds` can be serialized to `UserDefaults` keyed by `actionPlanId` without any Supabase changes.

**Example:**
```swift
var orderedActions: [MicroAction] {
    guard !userOrderedIds.isEmpty else { return microActions }
    let rank = userOrderedIds.enumerated().reduce(into: [UUID: Int]()) { $0[$1.element] = $1.offset }
    return microActions.sorted { (rank[$0.id] ?? Int.max) < (rank[$1.id] ?? Int.max) }
}
```

### Pattern 3: Two-Step Sheet Chaining via Sequential `@Published` Flags

**What:** `CongratsHalfSheet` is dismissed first, then `showActionPicker` is set to `true`. SwiftUI processes one sheet presentation per run loop iteration — setting both simultaneously can cause the second sheet to be silently dropped.

**When to use:** Any time two `.sheet` modifiers on the same view need to chain (one dismisses, other presents).

**Trade-offs:** A small `Task.sleep` or `DispatchQueue.main.asyncAfter` may be needed between dismiss and present to let SwiftUI settle. Test on device — this is a known SwiftUI timing issue.

**Example:**
```swift
func dismissCongrats() {
    showCongratsSheet = false
    let hasRemaining = microActions.contains(where: { !$0.isCompleted })
    if hasRemaining {
        // Give SwiftUI one run loop to process the dismiss before presenting
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            self?.showActionPicker = true
        }
    }
}
```

### Pattern 4: `nodeState` Update for User-Driven Ordering

**What:** The current `nodeState(at:actions:)` free function marks only the first incomplete action as `.active`. For user-driven ordering, ALL incomplete actions must be tappable so users can open their bubble and choose.

**Change:** Return `.active` for any incomplete action. Remove the `.locked` case from the v1.1 render path (nodes are only "locked" in a future game-mechanic sense, not in v1.1).

**Example:**
```swift
// v1.0 (current):
func nodeState(at index: Int, actions: [MicroAction]) -> NodeState {
    let action = actions[index]
    if action.isCompleted { return .completed }
    let firstIncompleteIndex = actions.firstIndex(where: { !$0.isCompleted })
    if firstIncompleteIndex == index { return .active }
    return .locked   // <-- blocks all non-first nodes
}

// v1.1:
func nodeState(at index: Int, actions: [MicroAction]) -> NodeState {
    actions[index].isCompleted ? .completed : .active
    // .locked removed — all incomplete actions are tappable
}
```

---

## Integration Points

### Internal Boundaries

| Boundary | Communication | Change in v1.1 |
|---|---|---|
| `JourneyPathView` ↔ `ActionPlanViewModel` | `@ObservedObject`, reads `orderedActions`, writes `activeNodeId` | Use `orderedActions` instead of `microActions` directly |
| `JourneyNodeView` ↔ `JourneyPathView` | `onTap` closure, `activeNodeId` param | `onTap` sets `activeNodeId`; new `activeNodeId` param drives bubble visibility |
| `NodeBubbleView` ↔ `JourneyNodeView` | Overlay; `onCTA` closure | New component; CTA closure sets `selectedAction` in parent |
| `ActionPickerSheet` ↔ `ActionPlanViewModel` | `@ObservedObject`; calls `pickAction(_:)` | New sheet; `showActionPicker` is the trigger |
| `CongratsHalfSheet` ↔ `ActionPlanViewModel` | Reads `completingActionId`; calls `dismissCongrats()` | Replaces `MomentumPickerSheet`; `showCongratsSheet` is the trigger |
| `ActionPlanDetailView` ↔ `ActionPlanViewModel` | Two new `.sheet(isPresented:)` modifiers added | `showCongratsSheet`, `showActionPicker` |
| `PlanCompletionView` ↔ `ActionPlanViewModel` | Unchanged — `.planComplete` state, `onDismiss` callback | No change |

### External Services

No new external services in v1.1. Supabase, Lottie, and Vortex dependencies are unchanged. User ordering is client-only state.

---

## Suggested Build Order

Dependencies flow bottom-up. Each step is unblocked once the prior step compiles.

1. **Update `nodeState(at:actions:)` in `JourneyNodeView.swift`**
   Remove `.locked` return for non-first incomplete nodes. All incomplete nodes become `.active`. This is a one-line change and unblocks bubble UI.

2. **Add `userOrderedIds`, `orderedActions`, `activeNodeId`, `showCongratsSheet`, `showActionPicker`, `pickAction()`, `dismissCongrats()` to `ActionPlanViewModel`**
   Pure additions to the ViewModel — no deletions yet. This unblocks all downstream view work.

3. **Build `NodeBubbleView`**
   Pure UI component taking `action: MicroAction`, `onCTA: () -> Void`. No ViewModel coupling. Styled as a callout bubble with action name + CTA label. Verify it positions correctly relative to zigzag offset nodes.

4. **Modify `JourneyNodeView` to show `NodeBubbleView`**
   Change `onTap` to set `activeNodeId`. Add `activeNodeId: UUID?` param (or binding). Overlay `NodeBubbleView` when `activeNodeId == action.id`. Tap on bubble CTA sets `selectedAction` and clears `activeNodeId`.

5. **Modify `JourneyPathView` to use `orderedActions`**
   Replace all references to `viewModel.microActions` in `ForEach` with `viewModel.orderedActions`. Pass `viewModel.activeNodeId` down to each `JourneyNodeView`. Add background tap gesture to clear `activeNodeId`.

6. **Build `ActionPickerSheet`**
   Takes `viewModel: ActionPlanViewModel`. Shows all `viewModel.microActions.filter { !$0.isCompleted }`. Each row taps → `viewModel.pickAction(action)`. Style similar to `CommitmentSheet` but shows all actions, not just top 3, and no schedule toggle.

7. **Build `CongratsHalfSheet`**
   Takes `viewModel: ActionPlanViewModel`. Shows completed action info (`completingActionId` → look up in `microActions`). Celebration animation (reuse Lottie/Vortex from existing celebration components). CTA "Keep the momentum?" → calls `viewModel.dismissCongrats()`. Presented at `.medium` detent.

8. **Modify `ActionPlanViewModel.toggleMicroAction`**
   Replace `showMomentumPicker = true` with `showCongratsSheet = true`. Remove `showMomentumPicker` and `MomentumPickerSheet` references.

9. **Wire new sheets into `ActionPlanDetailView`**
   Add `.sheet(isPresented: $viewModel.showCongratsSheet)` and `.sheet(isPresented: $viewModel.showActionPicker)`. Remove `showMomentumPicker` sheet. Add first-visit trigger in `.task` (after `loadActionPlan`) to set `showActionPicker = true` when no actions are completed yet.

10. **Delete `MomentumPickerSheet` (or repurpose)**
    If `MomentumPickerSheet` exists, delete it once `CongratsHalfSheet` + `ActionPickerSheet` fully replace its behavior. Confirm no other references before deleting.

---

## Anti-Patterns

### Anti-Pattern 1: Opening `ActionDetailSheet` Directly on Node Tap

**What people do:** Keep `onTap: { selectedAction = action }` unchanged, skipping the bubble step.

**Why it's wrong:** The bubble is the v1.1 feature. Without it, users cannot see the action name before committing to the detail sheet. The two-step (bubble preview → sheet) is the UX requirement.

**Do this instead:** Tap reveals bubble. Bubble CTA opens sheet. Tapping elsewhere dismisses bubble.

### Anti-Pattern 2: Mutating `microActions` Order for User Picks

**What people do:** Sort or reorder `microActions` array directly when user picks an action.

**Why it's wrong:** `microActions` is the Supabase-fetched array. Sorting it means the next `loadActionPlan()` call re-fetches in `priority` order and discards the user's pick. It also makes optimistic updates and rollback logic fragile.

**Do this instead:** Keep `microActions` as the source-of-truth fetch result. Use `userOrderedIds` + `orderedActions` computed property to apply display ordering without mutating the backing store.

### Anti-Pattern 3: Chaining Sheets with Simultaneous Flag Sets

**What people do:** `showCongratsSheet = false; showActionPicker = true` in the same synchronous call.

**Why it's wrong:** SwiftUI may process both flags in the same render pass and silently drop the second sheet presentation, leaving the user stuck on the dismissed state.

**Do this instead:** Use a brief `DispatchQueue.main.asyncAfter(deadline: .now() + 0.05)` between dismiss and present. This forces SwiftUI to process the dismiss transition before attempting the next presentation.

### Anti-Pattern 4: Showing Bubble via `@State` Inside `JourneyNodeView`

**What people do:** Each `JourneyNodeView` tracks `@State var showBubble = false`.

**Why it's wrong:** If the user taps a second node while a bubble is open, both bubbles would appear simultaneously (no mutual exclusion). Closing requires the user to tap the already-open node again, which is unintuitive.

**Do this instead:** Single `activeNodeId: UUID?` on the ViewModel. Setting any node's ID implicitly clears all other bubbles.

---

## Sources

- `ActionPlanViewModel.swift` — actual source, read 2026-03-19
- `JourneyNodeView.swift` — actual source, read 2026-03-19
- `JourneyPathView.swift` — actual source, read 2026-03-19
- `ActionPlanDetailView.swift` — actual source, read 2026-03-19
- `ActionDetailSheet.swift` — actual source, read 2026-03-19
- `PlanCompletionView.swift` — actual source, read 2026-03-19
- `CommitmentSheet.swift` — actual source, read 2026-03-19
- `ActionPlan.swift` (models) — actual source, read 2026-03-19
- SwiftUI sheet chaining known issue: community-documented timing requirement for sequential sheet presentations — confirmed in multiple sources (no official Apple documentation; pattern is broadly used)

---
*Architecture research for: v1.1 Actions Flow UX — Abimo*
*Researched: 2026-03-19*
