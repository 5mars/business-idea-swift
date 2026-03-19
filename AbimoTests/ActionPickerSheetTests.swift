//
//  ActionPickerSheetTests.swift
//  AbimoTests
//

import XCTest
@testable import Abimo

@MainActor
final class ActionPickerSheetTests: XCTestCase {

    // MARK: - Helpers

    /// Creates a fresh ViewModel with microActions pre-populated (no Supabase).
    private func makeViewModel(actionCount: Int) -> ActionPlanViewModel {
        let vm = ActionPlanViewModel()
        vm.microActions = (0..<actionCount).map { i in
            MicroAction(
                id: UUID(),
                actionPlanId: UUID(),
                text: "Action \(i + 1)",
                doneCriteria: "Done",
                timeEstimateMinutes: 10,
                priority: i,
                quadrant: nil,
                template: nil,
                actionType: nil,
                deepLinkData: nil,
                isCompleted: false,
                completedAt: nil,
                isCommitted: false,
                committedAt: nil,
                scheduledFor: nil,
                completionOutcome: nil,
                completionNote: nil,
                createdAt: Date()
            )
        }
        return vm
    }

    // MARK: - Tests

    func testIncompleteActionsFilterExcludesCompletedAndExcludedId() {
        let vm = makeViewModel(actionCount: 5)
        // Mark action[0] and action[2] completed
        vm.microActions[0].isCompleted = true
        vm.microActions[2].isCompleted = true

        let excludedId = vm.microActions[0].id

        // Replicate ActionPickerSheet's incompleteActions filter
        let incompleteActions = vm.orderedActions.filter { !$0.isCompleted && $0.id != excludedId }

        // Expect: action[1], action[3], action[4] (not action[0] — excluded, not action[2] — completed)
        XCTAssertEqual(incompleteActions.count, 3,
                       "incompleteActions must exclude both completed actions and the excludedId action")
        XCTAssertFalse(incompleteActions.contains(where: { $0.isCompleted }),
                       "incompleteActions must not contain any completed actions")
        XCTAssertFalse(incompleteActions.contains(where: { $0.id == excludedId }),
                       "incompleteActions must not contain the excluded action id")
    }

    func testCompletedActionsFilterExcludesExcludedId() {
        let vm = makeViewModel(actionCount: 5)
        // Mark action[0] and action[2] completed
        vm.microActions[0].isCompleted = true
        vm.microActions[2].isCompleted = true

        let excludedId = vm.microActions[0].id

        // Replicate ActionPickerSheet's completedActions filter
        let completedActions = vm.orderedActions.filter { $0.isCompleted && $0.id != excludedId }

        // Expect: only action[2] (action[0] is excluded)
        XCTAssertEqual(completedActions.count, 1,
                       "completedActions must exclude the action matching excludedId")
        XCTAssertTrue(completedActions.allSatisfy(\.isCompleted),
                      "completedActions must all have isCompleted == true")
        XCTAssertEqual(completedActions.first?.id, vm.microActions[2].id,
                       "completedActions must contain only action[2] (action[0] is excluded)")
    }

    func testFirstVisitPickerShowsAllIncompleteActions() {
        let vm = makeViewModel(actionCount: 4)
        // All actions are incomplete, no excludedId (firstVisit mode)
        let incompleteActions = vm.orderedActions.filter { !$0.isCompleted }

        XCTAssertEqual(incompleteActions.count, 4,
                       "First-visit picker must show all incomplete actions when none are completed")
    }

    func testPickActionDismissesPickerAndReorders() {
        let vm = makeViewModel(actionCount: 3)
        let targetId = vm.microActions[2].id

        vm.pickAction(id: targetId)

        XCTAssertFalse(vm.showActionPicker,
                       "pickAction must set showActionPicker to false")
        XCTAssertEqual(vm.orderedActions.first?.id, targetId,
                       "pickAction must reorder so the picked action is first")
    }
}
