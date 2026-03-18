# Architecture Research

**Domain:** Gamified task completion UX in SwiftUI MVVM — journey path, celebration overlays, animation coordination
**Researched:** 2026-03-18
**Confidence:** MEDIUM (SwiftUI patterns from official docs + community; Duolingo-specific path layout inferred from primitives)

## Standard Architecture

### System Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                          View Layer                                  │
│                                                                      │
│  ┌─────────────────────┐  ┌──────────────────┐  ┌───────────────┐  │
│  │  JourneyPathView    │  │  CelebrationView  │  │  ActionCard   │  │
│  │  (replaces Detail)  │  │  (fullscreen      │  │  (replaces    │  │
│  │                     │  │   overlay)        │  │  MicroAction  │  │
│  │  ScrollView + VStack│  │                   │  │  Row)         │  │
│  │  of path nodes      │  │  Lottie +         │  │               │  │
│  │  + connecting lines │  │  confetti +       │  │  emoji icon + │  │
│  │  + progress ring    │  │  haptic trigger   │  │  expand sheet │  │
│  └──────────┬──────────┘  └────────┬─────────┘  └──────┬────────┘  │
│             │                      │                    │           │
└─────────────┼──────────────────────┼────────────────────┼───────────┘
              │  @ObservedObject      │  .sheet / ZStack    │ callback
┌─────────────┼──────────────────────┼────────────────────┼───────────┐
│                       ViewModel Layer                                │
│                                                                      │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │  ActionPlanViewModel (@MainActor, ObservableObject)          │    │
│  │                                                              │    │
│  │  @Published microActions: [MicroAction]    ← existing       │    │
│  │  @Published progress: Double               ← existing       │    │
│  │  @Published activeCommitment: Commitment?  ← existing       │    │
│  │                                                              │    │
│  │  + @Published celebrationState: CelebrationState  ← new     │    │
│  │  + @Published justCompletedAction: MicroAction?   ← new     │    │
│  │  + func iconName(for: MicroAction) -> String       ← new    │    │
│  └─────────────────────────────────────────────────────────────┘    │
│                                                                      │
└────────────────────────────────┬─────────────────────────────────────┘
                                 │ async/await
┌────────────────────────────────┼─────────────────────────────────────┐
│                       Service Layer (unchanged)                      │
│                                                                      │
│  SupabaseService  ·  AIAnalysisService  ·  AudioRecordingService     │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility | Talks To |
|-----------|----------------|----------|
| `JourneyPathView` | Vertical scroll canvas with staggered node layout, connecting path lines, progress ring header | `ActionPlanViewModel` (read state + call toggleMicroAction) |
| `JourneyNodeView` | Single action node: circle button with emoji/icon, state (locked/active/done), tap target | `JourneyPathView` (callback) |
| `ActionDetailSheet` | Bottom sheet expanding one action's details (done criteria, template, deep link) — replaces expanded MicroActionRow | `ActionPlanViewModel` (read action, commit) |
| `CelebrationOverlay` | Full-screen overlay: Lottie animation + confetti burst + haptics; auto-dismisses after N seconds | `ActionPlanViewModel` (reads `celebrationState`) |
| `PlanCompletionView` | Full-screen dedicated screen: summary stats, big celebration, "what's next" CTA | `ActionPlanViewModel` (triggered when all done) |
| `ProgressRingView` | Circular trim-based progress ring showing X/total; replaces progress bar | `ActionPlanViewModel` (reads `progress`) |
| `HapticEngine` | Namespace of static helpers wrapping `UIImpactFeedbackGenerator` / `UINotificationFeedbackGenerator` | Called from ViewModel on MainActor |
| `ActionIconMapper` | Pure function mapping `MicroAction.actionType` → SF Symbol name + accent color | `ActionCard`, `JourneyNodeView` |
| `ActionsTabView` | Existing list of plans; gains journey-path entry points per plan | `ActionsTabViewModel` (unchanged) |

## Recommended Project Structure

