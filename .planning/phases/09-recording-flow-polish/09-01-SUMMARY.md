---
phase: 09-recording-flow-polish
plan: 01
subsystem: ui
tags: [swiftui, navigation, deep-link, coordinator, tdd, xctest, tabview, environmentobject]

# Dependency graph
requires: []
provides:
  - NavigationCoordinator ObservableObject with AppTab enum enabling cross-tab deep-link navigation
  - Post-save automatic navigation from Record tab to the new idea's detail view in Notes tab
  - Transcription placeholder card visible while speech-to-text transcription runs
  - Testable shouldShowTranscribingPlaceholder static helper with 4-case truth table
affects: [10-swot-flow-polish, any-future-navigation-changes]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Coordinator pattern via ObservableObject injected as @EnvironmentObject for cross-tab navigation
    - navigationDestination(isPresented:) with computed Binding<Bool> for programmatic push on deep-link
    - Static testable helpers on SwiftUI View structs for logic that needs behavioral coverage
    - Async test methods in @MainActor XCTestCase to avoid signal abrt crashes with @MainActor classes

key-files:
  created:
    - Abimo/Coordinators/NavigationCoordinator.swift
    - AbimoTests/NavigationCoordinatorTests.swift
    - AbimoTests/NoteDetailViewTests.swift
  modified:
    - Abimo/Views/RootView.swift
    - Abimo/Views/Recording/RecordingView.swift
    - Abimo/Views/Notes/NotesListView.swift
    - Abimo/Views/Notes/NoteDetailView.swift
    - Abimo.xcodeproj/project.pbxproj

key-decisions:
  - "NavigationCoordinator as @MainActor ObservableObject rather than @EnvironmentObject value type — supports published state and integrates cleanly with SwiftUI environment injection"
  - "Async test methods in @MainActor XCTestCase — required for Xcode 26 / Swift 6 strict concurrency; synchronous @MainActor class instantiation crashes with signal abrt"
  - "navigationDestination(isPresented:) computed Binding instead of sheet — allows push onto existing Notes NavigationStack without disrupting existing NavigationLink rows"
  - "Static shouldShowTranscribingPlaceholder helper extracts conditional from view body — makes placeholder logic unit-testable without ViewInspector"
  - "pendingNote cleared only on isPresented set{false} — avoids premature clearing that would break navigation before NoteDetailView renders"

patterns-established:
  - "Coordinator pattern: NavigationCoordinator @StateObject in RootView, passed as @EnvironmentObject to child views"
  - "Async test pattern: all test methods that instantiate @MainActor classes must be async func"
  - "Static testable logic: extract conditional view logic into static func on the View struct for XCTest coverage"

requirements-completed: [LOAD-01, NAV-01]

# Metrics
duration: 24min
completed: 2026-03-20
---

# Phase 09 Plan 01: Recording Flow Polish — Navigation + Transcription Placeholder Summary

**NavigationCoordinator with AppTab enum enabling automatic deep-link from Record tab to new idea's detail view, plus transcription placeholder card with spinner replacing near-empty state while speech-to-text runs**

## Performance

- **Duration:** 24 min
- **Started:** 2026-03-20T21:00:27Z
- **Completed:** 2026-03-20T21:24:00Z
- **Tasks:** 3 of 3
- **Files modified:** 8

## Accomplishments

- NavigationCoordinator created with AppTab enum (notes/record/actions/profile), selectedTab, pendingNote, and navigateToNote() — injected as @EnvironmentObject from RootView throughout the app
- TabView upgraded from uncontrolled to selection-bound using typed AppTab tags (no raw Int)
- RecordingView now captures saveRecording return value and triggers coordinator.navigateToNote() on success
- NotesListView uses navigationDestination(isPresented:) with computed Binding to push NoteDetailView when coordinator.pendingNote is set
- NoteDetailView shows a "Transcribing your idea..." placeholder card with spinner while isLoadingTranscription is true and transcription is nil; transitions smoothly to the "Put it to the test" CTA card when done
- 9 unit tests pass: 5 for NavigationCoordinator behavior, 4 for placeholder visibility truth table

## Task Commits

Each task was committed atomically:

1. **Task 1: Create NavigationCoordinator and wire cross-tab deep-link navigation** - `2f5f24b` (feat)
2. **Task 2: Add transcription placeholder card to NoteDetailView with behavioral tests** - `814075f` (feat)
3. **Task 3: Verify recording flow end-to-end** - human-verify checkpoint, approved by user

