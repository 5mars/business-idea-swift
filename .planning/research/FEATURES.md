# Feature Research

**Domain:** Gamified micro-action completion UX — v1.1 Actions Flow UX (action picker, tap bubbles, user ordering, two-step completion)
**Researched:** 2026-03-19
**Confidence:** HIGH (tap bubble UX pattern), HIGH (action picker patterns), MEDIUM (user-driven ordering), HIGH (two-step celebration flow)

---

## Context: What Already Exists

All features below are **net-new** for v1.1. The following are already shipped in v1.0 and must not be re-implemented:

- Journey path: vertical zigzag node map (`JourneyPathView`, `JourneyNodeView`)
- Node states: locked / active / completed with animated color transitions
- `CelebrationState` enum: `.idle`, `.inlineConfetti`, `.milestone`, `.planComplete`
- Inline confetti burst on node (Vortex)
- Milestone banners at 3, 5, 7 actions
- Full-screen plan completion overlay (`PlanCompletionView`)
- `MomentumPickerSheet`: post-completion "Keep the momentum?" sheet with action list + commit CTA (already exists in `CompletionReflectionSheet.swift`)
- `CommitmentSheet`: pre-action commitment picker
- Haptic engine and AnimationPolicy wrappers
- Streak tracking, nudge system, action detail sheets

---

## Feature Landscape

### Table Stakes (Users Expect These)

Features that are non-negotiable given that the milestone scope promises them. Missing these means the v1.1 milestone is incomplete.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Tap-to-reveal bubble on all journey nodes | Duolingo's own pattern: tapping a path node shows a tooltip/callout above it with the lesson name and a Start CTA — users who have used Duolingo expect this exact interaction | MEDIUM | Callout bubble anchored above the tapped node circle; shows action name + time estimate + "Start" button; dismissed on outside tap or on Start. Pure SwiftUI overlay with `@State var expandedNodeId`. No new dependencies needed. |
| Action picker screen (first-visit + after each completion) | Users arriving at a plan need to understand what actions exist and pick one — the current "auto-lock everything except node 0" flow removes agency | MEDIUM | Full list of all actions for the plan; radio-select UX matching existing `MomentumPickerSheet` style; triggered on first visit and replaced by congrats-sheet flow after completions. Reuses existing `MomentumPickerSheet` card component. |
| User-driven action ordering (chosen action becomes next active) | Users resist linear lock-step ordering when their context or priorities change; apps that force order get abandoned when the "next" action is blocked in real life | MEDIUM | "Pick next" changes which action is `active`; rest keeps relative order. Requires a `displayOrder` or `userPickedId` field in ViewModel state — no Supabase schema change needed (client-side reordering of the `microActions` array). |
| Congrats half-sheet after marking done | Every gamified app inserts a celebratory moment between completion and next action — the current flow goes straight to `MomentumPickerSheet` without a pause | MEDIUM | Half-sheet (`.medium` detent) with Lottie or SwiftUI animation + positive copy + "Next" button that transitions to the action picker. Two distinct steps: step 1 = congrats, step 2 = picker. Requires sequencing sheet presentation. |
| "What's next?" flow after congrats | The two-step completion flow ends with the user picking their next action — "Keep the momentum?" sheet already exists but needs to be wired as step 2 of the congrats flow | LOW | `MomentumPickerSheet` already exists. Needs to be triggered as a chained presentation: congrats sheet → user taps "Keep going" → picker sheet. No new UI required; coordination logic only. |

---

### Differentiators (Competitive Advantage)

