# Requirements: Abimo Actions Flow Revamp

**Defined:** 2026-03-18
**Core Value:** Users actually complete their micro-actions because the experience is engaging, rewarding, and fun

## v1 Requirements

Requirements for this milestone. Each maps to roadmap phases.

### Foundation

- [x] **FOUN-01**: App includes AnimationPolicy wrapper that gates all animations on `accessibilityReduceMotion`
- [x] **FOUN-02**: App includes HapticEngine with pre-prepared feedback generators for zero-latency haptic response
- [x] **FOUN-03**: App includes ActionIconMapper that maps action types (email, search, message, post, default) to emoji/icons

### Journey Path

- [x] **PATH-01**: User sees a vertical scrolling zigzag path with alternating left/right nodes instead of a flat task list
- [x] **PATH-02**: Each node displays one of three states: locked (future/greyed), active (current/highlighted), completed (done/checked)
- [x] **PATH-03**: Path auto-scrolls to the current active node when the view appears
- [x] **PATH-04**: Each node shows a progress ring indicating completion status
- [x] **PATH-05**: Nodes are connected by a visible line/path with animated fill showing progress
- [x] **PATH-06**: When a user completes an action, the next node plays an unlock animation transitioning from locked to active

### Action Cards

- [x] **CARD-01**: Each action displays as a card with a type-mapped emoji/icon, action text, and time estimate pill
- [x] **CARD-02**: Card shows simplified content by default — done criteria and templates are hidden until tap
- [x] **CARD-03**: Tapping a card expands it to reveal done criteria, template text, and deep link buttons
- [x] **CARD-04**: Completed cards show a distinct visual state (not just strikethrough) that feels rewarding
- [x] **CARD-05**: Card plays a spring/flip animation when marked as completed

### Celebrations

- [ ] **CELB-01**: Completing a micro-action triggers an inline confetti burst + haptic + animated checkmark directly on the card
- [ ] **CELB-02**: Completing ALL actions in a plan triggers a full-screen celebration with Lottie animation
- [ ] **CELB-03**: Plan completion celebration shows a summary screen with stats (actions completed, time invested)
- [ ] **CELB-04**: Plan completion screen offers a "Record a new voice note" CTA to encourage reflection
- [ ] **CELB-05**: Milestone celebrations (lighter than plan completion) trigger at 3, 5, and 7 completed actions

### Polish

- [ ] **POLI-01**: Haptic feedback fires on all key interactions: action completion, commitment, milestone
- [ ] **POLI-02**: Node state transitions animate smoothly (locked → active → completed)
- [ ] **POLI-03**: Progress rings animate their fill when progress changes

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### Enhanced Gamification

- **GAME-01**: Streak celebration on new streak milestones (3-day, 7-day, 30-day)
- **GAME-02**: Card flip animation variant (alternate celebration styles to prevent fatigue)
- **GAME-03**: Sound effects for celebrations (opt-in toggle)

### Advanced Path

- **ADVP-01**: Bezier curved connecting lines between nodes (instead of straight lines)
- **ADVP-02**: Parallax scrolling effect on path background

## Out of Scope

| Feature | Reason |
|---------|--------|
| XP/points system | Adds complexity without clear value for personal action plans |
| Leaderboards/social | App is personal, not competitive |
| AI-generated per-action emoji | Type-based mapping is sufficient and faster, no API change |
| Manual action creation | Keeping SWOT origin, not becoming a general todo app |
| Sound effects | Adds bundle size, may annoy users — revisit in v2 |
| Redesign of recording/transcription/SWOT | Only the actions experience is being revamped |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| FOUN-01 | Phase 1 | Complete |
| FOUN-02 | Phase 1 | Complete |
| FOUN-03 | Phase 1 | Complete |
| PATH-01 | Phase 2 | Complete |
| PATH-02 | Phase 2 | Complete |
| PATH-03 | Phase 2 | Complete |
| PATH-04 | Phase 2 | Complete |
| PATH-05 | Phase 2 | Complete |
| PATH-06 | Phase 2 | Complete |
| CARD-01 | Phase 2 | Complete |
| CARD-02 | Phase 2 | Complete |
| CARD-03 | Phase 2 | Complete |
| CARD-04 | Phase 2 | Complete |
| CARD-05 | Phase 2 | Complete |
| CELB-01 | Phase 3 | Pending |
| CELB-02 | Phase 3 | Pending |
| CELB-03 | Phase 3 | Pending |
| CELB-04 | Phase 3 | Pending |
| CELB-05 | Phase 3 | Pending |
| POLI-01 | Phase 4 | Pending |
| POLI-02 | Phase 4 | Pending |
| POLI-03 | Phase 4 | Pending |

**Coverage:**
- v1 requirements: 22 total
- Mapped to phases: 22
- Unmapped: 0 ✓

---
*Requirements defined: 2026-03-18*
*Last updated: 2026-03-18 after roadmap creation*