## Files Created/Modified

- `Abimo/Coordinators/NavigationCoordinator.swift` - New: AppTab enum + NavigationCoordinator with selectedTab, pendingNote, navigateToNote()
- `AbimoTests/NavigationCoordinatorTests.swift` - New: 5 async unit tests covering coordinator state transitions
- `AbimoTests/NoteDetailViewTests.swift` - New: 4 unit tests covering placeholder visibility truth table
- `Abimo/Views/RootView.swift` - Added coordinator @StateObject, environmentObject injection, TabView selection binding with AppTab tags
- `Abimo/Views/Recording/RecordingView.swift` - Added coordinator @EnvironmentObject, wired navigateToNote() on save success
- `Abimo/Views/Notes/NotesListView.swift` - Added coordinator @EnvironmentObject, navigationDestination(isPresented:) for deep-link push
- `Abimo/Views/Notes/NoteDetailView.swift` - Added shouldShowTranscribingPlaceholder static helper, transcribingPlaceholderCard view builder, updated cards section, animation on isLoadingTranscription
- `Abimo.xcodeproj/project.pbxproj` - Added NavigationCoordinatorTests, NoteDetailViewTests, ActionPickerSheetTests to AbimoTests target

## Decisions Made

- Used async test methods in @MainActor XCTestCase — required for Xcode 26 strict concurrency. Synchronous @MainActor class instantiation in XCTest crashes with signal abrt even when test class is also @MainActor.
- Used navigationDestination(isPresented:) with computed Binding rather than a separate NavigationLink — allows programmatic push without duplicating the note in the list's existing NavigationLinks.
- Static shouldShowTranscribingPlaceholder helper on NoteDetailView struct — avoids ViewInspector dependency while providing full XCTest behavioral coverage.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Added missing `import Combine` to NavigationCoordinator.swift**
- **Found during:** Task 1 (NavigationCoordinator creation)
- **Issue:** `@Published` property wrappers require Combine but only SwiftUI was imported; build failed with "initializer 'init(wrappedValue:)' is not available due to missing import of defining module 'Combine'"
- **Fix:** Added `import Combine` to NavigationCoordinator.swift
- **Files modified:** Abimo/Coordinators/NavigationCoordinator.swift
- **Verification:** Build succeeded after fix
- **Committed in:** 2f5f24b (Task 1 commit)

**2. [Rule 1 - Bug] Changed test methods from synchronous to async**
- **Found during:** Task 1 (NavigationCoordinatorTests)
- **Issue:** Synchronous test methods crash with signal abrt when instantiating @MainActor classes in Xcode 26 / Swift 6 strict concurrency, even when the test class itself is @MainActor
- **Fix:** Changed all test method signatures from `func testX()` to `func testX() async`
- **Files modified:** AbimoTests/NavigationCoordinatorTests.swift
- **Verification:** All 5 tests pass after fix
- **Committed in:** 2f5f24b (Task 1 commit)

**3. [Rule 2 - Missing] Added ActionPickerSheetTests.swift to pbxproj**
- **Found during:** Task 1 (setting up test infrastructure)
- **Issue:** ActionPickerSheetTests.swift existed on disk but was not referenced in the Xcode project — its tests never ran
- **Fix:** Added file reference and build file entry to AbimoTests target in project.pbxproj
- **Files modified:** Abimo.xcodeproj/project.pbxproj
- **Verification:** File now included in AbimoTests target
- **Committed in:** 2f5f24b (Task 1 commit)

---

**Total deviations:** 3 auto-fixed (2 bugs, 1 missing critical)
**Impact on plan:** All fixes necessary for compilation and correct test execution. No scope creep.

## Issues Encountered

- Xcode 26 / Swift 6 strict concurrency requires async test methods when instantiating @MainActor classes in XCTest, even with @MainActor test class annotation. All existing PostCompletionSheetTests tests that create @MainActor ViewModels synchronously also fail — this is a pre-existing project issue, deferred per scope boundary rules.

## Next Phase Readiness

- NavigationCoordinator is available as @EnvironmentObject throughout the app — any future cross-tab navigation can use coordinator.navigateToNote() or extend with new cases
- Human verification passed: save -> deep-link -> placeholder -> CTA transition -> idle reset all confirmed on device
- Phase 09-01 complete — NavigationCoordinator available as @EnvironmentObject throughout app for any future cross-tab navigation needs

---
*Phase: 09-recording-flow-polish*
*Completed: 2026-03-20*