Features that are not required but increase delight, orientation, and completion rates specifically for Abimo's use case.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Bubble shows action type emoji + time estimate | The bubble gives users enough context to decide "yes I want to do this now" before opening the full detail sheet — reduces "open, close, open again" friction | LOW | `ActionIconMapper.icon(for:).emoji` already available. Bubble layout: emoji + action title (2-line max) + "⏱ Xmin" chip + "Start" button. |
| Locked node bubble with "complete [action name] first" nudge | Users who tap locked nodes get confused by the padlock with no explanation — a bubble explaining the prerequisite reduces support friction | LOW | Same bubble component, different content for `.locked` state. "Finish '[prev action]' to unlock this." Copy only, no CTA. |
| Picker shows recommended action (pre-selected) | Reduces decision fatigue — user can accept the recommendation with one tap, or override it | LOW | Pre-select the first uncompleted action (existing `nextRecommendedAction` computed var). Already done in `MomentumPickerSheet.onAppear`. Extend to initial `ActionPickerScreen`. |
| Ordered persistence via local sort (no backend change) | User's "pick next" choice should survive a session reload — achieved by reordering the `microActions` array in ViewModel and reflecting in journey path | MEDIUM | Store a `[UUID]` display order in UserDefaults keyed by `planId`. No Supabase schema change. Re-applied on `loadActionPlan`. |
| Congrats animation reuses existing Lottie assets | Avoids adding new bundle assets; keeps celebration consistent with existing milestones | LOW | `PlanCompletionView` already uses Lottie trophy. The congrats sheet can use a simpler SwiftUI scale + confetti (Vortex) rather than a new Lottie file. |
| Smooth sheet-to-sheet transition (congrats → picker) | Jarring sheet dismiss + new sheet present creates visual discontinuity; a `NavigationStack` inside the sheet or a `ZStack` state transition is smoother | MEDIUM | Present a single sheet, use internal `@State var step: CongratsStep` to animate between congrats content and picker content within the same sheet. Avoids iOS double-sheet timing bugs. |

---

### Anti-Features (Commonly Requested, Often Problematic)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Full-screen action picker (every completion) | "Show all options" feels thorough | A full-screen picker on every action completion interrupts the flow — users want to complete the next action, not re-evaluate the whole plan | Half-sheet picker (`.large` detent at most), pre-selecting the recommended next action so the happy path is one tap |
| Drag-to-reorder on the journey path | "True" user ordering implies a sortable list | Drag reorder on a visual zigzag path is an unsolved UX problem (spatial metaphor breaks if nodes jump positions on drag); adds complexity with no clear visual language | Action picker as the reorder mechanism: "pick next" changes the active node without moving completed or locked nodes |
| Animated confetti on the congrats sheet AND inline | More celebration = more delight (assumed) | Confetti in a sheet on top of confetti in the background creates visual noise and can cause stutter on older devices | One confetti source per moment: inline confetti on node (already built), no additional confetti in the congrats sheet — use a simpler Lottie or scale animation instead |
| AI-suggested "what to do next" (edge function) | Intelligent recommendation feels premium | `"What's next" edge function` explicitly deferred — Supabase not ready; adding this blocks the milestone on backend work | Client-side recommendation using `nextRecommendedAction` (first incomplete action). Edge function deferred to v1.2. |
| Dismiss-and-re-open picker on "Later" | User might want to come back to the picker | Storing picker state across sessions adds complexity; "Later" should just dismiss — the nudge system already re-surfaces commitment prompts | "Later" = plain dismiss. The nudge system handles re-engagement. |
| XP or points shown in congrats sheet | Feels more game-like | Already documented as an anti-feature — no economy to spend points in | Streak increment + completed count in the congrats sheet summary instead |

---

## Feature Dependencies

```
Action Picker Screen
    └──requires──> MicroAction list (already in ViewModel.microActions)
    └──requires──> ActionIconMapper (already built)
    └──reuses──> MomentumPickerSheet card component (already built)
    └──enhances──> User-driven ordering (picker is the reorder mechanism)

Tap-to-reveal node bubble
    └──requires──> JourneyNodeView (already built — add overlay state)
    └──requires──> ActionIconMapper emoji (already built)
    └──conflicts──> ActionDetailSheet on tap (bubble replaces direct sheet open)
        → resolution: bubble "Start" button opens the detail sheet

User-driven ordering
    └──requires──> Action Picker Screen (picker is how user signals "next")
    └──requires──> Local sort persistence (UserDefaults keyed by planId)
    └──requires──> nodeState() function update (active = user-picked OR first incomplete)
    └──does NOT require──> Supabase schema change

Two-step completion sheet (congrats → picker)
    └──requires──> MomentumPickerSheet (already built — wire as step 2)
    └──requires──> Congrats half-sheet (new: step 1)
    └──replaces──> Current direct MomentumPickerSheet trigger in toggleMicroAction()
    └──requires──> Sheet sequencing: single sheet with internal step state

Congrats half-sheet
    └──requires──> CelebrationState (already built)
    └──enhances──> Existing inline confetti + milestone banner (additive, not replacement)
    └──requires──> Lottie OR SwiftUI animation (prefer SwiftUI to avoid new Lottie file)
```

### Dependency Notes

