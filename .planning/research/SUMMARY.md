# Project Research Summary

**Project:** Abimo v1.1 — Actions Flow UX
**Domain:** SwiftUI gamified micro-action journey path — action picker, node tap bubbles, user-driven ordering, two-step completion sheet
**Researched:** 2026-03-19
**Confidence:** HIGH

## Executive Summary

Abimo v1.1 is a pure SwiftUI enhancement milestone layered onto an already-shipped v1.0 codebase. The four target features (tap-to-reveal node bubbles, action picker screen, user-driven action ordering, and two-step congrats-to-picker completion flow) are all buildable with zero new dependencies using native SwiftUI APIs available within the iOS 26.2 deployment target. The existing Lottie and Vortex packages cover every animation need. The single recommended package change is a minor version bump of lottie-spm from 4.5.x to 4.6.0, which is a drop-in upgrade. All conclusions are drawn from direct reads of the actual source files — confidence is high because nothing is inferred.

The recommended approach is to treat this milestone as a layered extension of the existing `ActionPlanViewModel` → `JourneyPathView` → `JourneyNodeView` architecture. Two new views (`NodeBubbleView`, `ActionPickerSheet`) and one new sheet (`CongratsHalfSheet`) are added. The critical ViewModel changes are: adding `activeNodeId: UUID?` for mutual-exclusion bubble control, replacing `showMomentumPicker` with a `PostCompletionSheet` enum that drives the two-step flow as a single sheet rather than two competing boolean flags, and adding `userOrderedIds: [UUID]` plus an `orderedActions` computed property that applies user picks without mutating the Supabase-fetched `microActions` array.

The primary risks are two SwiftUI-specific traps that must be addressed before any view work begins. First, the current `nodeState(at:actions:)` function uses array index position as a proxy for ordering — user-driven reordering will produce two simultaneous `.active` nodes unless `JourneyPathView` switches to `viewModel.orderedActions` before the picker UI is built. Second, driving the congrats → picker transition with two independent booleans will cause SwiftUI's sheet queue to silently drop the second presentation. Both traps are low recovery cost at design time and high cost if discovered mid-integration.

---

## Key Findings

### Recommended Stack

No new dependencies. All four v1.1 features are built entirely from native SwiftUI APIs available at the iOS 26.2 deployment target: `.popover` + `.presentationCompactAdaptation(.popover)` for node bubbles, `presentationDetents(selection:)` for programmatic detent control, `interactiveDismissDisabled` to lock the congrats step, `matchedGeometryEffect` for the picker card → journey node transition, and `LazyVGrid` for the 2-column action picker layout. The existing Lottie `trophy.json` asset is reused as-is — adding new Lottie JSON files is explicitly an anti-feature.

**Core technologies:**
- SwiftUI native APIs (iOS 16.4+): All required APIs ship with the iOS 26.2 SDK — no installation required
- lottie-spm 4.6.0 (upgrade from 4.5.x): Congrats animation reusing existing `trophy.json` — drop-in upgrade, `LottieView` API unchanged since 4.3.0
- Vortex 1.0.4 (no change): Node bubble and completion particle effects — already at latest tag; no version bump needed
- `matchedGeometryEffect` + `@Namespace`: Action picker card → journey node visual continuity — native, zero dependencies
- `presentationDetents([.medium, .large], selection:)`: Two-step sheet expansion without dismiss/re-present cycle — only native approach that avoids a visual gap

**What not to add:** No drag-reorder library (wrong UX model — ordering is tap-to-pick-next, not physical drag). No third-party tooltip library (native `.popover` + `.presentationCompactAdaptation` is a 30-line replacement). No `SheeKit` (iOS 26.2 deployment target makes it redundant). No new Lottie JSON files (reuse `trophy.json`).

### Expected Features

**Must have (table stakes — required for v1.1 to be complete):**
- Tap bubble on active node — emoji + action name + time estimate + "Start" CTA that opens detail sheet
- Tap bubble on locked node — "finish [X] first" message, no CTA (explains prerequisite)
- Tap bubble on completed node — action name + "Done" badge, read-only (user orientation)
- Action picker screen on first visit — shows all actions before user touches anything; pre-selects first incomplete
- User-driven ordering — user's picked action becomes the next `.active` node in-session
- Congrats half-sheet (step 1) — presented after marking any action done; Lottie trophy + "Keep the momentum?" CTA
- Two-step sheet sequencing — congrats transitions to action picker via single `PostCompletionSheet` enum, not two sheet presentations

**Should have (competitive differentiators, add if time allows):**
- Local sort persistence via UserDefaults — user ordering survives app restart (no Supabase schema change; keyed by `planId`)
- Locked-node bubble copy refinement — "Finish '[prev action]' to unlock" rather than generic padlock with no explanation
- Picker pre-selection — recommended action pre-highlighted using existing `nextRecommendedAction` computed var