```
Abimo/
├── Models/
│   └── ActionPlan.swift          # unchanged — reuse as-is
├── ViewModels/
│   └── ActionPlanViewModel.swift # extend with celebrationState, justCompletedAction
├── Views/
│   ├── ActionPlan/
│   │   ├── ActionsTabView.swift            # existing — minor updates
│   │   ├── ActionPlanDetailView.swift      # replace body with JourneyPathView
│   │   ├── Journey/
│   │   │   ├── JourneyPathView.swift       # new — main journey scroll canvas
│   │   │   ├── JourneyNodeView.swift       # new — individual path node
│   │   │   └── ProgressRingView.swift      # new — circular progress indicator
│   │   ├── Cards/
│   │   │   ├── ActionDetailSheet.swift     # new — replaces MicroActionRow expanded state
│   │   │   └── ActionIconMapper.swift      # new — type → emoji/SF symbol mapping
│   │   ├── Celebration/
│   │   │   ├── CelebrationOverlay.swift    # new — per-action celebration
│   │   │   └── PlanCompletionView.swift    # new — all-done screen
│   │   ├── CommitmentSheet.swift           # existing — reuse unchanged
│   │   └── MomentumDashboard.swift         # existing — integrate into journey header
│   └── ...
├── Utilities/
│   └── HapticEngine.swift        # new — static haptic helpers
└── ...
```

### Structure Rationale

- **Journey/:** Path layout components are visually distinct and likely to evolve together; isolating them avoids polluting the ActionPlan folder
- **Cards/:** Action card + icon mapper are tightly coupled; grouping makes the mapping logic easy to find
- **Celebration/:** Overlay and plan-completion screen share animation lifecycle concerns; co-locating keeps that logic reviewable

## Architectural Patterns

### Pattern 1: Celebration State Machine in ViewModel

**What:** `celebrationState` is an enum published on `ActionPlanViewModel`. Views subscribe and render the appropriate overlay. The ViewModel drives state transitions, not the View.

**When to use:** Whenever animation triggers depend on business logic (completing an action, completing all actions). Keeps the View dumb.

**Trade-offs:** ViewModel holds UI-adjacent state, which purists dislike. Acceptable here because the state is transient and directly derived from domain events (completion).

**Example:**
```swift
enum CelebrationState: Equatable {
    case idle
    case singleAction(MicroAction)  // "Nice job!" overlay
    case allComplete                 // plan completion screen
}

// In ActionPlanViewModel:
@Published var celebrationState: CelebrationState = .idle

func toggleMicroAction(id: UUID, isCompleted: Bool) async {
    await confirmCompletion(id: id, ...)
    let allDone = microActions.allSatisfy(\.isCompleted)
    celebrationState = allDone ? .allComplete : .singleAction(action)
    // View auto-dismisses after timeout or user dismiss
}
```

### Pattern 2: Journey Node Layout via Offset Staggering

**What:** Render `MicroAction` nodes in a `ScrollView > VStack`. Each node is a `ZStack` containing a circle button and a connecting vertical line to the next node. Alternate left/right horizontal offsets to create the zigzag path feel.

**When to use:** The path must scroll and doesn't require actual curved geometry. Offset staggering is simpler than Path-following and performs better because it avoids GeometryReader in the hot scroll path.

**Trade-offs:** Zigzag is visual only (not a true bezier path). Sufficient for Duolingo-style feel without the complexity of scrollView-relative position tracking.

**Example:**
```swift
struct JourneyPathView: View {
    @ObservedObject var viewModel: ActionPlanViewModel

    // Alternate offsets: even index = left, odd = right
    private func offset(for index: Int) -> CGFloat {
        let baseOffset: CGFloat = 60
        return index.isMultiple(of: 2) ? -baseOffset : baseOffset
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                ForEach(Array(viewModel.microActions.enumerated()), id: \.element.id) { index, action in
                    JourneyNodeView(action: action, index: index)
                        .offset(x: offset(for: index))
                        .padding(.vertical, 20)
                }
            }
            .padding(.horizontal, 40)
        }
    }
}
```

### Pattern 3: Overlay Coordination via ZStack at Root of Detail View

**What:** `ActionPlanDetailView` (or its replacement) wraps its content in a `ZStack`. The `CelebrationOverlay` and `PlanCompletionView` sit above the journey content in that stack. Visibility is driven by `celebrationState`.

