# Stack Research

**Domain:** Gamified UX — Lottie animations, celebrations, haptic feedback, journey-path UI in SwiftUI
**Researched:** 2026-03-18
**Confidence:** MEDIUM-HIGH (core framework choices HIGH, version pinning MEDIUM due to WebSearch reliance)

---

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| lottie-spm (Airbnb Lottie) | 4.5.x | JSON-driven celebration animations | Industry standard for expressive animations that designers can author. `LottieView` has native SwiftUI API since 4.3.0. Use `lottie-spm` (not `lottie-ios`) — same XCFramework, <500 KB vs 300+ MB git history. Requires Swift 6 / Xcode 16+, which aligns with the project's Xcode 26.2 toolchain. |
| Vortex | 1.0.4 | Confetti/particle burst effects | Pure SwiftUI, zero UIKit bridging, by Paul Hudson (Hacking with Swift). Built-in confetti preset works in 3 lines. High-performance Metal-backed rendering. No bundle bloat. Better than ConfettiSwiftUI for this project because it composes with SwiftUI layout naturally. |
| SwiftUI `.sensoryFeedback` modifier | iOS 17+ (built-in) | Haptic feedback on completions and milestones | Zero-dependency, declarative, trigger-based. Replaced UIKit `UIFeedbackGenerator` for SwiftUI apps. Provides `.success`, `.impact`, `.selection` exactly matching the gamification touch points. No third-party needed. |
| SwiftUI `withAnimation` + `KeyframeAnimator` | iOS 17+ (built-in) | Checkmark spring, card transitions, state changes | iOS 17's `KeyframeAnimator` enables multi-stage celebration sequences (scale up → overshoot → settle) without chaining callbacks. `withAnimation(.spring(duration:bounce:))` with completion closure drives sequential UI states. |
| SwiftUI `matchedGeometryEffect` / `matchedTransitionSource` | iOS 17/18 (built-in) | Hero transitions between journey path and detail | `matchedGeometryEffect` for card-to-screen transitions within a NavigationStack. iOS 18 adds `matchedTransitionSource` + `.zoom` NavigationTransition for sheet/push transitions — cleaner for the celebration screen push. |
| SwiftUI `ScrollView` + `scrollTargetBehavior` | iOS 17+ (built-in) | Journey path vertical scroll with snap-to-node | `scrollTargetBehavior(.viewAligned)` snaps scroll to the active journey node on appearance. No third-party paging library needed. |

### Supporting Libraries

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| lottie-spm | 4.5.x | Lottie animation runner | Use for all celebration screen animations. Source `.lottie` or `.json` files from LottieFiles.com. Wire via `LottieView(name: "celebration").playing()`. |
| Vortex | 1.0.4 | Particle confetti burst | Trigger on action completion and plan completion screens. Use `.confetti` preset as baseline; customise shape/color to match app palette. |

No other third-party libraries are needed. The entire animation, haptics, and journey-path surface is covered by SwiftUI's built-in APIs (iOS 17+) plus the two libraries above.

### Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| LottieFiles.com | Source and preview Lottie JSON animations | Filter for "celebration", "checkmark", "star burst". Download `.lottie` (dotlottie) format — smaller than `.json`. Verify MIT/free license before use. |
| Xcode Accessibility Inspector | Test `reduceMotion` behavior | Set "Reduce Motion" on Simulator; verify all animations fall back to instant/static state. |
| Instruments (Animation Hitches template) | Verify 60fps on iPhone 12 target | Run after adding Lottie animations; check for dropped frames during celebration screens. |

---

## Installation

The project uses Xcode's built-in SPM integration (no `Package.swift` at root — it's an `.xcodeproj` project).

**Add via Xcode: File > Add Package Dependencies**

```
# Lottie (use lottie-spm, NOT lottie-ios)
https://github.com/airbnb/lottie-spm
→ Up to Next Major: 4.5.0

# Vortex
https://github.com/twostraws/Vortex
→ Up to Next Major: 1.0.0
```

No `npm install`. No CocoaPods. Both packages are pure SPM.