- **Tap bubble conflicts with direct detail-sheet-on-tap:** Currently `onTap: { selectedAction = action }` in `JourneyPathView` opens the detail sheet directly. The bubble introduces an intermediate step. The resolution is: tap → show bubble; bubble "Start" CTA → open detail sheet. Locked node tap → show bubble with "locked" copy, no CTA. This is a behavior change to `JourneyPathView` and `JourneyNodeView`.

- **User-driven ordering requires updating `nodeState()`:** The current `nodeState(at:actions:)` function marks the first incomplete action as `.active`. With user-driven ordering, the `.active` node is the user's pick (or first incomplete if no pick). This needs a `userPickedActionId: UUID?` in the ViewModel.

- **Two-step sheet replaces direct `MomentumPickerSheet` trigger:** `toggleMicroAction()` currently sets `showMomentumPicker = true` directly. This must be replaced with a congrats-first step. The `MomentumPickerSheet` already exists and does not need to change — only the trigger mechanism changes.

- **Action Picker on first visit:** First-visit picker replaces the current `CommitmentSheet` shown after action plan generation (`showCommitmentPicker = true`). The two sheets serve different purposes: CommitmentSheet = "commit to one action"; ActionPickerScreen = "understand all actions, pick your first." Decision: show ActionPickerScreen on first arrival; CommitmentSheet becomes the second step within the picker flow.

---

## MVP Definition

### Launch With (v1.1 — current milestone scope)

Minimum set that fulfills the milestone goal: "Make the journey path intuitive — users understand their actions, choose their own order, and get celebrated properly between completions."

- [ ] Tap bubble on active node — shows action name + time + "Start" CTA that opens detail sheet
- [ ] Tap bubble on locked node — shows "complete [X] first" message, no CTA
- [ ] Tap bubble on completed node — shows action name + "Done" badge, no CTA (orientation)
- [ ] Action picker screen — scrollable list of all actions, radio-select, shown on first visit
- [ ] User-driven ordering — chosen action becomes next `.active` node; local sort persists per plan
- [ ] Congrats half-sheet (step 1) — triggered after marking done; shows celebration animation + summary
- [ ] "Keep the momentum?" picker (step 2) — existing `MomentumPickerSheet` wired as continuation of congrats flow
- [ ] Sheet sequencing — congrats → picker as a single sheet with internal state, not two separate sheet presentations

### Add After Validation (v1.x)

- [ ] Ordered persistence via UserDefaults — if user ordering survives session reload, add this; if it feels natural to reset each session, defer
- [ ] Congrats sheet animation polish — upgrade from SwiftUI scale to Lottie if user feedback shows it feels flat
- [ ] Locked-node bubble copy refinement — A/B test "Finish X first" vs "Complete your current action first"

### Future Consideration (v2+)

- [ ] "What's next" AI edge function — intelligent post-completion recommendations from Supabase; deferred until backend ready
- [ ] Drag-to-reorder on journey path — only if user-driven ordering via picker proves insufficient
- [ ] Sound effects (opt-in) — only after audio asset strategy is resolved
- [ ] Streak freeze mechanic — only if streak-loss becomes a measured retention problem

---

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Tap bubble (active node) | HIGH | MEDIUM | P1 |
| Tap bubble (locked node — explains blocker) | HIGH | LOW | P1 |
| Action picker screen (first visit) | HIGH | MEDIUM | P1 |
| User-driven ordering (pick next) | HIGH | MEDIUM | P1 |
| Congrats half-sheet (step 1 of two-step) | HIGH | MEDIUM | P1 |
| Sheet sequencing: congrats → picker (step 2 wiring) | HIGH | LOW | P1 |
| Tap bubble (completed node) | MEDIUM | LOW | P2 |
| Local sort persistence (UserDefaults) | MEDIUM | LOW | P2 |
| Congrats animation (Lottie upgrade) | LOW | MEDIUM | P3 |
| AI "what's next" edge function | MEDIUM | HIGH | P3 (blocked) |

**Priority key:**
- P1: Required to ship v1.1
- P2: Polish pass — add if time allows
- P3: Defer

---

## Competitor Feature Analysis

