# Feature Research

**Domain:** Gamified micro-action completion UX (Duolingo-style celebration + journey path)
**Researched:** 2026-03-18
**Confidence:** HIGH (celebration UX patterns) / MEDIUM (journey path specifics) / HIGH (anti-features)

---

## Feature Landscape

### Table Stakes (Users Expect These)

These are non-negotiable once the interaction paradigm is "gamified." Missing any of these breaks the
promise implied by the Duolingo-style framing.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Immediate visual feedback on completion | Users expect instant acknowledgment — delay breaks the reward loop | LOW | Color/icon state change on the action card the moment it is tapped |
| Dedicated celebration screen per action | Every Duolingo lesson ends with a full-screen moment; users expect the same cadence | MEDIUM | "Nice job!" or equivalent full-screen interrupt after each micro-action mark-complete |
| Confetti / particle effect on celebration | Confetti is the universal signal of "you won" in mobile apps; absence reads as broken | MEDIUM | Lottie animation; must respect `accessibilityReduceMotion` |
| Haptic feedback on key interactions | iOS users expect physical confirmation on completions and commits; missing it feels cheap | LOW | `.sensoryFeedback(.success)` on completion; `.impact(.medium)` on commit tap |
| Satisfying checkmark animation | Static checkmarks read as a task manager, not a game | LOW | Scale + color transition; can be pure SwiftUI `withAnimation` |
| Visual progress indicator per plan | Users need a sense of "how far am I" at a glance | LOW | Progress bar or ring on the plan card / journey view |
| Differentiated states per action card | Completed, current, locked — users orient by these states | MEDIUM | Three visual states: locked/dim, current/highlighted, done/checked |
| Positive copy tone in celebration | Duolingo's whole thesis is "we're a motivation company not an education company" — generic "Done" feels cold | LOW | Short celebratory strings: "You did it!", "Keep going!", "That's one down!" |
| Full plan completion summary screen | When all actions in a plan are done, the moment must be marked distinctly from a single action | MEDIUM | Larger celebration with summary stats (actions done, streak impact) |
| Streak display visible from journey | Streaks are the #1 retention mechanic in gamified apps; must be visible at the journey level | LOW | Integrate existing streak data into journey path header or plan card |

---

### Differentiators (Competitive Advantage)

These are not expected by default but directly serve Abimo's core value ("users actually complete
their actions because it's engaging, not another abandoned to-do list").

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Vertical journey path (node map) | Transforms a list into a spatial metaphor — users see themselves on a road, not a queue | HIGH | Duolingo's 2022 redesign; nodes represent actions, path curves between them; scroll position = current action |
| Type-mapped emoji/icon per action card | Makes each action feel distinct and thematic without per-item AI calls; cognitive anchors | LOW | Map action `type` field to a fixed emoji set client-side; faster and consistent |
| Progressive disclosure on action cards | Dense info (templates, deep links) hidden behind tap/expand — keeps path visually clean | MEDIUM | Default card shows title + icon + time estimate; expand reveals done criteria, links |
| Animated progress ring (vs bar) | Circular progress rings (Apple Fitness style) feel more game-like and satisfying to close | MEDIUM | `Circle().trim()` with `withAnimation`; progress drives trim fraction |
| Contextual celebration variation | Vary the celebration screen copy and animation based on milestone position (1st action, midpoint, last) | MEDIUM | Three tiers: single action done, halfway point, plan complete — each has distinct tone |
| Smooth path state transitions | Animated unlock of the next action node after completing the current one | MEDIUM | Node scale-up + color transition + brief haptic burst when the next node activates |
| Commitment confirmation micro-moment | Small animated acknowledgment when a user commits to an action (pre-action, mere-measurement moment) | LOW | Brief icon pulse + `.sensoryFeedback(.selection)` — already in app, elevate the UX |
| Momentum dashboard integration | Streak + week activity baked into the journey path header rather than a separate tab | MEDIUM | Collapses the MomentumDashboard into the top of ActionsTabView / journey scroll header |

---

### Anti-Features (Commonly Requested, Often Problematic)