**When to use:** Whenever a celebration must cover the full view without a navigation push (celebrations are transient, not navigated to).

**Trade-offs:** ZStack overlays are simpler than NavigationStack pushes for transient celebrations. The overlay does not persist in navigation history. A full-screen `PlanCompletionView` that the user explicitly dismisses may warrant a navigation push instead — evaluate at build time.

**Example:**
```swift
// In ActionPlanDetailView:
ZStack {
    JourneyPathView(viewModel: viewModel)

    if case .singleAction(let action) = viewModel.celebrationState {
        CelebrationOverlay(action: action) {
            viewModel.celebrationState = .idle
        }
        .transition(.opacity)
        .zIndex(1)
    }

    if viewModel.celebrationState == .allComplete {
        PlanCompletionView(viewModel: viewModel)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .zIndex(2)
    }
}
.animation(.easeInOut(duration: 0.3), value: viewModel.celebrationState)
```

### Pattern 4: Reduce-Motion Guard at Animation Sites

**What:** Read `@Environment(\.accessibilityReduceMotion)` in each animated component. Replace motion-heavy animations with instant state changes or simple fades.

**When to use:** Any component that uses spring animations, confetti particles, Lottie, or positional transitions must gate on this setting.

**Trade-offs:** Adds a line of code per animated view. Worth it — Accessibility is non-negotiable per project constraints.

**Example:**
```swift
struct CelebrationOverlay: View {
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        ZStack {
            if !reduceMotion {
                // ConfettiSwiftUI or Lottie
                LottieView(animation: .named("celebration"))
                    .playbackMode(.playing(.fromProgress(0, toProgress: 1, loopMode: .playOnce)))
            }
            // Text "Nice job!" always shown regardless of motion setting
            celebrationText
        }
    }
}
```

### Pattern 5: Lottie via LottieView (SwiftUI native API, v4.3+)

**What:** Use `LottieView` from `lottie-ios` v4.3+ which provides a declarative SwiftUI component. Use `.playbackMode()` to control play/stop. Bind play trigger to `celebrationState`.

**When to use:** Celebration animations (confetti burst, checkmark, stars). Not for every interaction — only the "Nice job!" and plan-complete moments.

**Trade-offs:** Lottie adds SPM dependency. The `.lottie` bundle format (dotLottie) is smaller and faster than `.json` — prefer it for bundled animations. Must source free/licensed animations from LottieFiles or create custom ones.

**Example:**
```swift
LottieView(animation: .named("celebration-stars"))
    .playbackMode(.playing(.fromProgress(0, toProgress: 1, loopMode: .playOnce)))
    .animationDidFinish { _ in
        onDismiss()
    }
    .frame(width: 200, height: 200)
```

## Data Flow

### Action Completion Flow

```
User taps node in JourneyNodeView
    ↓
JourneyPathView calls viewModel.toggleMicroAction(id:, isCompleted: true)
    ↓
ActionPlanViewModel.toggleMicroAction()
    → optimistic local update to microActions[idx].isCompleted
    → UIImpactFeedbackGenerator.impactOccurred(.medium)  [haptic]
    → HapticEngine.completion()
    → supabase.toggleMicroAction() [persisted]
    → sets celebrationState = .singleAction(action) OR .allComplete
    ↓
CelebrationOverlay appears (ZStack overlay reacts to celebrationState)
    → Lottie animation plays
    → ConfettiSwiftUI burst triggers
    → UINotificationFeedbackGenerator.notificationOccurred(.success)
    ↓
User dismisses OR auto-dismiss after 2.5s
    → celebrationState = .idle
    → overlay fades out
    ↓
JourneyPathView re-renders: completed node shows filled checkmark state
```

### State Management

```
[ActionPlanViewModel]
    @Published microActions        → JourneyPathView (node states)
    @Published progress            → ProgressRingView (ring fill)
    @Published celebrationState    → ActionPlanDetailView ZStack (overlay visibility)
    @Published activeCommitment    → JourneyNodeView (committed badge)
    @Published justCompletedAction → CelebrationOverlay (action text)

[User Action]
    tap node → toggleMicroAction() → mutates microActions → UI updates
    tap commit → commitToAction() → mutates activeCommitment → committed badge updates
    celebrate dismiss → celebrationState = .idle → overlay fades
```

