# Requirements: Abimo

**Defined:** 2026-03-19
**Core Value:** Users actually complete their micro-actions because the experience is engaging, rewarding, and fun — not another abandoned to-do list.

## v1.0 Requirements (Validated)

All v1.0 requirements shipped. See MILESTONES.md for details.

## v1.1 Requirements

Requirements for Actions Flow UX milestone. Each maps to roadmap phases.

### Node Discoverability

- [ ] **DISC-01**: User can tap any journey node to see a bubble with the action name and a CTA button
- [ ] **DISC-02**: Bubble shows "Complete!" button on the active node and "See more" on completed nodes
- [ ] **DISC-03**: Only one bubble is visible at a time (tapping another node dismisses the previous)

### Action Picker

- [ ] **PICK-01**: User sees a full action list when first viewing a new plan, and can pick their first action
- [ ] **PICK-02**: User sees remaining actions after completing an action, with "Keep the momentum?" framing
- [ ] **PICK-03**: Action picker cards show action name, type icon, and time estimate

### User-Driven Ordering

- [x] **ORDR-01**: When user picks an action from the picker, it becomes the next node on the journey path
- [x] **ORDR-02**: Remaining unpicked actions keep their relative AI-generated order below the chosen one
- [x] **ORDR-03**: User's chosen order persists across app restarts (UserDefaults, keyed by plan ID)

### Completion Flow

- [ ] **CELB-01**: After completing an action, a congrats half-sheet appears with celebration animation and playful CTA
- [ ] **CELB-02**: Tapping the CTA slides the congrats sheet into the action picker ("Keep the momentum?" view)
- [x] **CELB-03**: Two-step flow uses a single sheet with enum-driven state (no boolean sheet races)

## Future Requirements

### Deferred from v1.1

- **DISC-04**: "Pick this next" bubble on unchosen/locked nodes as ordering entry point
- **CELB-04**: Voice note CTA ("What's next" edge function) — Supabase not ready

### Deferred from v1.0

- **GAME-01**: Streak celebration on new streak milestones (3-day, 7-day, 30-day)
- **GAME-02**: Card flip animation variant (alternate celebration styles to prevent fatigue)
- **GAME-03**: Sound effects for celebrations (opt-in toggle)
- **ADVP-01**: Bezier curved connecting lines between nodes
- **ADVP-02**: Parallax scrolling effect on path background

## Out of Scope

| Feature | Reason |
|---------|--------|
| Drag-to-reorder nodes on path | Over-engineered; picker-based selection is simpler and fits the game metaphor |
| XP/points system | Adds complexity without clear value for this use case |
| Sound effects on celebrations | Adds bundle size, may annoy users (revisit later) |
| Supabase schema changes for ordering | Client-side UserDefaults sufficient for v1.1; sync deferred |
| matchedGeometryEffect card-to-node | Nice-to-have animation polish, not core UX fix |
| Leaderboards/social | App is personal, not competitive |
| Manual action creation | Keeping SWOT origin, not becoming a general todo app |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| DISC-01 | Phase 6 | Pending |
| DISC-02 | Phase 6 | Pending |
| DISC-03 | Phase 6 | Pending |
| PICK-01 | Phase 7 | Pending |
| PICK-02 | Phase 7 | Pending |
| PICK-03 | Phase 7 | Pending |
| ORDR-01 | Phase 5 | Complete |
| ORDR-02 | Phase 5 | Complete |
| ORDR-03 | Phase 5 | Complete |
| CELB-01 | Phase 8 | Pending |
| CELB-02 | Phase 8 | Pending |
| CELB-03 | Phase 5 | Complete |

**Coverage:**
- v1.1 requirements: 12 total
- Mapped to phases: 12
- Unmapped: 0 ✓

---
*Requirements defined: 2026-03-19*
*Last updated: 2026-03-19 after v1.1 roadmap creation*
