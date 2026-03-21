# Requirements: Abimo

**Defined:** 2026-03-21
**Core Value:** Users actually complete their micro-actions because the experience is engaging, rewarding, and fun — not another abandoned to-do list.

## v1.3 Requirements

Requirements for Actions Polish milestone. Each maps to roadmap phases.

### Actions Tab Layout

- [ ] **TABS-01**: Actions tab cards show plan title + progress + clean committed action preview (not todo-style circle)
- [ ] **TABS-02**: Committed action preview dropdown expands to show full title and description
- [x] **TABS-03**: Streak section does not show a "commitment" button

### All-Actions View

- [ ] **LIST-01**: Button on journey path header opens a full-screen list of all micro-actions with descriptions, templates, and action buttons (copy, select as next)
- [ ] **LIST-02**: User can select any incomplete action as "next" from the all-actions view, syncing with the journey path

### Action Switching

- [x] **SWAP-01**: User can switch their next action from the tooltip on the journey path without completing the current one
- [ ] **SWAP-02**: Switching next action from either tooltip or all-actions view updates the journey path node order immediately

### Path Visuals

- [x] **PATH-01**: Connecting lines between journey nodes use Bezier curves instead of straight lines

### Tooltip Overhaul

- [x] **TIPS-01**: Tooltips are larger and show the full action title without truncation
- [x] **TIPS-02**: Tooltips expand inline to show description, template text, and action buttons (copy, etc.)
- [x] **TIPS-03**: Tooltips include "Do this next" (switch) and "Complete" buttons
- [x] **TIPS-04**: Tooltip arrow tip is aligned with the center of the tapped node, with no offset drift

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

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| TABS-01 | Phase 12 | Pending |
| TABS-02 | Phase 12 | Pending |
| TABS-03 | Phase 12 | Complete |
| LIST-01 | Phase 13 | Pending |
| LIST-02 | Phase 13 | Pending |
| SWAP-01 | Phase 11 | Complete |
| SWAP-02 | Phase 13 | Pending |
| PATH-01 | Phase 12 | Complete |
| TIPS-01 | Phase 11 | Complete |
| TIPS-02 | Phase 11 | Complete |
| TIPS-03 | Phase 11 | Complete |
| TIPS-04 | Phase 11 | Complete |

**Coverage:**
- v1.3 requirements: 12 total
- Mapped to phases: 12
- Unmapped: 0

---
*Requirements defined: 2026-03-21*
*Last updated: 2026-03-21 after roadmap creation*