**Defer (v1.x or v2+):**
- AI "what's next" edge function — Supabase not ready; client-side `nextRecommendedAction` is sufficient
- Drag-to-reorder on journey path — user-driven ordering via picker supersedes this
- Sound effects — explicitly excluded in PROJECT.md
- XP/points in congrats sheet — no economy exists to spend them

### Architecture Approach

The v1.0 MVVM architecture remains intact. V1.1 grafts onto it via targeted additions: two new `@Published` properties (`activeNodeId`, unified `PostCompletionSheet` enum), one computed property (`orderedActions`), two new methods (`pickAction(_:)`, `dismissCongrats()`), and three new view files. `JourneyNodeView`, `JourneyPathView`, and `ActionPlanDetailView` are modified. `MomentumPickerSheet` is retired once replaced by `CongratsHalfSheet` + `ActionPickerSheet`. No external services change. Supabase schema is untouched.

**Major components:**
1. `ActionPlanViewModel` (modified) — adds `activeNodeId`, `userOrderedIds`, `orderedActions`, `PostCompletionSheet` enum, `pickAction()`, `dismissCongrats()`
2. `NodeBubbleView` (new) — callout bubble overlay parameterised by `NodeState`; communicates via `onCTA` closure, no direct ViewModel coupling
3. `ActionPickerSheet` (new) — `LazyVGrid` 2-column layout of all incomplete actions; calls `viewModel.pickAction(_:)` on confirm; shown on first visit and after each non-final completion
4. `CongratsHalfSheet` (new) — `.medium` detent half-sheet; Lottie trophy animation; "Keep the momentum?" CTA advances `PostCompletionSheet` enum to `.picker`
5. `JourneyPathView` (modified) — switches from `viewModel.microActions` to `viewModel.orderedActions`; passes `activeNodeId` to each node; background tap clears `activeNodeId`
6. `JourneyNodeView` (modified) — tap sets `viewModel.activeNodeId` instead of directly opening `ActionDetailSheet`; overlays `NodeBubbleView` when `activeNodeId == action.id`

### Critical Pitfalls

1. **User ordering corrupts `nodeState` machine** — `nodeState(at:actions:)` uses `firstIndex(where: !isCompleted)` on the raw array. Any user reordering not reflected in the array passed to this function produces two simultaneous `.active` nodes. Prevention: switch `JourneyPathView` to pass `viewModel.orderedActions` to `nodeState()` before building the picker UI.

2. **Two sheet booleans cause presentation queue race** — SwiftUI processes one `.sheet` per run loop. Setting `showCongratsSheet = false; showActionPicker = true` synchronously drops the second. Prevention: model both steps as a single `PostCompletionSheet` enum; one `.sheet(item:)` reads from it; user's explicit CTA tap advances the enum — no timers, no race.

3. **Tap bubble gesture conflicts with node `Button`** — Overlays rendered inside a `Button` compete for tap gestures. If the bubble has its own CTA `Button`, the parent node `Button` may consume the gesture first. Prevention: drive all bubble visibility from `viewModel.activeNodeId` (mutual exclusion built-in); if conflicts appear, render bubbles at `JourneyPathView` level in a `ZStack`.

4. **`CelebrationState` collision on plan completion** — Adding the congrats half-sheet case inside `CelebrationState` will race with `.planComplete` on the last action. Prevention: keep the congrats half-sheet exclusively in `PostCompletionSheet`; when `celebrationState == .planComplete`, `PostCompletionSheet` stays `.none` — the full-screen overlay IS the celebration for plan completion.

5. **Zombie bubbles on completed nodes** — Bubbles driven by local `@State` inside `JourneyNodeView` are not cleared when a node transitions to `.completed`. Prevention: drive bubble visibility exclusively from `viewModel.activeNodeId`; `pickAction()` and `dismissCongrats()` both clear `activeNodeId` as part of their normal flow.

---

## Implications for Roadmap

The dependency graph in ARCHITECTURE.md and the pitfall-to-phase mapping in PITFALLS.md converge on the same build order: ViewModel data model first, then node rendering changes, then new sheet UI, then full wiring. Each phase is unblocked by the prior one compiling cleanly.

### Phase 1: ViewModel Foundation + Node State Refactor

**Rationale:** Every downstream view change depends on `viewModel.orderedActions` existing and `nodeState()` consuming it. This is the safest first step — pure Swift with no UI, verifiable by unit tests before any visual work. Doing this last causes Pitfall 1 (node state machine corruption) to be discovered mid-integration.

**Delivers:** `userOrderedIds: [UUID]`, `orderedActions` computed property, `activeNodeId: UUID?`, `PostCompletionSheet` enum (replacing two boolean flags), `pickAction()`, `dismissCongrats()` on ViewModel. `nodeState()` updated to return `.active` for all incomplete nodes. `JourneyPathView` switched to `orderedActions`.

