# Stack Research

**Domain:** SwiftUI iOS app — action picker, node tap bubbles, user-driven ordering, two-step completion sheet (v1.1 additions)
**Researched:** 2026-03-19
**Confidence:** HIGH — all recommendations verified against existing codebase, official SwiftUI API availability, and confirmed library versions via GitHub tags

---

## Current Stack (Do Not Re-Research)

The v1.0 stack is already in the project. This document covers only what changes for v1.1.

| Technology | Version | Status |
|------------|---------|--------|
| SwiftUI + UIKit | iOS 26.2 deployment target | Existing |
| Vortex | 1.0.4 (latest as of Aug 2025) | Existing — already at latest |
| lottie-spm | pinned to 4.5.x | Existing — upgrade to 4.6.0 |
| supabase-swift | existing | Existing — no change |
| AnimationPolicy | internal utility | Existing — extend for new flows |
| HapticEngine | internal utility | Existing — no change |
| ActionIconMapper | internal utility | Existing — no change |

---

## New Stack Requirements for v1.1

**No new SPM dependencies needed.**

All four features (action picker, node tap bubbles, user-driven ordering, two-step completion sheet) are fully buildable from:
- Native SwiftUI APIs, all available at iOS 16.4+ (well within the iOS 26.2 deployment target)
- The existing lottie-spm and Vortex packages already in the project
- Pure Swift state management extending the existing ViewModel pattern

Adding a third-party tooltip library would introduce a dependency for what is a 30-line custom `Path`. Adding a drag-reorder library is wrong for this feature: user-driven ordering is tap-to-select-next, not physical drag-and-drop. Resist scope creep.

---

## Recommended Stack Changes

### Core Technologies — No New Packages

| Technology | Version | Purpose | Why No Change |
|------------|---------|---------|---------------|
| SwiftUI | iOS 26.2 | All UI for all four features | All required APIs present: `.popover` + `.presentationCompactAdaptation`, `LazyVGrid`, `presentationDetents(selection:)`, `@Namespace` + `matchedGeometryEffect` |
| lottie-spm | 4.6.0 (upgrade from 4.5.x) | Congrats animation in two-step half-sheet | 4.6.0 is current as of January 2025. `LottieView` SwiftUI API is unchanged since 4.3.0. The upgrade is a drop-in and adds task cancellation fixes. Reuse existing `trophy.json` bundle resource |
| Vortex | 1.0.4 | Confetti in node bubbles and completion steps | Already on latest tag (Aug 2025). No change needed |

### New Usage of Existing Native APIs

These are native SwiftUI APIs the project does not yet use but will need for v1.1. No installation required — they ship with the iOS 26.2 SDK.

| API | Purpose | Why Chosen | Availability |
|-----|---------|------------|--------------|
| `.popover(isPresented:attachmentAnchor:)` + `.presentationCompactAdaptation(.popover)` | Tap-to-reveal callout bubble above each journey node showing action name + CTA | Forces true floating popover (not a sheet) on iPhone. `.point(.top)` as `attachmentAnchor` anchors it above the 56pt node circle. The only native approach that produces a positioned, auto-dismissing overlay without a full sheet. | iOS 16.4+ — safe at iOS 26.2 deployment target |
| `presentationDetents([.medium, .large], selection: $selectedDetent)` | Two-step completion sheet: programmatically expand from congrats (`.medium`) to action picker (`.large`) without dismissing and re-presenting | Selection binding is the only way to change detents from inside the sheet without a dismiss/re-present cycle, which would break the "keep the momentum" UX flow. | iOS 16+ |
| `interactiveDismissDisabled(_:)` | Lock the sheet during the congrats step so an accidental swipe doesn't kill the celebration. Release when the sheet is at `.large` (action picker) | Already verified working with `presentationDetents`. Combine with detent selection binding: when detent == `.medium`, pass `true`; when `.large`, pass `false`. | iOS 15+ |
| `@Namespace` + `matchedGeometryEffect` | Animate the chosen action card from the picker grid into its journey node slot | Built-in SwiftUI, zero dependencies. Creates the visual continuity that the chosen action becomes the next node. The same pattern powers segmented control highlights and card-to-grid transitions across the SwiftUI ecosystem. | iOS 14+ |
| `LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())])` | Action picker grid layout — 2-column card grid showing all incomplete actions | Shows all options at once without scrolling, matching the "see the whole plan" mental model. CommitmentSheet today uses a vertical `ForEach` of top 3; the picker needs all actions in a scannable grid. | iOS 14+ |

