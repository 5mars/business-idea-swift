# Project Research Summary

**Project:** Abimo — Actions Flow Revamp (Gamified UX Layer)
**Domain:** Gamified micro-action completion UX in SwiftUI — Duolingo-style journey path, celebration screens, haptic feedback
**Researched:** 2026-03-18
**Confidence:** MEDIUM-HIGH

## Executive Summary

Abimo's actions flow revamp is a well-scoped gamification layer on an existing SwiftUI/Supabase app. The goal is to replace a flat micro-action list with a spatially engaging journey path (vertical node map in the style of Duolingo's 2022 redesign) and to wrap action completions in satisfying celebration moments — animated checkmarks, full-screen confetti overlays, and haptic feedback. The domain is well-documented: Duolingo's design decisions have been publicly analyzed in depth, and all required technical primitives are available as iOS 17/18 built-ins or small, mature SPM packages (Lottie, Vortex). No new backend schema is required; the existing `MicroAction` and `ActionPlan` models already carry the completion state this feature needs.

The recommended approach is to build in clear dependency order — foundation utilities first (icon mapping, haptic helpers, AnimationPolicy), then the journey path and card states, then the celebration overlay system, and finally the full-plan completion screen as a natural extension of the celebration infrastructure. Two third-party packages cover animation needs that go beyond SwiftUI's built-ins: `lottie-spm` (4.5.x) for authored celebration animations and `Vortex` (1.0.4) for confetti particle bursts. Everything else — haptics, spring animations, scroll snapping, hero transitions — is covered by iOS 17+ built-in APIs.

