# Requirements: Abimo

**Defined:** 2026-03-20
**Core Value:** Users actually complete their micro-actions because the experience is engaging, rewarding, and fun — not another abandoned to-do list.

## v1.2 Requirements

Requirements for Flow Polish milestone. Each maps to roadmap phases.

### Navigation & Routing

- [x] **NAV-01**: After saving a recording, app switches to Notes tab and deep-links to the new idea's detail view
- [ ] **NAV-02**: "Get your action plan" button navigates to the action plan in the Actions tab (not just dismiss)

### Loading & Feedback

- [x] **LOAD-01**: Transcription-in-progress shows a loading indicator (spinner or skeleton) so the user knows the app is working

### Flow Simplification

- [ ] **FLOW-01**: SWOT analysis triggers with a single button tap (no intermediate page with second button)
- [ ] **FLOW-02**: After SWOT sheet dismisses, the idea's note view refreshes to show the SWOT card and "Ready to act" button without manual navigation

### Naming Consistency

- [ ] **NAME-01**: Action plan title inherits the idea's recording title — "Idea A" → "Idea A's action plan" everywhere it appears

## Future Requirements

### Deferred from v1.1

- **DISC-04**: "Pick this next" bubble on unchosen/locked nodes as ordering entry point
- **CELB-04**: Voice note CTA ("What's next" edge function) — Supabase not ready

## Out of Scope

| Feature | Reason |
|---------|--------|
| XP/points system | Adds complexity without clear value for this use case |
| Leaderboards/social | App is personal, not competitive |
| Sound effects | Adds bundle size, may annoy users (revisit later) |
| Manual action creation | Keeping SWOT origin, not becoming a general todo app |
| "What's next" AI edge function | Supabase not ready |
| Cross-device ordering sync | UserDefaults sufficient for now |
| Full SWOT/recording redesign | v1.2 fixes friction points, not a full redesign |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| NAV-01 | Phase 9 | Complete |
| LOAD-01 | Phase 9 | Complete |
| FLOW-01 | Phase 10 | Pending |
| FLOW-02 | Phase 10 | Pending |
| NAME-01 | Phase 10 | Pending |
| NAV-02 | Phase 10 | Pending |

**Coverage:**
- v1.2 requirements: 6 total
- Mapped to phases: 6
- Unmapped: 0

---
*Requirements defined: 2026-03-20*
*Last updated: 2026-03-20 after roadmap creation*