---

## Installation

No new packages to add. One version bump:

In Xcode: **File > Packages > Update to Latest Package Versions**

This pulls lottie-spm 4.6.0 if the project is pinned to 4.5.x. Verify the resolved version in Xcode's Package Dependencies pane after update.

---

## Alternatives Considered

| Recommended | Alternative | Why Not |
|-------------|-------------|---------|
| `.popover` + `.presentationCompactAdaptation(.popover)` for node bubbles | Third-party tooltip library (AMPopTip, SwiftUI-Tooltip, EasyTipView) | All three are UIKit wrappers or sporadically maintained. The native `.popover` + `.presentationCompactAdaptation(.popover)` API (iOS 16.4+) does exactly this with zero dependencies and native dismiss behavior. Deployment target is iOS 26.2 — no compatibility risk. |
| `presentationDetents(selection:)` for two-step sheet | Two separate sheets in sequence (dismiss first, present second) | Dismissing between steps kills the celebration momentum and produces a visual gap. A single sheet that expands detents is the correct UX — matches Apple's own "Rate this app" and App Store purchase flows. |
| Client-side `[UUID]` array ordering in ViewModel | `position` column on `micro_actions` Supabase table | Supabase schema changes are out of scope per PROJECT.md. Client-side ordering in memory is sufficient: the journey path renders from `viewModel.orderedMicroActions` (computed). Ordering does not need to survive an app restart for v1.1. |
| `LazyVGrid` for action picker | Vertical `ForEach` list (same as CommitmentSheet) | CommitmentSheet limits to top 3 actions. The full action picker must show all remaining actions. A 2-column grid is denser and faster to scan than a tall vertical list, especially for plans with 7+ actions. |
| `matchedGeometryEffect` for picker → node transition | Plain `.transition(.scale)` on the selected card | `matchedGeometryEffect` explicitly handles cross-view coordinate spaces, which is the core problem here: the picker card and the journey node are in different parts of the view hierarchy. A plain transition can't track position across them. |
| Reusing existing `trophy.json` Lottie for congrats half-sheet | Adding new Lottie JSON files for the half-sheet step | The trophy animation already exists in the bundle and is proven to work via `PlanCompletionView`. Reusing it avoids bundle bloat and keeps celebration visual language consistent. Scale it down to fit the `.medium` detent height. |

---

## What NOT to Add

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| Any drag-reorder library (`swiftui-reorderable-foreach`, etc.) | The ordering UX is tap-to-select-next, not physical drag. A drag library adds gesture conflicts with the existing `ScrollView` and node taps, and solves the wrong problem. | Pure Swift array manipulation in ViewModel on action selection. |
| `SheeKit` (UISheetPresentationController wrapper) | Deployment target is iOS 26.2. Native `presentationDetents` with `selection:` binding covers all required sheet behaviors without a UIKit bridge. SheeKit predates the current native API being sufficient. | Native SwiftUI `presentationDetents`. |
| `PopoverMessageBubble` / `qusc/SwiftUI-Popover` | Both wrap UIKit popovers. The native `.popover` + `.presentationCompactAdaptation(.popover)` at iOS 16.4+ is the direct SwiftUI-native replacement. | Native SwiftUI `.popover` modifier. |
| New Lottie JSON animation files | Additional `.json` or `.lottie` files bloat the app bundle and create visual inconsistency. The existing `trophy.json` covers every celebration moment. | Reuse `trophy.json`. Adjust `LottieView` frame size as needed. |
| Sound effects (`AVAudioPlayer` / `AVFAudio`) | Explicitly excluded from scope in PROJECT.md. | HapticEngine (existing) provides physical feedback. |
| `@AppStorage` or `UserDefaults` for action order persistence | Out of scope for v1.1. Ordering lives in session memory only. Persisting would require additional design decisions about conflict resolution with server state. | In-memory `@Published var userActionOrder: [UUID]` only. |

---

## Stack Patterns by Feature

**Action picker screen (first visit + after each completion):**
- Present via existing `showCommitmentPicker` / `showMomentumPicker` booleans, or unify into `showActionPicker: Bool` on the ViewModel
- `LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())])` inside a `.presentationDetents([.large])` sheet
- `@State var selectedActionId: UUID?` for highlight state inside the sheet
- `matchedGeometryEffect(id: action.id, in: namespace)` on both picker card and destination journey node for transition
- Wire "Confirm" button to new `viewModel.selectNextAction(id:)` method

