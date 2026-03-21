# Roadmap: Abimo

## Milestones

- ✅ **v1.0 Actions Flow Revamp** - Phases 1-4 (shipped 2026-03-19)
- ✅ **v1.1 Actions Flow UX** - Phases 5-8 (shipped 2026-03-20)
- ✅ **v1.2 Flow Polish** - Phases 9-10 (shipped 2026-03-21)
- 🚧 **v1.3 Actions Polish** - Phases 11-13 (in progress)

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

### 🚧 v1.3 Actions Polish (In Progress)

**Milestone Goal:** Make the Actions tab and journey path feel polished — clean layout, better tooltips, flexible action switching, and curved path lines.

- [x] **Phase 11: Tooltip Overhaul and Action Switching** - Redesigned tooltips with full titles, icon buttons, switch/complete actions, and fixed arrow alignment (completed 2026-03-21)
- [ ] **Phase 12: Path Curves and Actions Tab Cleanup** - Bezier curves between nodes and simplified Actions tab card layout
- [ ] **Phase 13: All-Actions View and Unified Switching** - Full action list accessible from path header with select-as-next wired to both surfaces

## Phase Details

### Phase 11: Tooltip Overhaul and Action Switching
**Goal**: Users see larger, fully-readable tooltips with Duolingo-style icon buttons and can switch their next action directly from the tooltip
**Depends on**: Phase 10
**Requirements**: TIPS-01, TIPS-02, TIPS-03, TIPS-04, SWAP-01
**Success Criteria** (what must be TRUE):
  1. Tapping a journey node opens a tooltip large enough to show the full action title without truncation
  2. Tapping an expand control inside the tooltip reveals the action description, template text, and copy button inline — without opening a separate sheet
  3. The tooltip contains a "Do this next" button that switches the active action and updates the journey path immediately — without completing the current action
  4. The tooltip contains a "Complete" button that marks the action done
  5. The tooltip arrow tip visually points to the center of the tapped node with no horizontal or vertical offset drift
**Plans:** 1/1 plans complete
Plans:
- [x] 11-01-PLAN.md — Rewrite NodeBubbleView + fix arrow alignment + wire action switching

### Phase 12: Path Curves and Actions Tab Cleanup
**Goal**: The journey path uses smooth Bezier curves between nodes and the Actions tab shows clean, focused card layouts without commitment clutter
**Depends on**: Phase 10
**Requirements**: PATH-01, TABS-01, TABS-02, TABS-03
**Success Criteria** (what must be TRUE):
  1. Connecting lines between journey path nodes are curved (Bezier) rather than straight segments
  2. Each action plan card in the Actions tab shows the plan title, progress indicator, and a clean committed-action preview — not a to-do-style circle
  3. The committed action preview expands to show the full title and description when tapped
  4. The Actions tab streak section has no "commitment" button visible
**Plans:** 2 plans
Plans:
- [ ] 12-01-PLAN.md — Bezier S-curves for path lines + remove commitment section from MomentumDashboard
- [ ] 12-02-PLAN.md — Bolt icon committed action preview with expand/collapse in ideaCards

### Phase 13: All-Actions View and Unified Switching
**Goal**: Users can open a full list of all micro-actions from the journey path header and select any incomplete action as their next, with the path updating immediately regardless of which surface triggered the switch
**Depends on**: Phase 11
**Requirements**: LIST-01, LIST-02, SWAP-02
**Success Criteria** (what must be TRUE):
  1. A button in the journey path header opens a full-screen list showing all micro-actions with descriptions, templates, and action buttons (copy, select as next)
  2. Tapping "Select as next" on any incomplete action in the all-actions view updates which node is active on the journey path immediately
  3. Switching next action from either the tooltip (Phase 11) or the all-actions view produces identical journey path state — both surfaces stay in sync
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
| 9. Recording Flow Polish | v1.2 | 1/1 | Complete | 2026-03-21 |
| 10. SWOT and Action Plan Flow | v1.2 | 2/2 | Complete | 2026-03-21 |
| 11. Tooltip Overhaul and Action Switching | v1.3 | 1/1 | Complete    | 2026-03-21 |
| 12. Path Curves and Actions Tab Cleanup | v1.3 | 0/2 | Not started | - |
| 13. All-Actions View and Unified Switching | v1.3 | 0/? | Not started | - |