---

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| lottie-spm | Pure SwiftUI `TimelineView` animations | Only if no designer is producing animation files and all motion must be coded by hand. Lottie's expressive range far exceeds what's practical to hand-code for celebrations. |
| lottie-spm | Rive (rive-ios) | If animations need interactive state machines (e.g., drag-to-fill progress that responds mid-gesture). Overkill for one-shot celebrations. Adds another large dependency. |
| Vortex | ConfettiSwiftUI (simibac) | ConfettiSwiftUI is simpler API but less maintained, last major release was 1.1.0 with no recent activity. Vortex is more actively developed and composable. |
| Vortex | SPConfetti (ivanvorobei) | SPConfetti is UIKit-backed — needs `UIViewRepresentable` bridging. Adds friction. Avoid in a pure SwiftUI project. |
| Vortex | `CAEmitterLayer` directly | If you need precise physics control (gravity, drag, mass per particle). Acceptable but requires UIKit bridge. Only worth it if Vortex presets are insufficient. |
| `.sensoryFeedback` modifier | `UIImpactFeedbackGenerator` | If targeting iOS 16 or below. This project targets iOS 26.2+, so `.sensoryFeedback` is always available and is strictly cleaner. |
| SwiftUI `KeyframeAnimator` | External animation sequencing library | No third-party sequencing library needed. `KeyframeAnimator` + `withAnimation` completion are sufficient for the checkmark, card flip, and state-change sequences in scope. |

---

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| `lottie-ios` SPM package (the main repo) | 300+ MB git history, slow clone. Same XCFramework as lottie-spm. | `lottie-spm` — identical runtime, ~500 KB package size. |
| Rive (`rive-ios`) | Heavy dependency, interactive state machine complexity not needed. Celebration animations here are one-shot, not interactive. | Lottie for authored animations, SwiftUI keyframes for coded ones. |
| SpriteKit particle systems | Requires `SpriteView` bridge, separate coordinate space, poor SwiftUI layout integration. Overkill for burst confetti. | Vortex — pure SwiftUI, composable, zero bridging overhead. |
| `UIViewPropertyAnimator` for sequence control | Defeats SwiftUI's reactive model, requires imperative lifecycle management. | `withAnimation(.spring(...)) { ... }` + `KeyframeAnimator` — stay declarative. |
| Third-party haptic libraries (e.g., `Haptica`) | All they do is wrap `UIFeedbackGenerator`. SwiftUI `.sensoryFeedback` modifier is the platform-native, declarative version — no wrapper needed. | `.sensoryFeedback(.success, trigger: isCompleted)` |
| Sound effects libraries | PROJECT.md explicitly excludes sound effects from scope. | Nothing — out of scope. |

---

## Stack Patterns by Variant

**For celebration animations (Lottie):**
- Use `LottieView(name: "celebration").playing(loopMode: .playOnce)` triggered by `.onChange` on a completion bool
- Pair `.accessibilityReduceMotion` environment check: skip or shorten animation duration when true
- Store `.lottie` files in the Xcode asset catalog or as bundle resources in `Abimo/Resources/`

**For confetti burst (Vortex):**
- Trigger `VortexSystem` with a `@State var confettiTrigger: Int = 0` incremented on completion
- Layer above the celebration screen content using `.overlay` or `ZStack`
- Respect `reduceMotion` by guarding the trigger increment

**For haptics:**
- Attach `.sensoryFeedback(.success, trigger: actionJustCompleted)` to the completion button
- Use `.sensoryFeedback(.impact(weight: .heavy), trigger: planAllComplete)` for the final plan completion (heavier = more satisfying)
- Use `.sensoryFeedback(.selection, trigger: commitToggle)` for the commitment toggle

**For journey path scroll:**
- Wrap node list in `ScrollViewReader` + `ScrollView`
- Call `proxy.scrollTo(activeNodeID, anchor: .center)` on `.onAppear` to position the path at the current node
- Use `scrollTargetBehavior(.viewAligned)` so manual scrolling snaps cleanly

**For card-to-celebration screen transition:**
- iOS 18 toolchain: use `matchedTransitionSource` on the action card + `.navigationTransition(.zoom(...))` on the celebration screen push
- iOS 17 fallback: `matchedGeometryEffect` with `@Namespace` within the same view hierarchy, or a simple `.spring` scale transition on `NavigationStack` push