| Feature | Duolingo | Habitica | Our Approach |
|---------|----------|----------|--------------|
| Node tap behavior | Tap node → speech bubble callout appears above it with lesson title + "Start" button; tapping Start begins the lesson | Tap task → full task detail opens in-line | Tap node → bubble callout above with action name + emoji + time + "Start" CTA (matches Duolingo exactly) |
| Locked node tap | Tap locked node → bubble explains "Complete previous lesson first" | Locked tasks grayed out, tapping shows "Requirements not met" | Tap locked node → bubble with "Finish '[prev action]' to unlock this" |
| Action selection / ordering | Linear — next lesson in path is locked in; no user choice of order | User creates and reorders tasks freely (full drag-to-reorder) | Hybrid: AI determines initial order; user picks "next active" via picker; rest keeps relative order |
| Post-completion flow | Lesson complete screen → XP/streak update → lesson path (one screen, not a sheet) | Task completed → XP/gold number pop animation → back to task list | Congrats half-sheet (step 1) → "Keep the momentum?" picker (step 2) → journey path |
| First-visit onboarding to plan | Shows first active lesson node on path, prompts to start immediately | New quest → task list shown immediately | Action picker screen on first visit: shows all actions, pre-selects first, user can confirm or pick different |

---

## Implementation Notes for Roadmap

### Tap Bubble: SwiftUI Pattern

Use an `.overlay` on `JourneyNodeView` with `@State var showBubble: Bool`. The bubble is a `VStack` in a `ZStack` positioned above the node circle using `.offset(y: -height)` and `.zIndex(1)`. Dismiss via `.onTapGesture` on the background or on the bubble's close area. No third-party library required.

```
JourneyNodeView
  └── Button (circle node)
  └── .overlay {
        if showBubble {
          NodeBubbleView(action: action, state: state, onStart: { ... })
            .offset(y: -bubbleHeight)
            .transition(.scale.combined(with: .opacity))
        }
      }
```

`JourneyPathView.onTap` must change from `selectedAction = action` to setting `expandedNodeId = action.id` on the path, and each node checks `expandedNodeId == action.id` to show its bubble. This keeps only one bubble open at a time.

### Two-Step Sheet: Single-Sheet State Pattern

Avoid presenting two sheets sequentially (iOS sheet timing is unreliable for back-to-back presentation). Instead, present one sheet and use internal state:

```swift
enum CompletionSheetStep {
    case congrats
    case picker
}
@State var completionSheetStep: CompletionSheetStep = .congrats
```

The sheet body switches content based on `completionSheetStep`. The "Keep going" button in the congrats view sets `completionSheetStep = .picker` with animation — no new sheet presentation.

### User-Driven Ordering: ViewModel Change

Add `userPickedNextActionId: UUID?` to `ActionPlanViewModel`. The `nodeState()` function becomes:

```
active = userPickedNextActionId if set and action matches
       = first incomplete action (existing behavior) if not set
```

When user picks an action in the picker, reorder `microActions` array so the picked action is the first incomplete item. This reorder drives the `nodeState()` logic. Persist the `microActions` order to UserDefaults on write, restore on `loadActionPlan`.

---

## Sources

- [Duolingo New Learning Path FAQ — Duolingo Help Center](https://support.duolingo.com/hc/en-us/articles/6448741924237-FAQ-Duolingo-s-new-learning-path)
- [The Science Behind Duolingo's Home Screen Redesign — Duolingo Blog](https://blog.duolingo.com/new-duolingo-home-screen-design/)
- [Duolingo UX and Gamification Breakdown — UserGuiding](https://userguiding.com/blog/duolingo-onboarding-ux)
- [Duolingo New Learning Path Review — Duoplanet](https://duoplanet.com/duolingo-new-learning-path-review/)
- [Streaks and Milestones for Gamification — Plotline](https://www.plotline.so/blog/streaks-for-gamification-in-mobile-apps)
- [Gamification in Product Design 2025 — Mockplus](https://www.mockplus.com/blog/post/gamification-ui-ux-design-guide)
- [14 App Gamification Examples — CleverTap](https://clevertap.com/blog/app-gamification-examples/)
- [Modal vs Popover vs Tooltip — UX Patterns](https://uxpatterns.dev/pattern-guide/modal-vs-popover-guide)
- [Popovers — Apple HIG](https://developer.apple.com/design/human-interface-guidelines/popovers)
- [aheze/Popovers — GitHub](https://github.com/aheze/Popovers) (considered, not needed — pure SwiftUI overlay is sufficient)
- Codebase analysis: `JourneyNodeView.swift`, `ActionPlanViewModel.swift`, `CompletionReflectionSheet.swift`, `ActionPlanDetailView.swift`, `JourneyPathView.swift`

---

*Feature research for: Abimo v1.1 Actions Flow UX — action picker, node tap bubbles, user-driven ordering, two-step completion celebration*
*Researched: 2026-03-19*