**Node tap bubbles (action name + CTA on tap, all states):**
- Add `@State private var showBubble = false` to `JourneyNodeView`
- In existing `onTap` closure: set `showBubble = true` instead of immediately calling `selectedAction = action`
- `.popover(isPresented: $showBubble, attachmentAnchor: .point(.top)) { NodeBubbleView(action: action, state: state, onOpen: { showBubble = false; selectedAction = action }) .presentationCompactAdaptation(.popover) }`
- `NodeBubbleView`: compact VStack with emoji, action name (2 lines max), time pill, and CTA button ("Open" → opens ActionDetailSheet; "Locked" → disabled label)
- Tapping outside auto-dismisses the bubble (default popover dismiss behavior — correct here)

**User-driven ordering:**
- Add `@Published var userActionOrder: [UUID]` to `ActionPlanViewModel`; default empty = server/priority order
- Add computed `var orderedMicroActions: [MicroAction]` that applies `userActionOrder` on top of `microActions`
- Add `func selectNextAction(id: UUID)` that moves the chosen ID to front of incomplete IDs in `userActionOrder`
- `JourneyPathView` renders from `viewModel.orderedMicroActions` instead of `viewModel.microActions`
- The existing `nodeState(at:actions:)` function works unchanged — "active" is still the first incomplete in the ordered array

**Two-step completion sheet (congrats → action picker):**
- `@State var completionSheetDetent: PresentationDetent = .medium`
- Sheet: `.presentationDetents([.medium, .large], selection: $completionSheetDetent)`
- `.interactiveDismissDisabled(completionSheetDetent == .medium)` — locked at congrats, dismissable from picker
- Step 1 (`.medium` height): `LottieView(animation: .named("trophy"))` + congrats copy + "Keep the momentum?" button
- "Keep the momentum?" tapped → `completionSheetDetent = .large` (sheet expands, no dismiss/re-present)
- Step 2 (`.large` height): action picker grid slides up via `if completionSheetDetent == .large { ActionPickerGrid(...) }`
- Wire to existing `celebrationState == .planComplete` path in `ActionPlanDetailView`, replacing or layering over `PlanCompletionView`

---

## Version Compatibility

| Package | Version | Compatible With | Notes |
|---------|---------|-----------------|-------|
| lottie-spm | 4.6.0 | iOS 13+, Swift 5.7+ | `LottieView` SwiftUI API stable since 4.3.0. `playbackMode` and `LottiePlaybackMode` parameters unchanged. Drop-in upgrade from any 4.x version. Verified via GitHub releases. |
| Vortex | 1.0.4 | iOS 16+, Swift 5.9+ | `VortexView` + `VortexViewReader` API unchanged since 1.0.0. `startTimeOffset` added in 1.0.4 is not required for this milestone. Verified via GitHub tags. |
| Native SwiftUI APIs | iOS 16.4+ for `.presentationCompactAdaptation` | iOS 26.2 deployment target | All other APIs (`presentationDetents`, `LazyVGrid`, `matchedGeometryEffect`) available iOS 16+/14+. Everything safe at iOS 26.2. |

---

## Sources

- https://github.com/twostraws/Vortex/tags — Vortex 1.0.4 confirmed as latest tag (Aug 2025) — HIGH confidence
- https://github.com/airbnb/lottie-spm/releases — lottie-spm 4.6.0 confirmed as latest release (Jan 2025) — HIGH confidence
- Apple Developer Documentation: `presentationCompactAdaptation(_:)` — iOS 16.4+ availability confirmed — HIGH confidence
- Apple Developer Documentation: `presentationDetents(_:selection:)` — iOS 16+ availability confirmed — HIGH confidence
- Apple Developer Documentation: `interactiveDismissDisabled(_:)` — iOS 15+ availability confirmed — HIGH confidence
- Existing codebase audit (CommitmentSheet.swift, ActionDetailSheet.swift, JourneyNodeView.swift, ActionPlanDetailView.swift, PlanCompletionView.swift) — Integration points and existing patterns confirmed by direct file reads — HIGH confidence
- project.pbxproj — iOS 26.2 deployment target, Vortex 1.0.4 and lottie-spm as only animation SPM packages — HIGH confidence

---

*Stack research for: Abimo v1.1 — action picker, node tap bubbles, user-driven ordering, two-step completion sheet*
*Researched: 2026-03-19*