### Key Data Flows

1. **Type-to-icon mapping:** `MicroAction.actionType` → `ActionIconMapper.icon(for:)` → SF Symbol name + Color. Pure function, no async. Called in `JourneyNodeView` and `ActionDetailSheet` at render time.

2. **Plan completion detection:** Computed in `ActionPlanViewModel.toggleMicroAction()` by checking `microActions.allSatisfy(\.isCompleted)` after optimistic update. No backend query needed. Sets `celebrationState = .allComplete`.

3. **Progress ring update:** `ProgressRingView` observes `viewModel.progress` (computed Double). Animates `.trim(from:to:)` with `.animation(.spring(response: 0.5, dampingFraction: 0.8), value: progress)`.

## Scaling Considerations

This is a single-user mobile app. Scaling here means feature complexity, not server load.

| Scale | Architecture Adjustments |
|-------|--------------------------|
| Current milestone (journey + celebrations) | Single ViewModel, ZStack overlay pattern, all in ActionPlan/ group |
| If celebration logic grows (streaks, XP, badges) | Extract `CelebrationCoordinator` class that `ActionPlanViewModel` delegates to — prevents ViewModel bloat |
| If multiple animation types proliferate | `AnimationRegistry` mapping celebration type → Lottie file name + confetti config |

### Scaling Priorities

1. **First bottleneck:** `ActionPlanViewModel` becomes bloated if it accumulates celebration + streak + nudge + commitment logic. Mitigation: extract `CelebrationCoordinator` early.
2. **Second bottleneck:** Journey path scroll performance if node count grows beyond ~15. Mitigation: `LazyVStack` instead of `VStack` in `JourneyPathView`.

## Anti-Patterns

### Anti-Pattern 1: Triggering Animations from View, Not ViewModel

**What people do:** Put `withAnimation {}` blocks inside `Button` actions in views, calling `celebrationActive = true` directly in the View.

**Why it's wrong:** Completion logic (did all actions finish? which celebration to show?) lives in the ViewModel. Views that duplicate this logic diverge and cause bugs. The ViewModel already owns `microActions` — it's the only place that can reliably detect "all done."

**Do this instead:** ViewModel sets `celebrationState`. View observes and renders the appropriate overlay. View does not decide *what* to celebrate, only *how* to render the given state.

### Anti-Pattern 2: Putting Lottie/Confetti Directly in JourneyPathView

**What people do:** Embed `LottieView` and confetti inside the scroll canvas.

**Why it's wrong:** Celebration overlays must cover the full screen. Embedding inside the scroll hierarchy clips them to the scroll content area and makes z-ordering unpredictable.

**Do this instead:** `CelebrationOverlay` is a sibling of `JourneyPathView` in the `ZStack` at `ActionPlanDetailView`'s root. It uses `.ignoresSafeArea()` to fill the screen.

### Anti-Pattern 3: GeometryReader in Scroll Content for Node Positioning

**What people do:** Wrap every `JourneyNodeView` in `GeometryReader` to calculate exact scroll-relative positions for bezier path drawing.

**Why it's wrong:** GeometryReader in ScrollView content is fragile, causes layout passes, and is overkill. The visual zigzag effect is achieved with alternating `.offset(x:)` — no scroll position tracking needed.

**Do this instead:** Offset staggering (Pattern 2 above). Reserve GeometryReader for the connecting-line SVG path only if a true curved line between nodes is required (Phase 2+ enhancement).

### Anti-Pattern 4: Blocking Main Thread with Animation Prep

**What people do:** Create `UIImpactFeedbackGenerator` instances at the point of use (inside a `Task` or async context).

**Why it's wrong:** The Taptic Engine needs prepare time. Creating the generator at call time introduces latency — haptic fires late or not at all.

**Do this instead:** Use `HapticEngine` as a namespace of pre-configured `static let` generators, or call `.prepare()` a beat before anticipated interaction (e.g., when the user starts pressing a node).

## Integration Points

### External Services

