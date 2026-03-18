# Pitfalls Research

**Domain:** Gamified SwiftUI app — Lottie animations, journey path UI, celebration screens
**Researched:** 2026-03-18
**Confidence:** MEDIUM-HIGH (Lottie issues confirmed via GitHub issues/discussions; gamification UX from research literature; SwiftUI specifics from WWDC and community sources)

---

## Critical Pitfalls

### Pitfall 1: Lottie UIViewRepresentable Recreated on Every State Change

**What goes wrong:**
`LottieAnimationView` is constructed fresh on every SwiftUI re-render because `makeUIView` is called too frequently. In scrollable views like `LazyVStack` or `List`, this causes animation layer creation overhead to accumulate — users see hitches and dropped frames when scrolling past action cards on the journey path. With 5+ animations on screen simultaneously, CPU can spike to 70-80% and memory exceeds 300-500 MB.

**Why it happens:**
SwiftUI's diffing cannot reuse `UIViewRepresentable` instances the same way UIKit reuses cells. When parent state changes (e.g., a task completes, a scroll offset updates), SwiftUI tears down and rebuilds the hosting view, which recreates the `LottieAnimationView` and re-initialises its animation layer. This was confirmed as the root cause in airbnb/lottie-ios issue #2516 and discussion #2517, with reports active as of January 2025.

**How to avoid:**
- Use `LottieView` (the official SwiftUI component from Lottie 4.3.0+), not a hand-rolled `UIViewRepresentable`. The official wrapper manages lifecycle better.
- Trigger Lottie animations only at the moment they are needed (celebration screen appears, action tapped) — do not keep idle Lottie views looping in list cells.
- On the journey path, use SwiftUI-native animations (spring, scale, checkmark morphing) for per-card idle state. Reserve Lottie for one-off celebration moments.
- Cache `LottieAnimation` objects with `LottieAnimation.named()` so the JSON is parsed once per session, not on each view creation.

**Warning signs:**
- Instruments shows repeated `animationLayerCreation` calls during scroll.
- Memory climbs linearly as user scrolls through more action cards.
- CPU > 40% while the journey path is idle (no active gesture).

**Phase to address:**
Journey Path phase (building the vertical path and action cards). Establish the no-Lottie-in-list-cells rule before any card UI is built.

---

### Pitfall 2: Core Animation Engine Silent Fallback to Main Thread

**What goes wrong:**
Lottie 4.0+ defaults to `.automatic` rendering, which uses the Core Animation engine (GPU, off-process, 0% CPU overhead). However, if an animation file uses unsupported features — After Effects expressions, trim paths on filled shapes, time remapping keyframes, or rounded corners on combined shapes — Lottie silently falls back to the Main Thread engine with no warning at runtime. The developer assumes they have GPU rendering; they actually have a CPU-blocking animation that degrades under load.

**Why it happens:**
Designers download animations from LottieFiles without knowing which features they use. The `.automatic` fallback is silent by design; there is no console log or assertion to signal the downgrade. Issues #1946 and #2060 in the lottie-ios repo document cases where `.automatic` mode silently dropped to main thread.

**How to avoid:**
- Source celebration animations from LottieFiles filtered to "Core Animation compatible" or test explicitly.
- During development, temporarily set `LottieConfiguration.shared.renderingEngine = .coreAnimation` (no fallback) to force a crash-or-render, confirming the file is compatible.
- Test each `.json` file in the Lottie Sample App before integrating.
- Avoid After Effects expressions entirely — they are not supported on iOS at all.

**Warning signs:**
- Instruments shows Lottie CPU usage above 5% during a celebration animation.
- The animation plays correctly but the main thread shows > 16ms frame time during playback.
- Animation appears slightly different between simulator and device (expression evaluation differs).

**Phase to address:**
Animation Assets phase (before celebration screens are built). Vet every `.json` asset for Core Animation compatibility before wiring it to any SwiftUI view.

---

### Pitfall 3: Celebration Screen Blocks User After Completion

**What goes wrong:**
A "Nice job!" screen appears after every micro-action completion and requires an explicit user tap to dismiss. With 5-10 actions per plan, this becomes friction — users start feeling interrupted rather than rewarded. The celebration designed to motivate becomes the obstacle between the user and their next action.

**Why it happens:**
Designers model celebration screens on Duolingo's lesson-complete screen, which appears once per session. Applied to per-micro-action completions (which happen multiple times in one sitting), the same mechanic creates a different user experience — one of interruption rather than reward. The pattern is borrowed without accounting for frequency.

