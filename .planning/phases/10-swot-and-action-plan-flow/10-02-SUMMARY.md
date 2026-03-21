---
phase: 10-swot-and-action-plan-flow
plan: "02"
subsystem: navigation
tags: [navigation, swot, action-plan, coordinator, async]
dependency_graph:
  requires: ["10-01"]
  provides: ["NAV-02", "FLOW-02"]
  affects: [SWOTAnalysisView, NavigationCoordinator, ActionsTabView]
tech_stack:
  added: []
  patterns: [fire-and-forget Task, @EnvironmentObject coordinator, @Published flag]
key_files:
  created: []
  modified:
    - Abimo/Coordinators/NavigationCoordinator.swift
    - Abimo/Views/Analysis/SWOTAnalysisView.swift
    - Abimo/Views/ActionPlan/ActionsTabView.swift
    - AbimoTests/NavigationCoordinatorTests.swift
decisions:
  - "Fire-and-forget Task in SWOTAnalysisView captures analysis/transcriptionText/noteTitle before dismiss and calls AIAnalysisService directly (not viewModel) so it survives sheet teardown"
  - "pendingPlanGeneration flag on NavigationCoordinator bridges loading state across the sheet dismiss boundary to ActionsTabView"
  - "ActionsTabView observes both selectedTab and pendingPlanGeneration changes to refresh at the right moments — on arrival and on generation completion"
metrics:
  duration: 25min
  completed_date: "2026-03-21"
  tasks_completed: 1
  files_changed: 4
---

# Phase 10 Plan 02: Wire Action Plan CTA Navigation Summary

**One-liner:** Navigate+dismiss+fire-and-forget pattern using coordinator flag bridges SWOT sheet and Actions tab across sheet dismissal boundary.

## What Was Built

Wired the "Get your action plan" button in SWOTAnalysisView to navigate to the Actions tab, dismiss the sheet, and fire background plan generation — eliminating the dead-end where the button previously only called `dismiss()`.

### NavigationCoordinator (`pendingPlanGeneration` flag)

Added `@Published var pendingPlanGeneration: Bool = false` to bridge the loading state across the SWOT sheet → Actions tab boundary. The flag is set before dismiss and cleared after generation completes.

### SWOTAnalysisView (`actionPlanCTA` button)

Replaced the simple `dismiss()` call with a three-step sequence:
1. Capture `analysis`, `transcriptionText`, and `noteTitle` before any state changes
2. Set `coordinator.pendingPlanGeneration = true`, switch tab to `.actions`, call `dismiss()`
3. Fire a `Task { @MainActor in }` that calls `AIAnalysisService()` directly (not viewModel, which is deallocated after dismiss)

### ActionsTabView (refresh + generating indicator)

- Added `@EnvironmentObject var coordinator: NavigationCoordinator`
- Added `.onChange(of: coordinator.selectedTab)` to call `viewModel.loadAllPlans()` when user arrives on Actions tab
- Added `.onChange(of: coordinator.pendingPlanGeneration)` to re-fetch when generation finishes
- Added inline "Cooking up your action plan..." `ProgressView` banner shown above plan list during generation
- Added first-plan loading state: when `plans.isEmpty && pendingPlanGeneration`, shows centered spinner + text instead of empty state

### Tests (NavigationCoordinatorTests)

Added 2 tests using the existing `@MainActor async` pattern:
- `testPendingPlanGenerationDefaultsFalse` — asserts the flag initializes to false
- `testPendingPlanGenerationToggle` — asserts the flag can be toggled true/false

All 7 NavigationCoordinator tests pass.

## Deviations from Plan

None — plan executed exactly as written.

## Acceptance Criteria Verification

- `grep "coordinator.selectedTab = .actions" SWOTAnalysisView.swift` — found at line 231
- `grep "pendingPlanGeneration" NavigationCoordinator.swift` — found at line 20
- `grep "pendingPlanGeneration" ActionsTabView.swift` — found at lines 22, 25, 52, 88
- `grep "AIAnalysisService()" SWOTAnalysisView.swift` — found at line 238
- `grep -c "dismiss()" SWOTAnalysisView.swift` — returns 2 (toolbar Done + actionPlanCTA)
- `grep "onChange.*selectedTab" ActionsTabView.swift` — found at line 83
- `grep "onChange.*pendingPlanGeneration" ActionsTabView.swift` — found at line 88
- `grep "Cooking up your action plan" ActionsTabView.swift` — found at lines 32 and 56
- `grep "pendingPlanGeneration" NavigationCoordinatorTests.swift` — found at lines 78-91

## Commits

| Hash | Type | Description |
|------|------|-------------|
| e8aec93 | test | add failing tests for pendingPlanGeneration (RED) |
| 4f939ee | feat | wire actionPlanCTA to navigate and generate (GREEN) |

## Self-Check: PASSED

Files confirmed present:
- Abimo/Coordinators/NavigationCoordinator.swift — FOUND
- Abimo/Views/Analysis/SWOTAnalysisView.swift — FOUND
- Abimo/Views/ActionPlan/ActionsTabView.swift — FOUND
- AbimoTests/NavigationCoordinatorTests.swift — FOUND

Commits confirmed:
- e8aec93 — FOUND
- 4f939ee — FOUND

Tests: 7/7 NavigationCoordinatorTests pass (TEST SUCCEEDED)
Build: BUILD SUCCEEDED