**Addresses:** User-driven ordering (foundational), action picker (foundational)

**Avoids:** Pitfall 1 (node state machine corruption), Pitfall 4 (CelebrationState collision)

### Phase 2: Tap Bubbles on Nodes

**Rationale:** Depends on Phase 1's `activeNodeId` being in place. `NodeBubbleView` is a self-contained UI component with no sheet dependencies — building it before sheet work keeps UI and navigation concerns separate. Gesture conflict testing can happen here before sheet complexity is added.

**Delivers:** `NodeBubbleView` with content parameterised by `NodeState` (active: "Start" CTA; locked: info-only; completed: read-only recap). Modified `JourneyNodeView` tap handler. Background tap dismissal on `JourneyPathView`.

**Uses:** Native SwiftUI `.overlay(alignment:)`, `opacity` transitions, existing `ActionIconMapper` emoji

**Avoids:** Pitfall 3 (gesture conflicts), Pitfall 6 (zombie bubbles), Pitfall 8 (locked node misleads user about availability)

### Phase 3: Action Picker Sheet

**Rationale:** Depends on Phase 1's `pickAction()` and `orderedActions`. The picker is shown on first visit and as step 2 of the completion flow — building it as a standalone sheet before the congrats sheet means Phase 4 wires to a working component rather than two unfinished ones simultaneously.

**Delivers:** `ActionPickerSheet` — `LazyVGrid` 2-column layout of all incomplete actions, radio-select, confirms via `viewModel.pickAction(_:)`. First-visit trigger in `ActionPlanDetailView.task`. Stale-data guard: `remainingActions` excludes `completingActionId` explicitly and is computed in `onAppear` not view body.

**Uses:** `LazyVGrid`, `presentationDetents([.large])`, existing `ActionIconMapper`, existing `MicroAction` list

**Avoids:** Pitfall 5 (stale data showing just-completed action in picker)

### Phase 4: Two-Step Completion Sheet + Full Wiring

**Rationale:** Depends on Phase 3's `ActionPickerSheet` being complete. This phase replaces the existing `toggleMicroAction` → `showMomentumPicker` flow with the `PostCompletionSheet` enum and retires `MomentumPickerSheet`. This is the highest-risk integration step because it touches `evaluateCelebrationState` and requires careful sheet timing.

**Delivers:** `CongratsHalfSheet` at `.medium` detent with Lottie `trophy.json` animation and "Keep the momentum?" CTA. `ActionPlanDetailView` wired to `PostCompletionSheet` enum via a single `.sheet(item:)`. `MomentumPickerSheet` retired. `DispatchQueue.main.asyncAfter(0.05)` gap in `dismissCongrats()` to let SwiftUI process the dismiss before presenting the picker.

**Uses:** Existing `trophy.json` Lottie asset, `presentationDetents`, `interactiveDismissDisabled`, existing Vortex confetti

**Avoids:** Pitfall 2 (sheet queue race), Pitfall 4 (CelebrationState collision on plan complete)

### Phase Ordering Rationale

- ViewModel before views: All three view phases depend on ViewModel state existing — building UI first requires placeholder state that must be refactored later.
- Bubbles before sheets: `NodeBubbleView` is self-contained; `ActionPickerSheet` is self-contained; `CongratsHalfSheet` depends on both — natural bottom-up order.
- Picker before congrats sheet: The "Keep the momentum?" CTA opens the picker — building the picker first means the congrats view wires to a working component.
- Sheet wiring last: `ActionPlanDetailView` changes and `MomentumPickerSheet` retirement are final integration steps; doing them early creates broken intermediate states.

### Research Flags

Phases with well-documented patterns (skip `/gsd:research-phase`):
- **Phase 1 (ViewModel):** All implementation code is already specified concretely in ARCHITECTURE.md including Swift code snippets. Pure Swift — no API ambiguity.
- **Phase 3 (Action Picker):** `LazyVGrid` and sheet presentation are standard SwiftUI. Pattern is identical to existing `CommitmentSheet` with a wider action list and different card count.