**For reduce motion accessibility:**
```swift
@Environment(\.accessibilityReduceMotion) var reduceMotion

// Pattern: substitute instant state change for animation
func animate(_ change: () -> Void) {
    if reduceMotion {
        change()
    } else {
        withAnimation(.spring(duration: 0.4, bounce: 0.3)) {
            change()
        }
    }
}
```

---

## Version Compatibility

| Package | Requires | Notes |
|---------|----------|-------|
| lottie-spm 4.5.x | Xcode 16+ / Swift 6.0+ | Project uses Xcode 26.2, fully compatible. If build fails on strict concurrency, lottie-spm 4.5.x ships as precompiled XCFramework so Swift 6 mode is not a concern. |
| Vortex 1.0.4 | iOS 16+, Swift 5.9+ | Compatible with project's iOS 26.2+ deployment target. No known issues. |
| `.sensoryFeedback` | iOS 17+ | Project minimum implied by Xcode 26.2 / iOS 26 deployment. Always available. |
| `KeyframeAnimator` | iOS 17+ | Same. Always available. |
| `matchedTransitionSource` + `.zoom` | iOS 18+ | Use with `#available(iOS 18, *)` guard if supporting iOS 17. Given the Xcode 26.2 target in project.pbxproj, iOS 18+ can be assumed as minimum but confirm deployment target before using without guard. |

---

## Sources

- [airbnb/lottie-spm GitHub](https://github.com/airbnb/lottie-spm) — Package URL, size comparison, version (WebSearch, MEDIUM confidence)
- [Lottie 4.3.0 SwiftUI support announcement](https://github.com/airbnb/lottie-ios/discussions/2189) — LottieView SwiftUI API confirmation (WebSearch, MEDIUM confidence)
- [Swift Package Index: Vortex](https://swiftpackageindex.com/twostraws/Vortex) — Version 1.0.4, platform support (WebSearch, MEDIUM confidence)
- [twostraws/Vortex GitHub](https://github.com/twostraws/Vortex) — Built-in confetti preset, pure SwiftUI, SPM URL (WebSearch, MEDIUM confidence)
- [SwiftUI sensoryFeedback — Hacking with Swift](https://www.hackingwithswift.com/quick-start/swiftui/how-to-add-haptic-effects-using-sensory-feedback) — Modifier API, feedback types, iOS 17 availability (WebSearch, HIGH confidence — Paul Hudson is authoritative)
- [Swift with Majid: Sensory feedback in SwiftUI](https://swiftwithmajid.com/2023/10/10/sensory-feedback-in-swiftui/) — Trigger-based pattern (WebSearch, HIGH confidence)
- [SwiftUI withAnimation completion — iOS 17](https://medium.com/devtechie/swiftui-withanimation-completion-callback-in-ios-17-3b7f1c7e81ad) — Completion callback API (WebSearch, MEDIUM confidence)
- [KeyframeAnimator — exyte.com](https://exyte.com/blog/keyframes-ios17) — Keyframe animation pattern for checkmark bounce (WebSearch, MEDIUM confidence)
- [matchedTransitionSource iOS 18](https://github.com/onmyway133/blog/issues/995) — Zoom navigation transition vs matchedGeometryEffect (WebSearch, MEDIUM confidence)
- [accessibilityReduceMotion — Hacking with Swift](https://www.hackingwithswift.com/quick-start/swiftui/how-to-detect-the-reduce-motion-accessibility-setting) — Environment key, conditional animation pattern (WebSearch, HIGH confidence)
- [createwithswift.com: Reduce Motion](https://www.createwithswift.com/ensure-visual-accessibility-supporting-reduced-motion-preferences-in-swiftui/) — SwiftUI reduce motion best practice (WebSearch, MEDIUM confidence)
- [scrollTargetBehavior — WWDC23](https://developer.apple.com/videos/play/wwdc2023/10159/) — Scroll snapping API, iOS 17 availability (Official Apple, HIGH confidence)
- project.pbxproj — Confirmed Xcode 26.2 toolchain, Supabase-only existing dependencies, SPM-only package management

---

*Stack research for: Gamified UX layer on Abimo SwiftUI app*
*Researched: 2026-03-18*
