# Roadmap: Abimo

## Milestones

- ✅ **v1.0 Actions Flow Revamp** - Phases 1-4 (shipped 2026-03-19)
- ✅ **v1.1 Actions Flow UX** - Phases 5-8 (shipped 2026-03-20)
- 🚧 **v1.2 Flow Polish** - Phases 9-10 (in progress)

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

### 🚧 v1.2 Flow Polish (In Progress)

**Milestone Goal:** Remove friction from the recording → SWOT → action plan pipeline and fix navigation/refresh bugs so the full idea-to-action flow works seamlessly.

- [x] **Phase 9: Recording Flow Polish** - Loading indicator during transcription and deep-link routing after save (completed 2026-03-21)
- [ ] **Phase 10: SWOT and Action Plan Flow** - Single-button SWOT trigger, post-SWOT refresh, action plan naming, and navigation to action plan

## Phase Details

### Phase 9: Recording Flow Polish
**Goal**: Users get clear feedback during transcription and land on their new idea immediately after saving
**Depends on**: Phase 8
**Requirements**: LOAD-01, NAV-01
**Success Criteria** (what must be TRUE):
  1. While transcription is running, a visible loading indicator (spinner or skeleton) appears so the user knows the app is working
  2. After saving a recording, the app navigates to the Notes tab and opens the new idea's detail view without any manual navigation
  3. The loading state clears and the idea detail view shows when transcription completes
**Plans**: 1 plan
Plans:
- [x] 09-01-PLAN.md — NavigationCoordinator, cross-tab deep-link, transcription placeholder card

### Phase 10: SWOT and Action Plan Flow
**Goal**: The full idea → SWOT → action plan pipeline works in one continuous forward flow with no dead ends or stale views
**Depends on**: Phase 9
**Requirements**: FLOW-01, FLOW-02, NAME-01, NAV-02
**Success Criteria** (what must be TRUE):
  1. The idea view shows a single button to trigger SWOT analysis — no intermediate page or second "Run the numbers" button
  2. After the SWOT sheet dismisses, the idea view automatically refreshes to show the SWOT card and "Ready to act" button without manual navigation
  3. The action plan title reads "{idea title}'s action plan" everywhere it appears — in the plan header, plan detail, and any sheet titles
  4. Tapping "Get your action plan" navigates to the action plan in the Actions tab, not just dismisses the sheet
**Plans**: TBD

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
| 9. Recording Flow Polish | v1.2 | 1/1 | Complete   | 2026-03-21 |
| 10. SWOT and Action Plan Flow | v1.2 | 0/? | Not started | - |