These appear on competitor feature lists but create friction, scope expansion, or dilute the core
experience for Abimo's context.

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| XP / points system | Feels game-like; every Duolingo article mentions XP | Adds a parallel scoring layer with no clear meaning in a personal AI-plan context; users ask "what do I spend points on?" which demands economy design | Streaks + completion count provide implicit score without economy overhead |
| Leaderboards | Social proof, peer comparison | Abimo is personal and private; comparing AI-generated personal action plans is awkward and potentially demotivating | Keep progress personal — the user competes with their own streak record |
| Sound effects | Duolingo's "ding" is iconic | Requires audio asset management, adds bundle size, and annoys users in public; silenced phones make it a no-op | Haptics + visual animations deliver the same emotional payload without audio |
| AI-generated per-action emoji/icons | Truly custom, contextual icons for each action | Adds latency (edge function call per action), inconsistent style, and cost; slows the journey render | Type-based mapping: finite set of action types → emoji; fast, consistent, free |
| Manual action creation | Power users want to add their own tasks | Conflicts with the core product thesis (AI-generated plans); opens a general todo-app scope that requires sorting, tagging, prioritization | Keep SWOT/AI as the only origin; if users want custom tasks, that is a future v2 consideration |
| Persistent badge/achievement wall | Duolingo has leagues and badges | Requires a persistent data model for earned badges, display UI, and curation — high effort for niche engagement | Milestone celebrations within the journey (animated at the moment of achievement) without a separate gallery |
| "Freeze" or skip mechanics | Habitica and Duolingo allow streak freezes | Adds state management complexity; the commitment system already handles "due" reminders — a freeze layer on top creates conflicting signals | Nudge system (already built) handles inactivity without needing a freeze token |
| Over-celebratory animations on every tap | More = more delight (assumed) | Celebration fatigue is real; if every small interaction fires confetti, the signal-to-noise drops and users stop noticing | Reserve full celebrations for completions only; use micro-interactions (scale, color) for lesser taps |

---

## Feature Dependencies

```
Journey Path (node map)
    └──requires──> Action card states (locked / current / done)
                       └──requires──> Data: completion status per action (already in MicroAction)

Celebration screen (per action)
    └──requires──> Completion trigger event (tap "mark done")
    └──requires──> Lottie animation assets (.lottie files for confetti/celebration)

Full plan completion summary
    └──requires──> Celebration screen (per action)  [same infra, extended]
    └──requires──> All-actions-done detection (already derivable from ActionPlan + MicroAction)

Animated progress ring
    └──requires──> Progress fraction derived from completed/total actions (trivial derivation)
    └──enhances──> Journey Path (visual header / plan card)

Momentum dashboard integration
    └──requires──> Streak data (already in app — MomentumDashboard)
    └──enhances──> Journey Path (header area)

Progressive disclosure (card expand)
    └──requires──> Action card states
    └──enhances──> Journey Path visual cleanliness

Haptic feedback
    └──requires──> Completion trigger event
    └──enhances──> Celebration screen, commitment confirmation

Contextual celebration variation
    └──requires──> Celebration screen (per action)
    └──requires──> Position index within plan (1st, nth, last)
```

### Dependency Notes

- **Journey path requires action card states:** The spatial path metaphor only works if each node visually communicates where the user is. Card states (locked, current, done) must be implemented before the path layout is meaningful.
- **Celebration screen requires Lottie assets:** The SPM dependency (lottie-ios) and animation JSON files must exist before the celebration screen can be wired up. Asset acquisition is a pre-implementation step.
- **Full plan completion requires per-action celebration infrastructure:** The summary screen reuses the same Lottie player, copy logic, and dismiss flow — build the per-action screen first, then extend for plan completion.
- **Haptic feedback has no hard dependencies:** Can be added to any interactive element independently; listed as an enhancer rather than a blocker.
- **Progressive disclosure enhances, does not block:** The journey path works without it, but the card density is poor without hide/show logic. Should be implemented in the same phase as the path, not deferred.

---

## MVP Definition

### Launch With (v1 — current milestone scope)

Minimum set that transforms the "utilitarian task manager" into the gamified experience.

- [ ] Journey path (vertical node map) replacing the flat action list — core spatial metaphor
- [ ] Action card with three states: locked, current, done — orientation requires these
- [ ] Type-mapped emoji/icon on each card — immediate visual identity without AI latency
- [ ] Progressive disclosure on cards (expand for templates/deep links) — keeps path clean
- [ ] Completion trigger → celebration screen with Lottie confetti — the primary reward moment
- [ ] Haptic feedback on completion and commit — physical confirmation of success
- [ ] Satisfying checkmark animation and card state transition — visual confirmation
- [ ] Full plan completion summary screen — marks the larger milestone distinctly
- [ ] Animated progress ring on plan — gives "how far" at a glance

### Add After Validation (v1.x)

Features to add once the core experience is proven engaging.

- [ ] Contextual celebration copy variation (1st action, midpoint, last) — requires usage data to confirm users notice the difference
- [ ] Smooth animated node-unlock transition — polish pass after core interactions are stable
- [ ] Momentum dashboard integration into journey header — consolidation UX, not blocking

### Future Consideration (v2+)

- [ ] Sound effects (opt-in toggle) — revisit if user research shows demand; requires audio assets
- [ ] Streak freeze / skip mechanics — only if streak loss becomes a known retention problem
- [ ] Badge/achievement wall — only if completion data shows repeat-session behavior to celebrate