| Service | Integration Pattern | Notes |
|---------|---------------------|-------|
| Supabase (existing) | `toggleMicroAction`, `commitMicroAction` — unchanged async/await | No schema changes needed; completion is already persisted |
| Lottie (new) | SPM: `lottie-ios` v4.3+ — `LottieView` in `CelebrationOverlay` | Prefer `.lottie` (dotLottie) over `.json` for bundle size; source files from LottieFiles |
| ConfettiSwiftUI (optional) | SPM: `ConfettiSwiftUI` — single `$counter` Int trigger | Alternative: pure SwiftUI Canvas particle system to avoid extra dependency |

### Internal Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| `JourneyPathView` ↔ `ActionPlanViewModel` | `@ObservedObject` + callbacks | View reads Published state; calls ViewModel methods. No reverse dependency. |
| `CelebrationOverlay` ↔ `ActionPlanViewModel` | Reads `celebrationState`; calls dismiss callback | Overlay is stateless — no @StateObject, no local logic |
| `ActionDetailSheet` ↔ `ActionPlanViewModel` | `@ObservedObject` pass-through from parent | Sheet receives ViewModel reference; can call `commitToAction` directly |
| `HapticEngine` ↔ `ActionPlanViewModel` | Direct call — `HapticEngine.completion()` | ViewModel calls on `@MainActor`, synchronous — no async needed |
| `ActionIconMapper` ↔ `JourneyNodeView` / `ActionDetailSheet` | Pure function call — `ActionIconMapper.symbol(for: action)` | No dependency injection; static or free function |

## Suggested Build Order

Dependencies flow bottom-up. Build in this order to avoid blockers:

1. **`ActionIconMapper`** — pure function, no dependencies. Can be built and tested in isolation.
2. **`ProgressRingView`** — pure view taking a `Double` progress value. No ViewModel coupling.
3. **`JourneyNodeView`** — consumes `MicroAction` and an icon from `ActionIconMapper`. Renders completed/active/locked states with checkmark animations.
4. **`HapticEngine`** — static helpers, no dependencies.
5. **Extend `ActionPlanViewModel`** — add `celebrationState`, `justCompletedAction`, update `toggleMicroAction` to set celebration state and fire haptics. Gate all-complete detection here.
6. **`JourneyPathView`** — composes nodes + connecting lines + `ProgressRingView` header. Reads from ViewModel. Replace `ActionPlanDetailView` body.
7. **`ActionDetailSheet`** — replaces `MicroActionRow` expanded state; re-uses existing template/deep link logic from `MicroActionRow`.
8. **`CelebrationOverlay`** — reads `celebrationState`. Integrates Lottie + confetti. Includes `accessibilityReduceMotion` guard.
9. **`PlanCompletionView`** — full-screen all-done screen. Can share animation components from `CelebrationOverlay`.
10. **Wire `ActionPlanDetailView` ZStack** — compose `JourneyPathView` + overlays. Replace the existing list-based detail body.

## Sources

- SwiftUI ScrollView documentation and scroll transition modifier: [Beyond scroll views — WWDC23](https://developer.apple.com/videos/play/wwdc2023/10159/)
- Lottie SwiftUI API (v4.3+): [Lottie 4.3.0 official SwiftUI discussion](https://github.com/airbnb/lottie-ios/discussions/2189)
- ConfettiSwiftUI library: [simibac/ConfettiSwiftUI](https://github.com/simibac/ConfettiSwiftUI)
- Reduce Motion accessibility pattern: [HackingWithSwift — reduce animations](https://www.hackingwithswift.com/quick-start/swiftui/how-to-reduce-animations-when-requested)
- Haptic feedback best practices: [HackingWithSwift — haptic effects](https://www.hackingwithswift.com/books/ios-swiftui/adding-haptic-effects)
- Progress ring with trim: [Animating a Circular Progress Bar in SwiftUI — Cindori](https://cindori.com/developer/swiftui-animation-rings)
- ZStack overlay coordination: community MVVM pattern for animation triggers via `@Published` state

---
*Architecture research for: Gamified journey path UX — Abimo Actions Flow Revamp*
*Researched: 2026-03-18*