**How to avoid:**
- Distinguish between micro-action completions (inline celebration: checkmark animation, haptic, brief color flash — no modal) and full plan completions (dedicated celebration screen is appropriate here).
- Auto-dismiss celebration overlays after 1.5-2 seconds, or use a non-blocking banner that slides in and out.
- The dedicated celebration screen described in PROJECT.md ("Nice job!" screen) should only block for the full plan completion, not each micro-action.

**Warning signs:**
- User testing shows repeated tapping through celebration screens without reading them.
- Session logs show celebration screen dismissed within < 500ms of appearing (users treating it as friction, not reward).
- Completion rate drops after the celebration screen is introduced.

**Phase to address:**
Celebration Screens phase. Define the distinction between inline celebration (non-blocking) and full-plan celebration (blocking, one time) before implementation begins.

---

### Pitfall 4: `accessibilityReduceMotion` Ignored or Checked Too Late

**What goes wrong:**
All Lottie animations, confetti particles, progress ring animations, and journey path transitions play regardless of the user's "Reduce Motion" system preference. For users with vestibular disorders, this causes physical discomfort. It is also an App Store review concern — Apple's HIG explicitly requires respecting Reduce Motion. If it is addressed only at the end, every animation touchpoint must be revisited individually.

**Why it happens:**
Developers add animations first and treat accessibility as a polish step. The check `UIAccessibility.isReduceMotionEnabled` (or SwiftUI's `@Environment(\.accessibilityReduceMotion)`) is a one-liner, but it must be wired into every animation trigger point. Forgetting even one (e.g., the confetti on plan completion) produces an incomplete implementation.

**How to avoid:**
- Create a shared `AnimationPolicy` service at the start of the milestone: `var shouldAnimate: Bool { !accessibilityReduceMotion }`. All animation sites check this instead of calling UIAccessibility directly.
- For Lottie: when reduce motion is active, either skip the animation or show a static first frame using `LottieView(...).playing(false)`.
- For confetti and SwiftUI animations: wrap all `withAnimation` calls through the policy check.
- Provide static alternatives: a simple filled checkmark instead of the animated morphing checkmark; a static color change instead of a particle burst.

**Warning signs:**
- No `accessibilityReduceMotion` text appears in a codebase search during code review.
- Animations trigger in snapshot tests without a reduce-motion variant.
- VoiceOver testing reveals animations playing when navigating action cards.

**Phase to address:**
Phase 1 of the milestone (foundation/setup). Establish the `AnimationPolicy` wrapper before any animation is wired up.

---

### Pitfall 5: VoiceOver Cannot Read Action Cards or Journey Path

**What goes wrong:**
The journey path is a visually rich custom layout — path nodes, progress indicators, card overlays. VoiceOver has no structured way to traverse it. Action cards with emoji icons, status indicators, and swipe-to-reveal interactions are silent to assistive technology. The app becomes unusable for screen reader users.

**Why it happens:**
Custom SwiftUI layouts (especially those using `GeometryReader`, `Canvas`, or `ZStack` with absolute positioning for the path) do not produce accessibility elements automatically. Emoji rendered as decorative visuals have no semantic role. Interactive elements hidden behind gestures (long press, swipe) are invisible to VoiceOver.

**How to avoid:**
- Attach `.accessibilityLabel`, `.accessibilityValue`, and `.accessibilityHint` to every action card from the first implementation.
- Mark purely decorative elements (path line, background shapes) with `.accessibilityHidden(true)`.
- Ensure hidden interactions (swipe to reveal deep links/templates) are also accessible via `.accessibilityAction`.
- Use `.accessibilityElement(children: .combine)` on card containers to produce a single tappable element with a complete description.

**Warning signs:**
- VoiceOver reads out "Image" for emoji icons without labels.
- Navigating the journey path with VoiceOver jumps in non-linear order.
- Interactive elements in collapsed card state are unreachable without swipe gesture.

**Phase to address:**
Action Card phase. Bake accessibility labels into the card component before the component is reused across the journey path.

---

### Pitfall 6: Over-Gamification Creates Anxiety Instead of Motivation

**What goes wrong:**
Streaks, completion counts, and progress rings shift user psychology from "I'm making progress" to "I must not break this." When a user misses a day, the broken streak display communicates failure rather than resumption. Combined with too many visual rewards per session, the app starts to feel like a Skinner box — obligation rather than delight.

**Why it happens:**
The mechanics that drive Duolingo engagement (streaks, leagues, loss aversion) work in a language-learning context where daily practice is the core loop. This app's micro-actions are tied to specific plans that may naturally have irregular completion patterns. Applying streak mechanics designed for daily habits to project-based work creates misaligned incentives.

**How to avoid:**
- Keep streak display positive: show current streak when it's active, show "Welcome back" when resuming, not a broken-streak shame state.
- The `MomentumDashboard` integration into the journey path should celebrate activity, not punish inactivity.
- Limit celebrations per session — the full-plan celebration screen is the peak moment; multiple micro-action celebrations should be lighter (haptic + checkmark only, not confetti every time).
- The PROJECT.md explicitly excluded XP/points and leaderboards — maintain that discipline; do not add them as "small enhancements."

**Warning signs:**
- Designs show a "streak broken" red state prominently.
- Confetti fires on every single micro-action (3-10 times per session).
- Users describe the app as "stressful" in early feedback rather than "satisfying."

**Phase to address:**
Celebration Screens and Journey Path phases. Define celebration intensity levels (micro, macro) in the design spec before building.

---

### Pitfall 7: Smooth Transitions Break When Data Reloads Mid-Animation

**What goes wrong:**
A user taps to complete an action. The animation sequence begins (haptic → checkmark morphs → card color transitions). Simultaneously, the completion triggers an async Supabase write, and when it resolves, the ViewModel publishes new state. SwiftUI re-renders the journey path mid-animation, causing the card to snap to its final state, or worse, the animation plays on the wrong card.

**Why it happens:**
SwiftUI animations are interrupted when their driving state changes unexpectedly. If `isCompleted` flips to `true` during a local animation sequence that is also driven by `isCompleted`, the animation and state are fighting. This is a classic MVVM problem: the ViewModel is the source of truth but the UI needs local animation state that exists independently of server-confirmed truth.

**How to avoid:**
- Separate local animation state from server-confirmed state. Use a local `@State var isAnimatingCompletion: Bool` that drives the visual sequence. Only after the animation completes, propagate the confirmed state from the ViewModel.
- Use `withAnimation(.spring) { ... }` with a completion callback (`iOS 17+: withAnimation(...) { ... } completion: { ... }`) to sequence: (1) animate, (2) then publish new ViewModel state.
- Do not bind Lottie `isPlaying` directly to a ViewModel `@Published` property that changes during network calls.

**Warning signs:**
- Cards visually "snap" to their completed state instead of transitioning.
- Completing an action while on a slow network produces inconsistent animation behavior.
- The same animation plays twice (once optimistically, once when server confirms).

**Phase to address:**
Journey Path / Action Card phase. Define the local-vs-server state split in the card component before connecting to ViewModel.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Hand-rolled `UIViewRepresentable` wrapper for Lottie | Full control over lifecycle | makeUIView called on every re-render, animation flicker, memory growth | Never — use official `LottieView` from Lottie 4.3.0+ |
| Lottie animations in every action card cell (idle loops) | Visually rich journey path | 300-500 MB memory, 70-80% CPU during scroll | Never — use native SwiftUI for idle states, Lottie for triggered moments only |
| Single `@Published` bool driving both local animation and server state | Simple code | Race conditions, animation interruptions on network response | Never for animated state — split local and remote truth |
| No `AnimationPolicy`/`accessibilityReduceMotion` wrapper | Faster first pass | Every animation site must be revisited individually at QA | Never — costs 30 minutes upfront, saves hours in audit |
| Confetti on every micro-action completion | More "wow" moments | Repetition fatigue, perceived as noise after first session | Never — reserve confetti for plan completion |
| `AnyView` wrapping in journey path node views | Easier conditional rendering | SwiftUI cannot diff, forces full redraw of all nodes on any state change | Never in hot-path scrollable views |

---

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| Lottie SPM | Adding package but using old `UIViewRepresentable` wrapper from tutorials | Use `import Lottie` then `LottieView(name: "animation")` directly — official SwiftUI API since 4.3.0 |
| Lottie + `.automatic` rendering | Assuming `.automatic` always means Core Animation | Test with `.coreAnimation` (no fallback) in DEBUG to verify asset compatibility |
| `UIImpactFeedbackGenerator` | Creating a new generator instance on every tap | Instantiate once (at `init` or `onAppear`), call `.prepare()` slightly before expected use, then `.impactOccurred()` |
| SwiftUI `.sensoryFeedback` (iOS 17+) | Using UIKit generator when the declarative modifier is available | Prefer `.sensoryFeedback(.success, trigger: completedCount)` for SwiftUI-idiomatic haptics |
| Supabase completion write + animation | Triggering ViewModel state update that kills in-flight animation | Sequence: animate locally first, then confirm to server, then update ViewModel state |
| `accessibilityReduceMotion` environment | Checking it inside a `LottieView` body vs. at call site | Read `@Environment(\.accessibilityReduceMotion)` at the parent view level and pass a `shouldPlay` binding down |

---

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Multiple concurrent Lottie instances in visible scroll region | 70-80% CPU, frame drops to 30fps during scroll | Lottie only on celebration screens and triggered moments; native SwiftUI for card idle states | 3+ animated views simultaneously visible |
| `GeometryReader` wrapping every journey path node | Constant layout recalculation, O(n) on every scroll event | Use `GeometryReader` once at the path container level to get total height; pass fixed offsets to nodes | Any path with > 5 nodes |
| `withAnimation` on a value that changes from async context | Animation plays twice or not at all | Ensure all ViewModel @Published mutations happen on `@MainActor`; use `.receive(on: DispatchQueue.main)` | Any async Supabase callback |
| Progress ring `trim` animation on `.onChange` of server data | Ring snaps to final position instead of animating | Drive ring via local `@State` that animates, sync to server value with `withAnimation` | Every action completion with network latency > 100ms |
| Confetti `CAEmitterLayer` or `SpriteKit` SKEmitterNode not stopped | Memory/GPU grows after celebration exits | Stop and remove emitter layer in `onDisappear` or in the view's deinit | Celebration screen shown 3+ times per session |

---

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Celebration modal after every single micro-action | Friction between actions; users tap through without reading | Inline non-blocking celebration (haptic + checkmark morph) for micro-actions; full modal only for plan completion |
| Streak display showing "broken" state prominently | Shame response; users avoid opening app after a missed day | Show streak when active; show encouraging "Welcome back — keep going" when resuming, never a broken-streak state |
| Journey path nodes all visible and equally weighted | No sense of progression; path feels like a list in disguise | Lock/dim future nodes, apply subtle scale difference to current node, celebrate reaching new nodes |
| Hiding all action detail behind gestures | Discovery problem; users don't know tap vs. swipe interaction exists | Show a hint affordance (e.g., chevron icon) on first few cards; use `.contextMenu` for secondary actions |
| Identical celebration for a 2-minute action and a 2-hour action | Reward feels disproportionate; no sense of milestone weight | Use time-estimate or action type to modulate celebration intensity (standard vs. milestone) |
| Card animations triggered on list initial load | All cards animate in simultaneously; feels chaotic not polished | Stagger entry animations with increasing delay: `delay = index * 0.05s` |

---

## "Looks Done But Isn't" Checklist

- [ ] **Lottie reduce motion:** `accessibilityReduceMotion` check exists at every Lottie call site, not just the celebration screen — verify with a search for `LottieView` vs `accessibilityReduceMotion` occurrences.
- [ ] **Core Animation compatibility:** Every `.json` animation file has been tested with `.coreAnimation` rendering engine forced (not `.automatic`) — verify no fallback warnings appear.
- [ ] **Haptic feedback on silent mode:** Haptics still fire when device is on silent (correct behavior); sound-dependent feedback removed — verify no `AudioServicesPlaySystemSound` calls in completion handlers.
- [ ] **Journey path scroll position preserved:** After completing an action, scroll position returns to the same node, not the top — verify `ScrollViewReader` `scrollTo` is called with the correct ID.
- [ ] **Celebration screen auto-dismiss:** The micro-action inline celebration does not require a tap — verify it dismisses after a fixed duration or on next user gesture.
- [ ] **VoiceOver traversal order:** Journey path nodes are read top-to-bottom matching visual order — verify with VoiceOver enabled in simulator.
- [ ] **Animation completion callback on spring animations:** Spring `.withAnimation` completions fire after the imperceptible tail ends, not when visually complete — verify using `completionCriteria: .removed` or a fixed-duration animation for sequencing logic.
- [ ] **Lottie memory released:** `LottieAnimationView` is not retained after the celebration screen is dismissed — verify with Instruments Leaks template after 5 celebration cycles.

---

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Lottie in list cells causing scroll jank | MEDIUM | Replace `LottieView` in cells with native SwiftUI animation; move Lottie to a fullscreen overlay triggered on action tap |
| Core Animation fallback discovered after assets integrated | LOW | Replace the non-compatible `.json` file; check LottieFiles for alternative with same concept that passes compatibility test |
| Celebration screen causing user friction (found in user testing) | LOW | Convert blocking modal to non-blocking overlay with `ZStack` + `transition(.opacity)` + `onAppear` timer dismiss |
| `accessibilityReduceMotion` missed across many call sites | MEDIUM | Add `AnimationPolicy` wrapper; grep for all `LottieView`, `withAnimation`, and `CAEmitterLayer` and route through it |
| Animation interrupted by async state update | MEDIUM | Add local `@State` animation flags to affected views; audit all `@Published` mutations that fire during animation sequences |
| Over-gamification feedback from users | LOW-MEDIUM | Reduce celebration intensity (remove confetti from micro-actions); adjust streak display to positive framing; no architectural change needed |

---

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Lottie recreated on re-render | Journey Path / Action Cards phase | Instruments scroll test: CPU < 20% with 10-card path visible |
| Core Animation silent fallback | Animation Assets (pre-building) | Force `.coreAnimation` mode; all animations play without fallback |
| Celebration screen blocks flow | Celebration Screens phase design spec | Micro-action completion: no modal appears; plan completion: modal appears once |
| `accessibilityReduceMotion` ignored | Foundation phase (before any animation) | Grep confirms `AnimationPolicy` or `accessibilityReduceMotion` at every animation site |
| VoiceOver unreadable cards | Action Card phase | VoiceOver traversal test: all cards read label + status + hint |
| Over-gamification anxiety | Design phase (celebration spec) | User testing: "satisfying" > "stressful" in feedback; no confetti on micro-actions |
| Animation/state race condition | Journey Path phase | Complete action on airplane mode: animation plays fully before card updates to completed state |

---

## Sources

- airbnb/lottie-ios GitHub Discussion #2517 — "Lottie performs poorly in SwiftUI" (January 2025 activity): https://github.com/airbnb/lottie-ios/discussions/2517
- airbnb/lottie-ios Issue #2516 — SwiftUI performance, `makeUIView` called too frequently: https://github.com/airbnb/lottie-ios/issues/2516
- airbnb/lottie-ios Issue #1946 — `.automatic` mode not working for some animations (silent fallback): https://github.com/airbnb/lottie-ios/issues/1946
- Announcing Lottie 4.0 for iOS — Core Animation rendering engine, off-process GPU rendering: https://medium.com/airbnb-engineering/announcing-lottie-4-0-for-ios-d4d226862a54
- Lottie 4.3.0 SwiftUI support announcement (official `LottieView` component): https://github.com/airbnb/lottie-ios/discussions/2189
- WCAG 2.1 Compliance for Lottie Animations (LottieFiles Developer Portal): https://developers.lottiefiles.com/docs/resources/wcag/
- SwiftUI Scroll Performance: The 120FPS Challenge (Jacob's Tech Tavern): https://blog.jacobstechtavern.com/p/swiftui-scroll-performance-the-120fps
- Demystify SwiftUI performance — WWDC23: https://developer.apple.com/videos/play/wwdc2023/10160/
- "Avoiding the Pitfalls: Best Practices and Ethical Gamification in UX" (Medium): https://medium.com/@gideonlyomu/avoiding-the-pitfalls-best-practices-and-ethical-gamification-in-ux-45ff3f2739ee
- "The Dark Side of Gamification: Ethical Challenges in UX/UI Design" (Medium): https://medium.com/@jgruver/the-dark-side-of-gamification-ethical-challenges-in-ux-ui-design-576965010dba
- SwiftUI Animation Completion (withAnimation completion callback, iOS 17+): https://www.hackingwithswift.com/quick-start/swiftui/how-to-run-a-completion-callback-when-an-animation-finishes
- iOS Advanced Lottie Animation — Memory Management (IDN Engineering): https://medium.com/idn-engineering/ios-advanced-lottie-animation-memory-management-7016402f0b1a

---
*Pitfalls research for: Gamified SwiftUI app — Lottie, journey path, celebration screens (Abimo)*
*Researched: 2026-03-18*