---

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Journey path (node map) | HIGH | HIGH | P1 |
| Action card states (locked/current/done) | HIGH | MEDIUM | P1 |
| Celebration screen (per action, Lottie) | HIGH | MEDIUM | P1 |
| Haptic feedback on completion | HIGH | LOW | P1 |
| Checkmark / card transition animation | HIGH | LOW | P1 |
| Type-mapped emoji/icon per card | MEDIUM | LOW | P1 |
| Full plan completion summary screen | HIGH | MEDIUM | P1 |
| Animated progress ring | MEDIUM | MEDIUM | P2 |
| Progressive disclosure on cards | MEDIUM | MEDIUM | P2 |
| Contextual celebration copy variation | MEDIUM | LOW | P2 |
| Smooth node-unlock transition | MEDIUM | MEDIUM | P2 |
| Momentum dashboard integration | LOW | MEDIUM | P2 |
| Sound effects | LOW | MEDIUM | P3 |
| Streak freeze mechanic | LOW | HIGH | P3 |
| Badge/achievement wall | LOW | HIGH | P3 |

**Priority key:**
- P1: Must have for launch
- P2: Should have, add when possible
- P3: Nice to have, future consideration

---

## Competitor Feature Analysis

| Feature | Duolingo | Habitica | Forest | Abimo Approach |
|---------|----------|----------|--------|----------------|
| Journey / path visualization | Vertical node path with winding road aesthetic | Flat task list + RPG character layer | Timer tree grows during focus session | Vertical node path (Duolingo model, not RPG) |
| Per-item completion celebration | Confetti burst + character animation + XP toast | XP/gold number pop-up + character stat change | Tree completion animation | Full-screen celebration screen + Lottie confetti (no XP numbers) |
| Full session completion | Large "Lesson complete" screen with XP total, streak update, league position | Quest completion screen with loot drop | Tree fully grown, added to forest | Plan completion summary with action count + streak update |
| Progress visualization | Crown levels + progress bar on node | HP/XP/MP bars | Timer ring closing | Progress ring per plan (Apple Fitness style) |
| Streak display | Persistent flame icon + streak count in header | Consecutive daily login streak | Consecutive session days | Streak in journey path header (integrated from existing MomentumDashboard) |
| Haptics | Yes (system-level on iOS) | Yes | Yes | Yes — `.sensoryFeedback` on completion and commit |
| Sound effects | Yes (dings, fanfares) | Yes (RPG sounds) | Yes (nature sounds) | Out of scope v1 |
| Social / competitive | Leagues, friend streaks, leaderboard | Parties, guild quests | Friend forests | Explicitly out of scope — personal app |
| Progressive disclosure on task details | Minimal (lesson content is the card itself) | Tasks expand for notes/checklist | N/A | Tap-to-expand for templates, deep links, done criteria |

---

## Sources

- [Duolingo UX and Gamification Breakdown — UserGuiding](https://userguiding.com/blog/duolingo-onboarding-ux)
- [Duolingo Gamification Case Study — Ulad Shauchenka](https://www.uladshauchenka.com/p/duolingo-case-study-the-gamification)
- [How to Design Like Duolingo — uinkits](https://www.uinkits.com/blog-post/how-to-design-like-duolingo-gamification-engagement)
- [Duolingo New Learning Path Review — Duoplanet](https://duoplanet.com/duolingo-new-learning-path-review/)
- [The Science Behind Duolingo's Home Screen Redesign — Duolingo Blog](https://blog.duolingo.com/new-duolingo-home-screen-design/)
- [Habitica Gamification Case Study — Trophy](https://trophy.so/blog/habitica-gamification-case-study)
- [Designing a Streak System: UX and Psychology — Smashing Magazine](https://www.smashingmagazine.com/2026/02/designing-streak-system-ux-psychology/)
- [Duolingo Micro-Interactions — UX Planet](https://uxplanet.org/ux-and-gamification-in-duolingo-40d55ee09359)
- [Gamification in Product Design 2025 — Arounda](https://arounda.agency/blog/gamification-in-product-design-in-2024-ui-ux)
- [Streaks and Milestones for Gamification — Plotline](https://www.plotline.so/blog/streaks-for-gamification-in-mobile-apps)
- [Adding Haptic Effects in SwiftUI — Hacking with Swift](https://www.hackingwithswift.com/quick-start/swiftui/how-to-add-haptic-effects-using-sensory-feedback)
- [Best Gamified Productivity Apps 2026 — Yu-kai Chou](https://yukaichou.com/lifestyle-gamification/best-task-management-tools-gamification-productivity-apps-2026-habitica-forest-beeminder-task-management-octalysis-best-apps/)
- [Mobile Confetti Design patterns — Mobbin](https://mobbin.com/explore/mobile/screens/confetti)

---

*Feature research for: Gamified micro-action completion UX (Duolingo-style) — Abimo Actions Flow Revamp*
*Researched: 2026-03-18*