Phases that may benefit from a focused implementation spike before building:
- **Phase 2 (Tap Bubbles):** Gesture priority between overlays and parent `Button` inside a `ScrollView` is a documented SwiftUI edge case. Recommend a 1-hour throwaway prototype to verify `activeNodeId`-driven overlay does not conflict with `JourneyPathView`'s `ScrollView` gesture recognizer before committing to production implementation.
- **Phase 4 (Two-Step Sheet):** The `DispatchQueue.main.asyncAfter` timing for sheet chaining must be verified on a physical device, not just Simulator. Recommend an end-to-end device test immediately after Phase 4 is wired before calling it done — rapid completion scenarios (completing 3 actions back-to-back) are the failure mode.

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All API availability confirmed against official Apple documentation. lottie-spm 4.6.0 and Vortex 1.0.4 verified via GitHub tags. Existing codebase read directly — no inference. |
| Features | HIGH | Table stakes confirmed against Duolingo design documentation. Anti-features are explicit, reasoned, and backed by competitor analysis. Feature dependencies traced to actual source files. |
| Architecture | HIGH | All conclusions drawn from reading actual source files, not inferred. Build order derived from real dependency graph. Code snippets are concrete, not pseudocode. Component boundaries match the live codebase. |
| Pitfalls | HIGH (SwiftUI/state), MEDIUM (UX) | SwiftUI sheet queue race and gesture priority pitfalls are first-hand codebase analysis confirmed against actual source. UX pitfalls (bubble fatigue, picker fatigue thresholds) are research and analogy — not A/B tested on Abimo's specific users. |

**Overall confidence:** HIGH

### Gaps to Address

- **UserDefaults persistence for ordering:** PITFALLS.md and FEATURES.md both identify this as a P2 item — the implementation path is clear (merge Supabase array with locally-stored `[UUID]` in `loadActionPlan`), but the decision of whether to include it in v1.1 or defer to v1.x has not been made. Cheapest to add at Phase 1; retroactively adding it to a shipping ViewModel requires re-testing the entire ordering flow.

- **`matchedGeometryEffect` namespace plumbing:** STACK.md recommends `matchedGeometryEffect` for the picker card → journey node transition, but ARCHITECTURE.md does not trace where `@Namespace` is declared and how it is passed to both `ActionPickerSheet` and `JourneyPathView`. This plumbing must be confirmed feasible — both components are presented from `ActionPlanDetailView`, so the namespace should live there — before committing to the animation in Phase 3.

- **`MomentumPickerSheet` retirement vs. component reuse:** ARCHITECTURE.md recommends removing it once `CongratsHalfSheet` + `ActionPickerSheet` replace its behavior. FEATURES.md implies its card row component should be reused inside `ActionPickerSheet`. Resolve before Phase 4: either extract the row component (preferred — avoids duplication) or replace outright. Deleting without checking all references will cause compile errors.

- **`CommitmentSheet` first-visit replacement:** FEATURES.md indicates `ActionPickerSheet` replaces `CommitmentSheet` on first visit. Confirm `CommitmentSheet` is not used in any flow other than first-visit (check `showCommitmentPicker` call sites in the ViewModel) before modifying the first-visit trigger in Phase 3.

---

## Sources

### Primary (HIGH confidence)
- `ActionPlanViewModel.swift` — actual source read 2026-03-19 — ViewModel state, completion flow, `evaluateCelebrationState`, `nodeState()` function
- `JourneyNodeView.swift`, `JourneyPathView.swift` — actual source read 2026-03-19 — `nodeState()` implementation, tap handling, overlay patterns
- `ActionPlanDetailView.swift` — actual source read 2026-03-19 — three concurrent `.sheet()` presenters and their boolean conditions
- `CommitmentSheet.swift`, `ActionDetailSheet.swift`, `PlanCompletionView.swift`, `CompletionReflectionSheet.swift` — actual source read 2026-03-19
- Apple Developer Documentation: `presentationCompactAdaptation(_:)` — iOS 16.4+ confirmed
- Apple Developer Documentation: `presentationDetents(_:selection:)` — iOS 16+ confirmed
- Apple Developer Documentation: `interactiveDismissDisabled(_:)` — iOS 15+ confirmed
- https://github.com/twostraws/Vortex/tags — Vortex 1.0.4 confirmed as latest tag (Aug 2025)
- https://github.com/airbnb/lottie-spm/releases — lottie-spm 4.6.0 confirmed as latest release (Jan 2025)
- project.pbxproj — iOS 26.2 deployment target, SPM package versions confirmed

### Secondary (MEDIUM confidence)
- Duolingo Help Center, Duolingo Blog, Duoplanet, UserGuiding — bubble tooltip behavior, locked node UX, post-completion celebration flow patterns
- Apple HIG: Popovers — popover usage guidelines for iPhone
- Plotline, Mockplus, CleverTap — gamification best practices, two-tier celebration model rationale

### Tertiary (MEDIUM-LOW confidence)
- SwiftUI sheet presentation queue limitation — community threads (SwiftUI Forum, Hacking with Swift issues tracker); not officially documented by Apple; pattern broadly reproduced and accepted across the community
- UserDefaults ordering persistence precedent — Things 3, OmniFocus; analogous app behavior, not directly verified for Abimo's data model

---

*Research completed: 2026-03-19*
*Ready for roadmap: yes*
