# Roadmap: Abimo

## Milestones

- ✅ **v1.0 Actions Flow Revamp** - Phases 1-4 (shipped 2026-03-19)
- ✅ **v1.1 Actions Flow UX** - Phases 5-8 (shipped 2026-03-20)
- ✅ **v1.2 Flow Polish** - Phases 9-10 (shipped 2026-03-21)
- ✅ **v1.3 Actions Polish** - Phases 11-13 (shipped 2026-03-21)
- 🔄 **v1.4 Custom Tab Bar** - Phase 14 (in progress)

## Phases

<details>
<summary>✅ v1.0 Actions Flow Revamp (Phases 1-4) - SHIPPED 2026-03-19</summary>

- [x] Phase 1: Foundation (2/2 plans) — completed 2026-03-18
- [x] Phase 2: Journey Path and Action Cards (3/3 plans) — completed 2026-03-19
- [x] Phase 3: Celebration System (2/2 plans) — completed 2026-03-19
- [x] Phase 4: Polish (1/1 plan) — completed 2026-03-19

</details>

<details>
<summary>✅ v1.1 Actions Flow UX (Phases 5-8) - SHIPPED 2026-03-20</summary>

- [x] Phase 5: ViewModel Foundation and Ordering Model (2/2 plans) — completed 2026-03-19
- [x] Phase 6: Tap Bubbles on Nodes (1/1 plan) — completed 2026-03-19
- [x] Phase 7: Action Picker Sheet (1/1 plan) — completed 2026-03-19
- [x] Phase 8: Two-Step Completion Sheet and Full Wiring (2/2 plans) — completed 2026-03-20

</details>

<details>
<summary>✅ v1.2 Flow Polish (Phases 9-10) - SHIPPED 2026-03-21</summary>

- [x] Phase 9: Recording Flow Polish (1/1 plan) — completed 2026-03-21
- [x] Phase 10: SWOT and Action Plan Flow (2/2 plans) — completed 2026-03-21

</details>

<details>
<summary>✅ v1.3 Actions Polish (Phases 11-13) - SHIPPED 2026-03-21</summary>

- [x] Phase 11: Tooltip Overhaul and Action Switching (1/1 plan) — completed 2026-03-21
- [x] Phase 12: Path Curves and Actions Tab Cleanup (2/2 plans) — completed 2026-03-21
- [x] Phase 13: All-Actions View and Unified Switching (1/1 plan) — completed 2026-03-21

</details>

### v1.4 Custom Tab Bar

- [ ] **Phase 14: Custom Tab Bar** - Replace system tab bar with Duolingo-style flat bottom bar; rename Notes to Ideas

## Phase Details

### Phase 14: Custom Tab Bar
**Goal**: Users navigate the app through a custom Duolingo-style tab bar with brand color selection, shake animations, haptic feedback, and a filled indicator — with the Ideas tab name used throughout
**Depends on**: Phase 13 (shipped v1.3)
**Requirements**: TBAR-01, TBAR-02, TBAR-03, TBAR-04, TBAR-05, TBAR-06, NAME-02
**Success Criteria** (what must be TRUE):
  1. The native iOS tab bar chrome is gone — no system tab bar appears anywhere in the app
  2. Tapping any tab plays haptic feedback and the selected icon shakes/bounces visibly
  3. The selected tab icon renders in brand color with a filled circle/pill behind it; unselected icons are gray with no indicator
  4. All 4 tabs show SF Symbol icons only (no text labels): Ideas, Record, Actions, Profile
  5. Every screen that previously said "Notes" now says "Ideas" with no remaining "Notes" references visible to the user
**Plans**: 2 plans
Plans:
- [x] 14-01-PLAN.md — Build CustomTabBar, replace TabView, rename Notes to Ideas
- [ ] 14-02-PLAN.md — On-device visual and haptic verification (checkpoint)

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Foundation | v1.0 | 2/2 | Complete | 2026-03-18 |
| 2. Journey Path and Action Cards | v1.0 | 3/3 | Complete | 2026-03-19 |
| 3. Celebration System | v1.0 | 2/2 | Complete | 2026-03-19 |
| 4. Polish | v1.0 | 1/1 | Complete | 2026-03-19 |
| 5. ViewModel Foundation and Ordering Model | v1.1 | 2/2 | Complete | 2026-03-19 |
| 6. Tap Bubbles on Nodes | v1.1 | 1/1 | Complete | 2026-03-19 |
| 7. Action Picker Sheet | v1.1 | 1/1 | Complete | 2026-03-19 |
| 8. Two-Step Completion Sheet and Full Wiring | v1.1 | 2/2 | Complete | 2026-03-20 |
| 9. Recording Flow Polish | v1.2 | 1/1 | Complete | 2026-03-21 |
| 10. SWOT and Action Plan Flow | v1.2 | 2/2 | Complete | 2026-03-21 |
| 11. Tooltip Overhaul and Action Switching | v1.3 | 1/1 | Complete | 2026-03-21 |
| 12. Path Curves and Actions Tab Cleanup | v1.3 | 2/2 | Complete | 2026-03-21 |
| 13. All-Actions View and Unified Switching | v1.3 | 1/1 | Complete | 2026-03-21 |
| 14. Custom Tab Bar | v1.4 | 1/2 | In Progress|  |