The primary risks are technical rather than strategic. Lottie is powerful but has well-documented pitfalls: it must not be placed in scrollable list cells (causes CPU/memory spikes), its `.automatic` rendering engine silently falls back to the main thread when animation files use unsupported AE features, and it must be coordinated with `accessibilityReduceMotion` at every call site. The UX risk is over-gamification: applying celebration modals to every micro-action (appropriate for Duolingo's one-action-per-session model) creates friction in Abimo's multi-action-per-session loop. The fix is a deliberate two-tier celebration model — inline non-blocking feedback for individual actions, full-screen celebration reserved for plan completion.

---

## Key Findings

### Recommended Stack

The entire feature is achievable with two SPM packages plus iOS 17/18 built-ins. `lottie-spm` (not `lottie-ios`) provides the `LottieView` SwiftUI component for authored celebration animations; the `lottie-spm` variant has an ~500 KB footprint vs. 300+ MB for the main repo's git history and is identical at runtime. `Vortex` (1.0.4, by Paul Hudson) provides Metal-backed confetti particle bursts as a pure SwiftUI composable — no UIKit bridging, composes naturally with `ZStack`. All haptic feedback is handled by SwiftUI's `.sensoryFeedback` modifier (iOS 17+), which replaces the UIKit `UIFeedbackGenerator` wrapper pattern. Animation sequencing uses `KeyframeAnimator` and `withAnimation(.spring(duration:bounce:))` with completion closures (iOS 17+). The journey path scroll uses `ScrollViewReader` + `scrollTargetBehavior(.viewAligned)` for snap-to-node behavior. Hero transitions use `matchedTransitionSource` + `.zoom` NavigationTransition on iOS 18 (available given the Xcode 26.2 toolchain), with `matchedGeometryEffect` as the iOS 17 fallback.

**Core technologies:**
- `lottie-spm` 4.5.x: authored celebration/confetti JSON animations — industry standard, native SwiftUI API, ~500 KB package size
- `Vortex` 1.0.4: particle confetti burst — pure SwiftUI, Metal-backed, zero UIKit bridging
- `.sensoryFeedback` modifier (iOS 17+ built-in): haptic feedback on completions and commit toggles — zero-dependency, declarative
- `KeyframeAnimator` + `withAnimation` completion (iOS 17+ built-in): multi-stage celebration animation sequencing — no third-party sequencer needed
- `scrollTargetBehavior(.viewAligned)` (iOS 17+ built-in): snap-to-active-node scroll behavior — no paging library needed
- `matchedTransitionSource` + `.zoom` (iOS 18+ built-in): hero card-to-celebration transition

### Expected Features

Features research is grounded in Duolingo design case studies, gamification psychology literature, and direct competitor analysis (Duolingo, Habitica, Forest). The table-stakes list reflects what users expect once the "gamified" interaction paradigm is established; missing any of them breaks the implied contract.

**Must have (table stakes — P1):**
- Vertical journey path (node map) replacing the flat action list — core spatial metaphor
- Action card states (locked, current, done) — orientation requires these; path is meaningless without them
- Celebration screen per action (Lottie confetti) — primary reward moment; absence reads as broken
- Haptic feedback on completion and commit — iOS users expect physical confirmation
- Satisfying checkmark animation and card state transition — static checkmarks read as a task manager
- Type-mapped emoji/icon per action card — visual identity without AI latency
- Full plan completion summary screen — marks the larger milestone distinctly from a single action
- Progressive disclosure on cards (expand for templates/deep links) — keeps path visually clean
- Animated progress ring per plan — "how far am I" at a glance

**Should have (competitive differentiators — P2):**
- Contextual celebration copy variation (1st action, midpoint, last) — requires usage validation first
- Smooth animated node-unlock transition — polish pass after core interactions are stable
- Momentum dashboard integration into journey path header — consolidation UX

**Defer (v2+):**
- Sound effects (opt-in toggle)
- Streak freeze / skip mechanics
- Badge/achievement wall
- XP/points system, leaderboards — explicitly excluded; do not add as "small enhancements"

### Architecture Approach

The architecture fits naturally into the existing MVVM structure. `ActionPlanViewModel` is extended with a `CelebrationState` enum (`idle`, `singleAction(MicroAction)`, `allComplete`) that drives overlay visibility without putting display logic in views. New views are organized into three subgroups under `Views/ActionPlan/`: `Journey/` (path canvas, nodes, progress ring), `Cards/` (action detail sheet, icon mapper), and `Celebration/` (per-action overlay, plan-completion screen). The service layer (Supabase, AI, audio) is untouched. A `HapticEngine` utility namespace and an `AnimationPolicy` accessibility wrapper are foundational utilities that must exist before any animated view is built.

**Major components:**
1. `JourneyPathView` — vertical scroll canvas with staggered node layout and connecting path lines; replaces `ActionPlanDetailView` body
2. `JourneyNodeView` — single node: emoji icon, locked/active/done states, tap target, checkmark animation
3. `CelebrationOverlay` — full-screen ZStack sibling (not child) of journey path; Lottie + Vortex confetti + haptics; auto-dismisses
4. `PlanCompletionView` — all-done dedicated screen; summary stats; reuses CelebrationOverlay animation components
5. `ActionDetailSheet` — bottom sheet expanding one action's details; replaces expanded `MicroActionRow`
6. `ProgressRingView` — `Circle().trim()` progress ring observing `viewModel.progress`
7. `ActionIconMapper` — pure function, `MicroAction.actionType` → SF Symbol + accent color
8. `HapticEngine` — static pre-configured haptic helpers; called from ViewModel on `@MainActor`

**Key pattern — ZStack overlay coordination:**
`ActionPlanDetailView` wraps content in a `ZStack`. `CelebrationOverlay` and `PlanCompletionView` are siblings of `JourneyPathView` in that stack, driven by `celebrationState`. They are not pushed onto the `NavigationStack` (transient, no navigation history). This is the critical architectural decision that prevents Lottie from being embedded inside the scroll hierarchy.

### Critical Pitfalls

1. **Lottie recreated on every SwiftUI re-render** — Use `LottieView` (official API from Lottie 4.3.0+), never a hand-rolled `UIViewRepresentable`. Never place `LottieView` in scrollable list cells — use native SwiftUI animations for card idle states. Reserve Lottie for triggered celebration moments only. Cache `LottieAnimation` objects so JSON is parsed once per session.

2. **Core Animation silent fallback to main thread** — Lottie's `.automatic` rendering silently falls back when animation files use After Effects expressions, time remapping, or unsupported trim paths. During development, force `.coreAnimation` mode (no fallback) to confirm asset compatibility. Vet every `.json` or `.lottie` file in LottieFiles before integrating.

3. **Celebration modal blocking flow between micro-actions** — A full-screen modal after every micro-action becomes friction (not reward) in a multi-action session. Use inline non-blocking celebration (haptic + checkmark morph, 1.5-2s auto-dismiss) for individual action completions. Full blocking celebration screen is appropriate only for plan completion.

4. **`accessibilityReduceMotion` ignored across animation sites** — Create a shared `AnimationPolicy` wrapper at the start of the milestone; all animation sites check it instead of calling UIAccessibility directly. Treat this as foundational infrastructure, not a polish step. Every Lottie call site, `withAnimation` block, and Vortex trigger must route through it.

5. **Animation interrupted by async Supabase state update** — Separate local animation state from server-confirmed state. A local `@State var isAnimatingCompletion` drives the visual sequence. Only after animation completes does the ViewModel propagate the server-confirmed state. Never bind Lottie `isPlaying` directly to a `@Published` property that changes during network calls.

---

## Implications for Roadmap

Based on research, the dependency graph is clear and drives the phase order. The journey path cannot be meaningful without card states. Card states require the icon mapper. The celebration overlay must sit outside the scroll hierarchy (architectural constraint discovered in ARCHITECTURE.md). `accessibilityReduceMotion` must be established before any animation is wired. Suggested phase structure:

### Phase 1: Foundation Utilities
**Rationale:** Three utilities have no dependencies and unblock everything else. Building them first means no animation site is ever written without accessibility support, no haptic call is ever written ad-hoc, and no card is ever rendered without a consistent icon. The PITFALLS research is explicit: `AnimationPolicy` must exist before any animation is wired.
**Delivers:** `ActionIconMapper` (pure function, fully testable), `HapticEngine` (static namespace), `AnimationPolicy` / `accessibilityReduceMotion` wrapper
**Avoids:** Pitfall 4 (reduce motion ignored across sites), Pitfall 1 (Lottie in wrong context)

### Phase 2: Journey Path and Action Card States
**Rationale:** The journey path is the core spatial metaphor and the highest-complexity component. Card states (locked/current/done) are a dependency of the path — nodes are meaningless without them. Progressive disclosure (expand/collapse) belongs in this phase because card density without it is poor. This phase replaces the existing flat list body.
**Delivers:** `JourneyPathView`, `JourneyNodeView` (3 states, checkmark animation, offset staggering), `ProgressRingView`, `ActionDetailSheet` (bottom sheet expanding card details)
**Uses:** `ActionIconMapper` (Phase 1), `scrollTargetBehavior(.viewAligned)`, `KeyframeAnimator`, `withAnimation(.spring)`, `HapticEngine` (commit haptic)
**Avoids:** Pitfall 3 (GeometryReader in scroll path), Pitfall 7 (local vs. server animation state — define split here)

### Phase 3: Celebration Overlay System
**Rationale:** Celebration infrastructure requires the journey path to exist (the overlay sits as a ZStack sibling of `JourneyPathView`). The `CelebrationState` enum extends `ActionPlanViewModel` — the ViewModel must already own `microActions` and `toggleMicroAction`. Lottie assets must be vetted for Core Animation compatibility before this phase begins.
**Delivers:** `CelebrationOverlay` (per-action, non-blocking, auto-dismiss), `CelebrationState` enum on `ActionPlanViewModel`, Lottie asset integration, Vortex confetti, `.sensoryFeedback(.success)` on completion
**Uses:** `lottie-spm` 4.5.x, `Vortex` 1.0.4, `AnimationPolicy` (Phase 1), `ZStack` overlay pattern (Architecture Pattern 3)
**Avoids:** Pitfall 1 (Lottie in scroll cells — overlay is a ZStack sibling), Pitfall 2 (Core Animation fallback — assets vetted before this phase), Pitfall 3 (blocking modals on micro-actions), Pitfall 5 (animation/state race)

### Phase 4: Plan Completion Screen and Polish
**Rationale:** Plan completion screen is a natural extension of the celebration overlay infrastructure. It reuses `LottieView`, confetti, and haptics. Smooth node-unlock transitions and momentum dashboard integration are polish-level additions that belong after the core loop is stable and validated.
**Delivers:** `PlanCompletionView` (full-screen all-done, summary stats, CTA), smooth node-unlock transition animation, momentum dashboard integration into journey path header
**Uses:** All prior phases; `matchedTransitionSource` + `.zoom` for iOS 18 hero transition
**Avoids:** Pitfall 6 (over-gamification — peak moment is clearly distinct from micro-action completions)

### Phase Ordering Rationale

- Foundation utilities (Phase 1) before any animation work is non-negotiable per pitfalls research; retrofitting `AnimationPolicy` across 15+ animation sites is a documented cost avoided by doing it first.
- Journey path (Phase 2) before celebration (Phase 3) because the overlay is architecturally a sibling of the journey view; building in reverse order would require refactoring the ZStack structure.
- Card states and progressive disclosure belong together (Phase 2) because the journey path's visual coherence depends on both simultaneously — a path with expanded cards but no lock states, or lock states with no card detail, is not a shippable increment.
- Plan completion (Phase 4) last because it is an extension of celebration infrastructure, not a prerequisite. Delivering a working journey path and per-action celebration loop is the meaningful v1; plan completion is the capstone.

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 2 (Journey Path):** Connecting line drawing between nodes (straight vs. curved bezier) may need a prototype spike. ARCHITECTURE.md recommends offset staggering for the zigzag effect and defers true bezier curves to Phase 2+ — confirm the visual fidelity is acceptable before committing to straight lines.
- **Phase 3 (Lottie Assets):** Animation file sourcing from LottieFiles requires a pre-build vetting step that is easy to skip. Consider making asset compatibility verification (forced `.coreAnimation` mode test) a required checklist item before Phase 3 begins, not during.

Phases with standard patterns (skip research-phase):
- **Phase 1 (Foundation Utilities):** `ActionIconMapper` is a pure function, `HapticEngine` is a well-documented pattern, `AnimationPolicy` is a standard environment key wrapper. No research needed.
- **Phase 4 (Plan Completion):** Reuses all infrastructure from Phase 3. The only new component is the summary stats display and CTA copy, both of which follow established SwiftUI patterns.

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | MEDIUM-HIGH | Core choices (Lottie, Vortex, built-in SwiftUI APIs) are well-sourced from official docs and high-credibility community authors. Version pinning (lottie-spm 4.5.x, Vortex 1.0.4) relies on WebSearch and should be verified at time of SPM add. |
| Features | HIGH | Table-stakes features are grounded in multiple Duolingo case studies and behavioral research. Anti-feature exclusions (XP, leaderboards, sound, badges) are explicitly consistent with PROJECT.md. Competitor analysis corroborates the two-tier celebration model. |
| Architecture | MEDIUM | MVVM patterns and ZStack overlay coordination are solid and well-documented. Duolingo-specific path layout (offset staggering for zigzag) is inferred from SwiftUI primitives rather than confirmed from a published Duolingo implementation. The staggering approach is the correct call but may require visual tweaking. |
| Pitfalls | MEDIUM-HIGH | Lottie-specific pitfalls are sourced from active GitHub issues with confirmed reproduction. UX pitfalls (over-gamification, celebration fatigue) are grounded in multiple behavioral research sources. Race condition pitfall (animation vs. async state) is a standard MVVM pattern — well understood. |

**Overall confidence:** MEDIUM-HIGH

### Gaps to Address

- **Bezier vs. offset path lines:** ARCHITECTURE.md recommends simple offset staggering for the zigzag path and defers true curved connecting lines. Whether straight line segments or curved beziers are visually required for the desired "Duolingo feel" should be prototyped early in Phase 2 before the full node component is built.
- **Lottie asset acquisition:** No specific animation files have been sourced yet. LottieFiles.com is identified as the source; "celebration", "checkmark", "star burst" are the search terms. Asset selection and Core Animation compatibility vetting must happen as a pre-Phase-3 task, not during implementation.
- **iOS 18 deployment target confirmation:** `matchedTransitionSource` + `.zoom` NavigationTransition requires iOS 18+. ARCHITECTURE.md recommends confirming the deployment target from `project.pbxproj` before using without `#available` guards. Given the Xcode 26.2 toolchain this is likely fine, but confirm before Phase 4.
- **Celebration copy strings:** Positive copy ("You did it!", "Keep going!") is listed as a table-stakes feature. No copy has been drafted. This is a content dependency for Phase 3/4 that should be resolved in planning, not during implementation.

---

## Sources

### Primary (HIGH confidence)
- Apple Developer Documentation / WWDC23 — ScrollView `scrollTargetBehavior`, `KeyframeAnimator`, `sensoryFeedback` modifier
- Paul Hudson / Hacking with Swift — `sensoryFeedback` modifier API, `accessibilityReduceMotion` pattern
- Swiftwithmajid.com — sensoryFeedback trigger-based pattern
- Duolingo Engineering Blog — Home screen redesign rationale (journey path)

### Secondary (MEDIUM confidence)
- airbnb/lottie-spm GitHub — Package URL, size comparison, version confirmation
- Lottie 4.3.0 SwiftUI discussion — `LottieView` SwiftUI API confirmation
- Swift Package Index: Vortex — version 1.0.4, platform support
- twostraws/Vortex GitHub — built-in confetti preset, pure SwiftUI, SPM URL
- airbnb/lottie-ios GitHub issues #2516, #2517 — Lottie recreation/performance pitfalls
- airbnb/lottie-ios GitHub issues #1946, #2060 — Core Animation silent fallback
- Hacking with Swift — matchedGeometryEffect, matchedTransitionSource patterns
- Multiple Duolingo UX case studies (UserGuiding, uinkits, Duoplanet, Arounda)
- Smashing Magazine — streak system UX and psychology

### Tertiary (LOW confidence)
- Medium articles on Lottie memory management and iOS performance — corroborate GitHub issues but are secondary accounts
- exyte.com blog on KeyframeAnimator — implementation pattern example

---

*Research completed: 2026-03-18*
*Ready for roadmap: yes*
